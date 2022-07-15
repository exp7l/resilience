// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./interfaces/ierc20.sol";
import "./interfaces/ivault.sol";
import "./interfaces/IMarketManager.sol";
import "./math.sol";
import "./rdb.sol";

/*
  Scope:
  0. Track each fund's (key: fundId) backing for each market (key: marketId)
  1. Manage vaults.
  2  Appointment of manager.
  3. Liquidity provision using USD from the vaults the fund manages. 
  4. Allow for direct redemption?
*/

contract Fund is Math {
    //       fundId
    mapping (uint => Appointment) public  appointments;

    mapping (uint => uint[])                         public  backings;

    //      fundId          marketId     weight
    mapping (uint => mapping(uint     => uint))      public  fundWeights;

    RDB rdb;

    struct Appointment {
        uint    fundId;
        address manager;
        address nomination;
    }

    constructor(address _rdb)
    {
        rdb = RDB(_rdb);
    }

    function createFund(uint    _fundId)
        external
    {
        Appointment memory _a = appointments[_fundId];
        require(_a.manager == address(0), "ERR_FUNDID_TAKEN");
        require(_a.manager != address(1), "ERR_RENOUNCED");
        appointments[_fundId] = Appointment({
            fundId:      _fundId,
            manager:     msg.sender,
            nomination:  address(0)});
    }

    // trigger when staking position changes - vault minting, set fund position
    function rebalanceMarkets(uint _fundId)
        public
    {

        bool _isSysCall = msg.sender == rdb.vault();
        bool _isManager = msg.sender == appointments[_fundId].manager;
        require(_isSysCall || _isManager, "ERR_AUTH");

        // wETH is the only asset now, so total liquidity is wETH's
        // vault USD balance.
        address _weth              = rdb.weth();
        IVault _v = IVault(rdb.vault());
        (, , ,uint _totalLiquidity, ) = _v.bvaults(_fundId, _weth);

        uint[] storage _backings = backings[_fundId];
        uint   _totalWeight;

        for (uint i=0; i < _backings.length; i++) {
            _totalWeight += fundWeights[_fundId][_backings[i]];
        }

        for (uint i=0; i < _backings.length; i++) {
            uint _marketId = _backings[i];
            uint _factor  = wdiv(fundWeights[_fundId][_marketId], _totalWeight);
            uint _marketLiquidity = wmul(_totalLiquidity, _factor);
            IMarketManager(rdb.marketManager()).setLiquidity(_marketId,
                                                             _fundId,
                                                             _marketLiquidity);
        }
    }
  
    // Persist state about the fund's portfolio allocation then rebalance.
    function setFundPosition(uint            _fundId,
                             uint[] calldata _markets,
                             uint[] calldata _weights)
        external
    {
        require(msg.sender == appointments[_fundId].manager, "ERR_AUTH");
        require(_markets.length == _weights.length, "ERR_INPUT_LEN");
        require(_markets.length <= 100, "ERR_INPUT_LEN");

        for (uint i=0; i < _markets.length; i++) {
            fundWeights[_fundId][_markets[i]] = _weights[i];
            backings[_fundId].push(_markets[i]);
        }

        rebalanceMarkets(_fundId);
    }
  
    function nominateFundOwner(uint    _fundId,
                               address _manager)
        external
    {
        Appointment storage _a = appointments[_fundId];
        require(msg.sender == _a.manager, "ERR_AUTH");
        _a.nomination = _manager;
    }

    function acceptFundOwnership(uint _fundId)
        external
    {
        Appointment storage _a = appointments[_fundId];
        require(msg.sender == _a.nomination, "ERR_AUTH");
        _a.manager    = msg.sender;
        _a.nomination = address(0);
    }
  
    function renounceFundOwnership(uint _fundId)
        external
    {
        Appointment storage _a = appointments[_fundId];
        require(msg.sender == _a.manager, "ERR_AUTH");
        _a.manager    = address(1);
        _a.nomination = address(0);
    }
}

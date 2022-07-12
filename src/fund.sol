// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/erc20.sol";
import "./rdb.sol";

/*
  Scope:
  1. Manage vaults.
  2 Appointment of manager.
  3. Liquidity provision using USD from the vaults the fund manages.
*/

contract Fund {
  //       fundId
  mapping (uint => Appointment) public  appointments;

  //       marketId  weight
  mapping (uint =>   uint)      public  positions;

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

  function createFund(uint    _fundId,
                      address _manager)
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
  
  function rebalanceMarkets(uint fundId)
    external
  {
  }
  
  function setFundPosition(uint            _fundId,
                           uint[] calldata _markets,
                           uint[] calldata _weights)
    external
  {
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

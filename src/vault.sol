// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/ierc20.sol";
import "./interfaces/ifund.sol";
import "./interfaces/ideed.sol";
import "./rdb.sol";
import "./auth.sol";
import "./math.sol";
import "./shield.sol";
 
/*
  Tracks debt accured by minting rUSD, by Big Vault and Small Vault. 
  A fund has one-to-many relationship with Big Vaults.
  A Big Vault has one-to-many relationship with Small Vaults.
*/

contract Vault is Auth, Math, Shield {

    RDB rdb;    
    // fundId => ctype => Big Vault; Mirrors the sum of Small Vaults
    mapping(uint => mapping(address => BVault)) public bvaults;
    // fundId => ctype => deedId => Small Vault
    mapping(uint => mapping(address => mapping(uint => SVault))) public svaults;
    uint public initialDebtShares = 100 * 10 ** 18;

    struct BVault {
        uint    fundId;    
        address ctype;       // collateral type
        uint    camount;     // collateral amount
        uint    usd;         // rUSD minted
        uint    debtShares;  // debt shares accured due to rUSD minting
    }

    struct SVault {
        uint    fundId;    
        address ctype;
        uint    deedId;    
        uint    camount;  
        uint    usd;
        uint    debtShares;  
    }    

    modifier own(uint _deedId)
    {
        IDeed _d = IDeed(rdb.deed());
        require(_d.ownerOf(_deedId) == msg.sender, "ERR_OWN");
        _;
    }

    event Deposit(uint    indexed fundId,
                  address indexed ctype,
                  uint    indexed deedId,
                  uint            camount);

    event Withdraw(uint    indexed fundId,
                   address indexed ctype,
                   uint    indexed deedId,
                   uint            camount);

    event Mint(uint    indexed fundId,
               address indexed ctype,
               uint    indexed deedId,
               uint            usd);

    event Burn(uint    indexed fundId,
               address indexed ctype,
               uint    indexed deedId,
               uint            usd);        
  
    constructor(address _rdb)
    {
        rdb           = RDB(_rdb);
        IERC20 _rusd  = IERC20(rdb.rusd());
        // Grant other contracts in the system access to rUSD
        _rusd.approve(rdb.fund(),          type(uint).max);
        _rusd.approve(rdb.marketManager(), type(uint).max);
    }

    function _createVaults(uint    _fundId,
                           address _ctype,
                           uint    _deedId)
        private
    {
        BVault storage _v  = bvaults[_fundId][_ctype];
        _v.fundId          = _fundId;
        _v.ctype           = _ctype;        
        SVault storage _mv = svaults[_fundId][_ctype][_deedId];
        _mv.fundId         = _fundId;        
        _mv.ctype          = _ctype;
        _mv.deedId         = _deedId;
    }    

    function deposit(uint    _fundId,
                     address _ctype,
                     uint    _deedId,
                     uint    _camount)
        external
        lock
        own(_deedId)
    {
        BVault storage _bv =  bvaults[_fundId][_ctype];
        if (_bv.fundId == 0) {
            _createVaults(_fundId, _ctype, _deedId);
        }        
        SVault storage _sv =  svaults[_fundId][_ctype][_deedId];
        _sv.camount += _camount;
        _bv.camount += _camount;
        require(IERC20(_ctype).transferFrom(msg.sender,
                                            address(this),
                                            _camount),
                "ERR_TRANSFER");
        emit Deposit(_fundId,
                     _ctype,
                     _deedId,
                     _camount);
    }

    function withdraw(uint    _fundId,
                      address _ctype,
                      uint    _deedId,
                      uint    _camount)
        external
        lock
        own(_deedId)
    {
        bvaults[_fundId][_ctype].camount -= _camount;
        svaults[_fundId][_ctype][_deedId].camount -= _camount;
        require(_metCratioReq(_fundId,
                              _ctype,
                              _deedId,
                              rdb.targetCratios(_ctype)),
                "ERR_CRATIO");
        require(IERC20(_ctype).transferFrom(address(this),
                                            msg.sender,
                                            _camount),
                "ERR_TRANSFER");
        emit Withdraw(_fundId,
                      _ctype,
                      _deedId,
                      _camount);
    }

    function _metCratioReq(uint    _fundId,
                           address _ctype,
                           uint    _deedId,
                           uint    _cratioReq)
        internal
        returns (bool)
    {
        SVault storage _svault = svaults[_fundId][_ctype][_deedId];
        if (_svault.usd == 0) return true;        
        uint _collateralUSD = rdb.assetUSDValue(_ctype, _svault.camount);
        uint cratioSVault   = wdiv(_collateralUSD, _svault.usd);
        return cratioSVault >= _cratioReq;
    }

    function mint(uint    _fundId,
                  address _ctype,
                  uint    _deedId,
                  uint    _usd)
        external
        lock
    {        
        require(_fundId != 0, "ERR_ID");
        require(_usd > 0,     "ERR_MINT");

        BVault storage _bv = bvaults[_fundId][_ctype];
        SVault storage _sv = svaults[_fundId][_ctype][_deedId];

        require(_sv.camount > 0, "ERR_MINT");

        if (_bv.fundId == 0) {
            _createVaults(_fundId, _ctype, _deedId);
        }

        if (_bv.debtShares == 0) {
            _bv.debtShares = initialDebtShares;
            _sv.debtShares = initialDebtShares;
        } else {
            uint _shareDiff  =  wmul(_bv.debtShares, wdiv(_usd, _bv.usd));
            _bv.debtShares  += _shareDiff;
            _sv.debtShares  += _shareDiff;
        }

        _bv.usd += _usd;
        _sv.usd += _usd;

        require(_metCratioReq(_fundId,
                              _ctype,
                              _deedId,
                              rdb.targetCratios(_ctype)),
                "ERR_CRATIO");

        IERC20(rdb.rusd()).mint(address(this), _usd);

        emit Mint(_fundId,
                  _ctype,
                  _deedId,
                  _usd);
        
    }

    function burn(uint    _fundId,
                  address _ctype,
                  uint    _deedId,
                  uint    _usd)
        external
        lock
    {
        require(_usd > 0,        "ERR_BURN");        

        BVault storage _bv = bvaults[_fundId][_ctype];         
        SVault storage _sv = svaults[_fundId][_ctype][_deedId];

        require(_sv.usd >= _usd, "ERR_BURN");

        uint _factor    =  wdiv(_usd, _bv.usd);
        uint _shareDiff =  wmul(_bv.debtShares, _factor);
        _bv.debtShares -= _shareDiff;
        _sv.debtShares -= _shareDiff;
        _bv.usd        -= _usd;
        _sv.usd        -= _usd;

        IERC20(rdb.rusd()).burn(address(this), _usd);

        emit Burn(_fundId,
                  _ctype,
                  _deedId,
                  _usd);        
    }

    function vaultDebt(uint    _fundId,
                       address _ctype)
        external
        view
    {
    }
  
    function totalDebtShares(uint    _fundId,
                             address _ctype)
        external
        view
    {
    }
  
    function debtPerShare(uint    _fundId,
                          address _ctype)
        external
        view
    {
    }

    function cratio(uint    _fundId,
                    address _ctype,
                    uint    _deedId)
        external
        view
    {
    }  

    function deedDebt(uint    _fundId,
                      address _ctype,
                      uint    _deedId)
        external
        view
    {
    }

    /* 
       Will revisit this in-depth. 
       For now, the liquidation mechanic is simply allowing liquidator
       to redeem collateral in a small vault at a steep (30%) discount, for simplicity.

       The SIP proposes debt&collateral socialization among small vaults in the same big vault. I think this can be the final backstop, but I think require some more thinking in relationship to other pieces, as well as redemption for collateral at the big vault level.
     */
    function liquidatePosition(uint     _fundId,
                               address  _ctype,
                               uint     _deedId,
                               uint     _usd)
        external
        lock
    {
        require(_metCratioReq(_fundId,
                              _ctype,
                              _deedId,
                              rdb.minCratios(_ctype)),
                "ERR_CRATIO");
        // How much of debt held by this small vault is covered by _usd?
        SVault storage _svault = svaults[_fundId][_ctype][_deedId];
        uint _collateralUSD    = rdb.assetUSDValue(_ctype, _svault.camount);
        require(_collateralUSD > 0, "ERR_EMPTY_SVAULT");
        uint _factor           = wdiv(_usd, _collateralUSD);
        uint _shareDiff        = wmul(_factor, _svault.debtShares);

        // deduct debt shares from the small vault as it is paid
        _svault.debtShares    -= _shareDiff;
        
        // burn USD
        IERC20(rdb.rusd()).burn(address(this), _usd);
        
        // transfer collateral to liquidator at discount
        uint _discount    = rdb.positionLiqudationDiscount(_ctype);
        uint _transferAmt = wdiv(WAD, WAD - _discount);
        require(IERC20(_ctype).transfer(msg.sender, _transferAmt),
                "ERR_TRANSFER");
    }
}

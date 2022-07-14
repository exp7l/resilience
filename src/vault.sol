// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./rdb.sol";
import "./auth.sol";
import "./math.sol";
import "./deed.sol";
import "./interfaces/erc20.sol";
import "forge-std/Test.sol";
 
struct VaultRecord {
  uint    fundId;    
  address collateralType;
  uint    collateralAmount;
  uint    usdBalance;
  uint    debtShares;
}

struct MiniVaultRecord {
  uint    fundId;    
  address collateralType;
  uint    deedId;    
  uint    collateralAmount;  
  uint    usdBalance;
  uint    debtShares;  
}

interface IFund
{
    function rebalanceMarkets(uint fundId) external;
}    

/*
  0. Track each vault's (key: fundId, collateralType) RUSD position and each minivault (key: fundId, collateralType, deedId)
  1. A fund can have as many vaults as there are accepted collateals.
  2. Debt shares are tracked here, liqudatiation reward and debt responsibility are shared among deeds associated with the vault.

  Reference:
  - https://github.com/balancer-labs/balancer-core/blob/master/contracts
*/

contract Vault is Auth, Math, Test {

  // Mirrors the sum of minivaults.
  //      fundId            collatealType
  mapping(uint   => mapping(address  => VaultRecord)) public vaults;

  //      fundId            collateralType      deedId 
  mapping(uint   => mapping(address  => mapping(uint => MiniVaultRecord))) public miniVaults;

  uint public initialDebtShares = 100 * 10 ** 18;

  RDB rdb;

  bool private _mutex;  

  modifier owned(uint _deedId)
  {
    require(Deed(rdb.deed()).ownerOf(_deedId) == msg.sender, "ERR_NOT_OWNED");
    _;
  }
 
  modifier lock()
  {
    require(!_mutex, "ERR_REENTRY");
    _mutex = true;
    _;
    _mutex = false;
  }
  
  constructor(address _rdb)
    {
      rdb = RDB(_rdb);
      ERC20(rdb.rusd()).approve(rdb.fund(), type(uint).max);
    }

  function deposit(uint    _fundId,
                   address _collateralType,
                   uint    _deedId,
                   uint    _collateralAmount)
    external
    lock
    owned(_deedId)
  {
    miniVaults[_fundId][_collateralType][_deedId].collateralAmount += _collateralAmount;
    bool success = ERC20(_collateralType).transferFrom(msg.sender,
                                                       address(this),
                                                       _collateralAmount);
    require(success, "ERR_TRANSFER");
    console.log("deposit called");
    IFund(rdb.fund()).rebalanceMarkets(_fundId);
  }

  function withdraw(uint _fundId,
                    address _collateralType,
                    uint _deedId,
                    uint _collateralAmount)
    external
    lock
    owned(_deedId)
  {
    miniVaults[_fundId][_collateralType][_deedId].collateralAmount -= _collateralAmount;
    require(_safeCratio(_fundId, _collateralType, _deedId));
    bool success = ERC20(_collateralType).transferFrom(address(this),
                                                       msg.sender,
                                                       _collateralAmount);
    require(success, "ERR_TRANSFER");
    console.log("withdraw called");
    IFund(rdb.fund()).rebalanceMarkets(_fundId);    
  }

  function _safeCratio(uint _fundId,
                       address _collateralType,
                       uint _deedId)
    internal
    returns (bool)
  {
    MiniVaultRecord storage _miniVault = miniVaults[_fundId][_collateralType][_deedId];
    uint _assetUSD = rdb.assetUSDValue(_collateralType,
                                       _miniVault.collateralAmount);
    if (_miniVault.usdBalance == 0) {
      return true;
    }
    return wdiv(_assetUSD, _miniVault.usdBalance) >= rdb.targetCratios(_collateralType);
  }    

  function _upsertVaults(uint    _fundId,
                         address _collateralType,
                         uint    _deedId)
    private
  {
    VaultRecord     storage _v  = vaults[_fundId][_collateralType];
    MiniVaultRecord storage _mv = miniVaults[_fundId][_collateralType][_deedId];
    _v.fundId                   = _fundId;
    _mv.fundId                  = _fundId;
    _v.collateralType           = _collateralType;
    _mv.collateralType          = _collateralType;
    _mv.deedId                  = _deedId;
  }


  function mint(uint    _fundId,
                address _collateralType,
                uint    _deedId,
                uint    _usdAmount)
    external
    lock
  {        
    VaultRecord     storage _v  = vaults[_fundId][_collateralType];
    MiniVaultRecord storage _mv = miniVaults[_fundId][_collateralType][_deedId];

    require(_usdAmount > 0,           "ERR_MINT");
    require(_mv.collateralAmount > 0, "ERR_MINT");

    _upsertVaults(_fundId, _collateralType, _deedId);

    if (vaults[_fundId][_collateralType].debtShares == 0) {
      _v.debtShares  = initialDebtShares;
      _mv.debtShares = initialDebtShares;
    } else {
      uint _mintFactor     =  wdiv(_usdAmount, _v.usdBalance);
      uint _newDebtShares  =  wmul(_v.debtShares, _mintFactor);
      _v.debtShares        += _newDebtShares;
      _mv.debtShares       += _newDebtShares;
    }

    _v.usdBalance  += _usdAmount;
    _mv.usdBalance += _usdAmount;

    require(_safeCratio(_fundId, _collateralType, _deedId));

    console.log("1");

    ERC20(rdb.rusd()).mint(address(this), _usdAmount);
  }

  function burn(uint    _fundId,
                address _collateralType,
                uint    _deedId,
                uint    _usdAmount)
    external
    lock
  {
    MiniVaultRecord storage _mv = miniVaults[_fundId][_collateralType][_deedId];
    VaultRecord     storage _v  = vaults[_fundId][_collateralType];    

    require(_usdAmount > 0,               "ERR_BURN");
    require(_mv.usdBalance >= _usdAmount, "ERR_BURN");

    uint _factor         =  wdiv(_usdAmount, _v.usdBalance);
    uint _diff           =  wmul(_v.debtShares, _factor);
    _v.debtShares        -= _diff;
    _mv.debtShares       -= _diff;
    _mv.usdBalance        -= _usdAmount;

    require(_safeCratio(_fundId, _collateralType, _deedId));

    ERC20(rdb.rusd()).burn(address(this), _usdAmount);
  }

  function vaultDebt(uint _fundId,
                     address _collateralType)
    external
    view
  {
  }
  
  function totalDebtShares(uint _fundId,
                           address _collateralType)
    external
    view
  {
  }
  
  function debtPerShare(uint _fundId,
                        address _collateralType)
    external
    view
  {
  }

  function cratio(uint _fundId,
                  address _collateralType,
                  uint _deedId)
    external
    view
  {
  }  

  function deedDebt(uint _fundId,
                    address _collateralType,
                    uint _deedId)
    external
    view
  {
  }
}

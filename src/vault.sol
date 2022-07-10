// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./rdb.sol";
import "./auth.sol";
import "./math.sol";
import "./deed.sol";
import "./interfaces/erc20.sol";

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
  uint    collateralAmount;  
  uint    deedId;
  uint    usdBalance;
  uint    debtShares;  
}

/*
1. A fund can have as many vaults as there are accepted collateals.
2. Debt shares are tracked here, liqudatiation reward and debt responsibility are shared among deeds associated with the vault.
*/

contract Vault is Auth, Math {

  bool private _mutex;

  // Mirrors the sum of minivaults.
  //      fundId            collatealType
  mapping(uint   => mapping(address  => VaultRecord))                              public vaults;

  //      fundId            collateralType      deedId 
  mapping(uint   => mapping(address  => mapping(uint => MiniVaultRecord)))         public miniVaults;

  uint initialDebtShares = 100 * 10 ** 18;

  RDB rdb;

  modifier miniVaultOwnerOnly(uint _deedId) {
    require(Deed(rdb.deed()).ownerOf(_deedId) == msg.sender);
    _;
  }
 
  modifier lock() {
    require(!_mutex, "ERR_REENTRY");
    _mutex = true;
    _;
    _mutex = false;
  }
  

  constructor(
    address _rdb
  )
  {
    rdb = RDB(_rdb);
  }

  function _targetCratioMaintained(
    uint _fundId,
    address _collateralType,
    uint _deedId
  )
    internal
    returns (bool)
  {
    MiniVaultRecord storage _miniVault   = miniVaults[_fundId][_collateralType][_deedId];
    uint _assetUSD                       = rdb.assetUSDValue(_collateralType, _miniVault.collateralAmount);
    return wdiv(_assetUSD, _miniVault.usdBalance) >= rdb.targetCratios(_collateralType);
  }

  function deposit(
    uint _fundId,
    address _collateralType,
    uint _deedId,
    uint _amount
  )
    external
    lock
    miniVaultOwnerOnly(_deedId)
  {
    miniVaults[_fundId][_collateralType][_deedId].collateralAmount += _amount;
  }

  function withdraw(uint _fundId, address _collateralType, uint _deedId, uint _amount)
    external
    lock
    miniVaultOwnerOnly(_deedId)
  {
    miniVaults[_fundId][_collateralType][_deedId].collateralAmount -= _amount;
    require(_targetCratioMaintained(_fundId, _collateralType, _deedId));
  }

  function mint(uint _fundId, address _collateralType, uint _deedId, uint _amount, address _user)
    external
    lock
  {
    MiniVaultRecord storage _miniVault   =  miniVaults[_fundId][_collateralType][_deedId];
    VaultRecord     storage _vault       =  vaults[_fundId][_collateralType];

    require(_amount > 0,                     "cannot-mint-zero-usd");
    require(_miniVault.collateralAmount > 0, "cannot-mint-with-zero-collateral");

    if (_vault.debtShares == 0) {
      _vault.debtShares                    =  initialDebtShares;
      _miniVault.debtShares                =  initialDebtShares;      
    } else {
      uint _mintFactor                     =  wdiv(_amount, _vault.usdBalance);
      uint _newDebtShares                  =  wmul(_vault.debtShares, _mintFactor);
      _vault.debtShares                    += _newDebtShares;
      _miniVault.debtShares                += _newDebtShares;
    }

    _vault.usdBalance                    += _amount;
    _miniVault.usdBalance                += _amount;

    require(_targetCratioMaintained(_fundId, _collateralType, _deedId));
    
    ERC20(rdb.rusd()).mint(address(this), _amount);
  }

  function burn(uint _fundId, address _collateralType, uint _deedId, uint _amount)
    external
    lock
  {
  }

  function vaultDebt(uint _fundId, address _collateralType)
    external
    view
  {
  }
  
  function totalDebtShares(uint _fundId, address _collateralType)
    external
    view
  {
  }
  
  function debtPerShare(uint _fundId, address _collateralType)
    external
    view
  {
  }

  function cratio(uint _fundId, address _collateralType, uint _deedId)
    external
    view
  {
  }  

  function deedDebt(uint _fundId, address _collateralType, uint _deedId)
    external
    view
  {
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./rdb.sol";
import "./auth.sol";
import "./math.sol";

struct VaultRecord {
  uint    fundId;    
  address collateralType;
  uint    collateralAmount;
  uint    rUSDAmount;
  uint    shares;
}

/*
1. A fund can have as many vaults as there are accepted collateals.
*/
contract Vault is Auth, Math {
  //      fundId => collateralType
  mapping(uint   => mapping(address         => VaultRecord))   public vaults;

  uint defaultShares = 100 * 10 ** 18;

  RDB rdb;

  modifier allowListed {
    require(msg.sender == rdb.fund());
    _;
  }

  constructor(address _rdb) {
    rdb = RDB(_rdb);
  }

  function mint(uint _fundId, uint _rUSDAmount, address _collateralType, uint _collateralAmount)
    external auth allowListed
  {
    // TODO: gas? Use a different data location in the branches.
    if (vaults[_fundId][_collateralType].collateralType == address(0)) {
      VaultRecord memory _record = vaults[_fundId][_collateralType];      
      _record = VaultRecord({
        fundId: _fundId,
        collateralType: _collateralType,
        collateralAmount: _collateralAmount,
        rUSDAmount: _rUSDAmount,
        shares: defaultShares
      });
    } else {
      VaultRecord storage _record =  vaults[_fundId][_collateralType];
      _record.collateralAmount    += _collateralAmount;
      _record.rUSDAmount          += _rUSDAmount;
      _record.shares              += wmul(_record.shares, wdiv(rdb.assetUSDValue(_collateralType, _collateralAmount), defaultShares));
    }
  }
}

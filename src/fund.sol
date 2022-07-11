// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/erc20.sol";
import "./rdb.sol";

/*
Scope:
1. Manage asset deposit from deeds.
2. Manage vaults.
3. Track vaults to debt shares.
4. Appointment of manager.
5. Liquidity provision using USD from the vaults the fund manages.
*/

contract Fund {
  //       fundId
  mapping (uint   => Appointment)                                      public  appointments;
  //       fundId           collateralType        
  mapping (uint   => mapping(address       => FundingRecord))          public  fundings;

  struct Appointment {
	uint    fundId;
    address manager;
    address nomination;
  }

  struct FundingRecord {
    uint    fundId;
    address collateralType;
    uint    usdBalance;
  }

  RDB rdb;

  constructor(address _rdb) {
	rdb = RDB(_rdb);
  }

  function createFund(uint _requestedFundId, address _owner) external {
    require(appointments[_requestedFundId].manager == address(0), "ERR_ID_TAKEN");
    appointments[_requestedFundId] = Appointment({
      fundId:      _requestedFundId,
      manager:     msg.sender,
      nomination:  address(0)
    });
  }
  function rebalanceMarkets(uint fundId) external {}
  function setFundPosition(uint fundId, uint[] calldata markets, uint[] calldata weights) external {}
  function nominateFundOwner(uint fundId, address owner) external {}
  function acceptFundOwnership(uint fundId) external {}
  function renounceFundOwnership(uint fundId) external {}
}

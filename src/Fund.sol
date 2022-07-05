// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IAccount.sol";

import "./IFund.sol";

import "./IERC20.sol";

import "./Configuration.sol";

contract Fund {
  mapping (uint => Ownership)                                              public  ownerships;
  mapping (uint => mapping(uint => mapping(address => Collateral)))        public  collaterals;

  struct Collateral {
	uint    accountId;
	address collateralType;
	uint    collateralAmount;
	uint    leverage;
	int     usdBalance;	
  }

  struct Ownership {
	uint    fundId;
    address owner;
    address nominated;
  }
  
  function createFund(uint requestedFundId, address owner) external {}
  function accountFundDebt(uint fundId, uint accountId, address collateralType) external {}
  function fundDebt(uint fundId) external {}
  function totalDebtShares(uint fundId) external {}
  function debtPerShare(uint fundId) external {}
  function collateralizationRatio(uint fundId, uint accountId, address collateralType) external {}

  function delegateCollateral(uint fundId, uint accountId, address collateralType, uint amount, uint exposure)
	external
  {
	
  }

  function mint(uint fundId, uint accountId, address collateralType, uint amount)
	external
  {
	// Mint through ERC20 resUSD
  }

  function burn(uint fundId, uint accountId, address collateralType, uint amount)
	external
  {
	
  }
  
  function rebalanceMarkets(uint fundId) external {}
  function setFundPosition(uint fundId, uint[] calldata markets, uint[] calldata weights) external {}
  function nominateFundOwner(uint fundId, address owner) external {}
  function acceptFundOwnership(uint fundId) external {}
  function renounceFundOwnership(uint fundId) external {}
}

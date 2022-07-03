// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Fund {
  
  mapping (uint => address)                                     public fundOwner;
  mapping (uint => address)                                     public fundNominatedOwner;
  mapping (uint => mapping(uint => mapping(address => int)))    public accountFundDebt;
  mapping (uint => int)                                         public fundDebt;
  mapping (uint => uint)                                        public totalDebtShares;
  
  function createFund(uint requestedFundId, address owner) external {
	require(fundOwner[requestedFundId] == address(0), "fund-id-taken");
	require(requestedFundId != 1, "fund-id-reserved");
	fundOwner[requestedFundId] = owner;
  }

  function debtPerShare(uint fundId) external returns (int) {

  }

  function collateralizationRatio(uint fundId, uint accountId, address collateralType) external returns (uint) {}

  function delegateCollateral(uint fundId, uint accountId, address collateralType, uint amount, uint exposure) external {}

  function rebalanceMarkets(uint fundId) external {}

  function setFundPosition(uint fundId, uint[] calldata markets, uint[] calldata weights) external {}

  function nominateFundOwner(uint fundId, address owner) external {
    require(fundOwner[fundId] == msg.sender, "fund-nominate-msg-sender-not-fund-owner");
	fundNominatedOwner[fundId] = owner;
  }

  function acceptFundOwnership(uint fundId) external {
	require(fundNominatedOwner[fundId] == msg.sender, "fund-msg-sender-not-nominated");
	fundOwner[fundId]          = msg.sender;
	fundNominatedOwner[fundId] = address(0);
  }

  function renounceFundOwnership(uint fundId) external {
	require(fundOwner[fundId] == msg.sender, "fund-renounce-msg-sender-not-fund-owner");
	fundOwner[fundId]          = address(1);
  }

  function liquidatePosition(uint fundId, uint accountId, address collateralType) external {}

  function liquidateFund(uint fundId, uint amount) external {}
}

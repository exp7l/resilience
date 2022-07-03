// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Optionally, create a fund takes no position to generate fiat.
interface IFund {
  function createFund(uint requestedFundId, address owner) external;
  function accountFundDebt(uint fundId, uint accountId, address collateralType) external returns (int);
  function fundDebt(uint fundId) external returns (int);
  function totalDebtShares(uint fundId) external returns (uint);
  function debtPerShare(uint fundId) external returns (int);
  function collateralizationRatio(uint fundId, uint accountId, address collateralType) external returns (uint);
  function delegateCollateral(uint fundId, uint accountId, address collateralType, uint amount, uint exposure) external;
  function rebalanceMarkets(uint fundId) external;
  function setFundPosition(uint fundId, uint[] calldata markets, uint[] calldata weights) external;
  function nominateFundOwner(uint fundId, address owner) external;
  function acceptFundOwnership(uint fundId) external;
  function renounceFundOwnership(uint fundId) external;
  function liquidatePosition(uint fundId, uint accountId, address collateralType) external;
  function liquidateFund(uint fundId, uint amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Optionally, create a fund takes no position to generate fiat.
interface IFund {
  function createFund(uint requestedFundId, address owner) external;
  function accountFundDebt(uint fundId, uint accountId, address collateralType) external;
  function fundDebt(uint fundId) external;
  function totalDebtShares(uint fundId) external;
  function debtPerShare(uint fundId) external;
  function collateralizationRatio(uint fundId, uint accountId, address collateralType) external;
  function delegateCollateral(uint fundId, uint accountId, address collateralType, uint amount, uint exposure) external;
  function mint(uint fundId, uint accountId, address collateralType, uint amount) external;
  function burn(uint fundId, uint accountId, address collateralType, uint amount) external;
  function rebalanceMarkets(uint fundId) external;
  function setFundPosition(uint fundId, uint[] markets, uint[] weights) external;
  function nominateFundOwner(uint fundId, address owner) external;
  function acceptFundOwnership(uint fundId) external;
  function renounceFundOwnership(uint fundId) external;
}

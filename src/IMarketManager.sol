// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IMarketManager {
  function registerMarket(address market) external returns (uint);
  function setSupplyTarget(uint marketId, uint fundId, uint amount) external;
  function supplyTarget(uint marketId) external returns (uint);
  function setLiquidity(uint marketId, uint fundId, uint amount) external returns (uint);
  function liquidity(uint marketId) external returns (uint);
  function fundBalance(uint marketId, uint fundId) external returns (int);
  function totalFundBalance(uint marketId) external returns (int);
  // What should be the unit here?
  function deposit(uint marketId, uint amount) external;
  // amount: amount of synth to redeem.
  function withdraw(uint marketId, uint amount, address recipient) external;
}

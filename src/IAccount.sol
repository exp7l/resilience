// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IAccount {
  function stake(uint accountId, address collateral, uint amount) external;
  function unstake(uint accountId, address collateral, uint amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IAccount {
  function mint(address owner) external;
  function stake(uint accountId, address collateralType, uint amount) external;
  function unstake(uint accountId, address collateralType, uint amount) external;
}

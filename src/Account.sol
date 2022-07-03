// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "ds-deed/deed.sol";

import "./IAccount.sol";

contract Account is IAccount, DSDeed {
  function stake(uint accountId, address collateralType, uint amount) external {
  }
  function unstake(uint accountId, address collateralType, uint amount) external {
  } 
}

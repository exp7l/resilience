// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IERC721.sol";

interface IAccount is IERC721 {
  function mint(uint requestedAccountId, address owner) external;
  function stake(uint accountId, address collateralType, uint amount) external;
  function unstake(uint accountId, address collateralType, uint amount) external;
  function hasRole(uint accountId, bytes32 role, address target) external view returns (bool);
  function grantRole(uint accountId, bytes32 role, address target) external;
  function revokeRole(uint accountId, bytes32 role, address target) external;
  function renounceRole(uint accountId, bytes32 role, address target) external;
}

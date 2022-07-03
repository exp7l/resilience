// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Auth.sol";

contract Configuration is Auth {
  
  mapping (address => bool) public approvedCollateralTypes;
  
  function setCollateralTypeApproval(address collateralType, bool approval) external auth stoppable {
	approvedCollateralTypes[collateralType] = approval;
  }
}

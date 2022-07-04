// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Auth.sol";

contract Configuration is Auth {
  
  mapping (address => bool) public approvedCollaterals;
  
  function setCollateralApproval(address _collateral, bool _approval) external auth stoppable {
	approvedCollaterals[_collateral] = _approval;
  }
}

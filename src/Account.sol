// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "ds-deed/deed.sol";

import "./IAccount.sol";

import "./IERC20.sol";

import "./Configuration.sol";


contract Account is IAccount, DSDeed("Resilience Account", "rsACCT") {

  Configuration configuration;
  
  constructor(address c) public {
	configuration = Configuration(c);
  }
  
  function stake(uint accountId, address collateralType, uint amount) external {
	require(configuration.approvedCollateralTypes(collateralType) == true);
    IERC20(collateralType).transferFrom(msg.sender, address(this), amount);
  }
  
  function unstake(uint accountId, address collateralType, uint amount) external {
	IERC20(collateralType).transferFrom(address(this), msg.sender, amount);
  } 
}

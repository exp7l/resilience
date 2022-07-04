// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "ds-deed/deed.sol";

import "./IAccount.sol";

import "./IERC20.sol";

import "./Configuration.sol";


contract Account is IAccount, DSDeed("Resilient Account", "rsACCT") {

  mapping(uint => mapping(address => uint)) public balance;
		  
  Configuration config;
  
  constructor(address _config) {
	config = Configuration(_config);
  }
  
  function stake(uint _accountId, address _collateral, uint _amount) external {
	require(config.approvedCollaterals(_collateral) == true);
    IERC20(_collateral).transferFrom(msg.sender, address(this), _amount);
	balance[_accountId][_collateral] += _amount;
  }
  
  function unstake(uint _accountId, address _collateral, uint _amount) external {
	balance[_accountId][_collateral] -= _amount;
	IERC20(_collateral).transferFrom(address(this), msg.sender, _amount);
	// TODO: Only allow unstake to take place if collateral ratio is inline.
  } 
}

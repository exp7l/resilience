// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./auth.sol";

// Grab bag of runtime data - Runtime Database

contract RDB is Auth {
  address                   public deed;

  // Approved asset types.
  mapping (address => bool) public approved;
  
  function approve(address _erc20)
    external auth
  {
	approved[_erc20] = true;
  }

  function deny(address _erc20)
    external auth
  {
    approved[_erc20] = false;
  }

  function setDeed(address _deed)
    external auth
  {
    deed = _deed;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./auth.sol";
import "./oracle.sol";

// Grab bag of runtime data - Runtime Database

contract RDB is Auth {
  address                   public deed;
  address                   public fund;

  // Approved asset types.
  mapping (address => bool) public approved;

  //       erc20      oracle
  mapping (address => address) public oracles;
  
  function approve(address _erc20)
    external auth
  {
	approved[_erc20] = true;
  }

  function disapprove(address _erc20)
    external auth
  {
    approved[_erc20] = false;
  }

  function setDeed(address _deed)
    external auth
  {
    deed = _deed;
  }

  function setFund(address _fund)
    external auth
  {
    fund = _fund;
  }

  // USD are in 18 digit precisions.
  function assetUSDValue(address _erc20, uint _amount)
    external view
    returns (uint)
  {
    return Oracle(oracles[_erc20]).usdValue(_amount);
  }
}

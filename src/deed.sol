// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/erc20.sol";
import "./rdb.sol";
import "ds-deed/deed.sol";

contract Deed is DSDeed("Resilient Deed", "RDeed") {

  RDB rdb;
  
  //      deedId =>         asset          => balance
  mapping(uint   => mapping(address        => uint))   public cash;
		  
  constructor(address _rdb) {
	rdb = RDB(_rdb);
  }

  function deposit(uint _deedId, address _erc20, uint _amount)
    external
  {
    require(msg.sender == _deeds[_deedId].guy, "not-owner");
	require(rdb.approved(_erc20), "not-approved");
	cash[_deedId][_erc20] += _amount;    
    ERC20(_erc20).transferFrom(msg.sender, address(this), _amount);
  }
  
  function withdraw(uint _deedId, address _erc20, uint _amount)
    external
  {
    require(msg.sender == _deeds[_deedId].guy, "not-owner");
    require(cash[_deedId][_erc20] >= _amount, "not-sufficient-fund");
	cash[_deedId][_erc20] -= _amount;
	ERC20(_erc20).transferFrom(address(this), msg.sender, _amount);
  } 
}

/*
Todos:
1. Check ERC20 transfer balance before and after.
2. Are there decomposable rights that would be useful to grant on the deed?
*/

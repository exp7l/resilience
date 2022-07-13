// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./auth.sol";
import "./oracle.sol";
import "./math.sol";
import "./deed.sol";

// Grab bag of runtime data - Runtime Database

contract RDB is Auth {
  address                   public deed;
  address                   public fund;
  address                   public vault;
  address                   public rusd;
  address                   public marketManager;
  mapping(address => uint)  public targetCratios;
  mapping(address => uint)  public minCratios;
  address                   public weth = address(0);

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

  function setVault(address _vault)
    external auth
  {
    vault = _vault;
  }  

  function setRUSD(address _rusd)
    external auth
  {
    rusd = _rusd;
  }

  function setWETH(address _weth)
    external auth
  {
    weth = _weth;
  }

  function setMarketManager(address _marketManager)
    external auth
  {
    marketManager = _marketManager;
  }      

  // USD are in 18 digit precisions.
  function assetUSDValue(address _erc20, uint _amount)
    public view
    returns (uint)
  {
    return Oracle(oracles[_erc20]).usdValue(_amount);
  }
}

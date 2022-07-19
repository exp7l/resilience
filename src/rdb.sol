// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./auth.sol";
import "./oracle.sol";
import "./math.sol";

// Grab bag of runtime data - Runtime Database

contract RDB is Auth {
    address public deed;
    address public fund;
    address public vault;
    address public rusd;
    address public marketManager;
    address public weth = address(0);
    // collateral => c-ratio
    mapping(address => uint256) public targetCratios;
    // collateral => c-ratio
    mapping(address => uint256) public minCratios;
    // Approved asset types.
    mapping(address => bool) public approved;
    uint256 public approvedLength;
    address[] public approvedKeys;
    // erc20 => oracle
    mapping(address => address) public oracles;
    // erc20 => liqudation discount in decimal in WAD eg. 0.3 * WAD
    mapping(address => uint256) public positionLiqudationDiscount;

    function approve(address _erc20) external auth {
        approved[_erc20] = true;
        approvedLength++;
        approvedKeys.push(_erc20);
    }

    function disapprove(address _erc20) external auth {
        approved[_erc20] = false;
    }

    function setDeed(address _deed) external auth {
        deed = _deed;
    }

    function setFund(address _fund) external auth {
        fund = _fund;
    }

    function setVault(address _vault) external auth {
        vault = _vault;
    }

    function setRUSD(address _rusd) external auth {
        rusd = _rusd;
    }

    function setWETH(address _weth) external auth {
        weth = _weth;
    }

    function setMarketManager(address _marketManager) external auth {
        marketManager = _marketManager;
    }

    // USD are in 18 digit precisions.
    function assetUSDValue(address _erc20, uint256 _amount)
        public
        view
        returns (uint256)
    {
        return Oracle(oracles[_erc20]).usdValue(_amount);
    }
}

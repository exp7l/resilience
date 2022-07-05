// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IMarket.sol";

// TODO: access control
contract Market is IMarket {
    uint256 public supplyTarget;
    /// @dev should also be equal to balance
    uint256 public liquidity;

    mapping(uint256 => uint256) fundBalances;

    function setSupplyTarget(uint256 newSupplyTarget) external {
        supplyTarget = newSupplyTarget;
    }

    function setLiquidity(uint256 newLiquidity) external {
        liquidity = newLiquidity;
    }

    function balance() external view returns (uint256) {
        return liquidity;
    }
}

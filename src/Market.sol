// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IMarket.sol";

// TODO: access control, erc20 for synth
contract Market is IMarket {
    uint256 public supplyTarget;
    /// @dev should also be equal to balance
    uint256 public liquidity;
    uint256 public totalFundBalances;

    mapping(uint256 => int256) public fundBalances;
    mapping(uint256 => uint256) public fundSupplyTargets;

    function setFundSupplyTarget(uint256 fundId, uint256 amount) external {
        // TODO: fundId check

        fundSupplyTargets[fundId] = amount;
    }

    function setSupplyTarget(uint256 newSupplyTarget) external {
        supplyTarget = newSupplyTarget;
    }

    function setFundLiquidity(uint256 fundId, uint256 amount) external {
        // TODO: fundId check

        int256 amountSigned = int256(amount);
        fundBalances[fundId] = amountSigned;
    }

    function setLiquidity(uint256 newLiquidity) external {
        liquidity = newLiquidity;
    }

    function balance() external view returns (uint256) {
        return liquidity;
    }

    function deposit(uint256 amount) external {
        susdBalances[msg.sender] += amount;
    }

    /// @dev basic synth spot market for sBTC as mentioned in SIP 303
    // TODO
    function mint(uint256 amount) external {}

    /// @dev basic synth spot market for sBTC as mentioned in SIP 303
    // TODO
    function burn(uint256 amount) external {}
}

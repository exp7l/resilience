// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./IMarket.sol";

// TODO: access control, erc20 interface for synth, price oracle
contract Market is IMarket {
    /// @dev synth erc20 contract address
    IERC20 public synth;
    uint256 synthPrice;

    uint256 public supplyTarget;
    uint256 public totalFundBalances;

    mapping(uint256 => int256) public fundBalances;
    mapping(uint256 => uint256) public fundSupplyTargets;

    // TODO price oracle
    constructor(address _synthAddr, uint256 _synthPrice) public {
        synth = IERC20(_synthAddr);
        synthPrice = _synthPrice;
    }

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

    // TODO decimal places
    function balance() external view returns (int256) {
        /// TODO price oracle
        return -1 * synth.totalSupply() * synthPrice;
    }

    function deposit(uint256 amount) external {
        susdBalances[msg.sender] += amount;
    }
}

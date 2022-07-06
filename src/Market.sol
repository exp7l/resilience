// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./IMarket.sol";
import "./IMarketManager.sol";
import "./ISynth.sol";

// TODO: access control, erc20 interface for synth, price oracle
contract Market is IMarket {
    /// @dev synth erc20 contract address
    ISynth public synth;
    uint256 public synthPrice;
    IERC20 public susd;

    IMarketManager public marketManager;

    uint256 public supplyTarget;
    uint256 public totalFundBalances;

    mapping(uint256 => int256) public fundBalances;
    mapping(uint256 => uint256) public fundSupplyTargets;

    // TODO price oracle
    constructor(
        address _synthAddr,
        uint256 _synthPrice,
        address _susdAddr,
        address _marketManagerAddr
    ) public {
        synth = ISynth(_synthAddr);
        synthPrice = _synthPrice;

        susd = IERC20(_susdAddr);

        marketManager = IMarketManager(_marketManagerAddr);
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

    // TODO decimals
    function buy(uint256 amount) external {
        bool success = susd.transferFrom(
            msg.sender,
            address(marketManager),
            amount
        );
        require(success, "ERC20: failed to transfer");

        uint256 synthAmount = amount / synthPrice;

        synth.mint(msg.sender, synthAmount);
    }
}

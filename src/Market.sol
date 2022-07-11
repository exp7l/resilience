// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./IMarket.sol";
import "./IMarketManager.sol";
import "./MarketManager.sol";
import "./ISynth.sol";

// TODO: access control, erc20 interface for synth, price oracle, optimisation
contract Market is IMarket {
    /// @dev synth erc20 contract address, assumes synth will only be used in this market
    ISynth public synth;
    uint256 public synthPrice;
    IERC20 public susd;

    IMarketManager public marketManager;

    uint256 public fee;

    // TODO price oracle
    constructor(
        address _synthAddr,
        uint256 _synthPrice,
        address _susdAddr,
        address _marketManagerAddr,
        uint256 _fee,
        address[] calldata _funds
    ) public {
        synth = ISynth(_synthAddr);
        synthPrice = _synthPrice;

        susd = IERC20(_susdAddr);

        marketManager = IMarketManager(_marketManagerAddr);

        fee = _fee;
        funds = _funds;
    }

    // TODO decimal places
    function balance() external view returns (int256) {
        /// TODO price oracle
        return -1 * synth.totalSupply() * synthPrice;
    }

    function deposit(uint256 amount) external {
        susdBalances[msg.sender] += amount;
    }

    // TODO decimals, send fees somewhere
    function buy(uint256 amount) external {
        uint256 fees = fee * amount;
        uint256 amountLeftToPurchase = amount - fees;

        uint256 synthAmount = amountLeftToPurchase / synthPrice;

        uint256 marketId = marketManager.marketsToId[address(this)];
        marketManager.deposit(marketId, amountLeftToPurchase);

        synth.mint(msg.sender, synthAmount);
    }

    // TODO decimals, send fees somewhere
    function sell(uint256 amount) external {
        bool success = synth.burn(msg.sender, amount);
        require(success, "ERC20: failed to transfer");

        uint256 susdAmount = amount * synthPrice;

        uint256 fees = fee * susdAmount;
        uint256 susdAmountLeft = susdAmount - fees;

        susd.transferFrom(address(marketManager), msg.sender, susdAmountLeft);
    }
}

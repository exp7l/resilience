// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./math.sol";
import "./interfaces/ierc20.sol";
import "./oracle.sol";
import "./interfaces/IMarket.sol";
import "./interfaces/IMarketManager.sol";
import "./MarketManager.sol";
import "./interfaces/ISynth.sol";

contract Market is IMarket, Math {
    /// @dev synth erc20 contract address, assumes synth will only be used in this market
    ISynth public synth;
    IERC20 public susd;
    Oracle public priceOracle;

    MarketManager public marketManager;

    uint256 public fee;

    constructor(
        address _synthAddr,
        address _susdAddr,
        address _marketManagerAddr,
        address _priceOracleAddr,
        uint256 _fee
    ) {
        synth = ISynth(_synthAddr);
        susd = IERC20(_susdAddr);
        marketManager = MarketManager(_marketManagerAddr);
        priceOracle = Oracle(_priceOracleAddr);
        fee = _fee;
    }

    function balance() external view returns (int256) {
        return -1 * int256(wmul(synth.totalSupply(), priceOracle.usdValue(1)));
    }

    // TODO send fees somewhere
    function buy(uint256 amount) external {
        uint256 fees = wmul(fee, amount);
        uint256 amountLeftToPurchase = amount - fees;

        uint256 synthAmount = wdiv(
            amountLeftToPurchase,
            priceOracle.usdValue(1)
        );

        uint256 marketId = marketManager.marketsToId(address(this));
        marketManager.deposit(marketId, amountLeftToPurchase);

        // @dev send fees here first
        bool success = susd.transferFrom(tx.origin, address(this), fees);
        require(success, "ERC20: failed to transfer");

        synth.mint(msg.sender, synthAmount);
    }

    // TODO send fees somewhere
    function sell(uint256 amount) external {
        synth.burn(msg.sender, amount);

        uint256 susdAmount = wmul(amount, priceOracle.usdValue(1));

        uint256 fees = wmul(fee, susdAmount);
        uint256 susdAmountLeft = susdAmount - fees;

        uint256 marketId = marketManager.marketsToId(address(this));
        marketManager.withdraw(marketId, susdAmountLeft, msg.sender);
    }
}

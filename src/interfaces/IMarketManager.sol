// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IMarketManager {
    function registerMarket(address market) external returns (uint256);

    // need to think about supply vs liquidity (maybe quantity vs quantity * price)
    function setSupplyTarget(
        uint256 marketId,
        uint256 fundId,
        uint256 amount
    ) external;

    function supplyTarget(uint256 marketId) external returns (uint256);

    function setLiquidity(
        uint256 marketId,
        uint256 fundId,
        uint256 amount
    ) external returns (uint256);

    function liquidity(uint256 marketId) external returns (uint256);

    // fund's debt incurred by underwriting a `buy` for `resBTC`
    function fundBalance(uint256 marketId, uint256 fundId)
        external
        returns (int256);

    // fund's debts across all markets
    function totalFundBalance(uint256 marketId) external returns (int256);

    // What should be the unit here?
    // manager takes resUSD from a market, then update debt balances for the funds that setLiquidity to this market and proportionally by the liquidity the fund provided
    function deposit(uint256 marketId, uint256 amount) external;

    // amount: amount of synth to redeem.
    function withdraw(
        uint256 marketId,
        uint256 amount,
        address recipient
    ) external;
}

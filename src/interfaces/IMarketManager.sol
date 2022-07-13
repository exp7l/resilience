// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IMarketManager {
    function registerMarket(address market)
        external
        returns (uint256);

    function setLiquidity(uint256 marketId,
                          uint256 fundId,
                          uint256 amount)
        external
        returns (uint256);

    function liquidity(uint256 marketId)
        external
        returns (uint256);

    // TODO: confirm
    // A fund's share of the reward (per synth trade?) is proportional to
    // its fundDebt. 
    function fundDebt(uint256 marketId,
                         uint256 fundId)
        external
        returns (int256);

    function totalFundDebt(uint256 marketId)
        external returns
        (int256);

    function deposit(uint256 marketId,
                     uint256 amount)
        external;

    function withdraw( uint256 marketId,
                       uint256 amount,
                       address recipient)
        external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IFund {
    function rebalanceMarkets(uint256 fundId) external returns (bool);

    function backings(uint256 fundId, uint256 i)
        external
        view
        returns (uint256);

    function backingLength(uint256 fundId) external view returns (uint256);
}

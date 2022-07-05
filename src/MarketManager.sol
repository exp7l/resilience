// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IMarketManager.sol";
import "./IMarket.sol";

contract MarketManager {
    uint256 counter;

    mapping(uint256 => address) idToMarkets;
    mapping(address => uint256) marketsToId;

    constructor() {
        counter = 1;
    }

    event MarketRegistered(
        uint256 indexed marketId,
        address indexed marketAddr
    );

    function registerMarket(address marketAddr) external returns (uint256) {
        // TODO: check Market implements balance() function
        require(marketsToId[marketAddr] != 0, "market contract already exists");

        idToMarkets[counter] = marketAddr;
        marketsToId[marketAddr] = counter;

        emit MarketRegistered(counter, marketAddr);
        counter += 1;
    }
}

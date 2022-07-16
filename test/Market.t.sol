// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./mocks/MockOracle.sol";
import "../src/token.sol";
import "../src/rdb.sol";
import "../src/fund.sol";
import "../src/MarketManager.sol";
import "../src/Market.sol";

contract MarketTest is Test {
    uint256 SYNTH_PRICE = 1 ether;
    // 1 percent
    uint256 FEE = 0.01 ether;

    RDB rdb;
    Fund fundRegistry;
    DSToken synth;
    MarketManager marketManager;
    DSToken susd;
    MockOracle mockOracle;
    Market market;

    function setUp() public {
        rdb = new RDB();
        fundRegistry = new Fund(address(rdb));
        synth = new DSToken("synth");
        marketManager = new MarketManager(
            address(synth),
            address(fundRegistry)
        );
        susd = new DSToken("susd");
        mockOracle = new MockOracle(SYNTH_PRICE);
        market = new Market(
            address(synth),
            address(synth),
            address(marketManager),
            address(mockOracle),
            FEE
        );
    }

    function testBalanceInitial() public {
        assertEq(market.balance(), 0);
    }

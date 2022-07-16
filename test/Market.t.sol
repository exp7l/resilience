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

    address user1;

    function setUp() public {
        user1 = vm.addr(1);
        vm.deal(user1, 1 ether);

        rdb = new RDB();
        fundRegistry = new Fund(address(rdb));
        synth = new DSToken("synth");

        susd = new DSToken("susd");
        // susd.allow(user1);
        susd.mint(user1, 1 ether);

        marketManager = new MarketManager(address(susd), address(fundRegistry));

        vm.prank(user1);
        susd.approve(address(marketManager), 1 ether);

        mockOracle = new MockOracle(SYNTH_PRICE);
        market = new Market(
            address(synth),
            address(synth),
            address(marketManager),
            address(mockOracle),
            FEE
        );

        marketManager.registerMarket(address(market));
    }

    function testBalanceInitial() public {
        assertEq(market.balance(), 0);
    }

    function testDepositOneSUSD() public {
        console.log(1);
        uint256 allowanceForUser = susd.allowance(
            user1,
            address(marketManager)
        );
        console.log(allowanceForUser);

        vm.prank(address(market), user1);
        marketManager.deposit(1, 1 ether);

        // TODO
    }
}

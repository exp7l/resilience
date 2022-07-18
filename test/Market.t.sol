// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/math.sol";
import "./mocks/MockOracle.sol";
import "../src/token.sol";
import "../src/rdb.sol";
import "../src/fund.sol";
import "../src/MarketManager.sol";
import "../src/Market.sol";

contract MarketTest is Test, Math {
    // 1 dollar
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

    uint256 marketId1 = 1;
    uint256 fundId1 = 1;

    address user1;
    address fundManager1;

    function setUp() public {
        user1 = vm.addr(1);
        vm.label(user1, "User 1");
        vm.deal(user1, 1 ether);

        fundManager1 = vm.addr(2);
        vm.label(fundManager1, "Fund Manager 1");
        vm.deal(fundManager1, 1 ether);

        rdb = new RDB();
        fundRegistry = new Fund(address(rdb));

        vm.prank(fundManager1);
        fundRegistry.createFund(1);
        synth = new DSToken("synth");

        susd = new DSToken("susd");
        susd.mint(user1, 1 ether);

        marketManager = new MarketManager(address(susd), address(fundRegistry));
        vm.label(address(marketManager), "Market Manager");

        mockOracle = new MockOracle(SYNTH_PRICE);
        market = new Market(
            address(synth),
            address(susd),
            address(marketManager),
            address(mockOracle),
            FEE
        );
        vm.label(address(market), "Market");

        vm.prank(user1);
        susd.approve(address(marketManager));
        vm.prank(user1);
        susd.approve(address(market));

        vm.prank(address(marketManager));
        susd.approve(address(market));

        synth.allow(address(market));

        marketManager.registerMarket(address(market));

        vm.prank(fundManager1);
        marketManager.registerFundInMarket(marketId1, fundId1);
    }

    function testBalanceInitial() public {
        assertEq(market.balance(), 0);
    }

    function testLiquidityInitial() public {
        assertEq(marketManager.liquidity(marketId1), 0);
    }

    function testTotalFundDebtInitial() public {
        assertEq(marketManager.totalFundDebt(marketId1), 0);
    }

    function testFundDebtInitial() public {
        assertEq(marketManager.fundDebt(marketId1, fundId1), 0);
    }

    function testRegisterMarket() public {
        address marketAddr = vm.addr(3);

        marketManager.registerMarket(marketAddr);
        assertEq(marketManager.counter(), 3);
    }

    function testSetLiquidity() public {
        uint256 amount = 1 ether;
        vm.prank(fundManager1);
        marketManager.setLiquidity(marketId1, fundId1, amount);

        assertEq(
            marketManager.marketToFundsToLiquidity(marketId1, fundId1),
            amount
        );
        assertEq(marketManager.liquidity(marketId1), amount);
    }

    function testDeposit() public {
        uint256 marketId = 1;
        uint256 externalLiquidity = 1 ether;

        vm.prank(address(market), user1);
        marketManager.deposit(marketId, externalLiquidity);

        assertEq(
            marketManager.marketToExternalLiquidity(marketId),
            externalLiquidity
        );
        assertEq(susd.balanceOf(user1), 0);
        assertEq(susd.balanceOf(address(marketManager)), externalLiquidity);
    }

    function testWithdraw() public {
        uint256 marketId = 1;
        uint256 externalLiquidity = 1 ether;
        uint256 amount = 1 ether;

        vm.prank(address(market), user1);
        marketManager.deposit(marketId, externalLiquidity);
        vm.prank(address(market), user1);
        marketManager.withdraw(marketId, amount, user1);

        assertEq(marketManager.marketToExternalLiquidity(marketId), 0);
        assertEq(susd.balanceOf(user1), amount);
        assertEq(susd.balanceOf(address(marketManager)), 0);
    }

    function testBuySynth() public {
        uint256 amount = 1 ether;
        uint256 fees = wmul(FEE, amount);
        uint256 amountLeftToPurchase = amount - fees;
        uint256 synthAmount = wdiv(amountLeftToPurchase, SYNTH_PRICE);

        vm.prank(fundManager1);
        marketManager.setLiquidity(marketId1, fundId1, amount);

        vm.prank(user1, user1);
        market.buy(amount);

        int256 expectedBalance = -1 *
            int256(wmul(synth.totalSupply(), SYNTH_PRICE));

        assertEq(susd.balanceOf(user1), 0);
        assertEq(susd.balanceOf(address(market)), fees);
        assertEq(susd.balanceOf(address(marketManager)), amountLeftToPurchase);
        assertEq(synth.balanceOf(user1), synthAmount);
        assertEq(synth.totalSupply(), synthAmount);
        assertEq(market.balance(), expectedBalance);
        assertEq(marketManager.liquidity(marketId1), amount);
        assertEq(marketManager.totalFundDebt(marketId1), expectedBalance);
        assertEq(marketManager.fundDebt(marketId1, fundId1), expectedBalance);
    }

    function testSellSynth() public {
        uint256 amount = 1 ether;
        uint256 fees = wmul(FEE, amount);
        uint256 amountLeftToPurchase = amount - fees;
        uint256 synthAmount = wdiv(amountLeftToPurchase, SYNTH_PRICE);

        vm.prank(fundManager1);
        marketManager.setLiquidity(marketId1, fundId1, amount);

        vm.prank(user1, user1);
        market.buy(amount);

        uint256 susdAmount = wmul(amountLeftToPurchase, SYNTH_PRICE);

        uint256 sellFees = wmul(FEE, susdAmount);
        uint256 susdAmountLeft = susdAmount - sellFees;

        vm.prank(user1);
        synth.approve(address(market));

        vm.prank(user1, user1);
        market.sell(synthAmount);

        assertEq(susd.balanceOf(user1), susdAmountLeft);
        assertEq(susd.balanceOf(address(marketManager)), 0);
        assertEq(susd.balanceOf(address(market)), fees + sellFees);
        assertEq(synth.balanceOf(user1), 0);
        assertEq(synth.totalSupply(), 0);
        assertEq(market.balance(), 0);
        assertEq(marketManager.liquidity(marketId1), amount);
        assertEq(marketManager.totalFundDebt(marketId1), 0);
        assertEq(marketManager.fundDebt(marketId1, fundId1), 0);
    }
}

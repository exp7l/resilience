// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IMarketManager.sol";
import "./Market.sol";

// TODO: inherit IMarketManager
contract MarketManager {
    uint256 counter;

    mapping(uint256 => address) idToMarkets;
    mapping(uint256 => address) idToDeposits;
    mapping(address => uint256) marketsToId;
    /// @dev susd balances
    mapping(address => uint256) usersToBalances;

    /// @dev marketId => fundId => supply target
    mapping(uint256 => mapping(uint256 => uint256))
        public marketToFundsToSupplyTargets;

    constructor() {
        counter = 1;
    }

    event MarketRegistered(
        uint256 indexed marketId,
        address indexed marketAddr
    );

    event SupplyTargetSet(
        uint256 indexed marketId,
        uint256 indexed fundId,
        uint256 indexed amount
    );

    function registerMarket(address marketAddr) external returns (uint256) {
        // TODO: check Market implements balance() function
        require(marketsToId[marketAddr] == 0, "market contract already exists");

        idToMarkets[counter] = marketAddr;
        marketsToId[marketAddr] = counter;

        emit MarketRegistered(counter, marketAddr);
        counter += 1;
    }

    function setSupplyTarget(
        uint256 marketId,
        uint256 fundId,
        uint256 amount
    ) external {
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");
        // TODO: fundId check

        marketToFundsToSupplyTargets[marketId][fundId] = amount;

        emit SupplyTargetSet(marketId, fundId, amount);
    }

    function supplyTarget(uint256 marketId) external returns (uint256) {
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");

        Market market = Market(marketAddr);
        return market.supplyTarget();
    }

    function setLiquidity(
        uint256 marketId,
        uint256 fundId,
        uint256 amount
    ) external {
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");
        // TODO: fundId check

        Market market = Market(marketAddr);
        market.setFundLiquidity(fundId, amount);
    }

    function liquidity(uint256 marketId) external returns (uint256) {
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");

        Market market = Market(marketAddr);
        return market.liquidity();
    }

    function fundBalance(uint256 marketId, uint256 fundId)
        external
        view
        returns (int256)
    {
        // TODO: fundId check
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");

        Market market = Market(marketAddr);

        int256 totalFundBalance = market.balance();
        uint256 share = market.fundLiquidities(fundId) / market.liquidity();

        return share * totalFundBalance;
    }

    function totalFundBalance(uint256 marketId) external view returns (int256) {
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");

        Market market = Market(marketAddr);

        return market.balance();
    }

    function deposit(uint256 marketId, uint256 amount) public {
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");

        usersToBalances[msg.sender] += amount;

        Market market = Market(marketAddr);

        market.mint(amount);
    }

    function withdraw(
        uint256 marketId,
        uint256 amount,
        address recipient
    ) public {
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");

        Market market = Market(marketAddr);

        market.burn(amount);

        usersToBalances[msg.sender] -= amount;
        require(usersToBalances[msg.sender] >= 0, "insufficient balance");
    }
}

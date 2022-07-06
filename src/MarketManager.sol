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

    constructor() {
        counter = 1;
    }

    event MarketRegistered(
        uint256 indexed marketId,
        address indexed marketAddr
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

        Market market = Market(idToMarkets[marketId]);
        market.setFundSupplyTarget(fundId, amount);
    }

    function setLiquidity(
        uint256 marketId,
        uint256 fundId,
        uint256 amount
    ) external {
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");
        // TODO: fundId check

        Market market = Market(idToMarkets[marketId]);
        market.setFundLiquidity(fundId, amount);
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

        return market.fundBalances(fundId);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./math.sol";
import "./interfaces/erc20.sol";
import "./interfaces/IMarketManager.sol";
import "./Market.sol";

// TODO: inherit IMarketManager
contract MarketManager is Math {
    uint256 counter;
    ERC20 public susd;

    mapping(uint256 => address) idToMarkets;
    mapping(address => uint256) public marketsToId;

    mapping(uint256 => address[]) public marketToFunds;

    /// @dev marketId => fundId => liquidity
    mapping(uint256 => mapping(uint256 => uint256))
        public marketToFundsToLiquidity;

    /// @dev marketId => external liquidity (susd deposited to swap to synth by traders)
    mapping(uint256 => uint256) public marketToExternalLiquidity;

    constructor(address _susdAddr) {
        counter = 1;
        susd = ERC20(_susdAddr);
    }

    event MarketRegistered(
        uint256 indexed marketId,
        address indexed marketAddr
    );

    event LiquiditySet(
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

    function setLiquidity(
        uint256 marketId,
        uint256 fundId,
        uint256 amount
    ) external {
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");
        // TODO: fundId check

        marketToFundsToLiquidity[marketId][fundId] = amount;

        emit LiquiditySet(marketId, fundId, amount);
    }

    function liquidity(uint256 marketId)
        public
        view
        returns (uint256 totalLiquidity)
    {
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");

        address[] memory funds = marketToFunds[marketId];
        require(funds.length > 0, "no funds");

        // TODO: fundId
        uint256 fundId = 0;

        for (uint256 i = 0; i < funds.length; i++) {
            totalLiquidity += marketToFundsToLiquidity[marketId][fundId];
        }
    }

    function totalFundDebt(uint256 marketId) public view returns (int256) {
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");

        Market market = Market(marketAddr);

        return market.balance();
    }

    function fundDebt(uint256 marketId, uint256 fundId)
        external
        view
        returns (int256)
    {
        // TODO: fundId check
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");

        int256 allFundDebt = totalFundDebt(marketId);
        uint256 marketLiquidity = liquidity(marketId);
        require(marketLiquidity > 0, "zero liquiity");

        uint256 share = wdiv(
            marketToFundsToLiquidity[marketId][fundId],
            marketLiquidity
        );

        return int256(wmul(share, uint256(allFundDebt)));
    }

    function deposit(uint256 marketId, uint256 amount) public {
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");

        /// @dev Transfers the specified amount of sUSD from msg.sender (in market.sol's buy() function) to market manager with the deposit() function.
        bool success = susd.transferFrom(tx.origin, address(this), amount);
        require(success, "ERC20: failed to transfer");

        marketToExternalLiquidity[marketId] += amount;
    }

    function withdraw(
        uint256 marketId,
        uint256 amount,
        address recipient
    ) public {
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");

        /// @dev ransfers the appropriate amount of sUSD from the market manager the withdraw() function to msg.sender (in market.sol's sell() function).
        bool success = susd.transferFrom(address(this), recipient, amount);
        require(success, "ERC20: failed to transfer");

        marketToExternalLiquidity[marketId] -= amount;
    }
}

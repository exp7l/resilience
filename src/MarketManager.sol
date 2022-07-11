// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./IMarketManager.sol";
import "./Market.sol";

// TODO: inherit IMarketManager
contract MarketManager {
    uint256 counter;
    IERC20 public susd;

    mapping(uint256 => address) idToMarkets;
    mapping(address => uint256) public marketsToId;

    mapping(uint256 => address[]) public marketToFunds;

    /// @dev marketId => fundId => supply target
    mapping(uint256 => mapping(uint256 => uint256))
        public marketToFundsToSupplyTargets;

    /// @dev marketId => fundId => liquidity
    mapping(uint256 => mapping(uint256 => uint256))
        public marketToFundsToLiquidity;

    /// @dev marketId => external liquidity (susd deposited to swap to synth by traders)
    mapping(uint256 => uint256) public marketToExternalLiquidity;

    constructor(address _susdAddr) {
        counter = 1;
        susd = IERC20(_susdAddr);
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

    function supplyTarget(uint256 marketId)
        external
        returns (uint256 supplytarget)
    {
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");

        address[] memory funds = marketToFunds[marketId];
        require(fund.length > 0, "no funds");

        mapping(uint256 => uint256)
            memory fundsToSupplyTargets = marketToFundsToSupplyTargets[
                marketId
            ];

        for (uint256 i = 0; i < funds.length; i++) {
            supplytarget += fundsToSupplyTargets[funds[i]];
        }

        return;
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
        external
        returns (uint256 totalLiquidity)
    {
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");

        address[] memory funds = marketToFunds[marketId];
        require(fund.length > 0, "no funds");

        mapping(uint256 => uint256)
            memory fundsToLiquidities = marketToFundsToLiquidity[marketId];

        for (uint256 i = 0; i < funds.length; i++) {
            totalLiquidity += fundsToLiquidities[funds[i]];
        }

        return;
    }

    function fundDebt(uint256 marketId, uint256 fundId)
        external
        view
        returns (int256)
    {
        // TODO: fundId check
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");

        int256 totalFundDebt = totalFundDebt(marketId);

        uint256 share = marketToFundsToLiquidity[marketId][fundId] /
            liquidity(marketId);

        return share * totalFundDebt;
    }

    function totalFundDebt(uint256 marketId) external view returns (int256) {
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");

        Market market = Market(marketAddr);

        return market.balance();
    }

    function deposit(uint256 marketId, uint256 amount) public {
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");

        /// @dev Transfers the specified amount of sUSD from msg.sender (in market.sol's buy() function) to market manager with the deposit() function.
        bool success = susd.transferFrom(tx.origin, address(this), amount);
        require(success, "ERC20: failed to transfer");

        marketToExternalLiquidity[marketAddr] += amount;
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

        marketToExternalLiquidity[marketAddr] -= amount;
    }
}

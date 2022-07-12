// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./math.sol";
import "./interfaces/erc20.sol";
import "./interfaces/IMarketManager.sol";
import "./Market.sol";
import "./fund.sol";

contract MarketManager is IMarketManager, Math {
    uint256 counter;
    ERC20 public susd;
    Fund public fundsRegistry;

    mapping(uint256 => address) idToMarkets;
    mapping(address => uint256) public marketsToId;

    mapping(uint256 => address[]) public marketToFunds;

    /// @dev marketId => fundId => liquidity
    mapping(uint256 => mapping(uint256 => uint256))
        public marketToFundsToLiquidity;

    /// @dev marketId => external liquidity (susd deposited to swap to synth by traders)
    mapping(uint256 => uint256) public marketToExternalLiquidity;

    constructor(address _susdAddr, address _fundsRegistryAddr) {
        counter = 1;
        susd = ERC20(_susdAddr);
        fundsRegistry = Fund(_fundsRegistryAddr);
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
    ) external returns (uint256) {
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");
        address fundManager = fundsRegistry.appointments(fundId);
        require(
            fundManager == msg.sender,
            "only fund manager can set liquidity"
        );

        emit LiquiditySet(marketId, fundId, amount);

        return amount;
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

    function deposit(uint256 marketId, uint256 amount) external {
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");
        require(msg.sender == marketAddr, "market is not caller");

        /// @dev Transfers the specified amount of sUSD from msg.sender (in market.sol's buy() function) to market manager with the deposit() function.
        bool success = susd.transferFrom(tx.origin, address(this), amount);
        require(success, "ERC20: failed to transfer");

        marketToExternalLiquidity[marketId] += amount;
    }

    function withdraw(
        uint256 marketId,
        uint256 amount,
        address recipient
    ) external {
        address marketAddr = idToMarkets[marketId];
        require(marketAddr != address(0), "market does not exist");
        require(msg.sender == marketAddr, "market is not caller");

        marketToExternalLiquidity[marketId] -= amount;
        require(
            marketToExternalLiquidity[marketId] + liquidity(marketId) >= 0,
            "market does not have enough liquidity"
        );

        /// @dev ransfers the appropriate amount of sUSD from the market manager the withdraw() function to msg.sender (in market.sol's sell() function).
        bool success = susd.transferFrom(address(this), recipient, amount);
        require(success, "ERC20: failed to transfer");
    }
}

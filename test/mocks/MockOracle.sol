// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../../src/oracle.sol";

contract MockOracle is Oracle {
    uint256 mockUsdValue;

    constructor(uint256 _mockUsdVale) {
        mockUsdValue = _mockUsdVale;
    }

    function usdValue(uint256 _amount)
        external
        view
        override
        returns (uint256)
    {
        return mockUsdValue;
    }
}

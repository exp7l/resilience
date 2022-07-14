// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Oracle {
    function usdValue(uint256 _amount) external view virtual returns (uint256) {
        revert("stub");
    }
}

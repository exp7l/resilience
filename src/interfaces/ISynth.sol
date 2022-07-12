// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./erc20.sol";

/**
 * @dev Extended from vanilla ERC20 to support synth interface
 */
interface ISynth is ERC20 {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

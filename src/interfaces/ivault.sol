// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IVault {
    function bvaults(uint fundId, address ctype)
        external
        returns (uint, address, uint, uint, uint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Shield
{
    bool internal _mutex;  

    modifier lock()
    {
        require(!_mutex, "ERR_REENTRY");
        _mutex = true;
        _;
        _mutex = false;
    }
}

// Reference: https://github.com/balancer-labs/balancer-core

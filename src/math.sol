// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Math {
    uint constant WAD = 1e18;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y)
        internal
        pure
        returns (uint z)
    {
        z = (x * y + WAD / 2) / WAD;
    }
    
    //rounds to zero if x/y < y / 2
    function wdiv(uint x, uint y)
        internal
        pure
        returns (uint z)
    {
        z = (x * WAD + y / 2) / y;
    }
}

// Reference: https://github.com/dapphub/ds-math/blob/master/src/math.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "ds-token/token.sol";
import "../src/deed.sol";
import "../src/fund.sol";
import "../src/vault.sol";
import "../src/math.sol";

contract VaultTest is Test, Math {
    RDB         rdb;
    Deed        deed;
    uint        deedId;  
    Fund        fund;
    uint        fundId;
    Vault       vault;
    DSToken     erc20;

    function setUp()
        public
    {
        rdb            = new RDB();
        deed           = new Deed(address(rdb));
        deedId         = deed.mint("test");
        fund           = new Fund(address(rdb));
        fundId         = 1;    
        vault          = new Vault(address(rdb));
        erc20          = new DSToken("TEST-ERC20");

        rdb.setDeed(address(deed));
        rdb.setFund(address(fund));
        rdb.setVault(address(vault));

        erc20.mint(type(uint).max);
        erc20.approve(address(vault), type(uint).max);
    }

    function testDeposit(uint _collateralAmount)
        public
    {
        vault.deposit(fundId, address(erc20), deedId, _collateralAmount);
        (, , uint _collateralAmountAfter, , ,) = vault.miniVaults(fundId, address(erc20), deedId);
        assertEq(_collateralAmountAfter, _collateralAmount);
    }

    // uint128 instead of uint256 due to overflow in test code.
    function testWithdraw(uint128 _collateralAmount)
        public
    {
        vault.deposit(fundId, address(erc20), deedId, _collateralAmount);
        vm.mockCall(
            address(rdb),
            abi.encodeWithSelector(rdb.assetUSDValue.selector),
            abi.encode(WAD)
            );
        vm.mockCall(
            address(rdb),
            abi.encodeWithSelector(rdb.targetCratios.selector),
            abi.encode(0)
            );
        uint _withdrawal                       = wmul(_collateralAmount, 0.3 * 10 ** 18);
        vault.withdraw(fundId, address(erc20), deedId, _withdrawal);
        (, , uint _collateralAmountAfter, , ,) = vault.miniVaults(fundId, address(erc20), deedId);
        assertEq(_collateralAmountAfter, _collateralAmount - _withdrawal);
    }

    function testMint(uint _usdAmount)
        public
    {
    }
}

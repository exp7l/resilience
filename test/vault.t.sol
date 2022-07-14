// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/token.sol";
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
    DSToken     rusd;

    function setUp()
        public
    {
        rdb            = new RDB();

        rusd           = new DSToken("RUSD");
        rdb.setRUSD(address(rusd));      

        deed           = new Deed(address(rdb));
        deedId         = deed.mint("test");        
        rdb.setDeed(address(deed));
        
        vault          = new Vault(address(rdb));
        rdb.setVault(address(vault));
        rusd.allow(address(vault));        

        fund           = new Fund(address(rdb));
        fundId         = 1;        
        rdb.setFund(address(fund));
        
        erc20          = new DSToken("TEST-ERC20");
        erc20.mint(type(uint128).max);
        erc20.approve(address(vault), type(uint).max);

        console.log("vault.t.sol setUp");
    }

    function testDeposit(uint128 _collateralAmount)
        public
    {
        console.log("testDeposit");
        vault.deposit(fundId, address(erc20), deedId, _collateralAmount);
        (,,, uint _amountAfter,,) = vault.miniVaults(fundId,
                                                     address(erc20),
                                                     deedId);
        assertEq(_amountAfter, _collateralAmount);
    }

    function testWithdraw(uint128 _collateralAmount)
        public
    {
        vm.mockCall(address(rdb),
                    abi.encodeWithSelector(rdb.assetUSDValue.selector),
                    abi.encode(WAD));
        vm.mockCall(address(rdb),
                    abi.encodeWithSelector(rdb.targetCratios.selector),
                    abi.encode(0));
	
        vault.deposit(fundId, address(erc20), deedId, _collateralAmount);
        uint _withdrawal = wmul(_collateralAmount, 0.3 * 10 ** 18);
        vault.withdraw(fundId, address(erc20), deedId, _withdrawal);
        (, , , uint _amountAfter, ,) = vault.miniVaults(fundId,
                                                        address(erc20),
                                                        deedId);
        assertEq(_amountAfter, _collateralAmount - _withdrawal);
    }

    function testMint(uint128 _usdAmount)
        public
    {
        vm.assume(_usdAmount != 0);
        vm.mockCall(address(rdb),
                    abi.encodeWithSelector(rdb.assetUSDValue.selector),
                    abi.encode(WAD));
        vm.mockCall(address(rdb),
                    abi.encodeWithSelector(rdb.targetCratios.selector),
                    abi.encode(0));

        vault.deposit(fundId, address(erc20), deedId, type(uint128).max);
        vault.mint(fundId, address(erc20), deedId, _usdAmount);
        (,,,,uint _vUSDAmount,uint _vDebtShares) = vault.miniVaults(fundId,
                                                                    address(erc20),
                                                                    deedId);
        assertEq(_vDebtShares,        vault.initialDebtShares());
        assertEq(_vUSDAmount,         _usdAmount);
        assertEq(rusd.totalSupply(),  _usdAmount);
    }

    function testMintTwice(uint128 _usdAmount)
        public
    {
        vm.assume(_usdAmount != 0 && _usdAmount != 1);
        vm.mockCall(address(rdb),
                    abi.encodeWithSelector(rdb.assetUSDValue.selector),
                    abi.encode(WAD));
        vm.mockCall(address(rdb),
                    abi.encodeWithSelector(rdb.targetCratios.selector),
                    abi.encode(0));

        vault.deposit(fundId, address(erc20), deedId, type(uint128).max);
        vault.mint(fundId, address(erc20), deedId, _usdAmount);
        vault.mint(fundId, address(erc20), deedId, _usdAmount);

        (,,,,uint _vUSDAmount,uint _vDebtShares) = vault.miniVaults(fundId,
                                                                    address(erc20),
                                                                    deedId);

        assertEq(_vDebtShares / 2       , vault.initialDebtShares());
        assertEq(_vUSDAmount  / 2       , _usdAmount);
        assertEq(rusd.totalSupply() / 2 , _usdAmount);
        // TODO: What does state change not apply after this point?
    }

    function testBurn(uint128 _usdAmount)
        public
    {
        vm.assume(_usdAmount != 0 && _usdAmount != 1);
        vm.mockCall(address(rdb),
                    abi.encodeWithSelector(rdb.assetUSDValue.selector),
                    abi.encode(WAD));
        vm.mockCall(address(rdb),
                    abi.encodeWithSelector(rdb.targetCratios.selector),
                    abi.encode(0));

        uint128 _deposit = type(uint128).max;
        vault.deposit(fundId, address(erc20), deedId, _deposit);
        vault.mint(fundId, address(erc20), deedId, _usdAmount);
        uint _divisor = _usdAmount % 2 == 0 ? 2 : 1;
        vault.burn(fundId, address(erc20), deedId, _usdAmount / _divisor);

        (,,,,uint _mvUSDAmount,uint _mvDebtShares) = vault.miniVaults(fundId,
                                                                      address(erc20),
                                                                      deedId);
        (,,,uint _vUSDAmount,uint _vDebtShares) = vault.vaults(fundId,
                                                               address(erc20));	

        uint _init = vault.initialDebtShares();
        assertEq(_mvDebtShares     , _init - _init / _divisor);
        assertEq(_mvUSDAmount      , _usdAmount - _usdAmount / _divisor);
        assertEq(rusd.totalSupply(), _usdAmount - _usdAmount / _divisor);
    }
}

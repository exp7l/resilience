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
        // For mint.
        rusd.allow(address(vault));

        fund           = new Fund(address(rdb));
        fundId         = 1;        
        rdb.setFund(address(fund));
        
        erc20          = new DSToken("TEST-ERC20");
        // Give test contract test tokens.
        erc20.mint(type(uint128).max);
        erc20.approve(address(vault), type(uint).max);
    }

    function testDeposit(uint128 _camount)
        public
    {
        vault.deposit(fundId, address(erc20), deedId, _camount);
        (,,, uint _camountSVault,,) = vault.svaults(fundId,
                                                    address(erc20),
                                                    deedId);
        assertEq(_camountSVault, _camount);
        (,,uint _camountBVault,,) = vault.bvaults(fundId,
                                                  address(erc20));
        assertEq(_camountBVault, _camount);
                                             
    }

    function testWithdraw(uint128 _camount)
        public
    {
        vm.mockCall(address(rdb),
                    abi.encodeWithSelector(rdb.assetUSDValue.selector),
                    abi.encode(WAD));
        vm.mockCall(address(rdb),
                    abi.encodeWithSelector(rdb.targetCratios.selector),
                    abi.encode(0));
	
        vault.deposit(fundId, address(erc20), deedId, _camount);
        uint _withdrawal = wmul(_camount, 0.3 * 10 ** 18);
        vault.withdraw(fundId, address(erc20), deedId, _withdrawal);
        (, , , uint _camountSVault, ,) = vault.svaults(fundId,
                                                       address(erc20),
                                                       deedId);
        assertEq(_camountSVault, _camount - _withdrawal);
        (, , uint _camountBVault, ,) = vault.bvaults(fundId,
                                                     address(erc20));
        assertEq(_camountBVault, _camount - _withdrawal);        
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
        (,,,,uint _svUSDAmount,uint _svDebtShares) = vault.svaults(fundId,
                                                                   address(erc20),
                                                                   deedId);
        assertEq(_svDebtShares,        vault.initialDebtShares());
        assertEq(_svUSDAmount,         _usdAmount);

        (,,,uint _bvUSDAmount,uint _bvDebtShares) = vault.bvaults(fundId,
                                                                  address(erc20));
                                                            
        assertEq(_bvDebtShares,        vault.initialDebtShares());
        assertEq(_bvUSDAmount,         _usdAmount);

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

        (,,,,uint _svUSDAmount,uint _svDebtShares) = vault.svaults(fundId,
                                                                 address(erc20),
                                                                 deedId);

        assertEq(_svDebtShares / 2       , vault.initialDebtShares());
        assertEq(_svUSDAmount  / 2       , _usdAmount);

        (,,,uint _bvUSDAmount,uint _bvDebtShares) = vault.bvaults(fundId,
                                                                   address(erc20));

        assertEq(_bvDebtShares / 2       , vault.initialDebtShares());
        assertEq(_bvUSDAmount  / 2       , _usdAmount);

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

        (,,,,uint _svUSDAmount,uint _svDebtShares) = vault.svaults(fundId,
                                                                   address(erc20),
                                                                   deedId);
        (,,,uint _bvUSDAmount,uint _bvDebtShares) = vault.bvaults(fundId,
                                                                 address(erc20));	

        uint _init = vault.initialDebtShares();
        assertEq(_svDebtShares     , _init - _init / _divisor);
        assertEq(_svUSDAmount      , _usdAmount - _usdAmount / _divisor);

        assertEq(_bvDebtShares     , _init - _init / _divisor);
        assertEq(_bvUSDAmount      , _usdAmount - _usdAmount / _divisor);
        
        assertEq(rusd.totalSupply(), _usdAmount - _usdAmount / _divisor);
    }
}

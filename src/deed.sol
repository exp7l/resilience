// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "ds-deed/deed.sol";
import "./interfaces/ierc20.sol";
import "./rdb.sol";
import "./shield.sol";

contract Deed is Shield, DSDeed("Resilient Deed", "RDeed")
{

    RDB rdb;
    // deedId => asset => balance
    mapping(uint => mapping(address => uint)) public cash;
		  
    event Deposit (uint    indexed deedId,
                   address indexed erc20,
                   uint    indexed amount);
    event Withdraw(uint    indexed deedId,
                   address indexed erc20,
                   uint    indexed amount);

    constructor(address _rdb)
    {
        rdb = RDB(_rdb);
    }

    function deposit(uint    _deedId,
                     address _erc20,
                     uint    _amount)
        external
        lock
    {
        require(msg.sender == _deeds[_deedId].guy, "ERR_AUTH");
        require(rdb.approved(_erc20),              "ERR_APPROVAL");
        cash[_deedId][_erc20] += _amount;
        require(IERC20(_erc20).transferFrom(msg.sender,
                                           address(this),
                                           _amount),
                "ERR_TRANSFER");
        emit Deposit(_deedId, _erc20, _amount);
    }
  
    function withdraw(uint    _deedId,
                      address _erc20,
                      uint    _amount)
        external
        lock
    {
        require(msg.sender == _deeds[_deedId].guy, "ERR_AUTH");
        require(cash[_deedId][_erc20] >= _amount,  "ERR_NSF");
        require(rdb.approved(_erc20),              "ERR_APPROVAL");
        cash[_deedId][_erc20] -= _amount;
        require(IERC20(_erc20).transferFrom(address(this),
                                           msg.sender,
                                           _amount),
                "ERR_TRANSFER");
        emit Withdraw(_deedId, _erc20, _amount);
    }
}

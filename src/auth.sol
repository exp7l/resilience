// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Reference: https://github.com/brianmcmichael/ds-deed

contract Auth {
  bool                             public   stopped;
  mapping (address => uint)        public   authorized;
  
  event Stop();
  event Start();
  event Allow(address indexed principal);
  event Deny(address indexed principal);
  
  modifier auth {
	require(authorized[msg.sender] == 1, "ERR_AUTH");
	_;
  }

  modifier stoppable {
	require(!stopped, "stopped");
	_;
  }

  constructor() {
    authorized[msg.sender] = 1;
  }

  function stop() external auth {
	stopped = true;
	emit Stop();
  }

  function start() external auth {
	stopped = false;
	emit Start();
  }

  function allow(address principal) external auth {
	authorized[principal] = 1;
	emit Allow(principal);
  }

  function deny(address principal) external auth {
	authorized[principal] = 0;
	emit Deny(principal);
  }
}

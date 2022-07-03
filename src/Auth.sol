// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Auth {
  bool                             public   stopped;
  mapping (address => uint)        public   wards;
  
  event Stop();
  event Start();
  event Rely(address indexed guy);
  event Deny(address indexed guy);
  
  modifier auth {
	require(wards[msg.sender] == 1, "ds-deed-not-authorized");
	_;
  }

  modifier stoppable {
	require(!stopped, "ds-deed-is-stopped");
	_;
  }

  function stop() external auth {
	stopped = true;
	emit Stop();
  }

  function start() external auth {
	stopped = false;
	emit Start();
  }

  function rely(address guy) external auth {
	wards[guy] = 1;
	emit Rely(guy);
  }

  function deny(address guy) external auth {
	wards[guy] = 0;
	emit Deny(guy);
  }
}

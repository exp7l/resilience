// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Failsafes:
// - redistribution
// - fund liqudation
// - recovery mode

interface ILiquidationManager {
	function accept(uint fundId, address collateralType, uint amount) external;
	function collateralAailable(uint fundId, uint accountId, address collateralType) external view returns (uint);
	function claim(uint fundId, uint accountId, address collateralType) external;
}

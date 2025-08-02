// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

// this is merely a simple contract used as PriceOracle
// real implementation should benefit from the likes of
// Chainlink 
interface IPriceOracle  {
    function setRatio(address a, address b, uint256 price) external;    
    function getRatio(address a, address b) external view returns (uint256);
    function getAmount(address a, address b, uint256 amount) external view returns (uint256);
}
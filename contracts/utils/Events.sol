// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;


library Events {
    event LiquidityInterestIndexUpdate(uint256 previous, uint256 newIndex, uint256 fromLastUpdate, uint256 numberOfSeconds);
    event SupplyAdded(address lender, uint256 scaledAmount);
}


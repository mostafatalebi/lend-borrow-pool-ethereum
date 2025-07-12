// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { Rate } from "../utils/Rate.sol";

library RateWrapper {
    function computeLinearInterest(uint256 rate, uint256 timeDelta) public pure returns (uint256) {
        return Rate.computeLinearInterest(rate, timeDelta);
    }

    function getScaledBalance(uint256 amount, uint256 interestIndex) public pure returns (uint256) {
        return Rate.getScaledBalance(amount, interestIndex);
    }
}
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { Types } from "../utils/Types.sol";
import { Constants } from "../utils/Constants.sol";
import { Errors } from "../utils/Errors.sol";


library Helpers {

    function getNthBit(uint8 value, uint8 n) internal pure returns (bool) {
        require(n < 8, "bit index out of range!");
        return (value & (1 << n)) != 0;
    }   

    function getNthBit(uint16 value, uint16 n) internal pure returns (bool) {
        require(n < 16, "bit index out of range!");
        return (value & (1 << n)) != 0;
    }
    

    /// Calculates the result equivalent to the given percentage of the original value
    /// @param value the amount in wei, otherwise the calculation might endup overflown 
    ///              or fails. 
    /// @param _percentage the percentage, a value from 1-99
    function percentageInWei(uint256 value, uint8 _percentage) internal pure returns (uint256 result) {
        uint256 _p = uint256(_percentage);
        result = (value / 100) * (_percentage);
    }


    // given a loan amount, using ltv (%), it calculates the required collateral amount 
    // no zero-checks, caller has to ensure such validation
    function getCollateralOf(uint256 _loanAmount, uint8 _ltv) internal pure returns (uint256 result) {
        return (_loanAmount * 100) / uint256(_ltv);
    }
}
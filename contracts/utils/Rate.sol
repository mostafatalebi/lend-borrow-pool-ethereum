// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {Constants} from "./Constants.sol";
import {RayMath} from "./RayMath.sol";

library Rate {
    using RayMath for uint256;

    uint256 constant RAY = 1e27;


    // copied exactly as-is from Aave codebase 
    // 
    function computeCompoundedInterest(
        uint256 rate,
        uint256 timeDelta
    ) internal pure returns (uint256) {
        
        uint256 exp = timeDelta;

        if (exp == 0) {
            return Constants.RAY;
        }

        uint256 expMinusOne;
        uint256 expMinusTwo;
        uint256 basePowerTwo;
        uint256 basePowerThree;
        unchecked {
            expMinusOne = exp - 1;

            expMinusTwo = exp > 2 ? exp - 2 : 0;

            basePowerTwo =
                rate.mulRay(rate) /
                (Constants.SECONDS_OF_A_YEAR * Constants.SECONDS_OF_A_YEAR);
            basePowerThree = basePowerTwo.mulRay(rate) / Constants.SECONDS_OF_A_YEAR;
        }

        uint256 secondTerm = exp * expMinusOne * basePowerTwo;
        unchecked {
            secondTerm /= 2;
        }
        uint256 thirdTerm = exp * expMinusOne * expMinusTwo * basePowerThree;
        unchecked {
            thirdTerm /= 6;
        }

        return
            Constants.RAY +
            (rate * exp) /
            Constants.SECONDS_OF_A_YEAR +
            secondTerm +
            thirdTerm;
    }

    /// note: this function skips validation of the inputs
    /// make sure the caller calls this safely
    /// Uses ray math to return an interest index (multipler) following
    /// the technique originally used by Aave protocol
    /// This is basically used for supply side (liquidity providers)
    function computeLinearInterest(uint256 rate, uint256 timeDelta) internal pure returns (uint256 newInterest) {
        if(rate == 0 || timeDelta == 0) {
            return RAY;
        } 
        newInterest = RAY + (rate.mulRay(timeDelta) / Constants.SECONDS_OF_A_YEAR );
    }

    /// applies current liquidity index to the amount
    function getScaledBalance(uint256 amount, uint256 index) internal pure returns (uint256 scaled) {
        scaled = amount.divRay(index);
    }

    function getDescaledBalance(uint256 scaledAmount, uint256 index) internal pure returns (uint256 descaled) {
        descaled = scaledAmount.mulRay(index);
    }

    

    // calculates the amount of load the asset has given away
    // and based on the current interest, calculates the share
    // of the protocol
    function calculateProtocolShare(uint256 currentScaledVarBorrow, 
    uint256 currentVariableBorrowIndex, 
    uint256 newVariableBorrowIndex, uint256 protocolSharePercentage) internal pure 
        returns (uint256 protocolShare)
                {                    
        uint256 currentTotalVariableBorrow = currentScaledVarBorrow.mulRay(currentVariableBorrowIndex);
        uint256 newTotalVariableBorrow = currentScaledVarBorrow.mulRay(newVariableBorrowIndex);        

        uint256 newlyAccruedAmount = newTotalVariableBorrow - currentTotalVariableBorrow;

        // the caller of this function needs to save this calculated
        // amount somewher; when minting interest profits for suppliers,
        // this amount will be taken into account and less tokens will
        // be transferred to suppliers, as the protocol share must not
        // be transferred with them, as expected. 
        // if(protocolSharePercentage != 0) {
            // protocolShare = newlyAccruedAmount.percentage(protocolSharePercentage);
        // }
    }

    /// 
    /// @param amountIn the amount in wei
    /// @param ratio the ratio in wei. This includes the ratio equivalent to 1e18 of original asset
    ///              e.g. 0.8 in wei becomes 8e17
    function getEquivalentRatio(uint256 amountIn, uint256 ratio) internal returns (uint256 amountOut) {
        return (amountIn * ratio) / Constants.WEI;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { Constants } from "./Constants.sol";

library RayMath {

    
    /// uses adding a half RAY to the number, following
    /// aave v3's technique
    /// multiplies two RAY numebers and returns a RAY result
    function mulRay(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = (a * b + Constants.HALF_RAY) / Constants.RAY;
    }

    function divRay(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = (a * Constants.RAY + b / 2) / b;
    }
    
    function percentage(uint256 value, uint256 _percentage) internal pure returns (uint256 result) {
        if(value < _percentage) {
            return 0;
        }
        result = (value / 100) * _percentage;
    }
}
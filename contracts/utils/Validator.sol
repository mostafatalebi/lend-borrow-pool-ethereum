// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;


import { Constants } from "./Constants.sol";
import { Errors } from "./Errors.sol";
import { Types } from "./Types.sol";

library Validator {
    function validateAsset(Types.Asset calldata asset) internal pure {
        require(asset.asset != address(0), "asset's address: bad address");
        require(asset.wrapperToken != address(0), "wrapperToken: bad addres");
        require(asset.rslopeBeforeUT != 0, "rslopeBeforeUT cannot be zero");
        require(asset.rslopeAfterUT != 0, "rslopeAfterUT cannot be zero");
        require(asset.liquidityIndex != 0, "liquidityIndex cannot be zero");
        require(asset.borrowIndex != 0, "borrowIndex cannot be zero");
        // require(asset.liquidityRate != 0, "liquidityRate cannot be zero");
        // require(asset.borrowRate != 0, "borrowRate cannot be zero");
        require(asset.ltv != 0, "ltv cannot be zero");
    }    
}
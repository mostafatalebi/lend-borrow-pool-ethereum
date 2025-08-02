// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;


import { Constants } from "./Constants.sol";
import { Errors } from "./Errors.sol";
import { Types } from "./Types.sol";
import { Roles } from "./Roles.sol";

library Validator {
    function validateAsset(Types.Asset calldata asset) internal pure {
        require(asset.asset != address(0), "asset's address: bad address");
        require(asset.rslopeBeforeUT != 0, "rslopeBeforeUT cannot be zero");
        require(asset.rslopeAfterUT != 0, "rslopeAfterUT cannot be zero");
        require(asset.liquidityIndex != 0, "liquidityIndex cannot be zero");
        require(asset.borrowIndex != 0, "borrowIndex cannot be zero");
        // require(asset.liquidityRate != 0, "liquidityRate cannot be zero");
        // require(asset.borrowRate != 0, "borrowRate cannot be zero");
        require(asset.ltv != 0, "ltv cannot be zero");
    }


    function validateBorrow(
                address assetToBorrow, 
                address collateral, 
                address borrower,
                uint16  userRole,
                uint256 requestedLoanAmount,
                Constants.Status   lastLoanStatus,
                Types.Asset memory assetObj, 
                Types.Asset memory collateralAsset
                ) internal pure {
        require(assetToBorrow != collateral, Errors.LoopedBorrowing());
        require(Roles.isUserBlacklisted(userRole) == false, Errors.Forbidden(borrower));
        require(requestedLoanAmount > 0, Errors.InputIzZero());
        require(assetToBorrow != address(0), Errors.BadAddress());     
        require(assetObj.active, Errors.AssetNotActive(assetToBorrow));
        require(assetObj.borrowable, Errors.AssetNotBorrowable(assetToBorrow));
        require(requestedLoanAmount > assetObj.minBorrowAmount, Errors.MinAmount(assetObj.minBorrowAmount, 
                requestedLoanAmount));
        require(collateralAsset.asset != address(0), Errors.AssetNotFound(collateral));
        require(lastLoanStatus != Constants.Status.Active, Errors.LoanStatusUnexpected(lastLoanStatus));
    }    
}
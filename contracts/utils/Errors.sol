// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { Constants } from "./Constants.sol";

library Errors {
    error InputIzZero();
    error BadAddress();
    error AssetNotFound(address asset);
    error AssetNotActive(address asset);
    error NonCollateralAsset(address asset);
    error Forbidden(address user);
    error Unauthorized(address user, uint16 currentPermission, uint16 permission);
    error UserNotAllowed(address user);
    error ContractIsNotActive();
    error InsufficientBalance(uint256 current, uint256 requested);
    error AssetNotBorrowable(address asset);
    error AlreadyDeleted(address user);
    error MinAmount(uint256 min, uint256 currentValue);
    error MaxAmount(uint256 max, uint256 currentValue);
    error Deleted();
    // when loan and collateral assets are the same
    error LoopedBorrowing();
    error CollateralNotFound();
    error AlreadyCollateralized();
    error LoanExceedsCollateral(uint256 allowedMaxLoan, uint256 currentlyRequestedAmount);
    error MaxSupplyExceeded();
    error UtilizationRateExceeded(uint256 ur, uint256 newUr);
    error LoanStatusUnexpected(Constants.Status currStatus);
    error LoanNotFound();
    error LoanNotRepayable();
    error LoanInsufficientRepayProvided();
    error AssetInsufficientAllowance(uint256 currentAllowance, uint256 requiredAllowance);
    error BadRatio(uint256 currentRatioValue);
    error RatioDoesNotExists(address a, address b);

    error Debug(uint256);
    error DebugAddress(address);
    error DebugForbidden(address current, address expected);
}
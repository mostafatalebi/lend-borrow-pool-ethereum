// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

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
    // when loan and collateral assets are the same
    error LoopedBorrowing();
    error NoCollateral();
    error AlreadyCollateralized();
    error LoanExceedsCollateral(uint256 allowedMaxLoan);
    error MaxSupplyExceeded();
    error UtilizationRateExceeded(uint256 ur, uint256 newUr);
    error UserHasActiveLoan();
    error LoanNotFound();
    error LoanNotRepayable();
    error LoanInsufficientRepayProvided();
}
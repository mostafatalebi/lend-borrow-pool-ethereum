// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;


import { Constants } from "./Constants.sol";

library Types {
    struct Asset {
        // ERC-20 address of the token
        address asset;

        // can the asset be used as a collateral
        bool allowAsCollateral;

        // ERC-20 address of its wrapperToken
        address wrapperToken; 

        // if the asset is active or not
        bool active;

        // in wei; minimum amount allowed for borrowing
        uint256 minBorrowAmount;        
        
        // if true, allows users to borrow
        // from this asset
        bool borrowable;

        // the address who has changed this asset
        address changedBy;

        // slopes multipliers for before and after
        // utilization rate stop
        uint256 rslopeBeforeUT;
        uint256 rslopeAfterUT;

        // indexes for liquidity and borrow
        uint256 liquidityIndex; // RAY
        uint256 borrowIndex; // RAY

        // rates for liquidity and borrow
        uint256 liquidityRate; // RAY
        uint256 borrowRate; // RAY

        // loan to value; a value from 1 to 100
        uint8 ltv;

        uint256 currentLtv;

        // last time any of the fields above have changed
        uint256 changedAt;

        // the last update of the index
        uint256 indexChangedAt;

        // total amount of liquidity (amount supplied)
        // in wei
        uint256 scaledBalance;

        // total debt; total amount of asset borrowed by
        uint256 stableBorrows; 

        uint256 protocolShareMultiplier;

        uint256 totalLoansCount;
    }

    struct Loan {
        address asset;
        address borrower;
        uint256 loanedAt;
        uint256 fixedRate;
        uint256 amount;
        Constants.Status status;        
    }

    // settings for an asset that
    // can be specified for a user; this
    // type is also used as global default for 
    // all users
    struct UserTokenSetting {
        // in percentage; the amount of loan
        // allowed is this percent of the total
        // locked collateral
        uint256 collaterlaThreshold;

        // both of the following values are
        // in wei
        uint256 maxBorrow;
        uint256 minBorrow;

        // if the user is allowed or not
        bool allowed;

        bool exists;
    }

    struct Collateral {
        address asset;
        address borrower;
        uint256 ts;        
        // in wei
        uint256 amount;
    }

    struct UserBalance {
        address user;
        mapping(address => Collateral) collaterals;
        mapping(address => uint256) balances;
    }

    struct UserAccount {
        address user;
        uint16 totalLoansCount;
        
        // ETH, in wei
        uint16 totalBorrowedValue;
        uint16 totalSuppliedValue;
        
    }
}
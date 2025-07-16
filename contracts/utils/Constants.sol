// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;



library Constants {
    uint64 constant SECONDS_OF_A_YEAR = 31536000;
    uint256 constant RAY = 1e27;
    uint256 public constant HALF_RAY = 5e26;
    uint256 public constant WEI = 1e18;

    enum Action {
        Supply, Borrow, Repay, Withdraw
    }

    enum Status {
        NotBlocked, Blocked, Active, InActive, Repaid, Cancelled
    }

    enum CollStatus {
        Locked, Released, Liquidified
    }
}
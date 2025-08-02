// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

abstract contract Shared {

    bool _locked;

    modifier lock() {
        require(!_locked, "Locked!");
        _locked = true;
        _;
        _locked = false;
    }
}
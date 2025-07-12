// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { Types } from "../utils/Types.sol";
interface ICoreLBV1 {
    
    /// allows lending asset to the protocol and receive
    /// LBToken in return
    /// the liquidity supply to the protocol will be profited
    /// through increasing of indexed interest. 
    /// a protocol fee get subtracted form profits as well
    /// Steps: 1- validation
    ///        2- updating indexed interest 
    ///        3- updating the supply balances
    ///        4- minting the scaled amount of lbToken to the supplier
    /// @param assetAddr the address of the ERC20 token
    /// @param amount the amount, in wei, of the token 
    ///        provided as liquidity
    function lend(address assetAddr, uint64 amount) external;


    /// In order for the borrowing to happen, the user
    /// must have already supplied an amount using supply()
    /// to the system. When requesting the borrow(), the
    /// collateral proportional to his/her "amount" will
    /// be locked by the system. 
    /// 
    /// @param assetToBorrow the address of the ERC20 token which 
    ///                      the user wants to borrow a loan in
    /// @param collateral the asset which is used to back this loan
    /// @param loanAmount the amount, in wei, of the token 
    ///        provided as liquidity
    function borrow(address assetToBorrow, address collateral, uint loanAmount) external;

    function withdraw(address assetAddr, uint64 amount, address to) external;
    function repay(address assetAddr, uint64 amount) external;
}
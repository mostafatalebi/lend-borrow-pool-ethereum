// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { Helpers } from "../utils/Helpers.sol";
import { Rate } from "../utils/Rate.sol";
import { Types } from "../utils/Types.sol";
import { Constants } from "../utils/Constants.sol";
import { Errors } from "../utils/Errors.sol";
import { IPriceOracle } from "../interfaces/IPriceOracle.sol";
import { PriceOracle } from "../oracle/PriceOracle.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract LoanManager {
    IPriceOracle priceOracle;

    Types.UserTokenSetting private globalDefaultSetting;

    mapping (address => Types.UserTokenSetting) private userSettings;

    mapping (address => Types.UserBalance) usersBalances;

    // each loan is saved under its associated asset
    // this way we can easily look up loans for a user
    // or an asset with no overhead
    //      [user]              [asset]   [loan data]
    mapping (address => mapping(address => Types.Loan)) loans;

    constructor() {
        globalDefaultSetting = Types.UserTokenSetting(75, type(uint256).max, 0, true, true);
    }

    function setPriceOracleContract(address _priceOracle) public  {
        priceOracle = IPriceOracle(_priceOracle);
    }

    function getUserCollateral(address user, address asset) external view returns (Types.Collateral memory) {
        return usersBalances[user].collaterals[asset];
    }

    function getUserBalance(address user, address asset) external view returns (uint256) {
        return usersBalances[user].balances[asset];
    }

    function getUserLoan(address asset) external view returns (Types.Loan memory) {
        return loans[msg.sender][asset];
    }

    function lockAsCollateral(address user, address collateralAsset, uint256 requestedCollAmount) internal {
        Types.UserTokenSetting memory _setting = globalDefaultSetting;
        if(userSettings[user].exists == true){
            _setting = userSettings[user];
        }
        require(_setting.allowed, Errors.Forbidden(msg.sender));
        require(usersBalances[user].collaterals[collateralAsset].amount == 0, Errors.AlreadyCollateralized());
        require(usersBalances[user].balances[collateralAsset] >= requestedCollAmount, 
                                Errors.InsufficientBalance(usersBalances[user].balances[collateralAsset], requestedCollAmount));

        Types.Collateral memory _coll;

        _coll.borrower =        user;
        _coll.ts       =        block.timestamp;   
        _coll.amount   =        requestedCollAmount;
        _coll.asset    =        collateralAsset;
        _coll.status   =        Constants.CollStatus.Locked;

        usersBalances[user].collaterals[collateralAsset] = _coll;
    }

    function handleCollateralization(address collateral, uint256 amount) internal {

    }

    function setGlobalDefaultSetting(Types.UserTokenSetting memory setting) internal {
        globalDefaultSetting = setting;
    }

    function _addSetting(address user, Types.UserTokenSetting memory setting) internal {
        userSettings[user] = setting;
    }

    function balanceOf(address asset, address user) internal returns (uint256) {
        return usersBalances[user].balances[user];
    }

    function balanceAfterCollateral(address asset, address user) internal returns (uint256) {
        uint256 _balance = usersBalances[user].balances[user];
        Types.Collateral memory _collateral = usersBalances[user].collaterals[asset];
        if(_collateral.amount > 0) {
            uint256 remained = _collateral.amount - _balance;
            if(remained < 0) {
                return 0;
            } 
            return remained;
        }
        return _balance;
    }

    function collaterlaOf(address collateral, address user) internal returns (Types.Collateral memory) {
        return usersBalances[user].collaterals[collateral];
    }

    /// returns in wei of the max amount of loan
    /// of the given asset, based on the locked amount
    /// of collateral of the reference asset
    /// (e.g. x amount of asset a locked, allows y amount of asset b at maximum)
    /// @param collateral the address of the asset which is locked as collateral
    /// @param ltv the amount of loanToValue of the original asset at the moment
    /// @param user the borrower's address
    /// @param ratio the ratio, in wei, of the collateral asset to request for loan asset
    function getMaxLoanAvailableByLockedCollateral(address collateral, uint8 ltv, address user, 
                                uint256 ratio) internal returns (uint256 amountOut) {
        Types.Collateral memory _collateral = usersBalances[user].collaterals[collateral];
        require(_collateral.amount > 0, Errors.CollateralNotFound());
        require(ltv > 0, Errors.InputIzZero());        
        uint256 ltvAmount = Helpers.percentageInWei(_collateral.amount, ltv);
        amountOut         = Rate.getEquivalentRatio(ltvAmount, ratio);
        return amountOut;
    }

    function enoughLiquidity(uint256 loanAmount, uint256 assetTotalDebt, uint256 assetTotalLiquidity )
                         internal view returns (uint256) {
        uint256 newTotalDebtAmount = assetTotalDebt+loanAmount;
        require(newTotalDebtAmount <= assetTotalLiquidity, Errors.MaxSupplyExceeded());
    }

    function getInterestRateBasedOnUr(uint256 loanAmount, uint256 assetTotalDebt, uint256 assetTotalLiquidity 
                    ,uint8 optimalUr) internal view returns (uint256) {
        uint256 urAmount    = Helpers.percentageInWei(assetTotalLiquidity, optimalUr);
        uint256 newTotalDebtAmount = assetTotalDebt+loanAmount;
        require(newTotalDebtAmount <= urAmount, Errors.UtilizationRateExceeded(urAmount, newTotalDebtAmount));
    }

    /// in order to avoid gas waste, we do not check
    /// if any loan exists or not. It is crucial 
    /// for the caller of this function to do necessary
    /// checkups. Since this is often a task of 
    /// of parent callers. 
    function insertLoan(Types.Loan memory _loan) internal {
        Constants.Status existingLoanIfAnyStatus = loans[_loan.borrower][_loan.asset].status;
        require(existingLoanIfAnyStatus != Constants.Status.Active, Errors.LoanStatusUnexpected(existingLoanIfAnyStatus));
        loans[_loan.borrower][_loan.asset] = _loan;
    }

    function hasActiveLoan(address user, address asset) internal view returns (bool) {
        return loans[user][asset].status == Constants.Status.Active;
    }

    function getLoan(address user, address asset) internal view returns (Types.Loan storage) {
        return loans[user][asset];
    }

    function getLoanStatus(address user, address asset) internal view returns (Constants.Status) {
        return loans[user][asset].status;
    }

    function loanRepay(Types.Loan storage loanObj, uint256 repayAmount) internal {
        loanObj.repayAmount = repayAmount;
        loanObj.repaidAt = block.timestamp;
        loanObj.status = Constants.Status.Repaid;
    }

    function releaseCollateral(address user, address asset) internal {
        require(usersBalances[user].collaterals[asset].status == Constants.CollStatus.Locked, 
                Errors.CollateralNotFound());

        usersBalances[user].collaterals[asset].status = Constants.CollStatus.Released;
        ERC20(asset).transfer(user, usersBalances[user].collaterals[asset].amount);
    }

}
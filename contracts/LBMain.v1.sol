// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {ICoreLBV1} from "./interfaces/ICoreLB.v1.sol";
import {IAssetManagerV1} from "./interfaces/IAssetManager.v1.sol";
import {IPriceOracle} from "./interfaces/IPriceOracle.sol";
import { UserManager } from "./abstracts/UserManager.sol";
import { LoanManager } from "./abstracts/LoanManager.sol";
import "./abstracts/Shared.sol";

import { PriceOracle } from "./oracle/PriceOracle.sol";
import { Types } from "./utils/Types.sol";
import { Events } from "./utils/Events.sol";
import { Errors } from "./utils/Errors.sol";
import { Rate } from "./utils/Rate.sol";
import { Roles } from "./utils/Roles.sol";
import { Validator } from "./utils/Validator.sol";
import { Helpers } from "./utils/Helpers.sol";
import "./LBToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { RayMath } from "./utils/RayMath.sol";


contract LBMainV1 is ICoreLBV1, IAssetManagerV1, UserManager, LoanManager, Shared {
    using RayMath for uint256;

    mapping (address => Types.Asset) private assetsList;
    
    // a global flag which controls
    // if the contract can do any ops 
    // or not. 
    bool private contractIsActive;

    modifier onlyAssetManager() {
        require(userHasPermission(msg.sender, Roles.ASSETM_BIT_INDEX), Errors.Forbidden(msg.sender));
        _;
    }

    modifier onlyProtocolManager() {
        require(userHasPermission(msg.sender, Roles.PROTOCOLM_BIT_INDEX), Errors.Unauthorized(msg.sender, userGetRole(msg.sender), 0x0041));
        _;
    }

    constructor() UserManager(msg.sender){

    }




    function setContractActivation(bool _state) public onlyProtocolManager {
        contractIsActive = _state;
    }

    /// @inheritdoc ICoreLBV1
    function lend(address assetAddr, uint64 amount) external lock {
        address sender = msg.sender;
        require(Roles.isUserBlacklisted(_usersRoles[sender]) == false, Errors.Forbidden(sender));
        // require(userHasPermission(sender, Roles.CRITICAL_PROTOCOL_MANAGER), Errors.Forbidden(sender));
        require(amount > 0, Errors.InputIzZero());
        require(assetAddr != address(0), Errors.BadAddress());  
        (bool exists, Types.Asset storage assetObj) = _getAsset(assetAddr);      
        require(exists, Errors.AssetNotFound(assetAddr));
        require(assetObj.active, Errors.AssetNotActive(assetAddr));
        require(contractIsActive, Errors.ContractIsNotActive());
        uint256 currentAllowance = ERC20(assetAddr).allowance(msg.sender, address(this));
        require(currentAllowance >= amount, Errors.AssetInsufficientAllowance(currentAllowance, amount));

       (uint256 newLiquidityIndex, ) = _updateIndexedInterests(assetAddr, assetObj);
    
       uint256 scaledBalance = Rate.getScaledBalance(amount, newLiquidityIndex);

       ERC20(assetAddr).transferFrom(sender, address(this), amount);
       _updateSupply(sender, assetObj, scaledBalance);
       _mintToSupplier(assetObj.wrapperToken, sender, scaledBalance);
    }
    
    function borrowWithCollateralAmount(address assetToBorrow, address collateral, uint256 collateralAmount)
        external {
            // @todo
            // @todo we need to implement several public helper function for various ways 
            // @todo of defining the loan amount by user. They call must eventually call
            // @todo the borrow() function, but enables user to approach loans differently
    }

    function borrow(address assetToBorrow, address collateral, uint256 loanAmount) public {
        address sender = msg.sender;
        (bool exists, Types.Asset storage assetObj) = _getAsset(assetToBorrow);
        (bool collExists, Types.Asset storage collAssetObj) = _getAsset(assetToBorrow);
        
        Validator.validateBorrow(assetToBorrow, 
                collateral, 
                sender, 
                userGetRole(sender),
                loanAmount,
                getLoanStatus(sender, assetToBorrow), 
                assetObj, 
                collAssetObj);

        (uint256 newLiquidityIndex, uint256 newBorrowIndex) = _updateIndexedInterests(assetToBorrow, assetObj);
        
        uint256 _loanAmountConvertedToCollAsset = priceOracle.getAmount(assetToBorrow, collateral, loanAmount);
        uint256 _requiredFinalCollateralAmount = Helpers.getCollateralOf(_loanAmountConvertedToCollAsset, assetObj.ltv);
        
        // locking the corresponding amount 
        lockAsCollateral(sender, collateral, _requiredFinalCollateralAmount);        

        loanAmount = Rate.getDescaledBalance(loanAmount, newBorrowIndex);
        Types.Loan memory loanObj = Types.Loan(assetToBorrow, collateral, sender, block.timestamp, 0, 0, assetObj.borrowRate, 
            loanAmount, Constants.Status.Active);
        // registering the loan
        insertLoan(loanObj);
        
        // sending the loan to the user
        ERC20(assetObj.asset).transfer(sender, loanAmount);
    }
    

    

    function withdraw(address asset, uint64 amount, address to) external {

    }

    function repay(address asset, uint64 amount) external {
        Types.Loan storage loanObj = getLoan(msg.sender, asset);
        require(loanObj.status == Constants.Status.Active, Errors.LoanNotFound());
        require(loanObj.status == Constants.Status.Active, Errors.LoanNotRepayable());
        (bool exists, Types.Asset memory assetObj) = _getAsset(asset);
        require(exists, Errors.AssetNotFound(asset));
        (, uint256 newBorrowIndex) = _updateIndexedInterests(asset, assetObj);
        uint256 descaledLoanAmount = Rate.getDescaledBalance(loanObj.amount, newBorrowIndex);
        require(amount >= descaledLoanAmount, Errors.LoanInsufficientRepayProvided());

        // getting the money back
        ERC20(asset).transferFrom(msg.sender, address(this), amount);

        // updating state
        loanRepay(loanObj, amount);
        releaseCollateral(msg.sender, loanObj.collateral);
    }

    

    function _amountIsApproved(address sender, address asset, uint256 amount) internal {
        ERC20(asset).transferFrom(sender, address(this), amount);
    }

    function _getAsset(address asset) internal view returns (bool exists, Types.Asset storage obj) {
        obj = assetsList[asset];
        if(obj.asset != address(0)) {
            exists = true;
        }
    }


    function _updateIndexedInterests(address assetAddr, Types.Asset memory assetObj) internal returns (uint256 newLiquidityIndex, 
                uint256 newBorrowIndex) {
        if(assetObj.indexChangedAt == 0) {
            assetObj.indexChangedAt = block.timestamp;
        }
        uint256 timeDelta = block.timestamp - assetObj.indexChangedAt;
        if(timeDelta < 1) {
            return (assetObj.liquidityIndex, assetObj.borrowIndex);
        }

        // this is used to calculate the index from the last update till now
        uint256 liquidityInterestFromLastCheck = Rate.computeLinearInterest(assetObj.liquidityRate, timeDelta);

        // this is to ensure we get an index from the beginning till now
        newLiquidityIndex = assetObj.liquidityIndex.mulRay(liquidityInterestFromLastCheck);
        
        emit Events.LiquidityInterestIndexUpdate(assetObj.liquidityIndex, newLiquidityIndex, 
            liquidityInterestFromLastCheck, timeDelta);

        // we can use Aave's compound interest calculator function later
        newBorrowIndex = Rate.computeLinearInterest(assetObj.borrowRate, timeDelta);

        // calculate how much new debt has been accumulated
        // @todo no protocol share for now
        // uint256 toBeMintedProtocolShare = Rate.calculateProtocolShare(assetObj.scaledVariableBorrow, 
        //     assetObj.borrowIndex, newBorrowIndex);

        // storing to be minuted tokens for the protocl
        // assetObj.nextMintAmount = toBeMintedProtocolShare; 
        _setIndexedInterests(assetAddr, newLiquidityIndex, newBorrowIndex);
    }

    function _setIndexedInterests(address asset, uint256 liquidityIndex, uint256 borrowIndex) internal {
        assetsList[asset].liquidityIndex = liquidityIndex;
        assetsList[asset].borrowIndex = borrowIndex;
        assetsList[asset].indexChangedAt = block.timestamp;
        assetsList[asset].changedAt = block.timestamp;
    }

    function _updateSupply(address lender, Types.Asset storage assetObj, uint256 scaledBalance) internal {
        usersBalances[lender].balances[assetObj.asset] += scaledBalance;
        assetObj.changedAt = block.timestamp;
        assetObj.scaledBalance = assetObj.scaledBalance + scaledBalance;  

        emit Events.SupplyAdded(lender, scaledBalance);
    }

    function _mintToSupplier(address wrapperAsset, address to, uint256 amount) internal {
        ILBToken(wrapperAsset).mint(to, amount);
    }

    /// @inheritdoc IAssetManagerV1
    function setAsset(Types.Asset calldata _asset, address _sender) external lock {
        Types.Asset storage assetObj = assetsList[_asset.asset];
        if(assetObj.asset != address(0)) {
            assetObj.asset = _asset.asset;
            assetObj.allowAsCollateral = _asset.allowAsCollateral;
            assetObj.active = _asset.active;
            assetObj.rslopeBeforeUT = _asset.rslopeBeforeUT;
            assetObj.rslopeAfterUT = _asset.rslopeAfterUT;
            assetObj.ltv = _asset.ltv;
            assetObj.borrowable = _asset.borrowable;
        } else {
            assetObj.asset = _asset.asset;
            assetObj.allowAsCollateral = _asset.allowAsCollateral;
            assetObj.active = _asset.active;
            assetObj.rslopeBeforeUT = _asset.rslopeBeforeUT;
            assetObj.rslopeAfterUT = _asset.rslopeAfterUT;
            assetObj.ltv = _asset.ltv;
            assetObj.wrapperToken = _asset.wrapperToken;
            assetObj.borrowIndex = _asset.borrowIndex;
            assetObj.liquidityIndex = _asset.liquidityIndex;
            assetObj.liquidityRate = _asset.liquidityRate;
            assetObj.borrowRate = _asset.borrowRate;
            assetObj.scaledBalance = 0;
            assetObj.stableBorrows = 0;
            assetObj.protocolShareMultiplier = _asset.protocolShareMultiplier;
            assetObj.borrowable = _asset.borrowable;  
        }
        assetObj.changedBy = _sender;
        assetObj.indexChangedAt = block.timestamp;
        assetObj.changedAt = block.timestamp;
        assetsList[_asset.asset] = assetObj;
    }

    function getAsset(address asset) external view onlyAssetManager returns (Types.Asset memory) {
        return assetsList[asset];
    }
}
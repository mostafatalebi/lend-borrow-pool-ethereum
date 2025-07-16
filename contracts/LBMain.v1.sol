// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {ICoreLBV1} from "./interfaces/ICoreLB.v1.sol";
import {IAssetManagerV1} from "./interfaces/IAssetManager.v1.sol";
import {IPriceOracle} from "./interfaces/IPriceOracle.sol";
import { UserManager } from "./abstracts/UserManager.sol";
import { LoanManager } from "./abstracts/LoanManager.sol";

import { PriceOracle } from "./oracle/PriceOracle.sol";
import { Types } from "./utils/Types.sol";
import { Events } from "./utils/Events.sol";
import { Errors } from "./utils/Errors.sol";
import { Rate } from "./utils/Rate.sol";
import { Roles } from "./utils/Roles.sol";
import "./LBToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {RayMath} from "./utils/RayMath.sol";


contract LBMainV1 is ICoreLBV1, IAssetManagerV1, UserManager, LoanManager {
    using RayMath for uint256;

    mapping (address => Types.Asset) private assetsList;

    address owner;

    mapping (address => Constants.Status) blacklistedSuppliers;
    
    // a global flag which controls
    // if the contract can do any ops 
    // or not. 
    bool private contractIsActive;

    // handling reenterancy
    bool locked = false;

    modifier onlyAssetManager() {
        require(userHasPermission(msg.sender, Roles.ASSETM_BIT_INDEX), Errors.Forbidden(msg.sender));
        _;
    }

    modifier onlyProtocolManager() {
        require(userHasPermission(msg.sender, Roles.PROTOCOLM_BIT_INDEX), Errors.Unauthorized(msg.sender, userGetRole(msg.sender), 0x0041));
        _;
    }

    constructor() UserManager(msg.sender){
        owner = msg.sender;
    }

    function setPriceOracleContract(address _priceOracle) public  {
        priceOracle = IPriceOracle(_priceOracle);
    }


    function setContractActivation(bool _state) public onlyProtocolManager {
        contractIsActive = _state;
    }

    /// @inheritdoc ICoreLBV1
    function lend(address assetAddr, uint64 amount) external lock {
        // _amountIsApproved(msg.sender, Addr, amount);
        address sender = msg.sender;
        require(Roles.isUserBlacklisted(_usersRoles[sender]) == false, Errors.Forbidden(sender));
        // require(userHasPermission(sender, Roles.CRITICAL_PROTOCOL_MANAGER), Errors.Forbidden(sender));
        require(amount > 0, Errors.InputIzZero());
        require(assetAddr != address(0), Errors.BadAddress());  
        (bool exists, Types.Asset storage assetObj) = _getAsset(assetAddr);      
        require(exists, Errors.AssetNotFound(assetAddr));
        require(assetObj.active, Errors.AssetNotActive(assetAddr));
        require(contractIsActive, Errors.ContractIsNotActive());

       (uint256 newLiquidityIndex, ) = _updateIndexedInterests(assetAddr, assetObj);
    
       uint256 scaledBalance = Rate.getScaledBalance(amount, newLiquidityIndex);

       _updateSupply(assetObj, scaledBalance);
       _mintToSupplier(assetObj.wrapperToken, sender, scaledBalance);
    }

    function borrow(address assetToBorrow, address collateral, uint loanAmount) external {
        address sender = msg.sender;
        require(assetToBorrow != collateral, Errors.LoopedBorrowing());
        require(Roles.isUserBlacklisted(_usersRoles[sender]) == false, Errors.Forbidden(sender));
        require(loanAmount > 0, Errors.InputIzZero());
        require(assetToBorrow != address(0), Errors.BadAddress());  
        (bool exists, Types.Asset storage assetObj) = _getAsset(assetToBorrow);      
        require(exists, Errors.AssetNotFound(assetToBorrow));
        require(assetObj.active, Errors.AssetNotActive(assetToBorrow));
        require(assetObj.borrowable, Errors.AssetNotBorrowable(assetToBorrow));
        require(contractIsActive, Errors.ContractIsNotActive());
        require(loanAmount > assetObj.minBorrowAmount, Errors.MinAmount(assetObj.minBorrowAmount, loanAmount));
        require(assetsList[collateral].asset != address(0), Errors.AssetNotFound(collateral));
        require(hasActiveLoan(sender, assetToBorrow) == false, Errors.UserHasActiveLoan());
        (uint256 newLiquidityIndex, uint256 newBorrowIndex) = _updateIndexedInterests(assetToBorrow, assetObj);
        
        lockAsCollateral(sender, collateral, loanAmount);        

        // @todo room for improvement; we can cache the result per each block
        uint256 ratio = priceOracle.getPrice(collateral, assetToBorrow);

        uint256 maxLoanAllowed = maxLoan(collateral, assetObj.ltv, sender, ratio);

        require(maxLoanAllowed >= loanAmount, Errors.LoanExceedsCollateral(maxLoanAllowed));

        loanAmount = Rate.getDescaledBalance(loanAmount, newBorrowIndex);
        Types.Loan memory loanObj = Types.Loan(assetToBorrow, collateral, sender, block.timestamp, 0, 0, assetObj.borrowRate, 
            loanAmount, Constants.Status.Active);

        // recording the loan
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

    function _updateSupply(Types.Asset storage assetObj, uint256 scaledBalance) internal returns (uint256 aTokenToMint) {
        assetObj.changedAt = block.timestamp;
        assetObj.scaledBalance = assetObj.scaledBalance + scaledBalance;
        aTokenToMint = scaledBalance;        
    }

    function _mintToSupplier(address wrapperAsset, address to, uint256 amount) internal {
        ILBToken(wrapperAsset).mint(to, amount);
    }

    function _userIsAllowed(address user, Constants.Action action) internal view returns (bool) {
        if(action == Constants.Action.Supply) {
            return blacklistedSuppliers[user] == Constants.Status.Blocked ? false : true;
        }
        return true;
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
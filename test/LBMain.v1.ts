
import { time } from "@nomicfoundation/hardhat-network-helpers"
import { expect } from "chai";
import { Block, ContractFactory } from "ethers";
import hre, { ethers } from "hardhat";
import { AssetManager, AssetManager__factory, AssetManagerWrapper, AssetManagerWrapper__factory, LBMainV1, LBMainV1__factory, LBToken, LBToken__factory, MockToken, MockToken__factory } from "../typechain-types";
import { Types } from "../typechain-types/contracts/AssetManager.v1.sol/AssetManager";
import * as Custom from "./types"
import * as Utils from "./utils"
import * as JsSolidity from "./solidity"

describe("LBMain.v1", function () {
    // Signers
    let owner:         Custom.HardhatSigner,  supplier:        Custom.HardhatSigner, 
     assetManagerUser: Custom.HardhatSigner,  protocolManager: Custom.HardhatSigner,
     borrower:         Custom.HardhatSigner;

     // Factories
    let 
    _lbToken:              LBToken__factory,    _mainLbV1:       LBMainV1__factory, 
    _asset:                AssetManager__factory, 
    _wrapperAssetManager:  AssetManagerWrapper__factory,
    _borrowableAsset:      MockToken__factory;

    // Contracts
    let 
    $lbToken:              LBToken,               $mainLb:               LBMainV1, 
    $assetManager:         AssetManager,          $lbtOfLendingToken:    LBToken,            
    $wrapperAssetManager:  AssetManagerWrapper,   $borrowableAsset:      LBToken,
    $collaterallableAsset: LBToken,               $lbtOfBorrowableToken: LBToken;

    this.beforeEach(async function(){
        [owner, supplier, borrower, assetManagerUser, protocolManager] = await hre.ethers.getSigners();

        // Creating contract factories
        _asset               = await hre.ethers.getContractFactory("AssetManager");
        _wrapperAssetManager = await hre.ethers.getContractFactory("AssetManagerWrapper");
        _mainLbV1            = await hre.ethers.getContractFactory("LBMainV1");
        _lbToken             = await hre.ethers.getContractFactory("LBToken");
        _borrowableAsset     = await hre.ethers.getContractFactory("LBToken");


        // deloying the instanciated contracts
        $mainLb                = await _mainLbV1.connect(owner).deploy();
        $assetManager          = await _asset.connect(assetManagerUser).deploy(await $mainLb.getAddress());
        $wrapperAssetManager   = await _wrapperAssetManager.connect(assetManagerUser).deploy(await $assetManager.getAddress());
        $lbToken               = await _lbToken.connect(owner).deploy(10_000n, "MOCK",                 "MTK");
        $borrowableAsset       = await _lbToken.connect(supplier).deploy(10_000n, "LoanToken",            "LTK");
        $collaterallableAsset  = await _lbToken.connect(borrower).deploy(100n,    "CollateralAsset",      "CLAS");
        $lbtOfBorrowableToken  = await _lbToken.connect(owner).deploy(0n,      "LBTOfBorrowable",      "LBTBorr");
        $lbtOfLendingToken     = await _lbToken.connect(owner).deploy(0n,      "LBTOfCollateralAsset", "LBTColl");

        // change ownership of LBToken contracts to mainLb contract
        // @todo on contract side, when LBToken roles are defined, it would be more appropriate
        // to add them here too. Instead of changing ownership, which is not a good approach
        await $lbtOfBorrowableToken.connect(owner).changeOwner(await $mainLb.getAddress(), 0n);

        // doing basic and necessary contracts authorization and delegations
        $assetManager.addUser(await $wrapperAssetManager.getAddress(), 0x0011);
    });

    // Definition: two assets are deposited, which
    // are named $lendingAsset, $collateralAsset and $borrowableAsset
    // lender user lends $borrowableAsset asset to the system
    // borrower user lends $collateral asset to the system
    // a system user updates the PriceOracle with a proper ratio
    // between the above assets
    // the borrower user requests to borrow from $borrowableAsset,
    // given that it already has enoguh collateral. These are all
    // asserted continously within the test suit. 
    // During each major operation, subtle things such as
    // roles, users, index etc. are asserted
    it("a complete lend and borrow cycle", async function() {    
        let lentAsset: Types.AssetStruct = {
            asset:                   await $collaterallableAsset.getAddress(),
            wrapperToken:            await $lbtOfLendingToken.getAddress(),
            allowAsCollateral:       true,
            active:                  true,
            rslopeAfterUT:           Custom.getPercentOf(Custom.Ray, 15n),
            rslopeBeforeUT:          Custom.getPercentOf(Custom.Ray, 60n),
            liquidityRate:           0n,
            borrowRate:              0n,
            ltv:                     75n,
            protocolShareMultiplier: 0n,
            liquidityIndex:          Custom.Ray,
            borrowIndex:             1n,
            changedBy:               ethers.ZeroAddress,
            indexChangedAt:          0n,
            changedAt:               0n,
            scaledBalance:           0n,
            minBorrowAmount:         0n,
            borrowable:              true,
            stableBorrows:           0n,
            totalLoansCount:         0n,
            currentLtv:              0n
        };

        let borrowableAsset: Types.AssetStruct = {
            asset:                   await $borrowableAsset.getAddress(),
            wrapperToken:            await $lbtOfBorrowableToken.getAddress(),
            allowAsCollateral:       true,
            active:                  true,
            rslopeAfterUT:           Custom.getPercentOf(Custom.Ray, 15n),
            rslopeBeforeUT:          Custom.getPercentOf(Custom.Ray, 60n),
            liquidityRate:           0n,
            borrowRate:              0n,
            ltv:                     75n,
            protocolShareMultiplier: 0n,
            liquidityIndex:          Custom.Ray,
            borrowIndex:             1n,
            changedBy:               ethers.ZeroAddress,
            indexChangedAt:          0n,
            changedAt:               0n,
            scaledBalance:           0n,
            minBorrowAmount:         0n,
            borrowable:              true,
            stableBorrows:           0n,
            totalLoansCount:         0n,
            currentLtv:              0n
        };

        // handling authorizations and user delegation
        await $mainLb.connect(owner).addUser(owner, 0xFFFD);
        await $mainLb.connect(owner).addUser(protocolManager, 0x0041);
        
        expect(Custom.hexPrint(await $mainLb.connect(owner).userGetRole(await protocolManager.getAddress()))).to.equal("0x0041")

        await       $mainLb.connect(protocolManager) .setContractActivation(true);              
        await       $mainLb.connect(owner)           .addUser(await $assetManager.getAddress(), 0x0011);
        await $assetManager.connect(assetManagerUser).addUser(assetManagerUser, 0x0011);
        await $assetManager.connect(assetManagerUser).setAsset(lentAsset,     await assetManagerUser.getAddress());
        await $assetManager.connect(assetManagerUser).setAsset(borrowableAsset, await assetManagerUser.getAddress());

        // financing
        console.log(await borrower.getAddress());
        let tx            = await $mainLb.connect(supplier).lend(await $borrowableAsset.getAddress(), ethers.parseUnits("1", 18));
        let receipt       = await tx.wait();
        let debugEvent    = Utils.GetEvent($mainLb, receipt, "LiquidityInterestIndexUpdate");
        console.log(debugEvent.args);
        let LIndex        = await $wrapperAssetManager.connect(assetManagerUser).getLiquidityIndex(await $borrowableAsset.getAddress())
        console.log(LIndex);
        let scaledBalance = await $wrapperAssetManager.connect(assetManagerUser).getScaledBalance(await $borrowableAsset.getAddress())
        // assertions
        expect(scaledBalance).to.equal(JsSolidity.getScaledBalance(ethers.parseUnits("1", 18), LIndex));

        // forwarding the blocks
        const currentBlock: Block | null = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
        if(currentBlock != null) {
            // since there is no borrowing yet, the following
            // block forwarding must NOT in any way affect
            // interest index, as it remains 1 due to utilization of 0
            await time.increaseTo(currentBlock?.timestamp+100000);
        }

        // doing more transactions
        tx            = await $mainLb.connect(supplier).lend(await $borrowableAsset.getAddress(), ethers.parseUnits("1", 18));
        receipt       = await tx.wait();
        debugEvent    = Utils.GetEvent($mainLb, receipt, "LiquidityInterestIndexUpdate");
        scaledBalance = await $wrapperAssetManager.connect(assetManagerUser).getScaledBalance(await $borrowableAsset.getAddress());
        LIndex        = await $wrapperAssetManager.connect(assetManagerUser).getLiquidityIndex(await $borrowableAsset.getAddress())
        // doing the assertions
        expect(scaledBalance).to.equal(JsSolidity.getScaledBalance(ethers.parseUnits("2", 18), LIndex));
        
        // the following line, though calls lend(), but is meant for further collateralization
        tx  = await $mainLb.connect(borrower).lend(await $collaterallableAsset.getAddress(), ethers.parseUnits("2", 18));
        
        // now we do a borrowing
        tx  = await $mainLb.connect(borrower).borrow(await $borrowableAsset.getAddress(), await $collaterallableAsset.getAddress(), ethers.parseUnits("0.2", 18));
    });
});
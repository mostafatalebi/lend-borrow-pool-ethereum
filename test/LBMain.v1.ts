
import { time } from "@nomicfoundation/hardhat-network-helpers"
import { expect } from "chai";
import { Block, ContractFactory } from "ethers";
import hre, { ethers } from "hardhat";
import { AssetManager, AssetManager__factory, AssetManagerWrapper, AssetManagerWrapper__factory, LBMainV1, LBMainV1__factory, MockToken, MockToken__factory } from "../typechain-types";
import { Types } from "../typechain-types/contracts/AssetManager.v1.sol/AssetManager";
import * as Custom from "./types"
import * as Utils from "./utils"

describe("LBMain.v1", function () {
    let owner: Custom.HardhatSigner, supplier: Custom.HardhatSigner, borrower: Custom.HardhatSigner,
     assetManagerUser: Custom.HardhatSigner, protocolManager: Custom.HardhatSigner;
    let _mockToken: MockToken__factory, _mainLbV1: LBMainV1__factory, 
    _asset: AssetManager__factory, _wrapperToken: MockToken__factory, _wrapperAssetManager: AssetManagerWrapper__factory;
    let $mockToken: MockToken, $mainLb: LBMainV1, 
    $assetManager: AssetManager, $wrapperToken: MockToken, $wrapperAssetManager: AssetManagerWrapper;

    this.beforeEach(async function(){
        [owner, supplier, borrower, assetManagerUser, protocolManager] = await hre.ethers.getSigners();

        // Creating contract factories
        _mockToken           = await hre.ethers.getContractFactory("MockToken");
        _wrapperToken        = await hre.ethers.getContractFactory("MockToken");
        _mainLbV1            = await hre.ethers.getContractFactory("LBMainV1");
        _asset               = await hre.ethers.getContractFactory("AssetManager");
        _wrapperAssetManager = await hre.ethers.getContractFactory("AssetManagerWrapper");

        // deloying the instanciated contracts
        $mockToken           = await _mockToken.connect(owner).deploy(10_000n, "MOCK", "MTK");
        $wrapperToken        = await _wrapperToken.connect(owner).deploy(0n, "WMOCK", "WMTK");
        $mainLb              = await _mainLbV1.connect(owner).deploy();
        $assetManager        = await _asset.connect(assetManagerUser).deploy(await $mainLb.getAddress());
        $wrapperAssetManager = await _wrapperAssetManager.connect(assetManagerUser).deploy(await $assetManager.getAddress());

        // doing basic and necessary contracts authorization and delegations
        $assetManager.addUser(await $wrapperAssetManager.getAddress(), 0x0011);
    });


    it("first test, just deploy", async function() {    
        let assetObject: Types.AssetStruct = {
            asset:                   await $mockToken.getAddress(),
            wrapperToken:            await $wrapperToken.getAddress(),
            allowAsCollateral:       true,
            active:                  true,
            rslopeAfterUT:           Custom.getPercentOf(Custom.Ray, 15n),
            rslopeBeforeUT:          Custom.getPercentOf(Custom.Ray, 60n),
            liquidityRate:           0n,
            borrowRate:              0n,
            ltv:                     Custom.getPercentOf(Custom.Ray, 75n),
            protocolShareMultiplier: 0n,
            liquidityIndex:          Custom.Ray,
            borrowIndex:             1n,
            changedBy:               ethers.ZeroAddress,
            indexChangedAt:          0n,
            changedAt:               0n,
            scaledBalance:           0n,
            scaledVariableBorrow:    0n,
            totalDebt:               0n,
            nextMintAmount:          0n,
        };

        // handling authorizations and user delegation
        await $mainLb.connect(owner).addUser(owner, 0xFFFD);
        await $mainLb.connect(owner).addUser(protocolManager, 0x0041);
        
        expect(Custom.hexPrint(await $mainLb.connect(owner).userGetRole(await protocolManager.getAddress()))).to.equal("0x0041")
        await       $mainLb.connect(protocolManager).setContractActivation(true);                    
        await       $mainLb.connect(owner).addUser(await $assetManager.getAddress(), 0x0011);
        await $assetManager.connect(assetManagerUser).addUser(assetManagerUser, 0x0011);
        await $assetManager.connect(assetManagerUser).setAsset(assetObject, await assetManagerUser.getAddress());

        // financing
        let tx = await $mainLb.connect(supplier).lend(await $mockToken.getAddress(), ethers.parseUnits("1", 18));
        let receipt = await tx.wait();
        let debugEvent = Utils.GetEvent($mainLb, receipt, "LiquidityInterestIndexUpdate");
        // console.log(debugEvent.args);
        let scaledBalance = await $wrapperAssetManager.connect(assetManagerUser).getScaledBalance(await $mockToken.getAddress())

        // assertions
        expect(scaledBalance).to.equal(ethers.parseUnits("1", 18)*Custom.Ray);

        // forwarding the blocks
        const currentBlock: Block | null = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
        if(currentBlock != null) {
            // since there is no borrowing yet, the following
            // block forwarding must NOT in any way affect
            // interest index, as it remains 1 due to utilization of 0
            await time.increaseTo(currentBlock?.timestamp+100000);
        }

        // doing more transactions
        let asset = await $mainLb.connect(owner).getAsset(await $mockToken.getAddress())
        tx = await $mainLb.connect(supplier).lend(await $mockToken.getAddress(), ethers.parseUnits("1", 18));
        receipt = await tx.wait();
        debugEvent = Utils.GetEvent($mainLb, receipt, "LiquidityInterestIndexUpdate");
        // console.log(debugEvent.args);
        scaledBalance = await $wrapperAssetManager.connect(assetManagerUser).getScaledBalance(await $mockToken.getAddress());

        // doing the assertions
        expect(scaledBalance).to.equal(ethers.parseUnits("2", 18)*Custom.Ray);
    });
});

import { expect } from "chai";
import hre, { ethers } from "hardhat";
import { RateWrapper, RateWrapper__factory } from "../typechain-types";
import * as Custom from "./types"
import * as JsSolidity from "./solidity"

type HardhatSigner = Awaited<ReturnType<typeof hre.ethers.getSigner>>;

describe("RateWrapper", function(){
    let owner: HardhatSigner;
    let rateWrapper: RateWrapper__factory;
     this.beforeEach(async function(){
        [owner] = await ethers.getSigners();
     });
    let $rateFactory: RateWrapper;
    this.beforeAll(async function(){
        rateWrapper = await hre.ethers.getContractFactory("RateWrapper");
        $rateFactory = await rateWrapper.deploy();
    });
    

    it("computeLinearInterest()", async function(){
        let newInterest = await $rateFactory.computeLinearInterest(0, 0)
        expect(newInterest).to.equal(Custom.Ray);
        expect(newInterest).to.equal(JsSolidity.calculateLinearInterest(0n, 0n));
    });

    it("getScaledBalance()", async function(){
        let scaledBalance = await $rateFactory.getScaledBalance(10000n, Custom.Ray);
        let __scaledBalance = JsSolidity.getScaledBalance(10000n, Custom.Ray);
        expect(scaledBalance).to.equal(__scaledBalance);
        console.log(JsSolidity.getScaledBalance(10000n, Custom.Ray*20n));
        // expect(scaledBalance).to.equal(Custom.Ray);
    });
});
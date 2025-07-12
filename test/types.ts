import hre, { ethers } from "hardhat";

export type HardhatSigner = Awaited<ReturnType<typeof hre.ethers.getSigner>>;

export function convertIntTo16BitDecimal(n: number) : string {
    let hex = n.toString(16);
    let str: string = "0x";
    if(hex.length < 4) {
        var remainder = 4-hex.length;
        Array.from({ length: 2 }, (_, i) => {
            str += "0";
        });
    }
    return str+hex;
}

export function getPercentOf(num: bigint, percent: bigint) : bigint {
    return (num*percent)/100n;
}

export function hexPrint(s: any) : string {
    return convertIntTo16BitDecimal(s.toString(16));
}

export const WAD = 1_000_000_000_000_000_000n;
export const Ray = ethers.toBigInt("1000000000000000000000000000");
export const HalfRay = ethers.toBigInt("500000000000000000000000000");
export const NumOfSecondsPerYear = ethers.toBigInt("31536000");



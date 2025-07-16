import * as Custom from "./types"


// some simpler pure Solidity functions have been re-implemented
// here for the sake more debuggable unit tests. It is recommended
// that these functions be used along side original contract's function
// in the test; this ensures any modification of original Solidity functions
// causes these functions to mismatch and hence resulting in test-failure and
// avoids unnoticed mismatching. 
//


export function calculateLinearInterest(rate: bigint, timeDelta: bigint) : bigint {
    if(rate == 0n) {
        return Custom.Ray;
    } else if (timeDelta == 0n) {
        return rate;
    }
    return Custom.Ray + ((rate * timeDelta + Custom.HalfRay) / Custom.NumOfSecondsPerYear);
}

export function getScaledBalance(amount: bigint, index: bigint) : bigint {
    return ((amount * Custom.Ray)+(index / 2n)) / index;
}

export function getDescaledBalance(amount: bigint, index: bigint) : bigint {
    return amount * index / Custom.Ray;
}
// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.21 < 0.9.0;

import "../../contracts/LBMain.v1.sol";

contract DbgEntry {
    event EvmPrint(string);

    constructor() {
        emit EvmPrint("DbgEntry.constructor");

        // Here you can either deploy your contracts via `new`, eg:
        //  Counter counter = new Counter();
        //  counter.increment();

        LBMainV1 lbMain = new LBMainV1();
        // or interact with an existing deployment by specifying a `fork` url in `dbg.project.json`
        // eg:
        //  ICounter counter = ICounter(0x12345678.....)
        //  counter.increment(); 
        //
        // If you have correct symbols (`artifacts`) for the deployed contract, you can step-into calls.
        // lbMain.addUser(msg.sender, 0x0044);

        emit EvmPrint("DbgEntry return");
    }
}
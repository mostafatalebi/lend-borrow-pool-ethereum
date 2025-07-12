// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {UserManager} from "../abstracts/UserManager.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";


contract PriceOracle is IPriceOracle, UserManager {

   //       [asset 1]          [asset 2]   [wei-rate]
    mapping (address => mapping(address => uint256)) _prices;
    
    constructor() UserManager(msg.sender) {}

    function setPrice(address a, address b, uint256 price) public onlyOwner {
        _prices[a][b] = price;
    }

    function getPrice(address a, address b) public onlyOwner view returns (uint256) {
        return _prices[a][b];
    }
}
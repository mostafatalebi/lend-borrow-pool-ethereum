// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {UserManager} from "../abstracts/UserManager.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {Roles} from "../utils/Roles.sol";
import {Errors} from "../utils/Errors.sol";
import {Constants} from "../utils/Constants.sol";


contract PriceOracle is  UserManager, IPriceOracle {

   //       [asset 1]          [asset 2]   [rate in wei]
    mapping (address => mapping(address => uint256)) _prices;

    modifier priceReader() {
        require(userHasPermission(msg.sender, Roles.PROTOCOLM_BIT_INDEX), Errors.Unauthorized(msg.sender, userGetRole(msg.sender), Roles.PROTOCOL_MANAGER));
        _;
    }

    modifier priceWriter() {
        require(userHasPermission(msg.sender, Roles.PROTOCOLM_BIT_INDEX), Errors.Forbidden(msg.sender));
        _;
    }
    
    constructor() UserManager(msg.sender) {}

    function setRatio(address a, address b, uint256 price) external priceWriter {
        require(price > 0, Errors.InputIzZero());
        _prices[a][b] = price;
    }

    function getRatio(address a, address b) public priceReader view returns (uint256) {
        return _prices[a][b];
    }

    function getAmount(address a, address b, uint256 amount) external view returns (uint256) {
        require(amount > 0, Errors.InputIzZero());
        uint256 ratio = _prices[a][b];
        require(ratio > 0, Errors.RatioDoesNotExists(a, b));
        return (ratio * amount) / Constants.WEI;
    }
}
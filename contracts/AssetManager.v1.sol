// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {ICoreLBV1} from "./interfaces/ICoreLB.v1.sol";
import {IAssetManagerV1} from "./interfaces/IAssetManager.v1.sol";
import {UserManager} from "./abstracts/UserManager.sol";
import {Shared} from "./abstracts/Shared.sol";
import { Types } from "./utils/Types.sol";
import { Errors } from "./utils/Errors.sol";
import { Roles } from "./utils/Roles.sol";
import { Validator } from "./utils/Validator.sol";


contract AssetManager is IAssetManagerV1, UserManager, Shared  {
    IAssetManagerV1 relayedContract;
    
    constructor(address lbMainContractAddr) UserManager(msg.sender) {
        relayedContract = IAssetManagerV1(lbMainContractAddr);
    }
    
    /// @inheritdoc IAssetManagerV1
    function setAsset(Types.Asset calldata asset, address _sender) external lock {
        require(_sender == msg.sender, "_sender should match msg.sender");
        require(userHasPermission(msg.sender, Roles.ASSETM_BIT_INDEX), Errors.Forbidden(msg.sender));
        Validator.validateAsset(asset);
        IAssetManagerV1(relayedContract).setAsset(asset, address(this));
    }

    function getAsset(address asset) external view returns (Types.Asset memory) {
        require(userHasPermission(msg.sender, Roles.ASSETM_BIT_INDEX), Errors.Forbidden(msg.sender));
        return IAssetManagerV1(relayedContract).getAsset(asset);
    }
}
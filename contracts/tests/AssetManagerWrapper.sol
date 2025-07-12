// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { Rate } from "../utils/Rate.sol";
import { Types } from "../utils/Types.sol";
import { IAssetManagerV1 } from "../interfaces/IAssetManager.v1.sol";

/// @title AssetWrapper
/// @author 
/// @notice this wrapper is intended to be used only
//          for testing and no production deployment
contract AssetManagerWrapper {
    
    // the address of AssetManager contract
    IAssetManagerV1 assetManagerContract;

    constructor(address _assetManagerContract) {
        assetManagerContract = IAssetManagerV1(_assetManagerContract);
    }

    function getAsset(address _asset) internal view returns (Types.Asset memory) {
        return IAssetManagerV1(assetManagerContract).getAsset(_asset);
    }


    function getLiquidityIndex(address _asset) public view returns (uint256) {
        Types.Asset memory asset = getAsset(_asset);
        return asset.liquidityIndex;
    }

    function getLiquidityRate(address _asset) public view returns (uint256) {
        Types.Asset memory asset = getAsset(_asset);
        return asset.liquidityRate;
    }

    function getScaledBalance(address _asset) public view returns (uint256) {
        Types.Asset memory asset = getAsset(_asset);
        return asset.scaledBalance;
    }

    function getChangedAt(address _asset) public view returns (uint256) {
        Types.Asset memory asset = getAsset(_asset);
        return asset.changedAt;
    }

    function getIndexChangedAt(address _asset) public view returns (uint256) {
        Types.Asset memory asset = getAsset(_asset);
        return asset.indexChangedAt;
    }
    
}
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { Types } from "../utils/Types.sol";
interface IAssetManagerV1 {
    
    /// inserts/updates an assets into the 
    /// underlying relayed contract. It is expected of the 
    /// implementation to retain the asset validation and
    /// related logics in itself; while the underlying contract
    /// might have its own essential validations
    /// @param asset the data of the asset
    /// @param _sender the address of the sender. Some implementation might
    ///                want to user msg.sender; specifically those impls. 
    ///                facing the public. 
    function setAsset(Types.Asset calldata asset, address _sender) external;

    function getAsset(address asset) external view returns (Types.Asset calldata);    
}
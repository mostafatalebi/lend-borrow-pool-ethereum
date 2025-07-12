// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { Types } from "../utils/Types.sol";
import { Roles } from "../utils/Roles.sol";
import { Helpers } from "../utils/Helpers.sol";
import { Errors } from "../utils/Errors.sol";


abstract contract UserManager {    
    address private owner;

    /// key => the address of the user
    /// value => 16 bits holding permissions bits
    /// what each bit means is not a concern of this
    /// contract, the implementor must take care of it
    /// @notice refer to Role.sol file to read constant roles
    mapping (address => uint16) _usersRoles;    


    bool private locked;

    modifier lock() {
        require(!locked, "Locked!");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, Errors.Forbidden(msg.sender));
        _;
    }
    
    constructor (address _owner) {
        owner = _owner;
    }

    function setOwner(address _owner) internal {
        require(owner == address(0), Errors.Forbidden(_owner));
        owner = _owner;
    }

    function changeOwner(address newOwner, uint8 oldOwnerNewRole) external onlyOwner {
        require(newOwner != owner, "Aborted");
        address oldAdmin = owner;
        owner = newOwner;
        _usersRoles[owner] = Roles.SUPER_ADMIN;
        _usersRoles[oldAdmin] = oldOwnerNewRole;
    }

    function addUser(address user, uint16 role) external onlyOwner {
        _usersRoles[user] = role;
    }

    function deleteUser(address user) external onlyOwner {
        bool doesExist = Helpers.getNthBit(_usersRoles[user], Roles.EXISTENCE_BIT_INDEX);
        require(doesExist, Errors.AlreadyDeleted(user));
        _usersRoles[user] = _usersRoles[user] | (uint16(1) << Roles.DELETION_BIT_INDEX);
    }

    function userExists(address user) public view returns (bool) {
        return !Helpers.getNthBit(_usersRoles[user], Roles.DELETION_BIT_INDEX);
    }

    function userHasPermission(address user, uint16 permissionBit) public view returns (bool) {        
        uint16 deletionBit = (_usersRoles[user] & (uint16(1) << Roles.DELETION_BIT_INDEX));
        if(deletionBit == 0) {
            return (_usersRoles[user] & (uint16(1) << permissionBit)) != 0;
        }
        return false;
    }

    function userGetRole(address _user) public view returns (uint16) {
        return _usersRoles[_user];
    }


}
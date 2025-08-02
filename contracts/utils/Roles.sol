// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { Types } from "./Types.sol";
/// @title Roles manages bit-level permission
/// @author Mostafa Talebi most.talebi@gmail.com
/// This library has a preset list of roles
/// which are storage and gas efficient. Each role
/// is a uint16 binary. Each bit in this number
/// represent a specific permission. They can be
/// get combined (except some specific bits for deletion
/// and types). The constant are self explanatory. 
library Roles {
    // the roles uses uint16 for storing permission bits
    uint8 public constant ROLES_BIT_SIZE                 = 16; 

    // to do a lookup in the users, simply
    // check, for a given address, if this bit
    // is 1 or not. If 1, then the user exists in the system
    uint8 public constant EXISTENCE_BIT_INDEX          = 0;
    // then the user is deleted from system
    // to undo this, set this to 0 and the last bit 1
    uint8 public constant DELETION_BIT_INDEX             = 1;    
    uint8 public constant BORROWERSM_BIT_INDEX           = 2;
    // flag for lenders manager role
    uint8 public constant LENDERSM_BIT_INDEX             = 3;
    // flag for asset manager role
    uint8 public constant ASSETM_BIT_INDEX               = 4;
    // flag for user manager role
    uint8 public constant USERM_BIT_INDEX                = 5;
    // flag for the protocol manager role
    uint8 public constant PROTOCOLM_BIT_INDEX            = 6;   
    
    uint8 public constant LENDER_BIT_INDEX               = ROLES_BIT_SIZE-1;
    uint8 public constant BORROWER_BIT_INDEX             = ROLES_BIT_SIZE-2;

    // guide for each bit is as follows:
    // from left to right: 
    // all bits 1 together means super admin
    // [user][asset][lenders][borrowers][rest unused sofar][two last and rightmost bits are for active/inactive]
    // each role entry contains its binary in a comment following it
    // to see bit level permission, simply look into the comment
    // You can make more roles by combining these permission bits.
    // bits are 1s. The last bit of each bitset is dedicated to 
    // existence_bit; which indicates if the current entity exists or not (useful for deleting,
    // blacklisting, checking if a user exists at all or not [workaround for Solidity's default zeros] etc.)
    //                     [ROLE]                       [HEX]     [BINARY]
    uint16 public constant SUPER_ADMIN               =  0xFFFD; // 1111111111111101
    uint16 public constant DELETION_BIT              =  0x0002; // 0000000000000010
    uint16 public constant BORROWERS_MANAGER         =  0x0005; // 0000000000000101
    uint16 public constant LENDERS_MANAGER           =  0x0009; // 0000000000001001
    uint16 public constant ASSET_MANAGER             =  0x0011; // 0000000000010001
    uint16 public constant USER_MANAGER              =  0x0021; // 0000000000100001
    uint16 public constant PROTOCOL_MANAGER          =  0x0041; // 0000000001000001                                                          
    uint16 public constant MINTER                    =  0x0081; // 0000000010000001                                                          


    // role types are useful for combining it for
    // other bits such as "EXISTENCE_BIT_INDEX" to 
    // enable blacklisting/whitelisting lenders/borrowers
    // 1111000000000000 Four first bits from left are considered
    // to be used for type assertions
    uint16 public constant USER_LENDER               =  0x8001;  // 1000000000000001;
    uint16 public constant USER_BORROWER             =  0x4001;  // 0100000000000001;


    function combine(uint16 a, uint16 b)  internal pure returns (uint16) {
        return a & b;
    }

    function hasPermission(uint16 roleBits, uint16 permission) internal pure returns (bool) {
        require(permission < ROLES_BIT_SIZE, "out of range permission bit!");
        return (roleBits & (1 << permission)) != 0;
    }   

    // it sets EXISTENCE_BIT_INDEX of the role to 1
    // Which means enabling the user
    function enableRole(uint16 role) internal pure returns (uint16) {
        return role | (uint16(1) << Roles.EXISTENCE_BIT_INDEX);
    }

    function toggleExistence(uint16 role) internal pure returns (uint16) {
        return role ^ (uint16(1) << Roles.EXISTENCE_BIT_INDEX);
    }

    function isUserBlacklisted(uint16 currentRole) internal pure returns (bool) {
        return (currentRole & (1 << EXISTENCE_BIT_INDEX)) != 0;
    }
}
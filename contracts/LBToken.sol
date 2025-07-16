// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { LoanManager } from "./abstracts/LoanManager.sol";
import { UserManager } from "./abstracts/UserManager.sol";
import { ILBToken } from "./interfaces/ILBToken.sol";
import { Constants } from "./utils/Constants.sol";
import { Types } from "./utils/Types.sol";
import { Errors } from "./utils/Errors.sol";
import { RayMath } from "./utils/RayMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract LBToken is ILBToken, ERC20, LoanManager, UserManager {
    address owner;

    // @todo add roles:
    // we need to add roles for minting and burning
    // in LBToken contract
    // for the time being, we use simple onlyOwner modifier
    // which clearly is not adequate. 


    constructor(uint256 _totalSupply, string memory _name, string memory _symbol) ERC20(_name, _symbol)
        UserManager(msg.sender) {
        owner = msg.sender;
        if(_totalSupply > 0){
            _mint(msg.sender, _totalSupply);
        }
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    
}
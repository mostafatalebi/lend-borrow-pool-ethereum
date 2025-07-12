// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { LoanManager } from "./abstracts/LoanManager.sol";
import { Constants } from "./utils/Constants.sol";
import { Types } from "./utils/Types.sol";
import { Errors } from "./utils/Errors.sol";
import { RayMath } from "./utils/RayMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract LBToken is ERC20, LoanManager {
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner, "FORBIDDEN");
        _;
    }

    constructor() ERC20("LBToken", "LBTV1") {
        owner = msg.sender;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    
}
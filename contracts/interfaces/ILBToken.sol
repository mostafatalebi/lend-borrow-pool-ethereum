pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
interface ILBToken {
    function mint(address to, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}
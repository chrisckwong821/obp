pragma solidity ^0.8.0;

interface IBettingRouter {
    function placeBet(address operator, uint256 item, uint256 amount, address bettor) external;
}
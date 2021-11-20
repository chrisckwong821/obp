pragma solidity ^0.8.0;

interface ICourt {
    function sue(address operator, address referee) external;
    function vote(address operator, uint256 amount, bool isCorrupt) external;
    function rule(address operator) external;
    function confiscate(address operator, address referee) external;
    function stake(uint256 _amount) external;
    function unstake(uint256 _amount) external;


}
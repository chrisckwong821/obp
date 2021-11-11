// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OBPToken is ERC20 {
    uint public INITIAL_SUPPLY = 12000;
    constructor() ERC20("online betting protocol", "OBP") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}
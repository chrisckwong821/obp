// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IBettingRouter.sol";
import "./BettingOperator.sol";

/// @title A router is used so that a bettoken can be approved once and then used to bet on any Operators afterwards.
contract BettingRouter is IBettingRouter {
    address public immutable deployer;
    address public immutable OBPToken;
    constructor(address _deployer, address _OBPToken) public {
        deployer = _deployer;
        OBPToken = _OBPToken;
    }

    function placeBet(address operator, uint256 item, uint256 amount, address bettor) external override {
        address sender = msg.sender;
        bool success = IERC20(OBPToken).transferFrom(sender, operator, amount);
        require(success , 'participate: TRANSFER_FAILED');
        BettingOperator(operator).placeBet(item, amount, bettor, true);
    }
}
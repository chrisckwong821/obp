// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



//This is a modification from sushibar implementation, with an added mapping for storing valid Referees and their current staking totals
interface IOBPMain {
    function allReferees(uint256) external returns(address);
}
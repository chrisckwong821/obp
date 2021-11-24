// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/IRefereeDeployer.sol';
import './Referee.sol';

/// @title RefereeDeployer is called from OBPMain to deploy a referee
/// @notice RefereeDeployer should NOT be called directly as referee deployed is not recognized by OBPMain
contract RefereeDeployer is IRefereeDeployer {
    address public arbitrationTimeSetter;
    uint256 arbitrationTime = 1 seconds;

    event RefereesCreated(address operator);


    function refereeCodeHash() public pure returns (bytes memory) {
        return type(Referee).creationCode;
    }

    function refereeByteCode(uint256 _arbitrationTime, address court, address owner, address OBPToken) public pure returns (bytes memory) {
         return abi.encodePacked(refereeCodeHash(), abi.encode(_arbitrationTime, court, owner, OBPToken));
     }

     function refereeSalt(uint256 _arbitrationTime, address court, address owner, address OBPToken) private returns (bytes32){
         return keccak256(abi.encodePacked(_arbitrationTime, court, owner, OBPToken, block.number));
     }

    function getcreatedAddress(address court, address owner, address OBPToken) public returns(address referee) {
        bytes memory bytecode  = refereeByteCode(arbitrationTime, court, owner, OBPToken);
        bytes32 salt = refereeSalt(arbitrationTime, court, owner, OBPToken);
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))
        );
        return address(uint160(uint(hash)));
    }

    /// @dev a 0x0 would be returned in case create2 fails due to insuffiicent gas
    function createReferee(address court, address owner, address OBPToken) external override returns(address referee){
        bytes memory bytecode = refereeByteCode(arbitrationTime, court, owner, OBPToken);
        bytes32 salt = refereeSalt(arbitrationTime, court, owner, OBPToken);
        assembly {
            referee := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        
        emit RefereesCreated(referee);
    }

    function setArbitrationWindow(uint256 _arbitrationTime) external override {
        require(msg.sender == arbitrationTimeSetter, 'setArbitrationWindow: FORBIDDEN');
        arbitrationTime = _arbitrationTime;
    }


}
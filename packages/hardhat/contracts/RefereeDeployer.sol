// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/IRefereeDeployer.sol';
import './Referee.sol';

contract RefereeDeployer is IRefereeDeployer {
    address public arbitrationTimeSetter;
    uint256 arbitrationTime = 1 seconds;
    //address[] public allReferees;

    event RefereesCreated(address operator);


    function refereeCodeHash() public pure returns (bytes memory) {
        return type(Referee).creationCode;
    }

    function refereeByteCode(uint256 _arbitrationTime, address court, address owner, address OBPToken) public pure returns (bytes memory) {
         //return keccak256(abi.encodePacked(_arbitrationTime, court, owner, OBPToken));
         return abi.encodePacked(refereeCodeHash(), abi.encode(_arbitrationTime, court, owner, OBPToken));
     }

     function refereeSalt(uint256 _arbitrationTime, address court, address owner, address OBPToken) public pure returns (bytes32){
         return keccak256(abi.encodePacked(_arbitrationTime, court, owner, OBPToken));
     }

    function getcreatedAddress(address court, address owner, address OBPToken) public view returns(address referee) {
        bytes memory bytecode  = refereeByteCode(arbitrationTime, court, owner, OBPToken);
        bytes32 salt = refereeSalt(arbitrationTime, court, owner, OBPToken);
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))
        );
        return address(uint160(uint(hash)));
    }

    function createReferee(address court, address owner, address OBPToken) external override returns(address referee){
        bytes memory bytecode = refereeByteCode(arbitrationTime, court, owner, OBPToken);
        bytes32 salt = refereeSalt(arbitrationTime, court, owner, OBPToken);
        assembly {
            referee := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        //allReferees.push(referee);
        emit RefereesCreated(referee);
    }

    function setArbitrationWindow(uint256 _arbitrationTime) external override {
        require(msg.sender == arbitrationTimeSetter, 'setArbitrationWindow: FORBIDDEN');
        arbitrationTime = _arbitrationTime;
    }


}
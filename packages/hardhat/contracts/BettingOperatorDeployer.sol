// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/IBettingOperatorDeployer.sol';
import './BettingOperator.sol';

/// @title BettingOperatorDeployer is called from OBPMain to deploy a referee
/// @notice BettingOperatorDeployer should NOT be called directly as operator deployed is not recognized by OBPMain
contract BettingOperatorDeployer is IBettingOperatorDeployer {
    uint256 public feeToOperator = 10000; //1% TO OPERATOR
    uint256 public feeToReferee = 30000; // 3% to REFEREE
    uint256 public feeToCourt = 10000;

    address public feeSetter;
    

    event OperatorCreated(address operator, uint256 roothash);
    function bettingOperatorCodeHash() public pure returns (bytes memory) {
        return type(BettingOperator).creationCode;
    }


    function bettingOperatorSalt(address OBPMain, address OBPToken, address owner, uint256 roothash, address court, uint256 _feeToOperator,uint256 _feeToReferee, uint256 _feeToCourt) private returns (bytes32) {
        return keccak256(abi.encodePacked(OBPMain, OBPToken, owner, roothash, court, _feeToOperator, _feeToReferee, _feeToCourt, block.number));
    }

    function bettingOperatorByteCode(address OBPMain, address OBPToken, address owner, uint256 roothash, address court, uint256 _feeToOperator,uint256 _feeToReferee, uint256 _feeToCourt) public pure returns (bytes memory) {
        return abi.encodePacked(bettingOperatorCodeHash(), abi.encode(OBPMain, OBPToken, owner, roothash, court, _feeToOperator, _feeToReferee, _feeToCourt));
    }

    function getcreatedAddress(address OBPMain, address OBPToken, address owner, uint256 roothash, address court) public returns(address operator) {
        bytes memory bytecode  = bettingOperatorByteCode(OBPMain, OBPToken, owner, roothash, court, feeToOperator, feeToReferee, feeToCourt);
        bytes32 salt = bettingOperatorSalt(OBPMain, OBPToken, owner, roothash, court, feeToOperator, feeToReferee, feeToCourt);
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))
        );
        return address(uint160(uint(hash)));
    }

    /// @dev a 0x0 would be returned in case create2 fails due to insuffiicent gas
    function createBettingOperator(address OBPMain, address OBPToken, address owner, uint256 roothash, address court) external override returns(address operator){

        bytes memory bytecode = bettingOperatorByteCode(OBPMain, OBPToken, owner, roothash, court, feeToOperator, feeToReferee, feeToCourt);
        bytes32 salt = bettingOperatorSalt(OBPMain, OBPToken, owner, roothash, court, feeToOperator, feeToReferee, feeToCourt);
        assembly {
            operator := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
             if iszero(extcodesize(operator)) {
                 revert(0, 0)
             }
        }
        
        emit OperatorCreated(operator, roothash);
    }

    function setOperatorFee(uint256 _feeToOperator) external override {
        require(msg.sender == feeSetter, 'setOperatorFee: FORBIDDEN');
        feeToOperator = _feeToOperator;
    }

    function setRefereeFee(uint256 _feeToReferee) external override {
        require(msg.sender == feeSetter, 'setRefereeFee: FORBIDDEN');
        feeToReferee = _feeToReferee;
    }


}



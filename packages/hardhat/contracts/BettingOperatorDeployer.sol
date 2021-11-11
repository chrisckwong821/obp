pragma solidity ^0.8.0;

import './interfaces/IBettingOperatorDeployer.sol';
import './BettingOperator.sol';
contract BettingOperatorDeployer is IBettingOperatorDeployer {
    uint256 public feeToOperator = 10000; //1% TO OPERATOR
    uint256 public feeToReferee = 30000; // 4% to REFEREE
    uint256 public feeToCourt = 10000;

    address public feeSetter;

    address[] public allOperators;

    event OperatorCreated(address operator, uint);

    function allOperatorsLength() public view returns (uint) {
        return allOperators.length;
    }

    function bettingOperatorCodeHash() public pure returns (bytes memory) {
        return type(BettingOperator).creationCode;
    }


    function bettingOperatorSalt(address OBPToken, address owner, uint256 roothash, address court, uint256 _feeToOperator,uint256 _feeToReferee, uint256 _feeToCourt) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(OBPToken, owner, roothash, court, _feeToOperator, _feeToReferee, _feeToCourt));
    }

    function bettingOperatorByteCode(address OBPToken, address owner, uint256 roothash, address court, uint256 _feeToOperator,uint256 _feeToReferee, uint256 _feeToCourt) public pure returns (bytes memory) {
        return abi.encodePacked(bettingOperatorCodeHash(), abi.encode(OBPToken, owner, roothash, court, _feeToOperator, _feeToReferee, _feeToCourt));
    }
    
    function createBettingOperator(address OBPToken, address owner, uint256 roothash, address court) external override returns(address operator){
        bytes memory bytecode = bettingOperatorByteCode(OBPToken, owner, roothash, court, feeToOperator, feeToReferee, feeToCourt);
        bytes32 salt = bettingOperatorSalt(OBPToken, owner, roothash, court, feeToOperator, feeToReferee, feeToCourt);
        assembly {
            operator := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            // if iszero(extcodesize(operator)) {
            //     revert(0, 0)
            // }
        }
        allOperators.push(operator);
        emit OperatorCreated(operator, allOperators.length);
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



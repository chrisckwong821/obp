pragma solidity ^0.8.0;

interface IBettingOperatorDeployer {

    function createBettingOperator(address OBPMain, address OBPToken, address owner, uint256 roothash, address court) external returns(address);
    function setOperatorFee(uint256 _feeToOperator) external;
    function setRefereeFee(uint256 _feeToRefereeFee) external;
}
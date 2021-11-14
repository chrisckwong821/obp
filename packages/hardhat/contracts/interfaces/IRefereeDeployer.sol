pragma solidity ^0.8.0;

interface IRefereeDeployer {

    function createReferee(address owner, address court, address OBPToken) external returns(address);
    function setArbitrationWindow(uint256 _arbitrationTime) external;

}
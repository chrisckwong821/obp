pragma solidity ^0.8.0;

interface IBettingOperator {


    function withdraw(uint item, address _to)  external ;
    function verify(uint256 _refereeValueAtStake, uint256 _maxBet, uint256 refereeIds) external;
    function placeBet(uint item, uint amount, address bettor) external;
    function withdrawOperatorFee(uint256 _amount, address _to)  external;
    function injectResultBatch(bytes calldata) external;
    function injectResult(uint256) external;
    function closeItem(uint256 item) external;
    // the more gas-efficient way; 
    function closeItemBatch(bytes calldata) external;
    function setTotalUnclaimedPayoutAfterConfiscation() external;
    function withdrawFromFailedReferee(uint256 item, address _to) external;
    
    
}
pragma solidity ^0.8.0;

interface IReferee {
    function participate(uint256 _amount) external;
    function withdraw(address _to, uint256 _amount) external;

    //onlyOwner
    function anounceResult(address bettingOperator, bytes calldata data) external;
    function pushResult(address bettingOperator, uint256 item_index) external;
    function pushResultBatch(address bettingOperator) external;
    function closeItem(address operator, uint256 item) external;
    function closeItemBatch(address operator) external;
    function revokeResult(address BettingOperator, uint256 item_index) external;
    function verify(address bettingOperator, uint256 _refereeValueAtStake, uint256 maxBet) external;
    //onlyCourt
    function confiscate(address operator) external;
}
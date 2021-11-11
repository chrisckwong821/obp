pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./BettingOperator.sol";


contract Referee {
    // (contributers => amount)
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    constructor(uint256 _arbitrationTime, address _court, address _owner, address _OBPToken) {
        court = _court;
        arbitrationTime = _arbitrationTime;
        owner = _owner;
        OBPToken = _OBPToken;
    }

    // a Result is encoded in uint256 to save storage
    // struct result {
    //     uint112 item;
    //     uint112 payout;
    //     uint32 lastupdatedtime;
    // }
    
    address OBPToken;
    uint256 arbitrationTime;
    //owner decides which operator to safeguard etc, call pushResult etc.
    address owner;
    address court;
    mapping(address => uint) public stakers;

    uint256 public totalStaked;
    uint256 public freezedUnderReferee;
    // operator => amountOBP_instake for safeguarding
    mapping(address => uint) public operatorUnderReferee;
    // bettingOperator => item + payOutResult + payoutLastUpdatedTime
    mapping(address => bytes) public results;


    modifier onlyCourt() {
        require(msg.sender == court);
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function _getCurrentFreezeRatio() internal view returns(uint256 currentFreezeRatio) {
        currentFreezeRatio = (freezedUnderReferee * 1000 / totalStaked);
    }
    
    function encodeResult(uint112 _item, uint112 _payout, uint32 _lastupdatedTime) public pure returns(bytes memory) {
        return abi.encodePacked(_item, _payout, _lastupdatedTime);
    }

    function decodeResult(uint256 _encodedResult) public pure returns(uint112 item, uint112 payout, uint32 lastupdatedtime){
        item = uint112(_encodedResult);
        payout = uint112(_encodedResult >> 112);
        lastupdatedtime = uint32(_encodedResult >> 224);
    }
    function participate(uint256 _amount) external {
        (bool success, bytes memory data) = OBPToken.call(abi.encodeWithSelector(SELECTOR, address(this), _amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'participate: TRANSFER_FAILED');
        stakers[msg.sender] = _amount;
        totalStaked += _amount;
    }
    function withdraw(address _to, uint256 _amount) external {
        require(stakers[msg.sender] > 0, "withdraw:: YOU HAVE NO STAKE"); 
        require(totalStaked - freezedUnderReferee > _amount, "withdraw::AVAILABLE STAKE FOR WITHDRAW NOT ENOUGH");
        uint256 withdrawAmount;

    // if freezed ratio > 90%, withdraw takes a 1% fee.
        if (_getCurrentFreezeRatio() > 900) {
            withdrawAmount = _amount * 99 / 100;
        } else {
            withdrawAmount = _amount;
        }
        //remove the bet before transferring
        stakers[msg.sender] -= _amount;
        totalStaked -= _amount;
        (bool result) = IERC20(OBPToken).transfer(_to, withdrawAmount);
        require(result, "withdraw: TRANSFER_FAILED");
    }

    function anounceResult(address bettingOperator, bytes calldata data) external onlyOwner {
        results[bettingOperator] = abi.encodePacked(results[bettingOperator], data);
    }

    // select an index in the result mapping and push to the operator
    function pushResult(address bettingOperator, uint256 item_index) external onlyOwner {
        bytes memory data;
        uint256 item;
        bytes32 result = results[bettingOperator][item_index];
        assembly {
                item := mload(add(result,32))
                }
        (, , uint32 parsedPayoutLastUpdatedTime) = decodeResult(item);
                // only push result that passes the arbitration window
        if (block.timestamp > arbitrationTime + parsedPayoutLastUpdatedTime) {
        BettingOperator(bettingOperator).injectResultBatch(data);
    }
}
    // push the entire result mapping to the operator    
    function pushResultBatch(address bettingOperator) external onlyOwner {
        bytes memory data;
        uint256 item;
        bytes memory result = results[bettingOperator];
        for (uint256 i =32; i < result.length; i+32) {
            assembly {
                item := mload(add(result,i))
                }
        (uint112 parsedItem, uint112 parsedPayout, uint32 parsedPayoutLastUpdatedTime) = decodeResult(item);
                // only push result that passes the arbitration window
            if (block.timestamp > arbitrationTime + parsedPayoutLastUpdatedTime) {
                data = abi.encodePacked(encodeResult(parsedItem, parsedPayout, parsedPayoutLastUpdatedTime), data);
            }
        }
        // push result
        BettingOperator(bettingOperator).injectResultBatch(data);
    }

    function revokeResult(address _BettingOperator, uint256 item_index) external onlyOwner {
        //wipe out the whole entry, then you can push again, the original result in operator would be overrided as the result is read in a list.
        //eg result in operator{item, payout, lastupdatedtime} [1,1000, xxxx], [1,0, xxxx] => pool for Item1 would end up with 0.
        results[_BettingOperator][item_index] = 0;
    }
    function verify(address bettingOperator, uint256 _refereeValueAtStake, uint256 maxBet) external onlyOwner {
        freezedUnderReferee += _refereeValueAtStake;
        require(freezedUnderReferee <= totalStaked);
        BettingOperator(bettingOperator).verify(_refereeValueAtStake, maxBet);
        operatorUnderReferee[bettingOperator] = _refereeValueAtStake;
    }

    // this function exposes the referee to confiscation from the court.
    // OBP staked for that operator would be confiscated and transferred to the operator.
    function confiscate(address operator) external onlyCourt {
        uint256 amount = operatorUnderReferee[operator];
        totalStaked -= amount;
        freezedUnderReferee -= amount;
        IERC20(OBPToken).transfer(operator, amount);
    }



}
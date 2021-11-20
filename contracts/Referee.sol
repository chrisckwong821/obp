pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./BettingOperator.sol";


contract Referee {
    // (contributers => amount)
    //bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transferfrom(address,address,uint256)')));
    constructor(uint256 _arbitrationTime, address _court, address _owner, address _OBPToken) {
        court = _court;
        arbitrationTime = _arbitrationTime;
        owner = _owner;
        OBPToken = _OBPToken;
    }

    // a Result is encoded in an uint256 to save storage
    // {
    //     uint112 item;
    //     uint112 payout;
    //     uint32 lastupdatedtime;
    // }
    // bettingOperator => item + payOutResult + payoutLastUpdatedTime
    mapping(address => bytes) public results;
    
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
        item = uint112(_encodedResult >> 144);
        payout = uint112(_encodedResult >> 32);
        lastupdatedtime = uint32(_encodedResult);
    }
    function participate(uint256 _amount) external {
        address sender = msg.sender;
        bool success = IERC20(OBPToken).transferFrom(sender, address(this), _amount);
        require(success , 'participate: TRANSFER_FAILED');
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
        uint256 item;
        bytes memory result = results[bettingOperator];
        uint256 indexBytes = 32*item_index;
        assembly {
                item := mload(add(result, indexBytes))
                }
        (, , uint32 parsedPayoutLastUpdatedTime) = decodeResult(item);
                // only push result that passes the arbitration window
        if (block.timestamp > arbitrationTime + parsedPayoutLastUpdatedTime) {
            BettingOperator(bettingOperator).injectResult(item);
    }
}
    // push the entire result mapping to the operator    
    function pushResultBatch(address bettingOperator) external onlyOwner {//(bytes memory data){
        
        uint256 item;
        bytes memory result = results[bettingOperator];
        //return result.length;
         bytes memory data;
         for (uint256 i = 0; i < result.length; i+=32) {
             assembly {
                 item := mload(add(result, add(32, i)))
                 }
         (uint112 parsedItem, uint112 parsedPayout, uint32 parsedPayoutLastUpdatedTime) = decodeResult(item);
        //         // only push result that passes the arbitration window
            if (block.timestamp > arbitrationTime + parsedPayoutLastUpdatedTime) {
                data = abi.encodePacked(data, item);
            }
            require(parsedItem > 0, "DEBUG: parseItem shd > 0");
         }
        // push result
        
        BettingOperator(bettingOperator).injectResultBatch(data);
    }

    function revokeResult(address bettingOperator, uint256 item) external onlyOwner {
        //wipe out the whole entry, then you can push again, the original result in operator would be overrided as the result is read in a list.
        //for example result in operator {item, payout, lastupdatedtime} = [1,1000, xxxx], [1,0, xxxx] => pool for Item1 would end up with 0.
        results[bettingOperator][item] = 0;
    }

   function closeItem(address bettingOperator, uint256 item) external onlyOwner {
        BettingOperator(bettingOperator).closeItem(item);
   }
    function closeItemBatch(address bettingOperator) external onlyOwner {
        bytes memory result = results[bettingOperator];
        // push result
        BettingOperator(bettingOperator).closeItemBatch(result);
    }
    function verify(address bettingOperator, uint256 _refereeValueAtStake, uint256 maxBet, uint256 refereeIds) external onlyOwner {
        freezedUnderReferee += _refereeValueAtStake;
        require(freezedUnderReferee <= totalStaked);
        BettingOperator(bettingOperator).verify(_refereeValueAtStake, maxBet, refereeIds);
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
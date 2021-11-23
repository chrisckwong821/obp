// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./abstracts/CourtUpgradeable.sol";
import "./interfaces/IReferee.sol";
import "./interfaces/IBettingOperator.sol";

/// @title V1 Court logic with basic voting and staking logic
contract CourtV1 is CourtUpgradeable {

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

	address public OBPToken;
    //before votingWindow
    uint256 votingWindow = 3 days;
    //address of stakers => amount_staked
    mapping(address=>uint256) stakings;
    uint256 totalStaked;

    // lock the unstake function until expiry;
    //stakers => amount_locked
    mapping(address => uint256) _votingLock;

    struct Ruling {
        address operator;
        address referee;
        uint256 expiry;
        bool isClosed;
        bool isRefereeCorrupt;
        uint256 isCorruptVoteCount;
        uint256 isNotCorruptVoteCount;
        mapping(address => uint256) votes;
        
    }
    /// @dev oeprator => case
    mapping(address => Ruling) public  rulings;

    event Staked(uint amount, address staker);
    event Unstaked(uint amount, address unstaker);
    event Sued(address operator, address referee);
    event Ruled(address operator, bool isRefereeCorrupt);

    /// @notice operator may collude with referee; so anyone can initiate a sue. A successful sue would only split the referee's stake to those who place a bet on that operator.
    function sue(address operator, address referee) external {       
        // bettor is recommended to bet on operator that is safeguarded by an amount of OBP that exceeds the total bet size
        Ruling storage Rule = rulings[operator];
        Rule.referee = referee;
        Rule.expiry =block.timestamp + votingWindow;
        Rule.isClosed =  false;
        Rule.isRefereeCorrupt = false;
        Rule.isCorruptVoteCount = 0;
        Rule.isNotCorruptVoteCount = 0;

        emit Sued(operator, referee);
    }

    /// @notice allow a custom vote within your staking, allow repeated voting, would add on to your previous votes; technically you can also vote for both sides, which makes yr vote meaningless.
    function vote(address operator, uint256 amount, bool isCorrupt) external {
        require(stakings[_msgSender()] >= amount, "vote:: STAKED AMOUNT IS INSUFFICIENRT");
        require(rulings[operator].expiry < block.timestamp, "vote:: CASE IS ALREADY CLOSED");
        require(rulings[operator].votes[_msgSender()] < (stakings[_msgSender()] - amount), "vote:: INSUFFICIENT VOTING POWER LEFT FOR THIS CASE");
        _votingLock[_msgSender()] = rulings[operator].expiry;

        rulings[operator].votes[_msgSender()] += amount;
        if (isCorrupt) {
            rulings[operator].isCorruptVoteCount += amount;
        } else {
            rulings[operator].isNotCorruptVoteCount += amount;
        }

    }

    function viewRuling(address operator) public view returns(uint256 isCorruptVoteCount, uint256 isNotCorruptVoteCount, address _operator, address referee, uint256 expiry, bool isClosed, bool isRefereeCorrupt) {
        isCorruptVoteCount = rulings[operator].isCorruptVoteCount;
        isNotCorruptVoteCount = rulings[operator].isNotCorruptVoteCount;
        _operator = rulings[operator].operator;
        referee = rulings[operator].referee;
        expiry = rulings[operator].expiry;
        isClosed = rulings[operator].isClosed;
        isRefereeCorrupt = rulings[operator].isRefereeCorrupt;
    }
    function viewRulingVoter(address operator, address voter) public view returns(uint256) {
        return rulings[operator].votes[voter];
    }

    function rule(address operator) external {
        require(rulings[operator].expiry > block.timestamp, "vote:: CASE IS  STILL OPEN");
        rulings[operator].isClosed = true;
        // if vote counts tie, then referee is not corrupt
        if (rulings[operator].isCorruptVoteCount > rulings[operator].isNotCorruptVoteCount) {
            rulings[operator].isRefereeCorrupt = true;
        } else {
            rulings[operator].isRefereeCorrupt = false;
        }
        emit Ruled(operator, rulings[operator].isRefereeCorrupt);
    }
    function confiscate(address operator, address referee) external {
        require((rulings[operator].isRefereeCorrupt && rulings[operator].isClosed) ,"confiscate:: RULING NOT VALID FOR CONFISCATION");
        IReferee(referee).confiscate(operator);
        IBettingOperator(operator).setTotalUnclaimedPayoutAfterConfiscation();
    }

    function stake(uint256 _amount)  external {
        (bool success, bytes memory data) = OBPToken.call(abi.encodeWithSelector(SELECTOR, address(this), _amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'participate: TRANSFER_FAILED');
        stakings[_msgSender()] = _amount;
        totalStaked += _amount;
         emit Staked(_amount, _msgSender());

    }
    function unstake(uint256 _amount) external {
        require(stakings[_msgSender()] > 0, "withdraw:: YOU HAVE NO STAKE"); 
        //remove the stake record before transferring
        stakings[_msgSender()] -= _amount;
        totalStaked -= _amount;
        (bool result) = IERC20(OBPToken).transfer(_msgSender(), _amount);
        require(result, "withdraw: TRANSFER_FAILED");
    }
}
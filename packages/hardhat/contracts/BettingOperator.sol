pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BettingOperator {
    
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    // This is a hash of the json of all the bettingItems
    // Once deployed, the betters and referees depend on this hash to verify their source of truth
    // use EIP 712 for typed structured data
    uint256 public roothashOfbettingItems;
    address public OBPToken;
    //operator
    address public owner;
    address public court;
    //defined an invited referee
    address public referee;
    uint256 public refereeValueAtStake; // OBP token locked for this Operator

    //defined and injected by the deployer
    uint256 public feeToOperator;
    uint256 public feeToReferee;
    uint256 public feeToCourt;

    uint256 public unclaimedFeeToOperator;
    uint256 public unclaimedFeeToReferee;
    uint256 public unclaimedFeeToCourt;
    //accepted token
    address public betToken;

    bool public canWithdraw = false;
    //verify by an Referee
    bool public verified = false;
    mapping (uint256 => Pool) bettingItems;

    struct Pool{
        uint256 Id;
        //current total bet
        uint256 poolSize;
        //bettor => amount 
        mapping(address => uint256) bettors;
        // exp : PoolSize: (Pool1 : 1000), (Pool2: 1000)
        // then the poolPayout can look like (Pool1: 2000, Pool2: 0), (Pool1: 1500, Pool2: 500) etc
        uint256 payout;
        bool isClosed;
    }    
    // there would be a checking when Referee InjectResult so that the total payout cannot be bigger than the total bet 
    uint256 public totalReleasedPayout;
    // money that is claimed by bettor
    uint256 public totalClaimedPayout;
    uint256 public totalOperatorBet;
    uint256 public maxBetLimit;

    //snapshot upon confiscation
    uint256 public totalUnclaimedPayoutAfterConfiscation;
    

    constructor (address _OBPToken, address _owner, uint256 _roothashOfbettingItems, address _court, uint256 _feeToOperator, uint256 _feeToReferee, uint256 _feeToCourt) {
        OBPToken = _OBPToken;
        owner = _owner;
        roothashOfbettingItems = _roothashOfbettingItems;
        court = _court;
        feeToOperator = _feeToOperator;
        feeToReferee = _feeToReferee;
        feeToCourt = _feeToCourt;
    }

    function decodeResult(uint256 _encodedResult) public pure returns(uint112 item, uint112 payout, uint32 lastupdatedtime){
        item = uint112(_encodedResult);
        payout = uint112(_encodedResult >> 112);
        lastupdatedtime = uint32(_encodedResult >> 224);
    }

    modifier onlyReferee() {
        require(msg.sender == referee);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyCourt() {
        require(msg.sender == court);
        _;
    }

    function withdrawOperatorFee(uint256 _amount, address _to)  external onlyOwner {
        require(unclaimedFeeToOperator > 0, "withdrawOperatorFee:: THAT IS NO UNCLAIMED AMOUTN");
        unclaimedFeeToOperator -= _amount;
        (bool result) = IERC20(betToken).transfer(_to, _amount);
        require(result, "withdrawOperatorFee: TRANSFER_FAILED");
        // when operator withdraws fee, they are also responsible for settling the fee to the referee as well as the court.
        withdrawRefereeFee(unclaimedFeeToReferee);
        withdrawCourtFee(unclaimedFeeToCourt);

    }

    function withdrawRefereeFee(uint256 _amount) public {
        require(unclaimedFeeToReferee > 0, "withdrawRefereeFee:: THAT IS NO UNCLAIMED AMOUTN");
        unclaimedFeeToReferee -= _amount;
        (bool result) = IERC20(betToken).transfer(referee, _amount);
        require(result, "withdrawRefereeFee: TRANSFER_FAILED");
    }

    function withdrawCourtFee(uint256 _amount) public {
        require(unclaimedFeeToCourt > 0, "withdrawCourtFee:: THAT IS NO UNCLAIMED AMOUTN");
        unclaimedFeeToCourt -= _amount;
        (bool result) = IERC20(betToken).transfer(court, _amount);      
        require(result, "withdrawCourtFee: TRANSFER_FAILED");
    }


    function checkPoolPayout(uint256 _item) public view returns(uint256) {
        return bettingItems[_item].payout;
    }
    
    function checkPayoutByAddress(address _address, uint256 _item) public view returns(uint256) {
        return bettingItems[_item].bettors[_address] * bettingItems[_item].payout / bettingItems[_item].poolSize;
    }


    function verify(uint256 _refereeValueAtStake, uint256 _maxBet) external onlyReferee {
        require(verified == false, "verify:: ALREADY VERIFIERD");
        verified = true;
        refereeValueAtStake = _refereeValueAtStake;
        maxBetLimit = _maxBet;
    }
    function placeBet(uint item, uint amount, address bettor) external {
        require(bettingItems[item].isClosed == false, "the betting item is already closed"); 
        require(maxBetLimit - totalOperatorBet > amount, "placeBet:: the maxBet exceeds after taking this bet");
        (bool success, bytes memory data) = betToken.call(abi.encodeWithSelector(SELECTOR, address(this), amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'placeBet: TRANSFER_FAILED');

        unclaimedFeeToOperator += (amount * feeToOperator) / 10**6;
        unclaimedFeeToReferee += (amount * feeToReferee) / 10**6;        
        unclaimedFeeToCourt += (amount * feeToCourt) / 10**6;        

        amount = amount * ( 10**6 - feeToReferee - feeToOperator - feeToCourt) / 10**6;

        bettingItems[item].bettors[bettor] = amount;
        bettingItems[item].poolSize += amount;
        totalOperatorBet += amount;
    }
    // this is a function to withdraw normally, unless there is OBP compensation, only 1 ERC20 transfer is involved.
    function withdraw(uint item, address _to)  external {
        address bettor = msg.sender;
        require(bettingItems[item].isClosed, "the betting item is still open"); 
        require(bettingItems[item].payout > 0, "withdraw:: THERE is no Payout in this item");
        uint256 amount = checkPayoutByAddress(bettor, item);
        uint256 amountOBP = getAmountFromFailedReferee(item, bettor);
        totalClaimedPayout += amount;
        //remove the bet before transferring
        bettingItems[item].bettors[msg.sender] = 0;
        (bool result) = IERC20(betToken).transfer(_to, amount);
        require(result, "withdraw: TRANSFER_FAILED");
        if (amountOBP > 0 ) {
            // this number is non-zero only when OBP is confiscated from referee.
            // if you prefer getting the OBP instead of the payout, pls call withdrawFromFailedReferee(uint256 item, address _to);
            (bool resultToCourt) = IERC20(OBPToken).transfer(court, amountOBP);
            require(resultToCourt, "withdraw: TRANSFER_FAILED"); 
        }
    }

    //can be any number of result to be pushed 
    function injectResultBatch(bytes calldata data) external onlyReferee {

        uint256 item;
        //uint256 parsedPayoutLastUpdatedTime;
        for (uint i =32; i < data.length; i+=32) {
            assembly {
                item := calldataload(i)
                }
            (uint112 parsedItem, uint112 parsedPayout,) = decodeResult(item);
            // 0 can be a empty entry pushed from Referee
            if (parsedItem != 0 && bettingItems[item].isClosed == false) {
                // allow an update of payout in case a wrong value is pushed.
                // close is not called in this function for the purpose of changing
                // when an item is closed, bettor starts to claim and there is no way to correct any mistake
                uint256 oldPayout = bettingItems[parsedItem].payout;
                bettingItems[parsedItem].payout = parsedPayout;
                totalReleasedPayout = totalReleasedPayout + parsedPayout - oldPayout;
            }
            
        }
        // assert at last but not in the loop for efficient gas
        require(totalOperatorBet >= totalReleasedPayout ,"injectResult::the released payout is bigger than the total bet");
                // close the item so winner can start claiming:
        //closeItemBatch(data);
    }
    
    function closeItem(uint256 item) external onlyReferee {
        bettingItems[item].isClosed = true;
    }

    function closeItemBatch(bytes calldata data) external onlyReferee {
        uint256 item;
        //this is for closing item only, assuming data is parsed in itemId:payout::timestamp format, skipping every 32 bits that is payout data.
        for (uint i =32; i < data.length; i+=32) {
            assembly {
                item := calldataload(i)
                }
            (uint112 parsedItem, , ) = decodeResult(item);
            bettingItems[parsedItem].isClosed = true;
        }
    }
    function setTotalUnclaimedPayoutAfterConfiscation() external onlyCourt {
        // this is to decide the portion of OBP each unclaimed bettor is eligible for.
        // people who claim their money is not eligible
        totalUnclaimedPayoutAfterConfiscation = totalOperatorBet - totalClaimedPayout;
    }

    function getAmountFromFailedReferee(uint256 item, address bettor) view public returns(uint256) {
        if(totalUnclaimedPayoutAfterConfiscation == 0 ) {return 0;}
        return refereeValueAtStake * bettingItems[item].bettors[bettor] / totalUnclaimedPayoutAfterConfiscation;

    }
    function withdrawFromFailedReferee(uint256 item, address _to) external {
        //OBP is transferred from a failed refererr to this address.
        // once OBP is transferred in, those who hasnt claimed their payout, can decide if they want to claim OBP, or their payout.

        //all bettors WHO HAVENT CLAIMED THEIR PAYOUT get their shares based on their bet.
        // YOU EITHER GET YOUR PAYOUT(NO MATTER U WIN OR LOSS), OR THE OBP compensation.

        // if you get the OBP, your payout is donated to the court.
        // if you get the payout, your OBP is forfeited, and sent back to the court.
        address bettor = msg.sender;
        uint256 _amount = getAmountFromFailedReferee(item, bettor);
        require(_amount > 0, "withdrawFromFailedReferee:: THERE IS NO OBP FOR U");
        // originalBet to be sent to court
        uint256 originalPayout = checkPayoutByAddress(bettor, item);
        //set to 0 first to prevent re-entrance
        bettingItems[item].bettors[bettor] = 0;
        // send bet to court
        if (originalPayout > 0) {
            (bool resultToCourt) = IERC20(betToken).transfer(court, originalPayout);
            require(resultToCourt, "withdraw: TRANSFER_FAILED");
        }
        //take OBP
        (bool result) = IERC20(OBPToken).transfer(_to, _amount);
        require(result, "withdraw: TRANSFER_FAILED");
        

    }




}
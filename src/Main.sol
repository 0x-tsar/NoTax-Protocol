// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
// import "forge-std/Test.sol"; // remove for production

import {WETH9} from "./interfaces/IWETH.sol";
import {IPool} from "./interfaces/IPool.sol";
import {AToken} from "../src/interfaces/IAToken.sol";
import {StakedToken} from "./StakedToken.sol";
import {CommunityBadges} from "./CommunityBadges.sol";

import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";


contract Main is ReentrancyGuard { // remove test for production
    StakedToken public stakedToken;
    CommunityBadges public communityBadges; // should this be upgradeable in order to add more badges in the future? can work as a PoH.

    enum Categories {
        UNDEFINED,
        INFRASTRUCTURE,
        HEALTH,
        ENVIRONMENT,
        ANIMAL_CAUSE,
        SOCIAL_CAUSE
    }

    // events
    event AmountStaked(uint256 indexed amount);
    event AmountUnstaked(uint256 indexed amount);
    event ReceiveFunctionCalled(address indexed sender, uint256 indexed amount);

    // errors
    error Main__ZeroValue();
    error Main__NoAmountStaked();
    error Main__NotTheOwner(address sender, address owner);
    error Main__oficialAlreadyHasCategory();
    error Main__UserMustFirstWithdrawToStakeAgain();
    error Main__TokenNotAllowedForStaking();
    error Main__NoLiquidityStakedToReap();
    error Main__MinTimelockNotFinished(uint, uint);
    error Main__ProtocolFeeHasMaxValue();

    // state variables
    struct Category {
        uint256 infrastructure;
        uint256 health;
        uint256 environment;
        uint256 animalCause;
        uint256 socialCause;
    }

    // can be considered a registry of each user.
    struct UserSnapshot {
        uint256 index;
        uint256 timeDeposit;
        uint256 timeWithdraw;
        uint256 valueDeposited;
        uint256 median;
        address token;
        address sender;
        bool isRetrievable;
        Categories category;
        // @audit-info IMPORTANT! TODO: 
        // string country/region?  this can then be passed to the sub dao so the correct amount is distributed to not only the area chosen by the user but also the region he wants to improve [his local community, for example]
        // maybe create a timesSnapshot counter to beter distribute the counter. something for later.
    }


    // TODO: stake with stables & stake to more than one category at a time
    address public INFRASTRUCTURE_DAO;
    address public HEALTH_DAO;
    address public ENVIRONMENT_DAO;
    address public ANIMAL_CAUSE_DAO;
    address public SOCIAL_CAUSE_DAO;
    

    mapping(address user => UserSnapshot[]) public userSnapshot; 
    mapping(address => uint256) public indexUserSnapshot; // user current index, starts at 0

    UserSnapshot[] public globalUserSnapshot;

    // the total amount the user staked in all categories together
    mapping(address collaborator => uint256 totalAmountStaked) public totalStaked;

    mapping(address collaborator => uint256 quantity) public totalAmountStakedEver; // this one is just for keeping track of the total ever staked, it is not perfect though because it can be tricked by just staking and removing at the same block. for now lets add it.

    // amount of staked for each category, temporary since it will be removed after unstaking.
    mapping(address => Category) public userEachCategory;
    // mapping(address => Category) public userEachCategoryTotalGenerated; // not being used yet, implement it later, only implemented at the end of the Unstake function
    mapping(address => Categories) public whichCategoryOficial; // WHITELIST which category | WHICH category is the oficial DAO for this address
    mapping(address oficial => bool isAllowed) public whitelistedOficials; //      | IF the address is allowed to receive the funds 
    mapping(address token => bool isAllowed) public allowedTokens;
    mapping(address user => Categories) public userCurrentCategory; // this is the current category the user is staking, it can only be one at a time, for now.
    mapping (address user => uint256 points) public userPoints;


    // amount of staked for each category, permanent since it will be used to display how much the contract ever yield for each Category, mostly for showing.
    // mapping(address => Category) public totalEverEachCategory;

    WETH9 public weth;
    IPool public aavePool; // next version add options for other options.
    AToken public aaveTokenLP; // lp aave token, this rebalances and adds the yielded value automatic
    // IERC20 public usdcToken = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC mainnet address, it's a proxy

    address public owner; // later make this private with a function to access this
    uint256 public protocolFee = 0; // lets first start to zero  // basis point = 0.05%. this is not being taken yet, implement when possible
    uint256 public MAX_PROTOCOL_FEE = 200; // 2% max fee, not definitive. 

    uint256 public currentTimelock = 0;
    uint256 public constant MIN_TIMELOCK = 14 days; // min waiting time
    uint256 public timelockOG = 0;
    bool public timelockFinished;

    uint256 POINTS_DENOMINATOR = 1000000000000000000000; //1e24  | maybe tweak it later, apperently it works.



    constructor() {
        // after tests use the proxy address instead of the implementation one.
        weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // ethereum weth address
        aavePool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2); // ethereum aave pool address
        aaveTokenLP = AToken(0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8); // ethereum aave contract address

        owner = msg.sender; // later this should be a multisig/dao or atleast add timelock for decentralization, for now let's stick with this

        setTokenAllowed(address(weth), true); //allowing weth [MAINNET]
        // setTokenAllowed(0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c, true); //allowing usdc [MAINNET]  this is Aave Ethereum USDC (aEthUSDC), should it be this or the OG usdc?

        // stakedToken = StakedToken(_staked_token); // staked token, 
    }

    ///////////////////////////////////////////////////////////////////////////
    //////////////////////////// MODIFIERS ////////////////////////////////////
    // this will prevent the admin from just calling `startTimelock` right away so it passes the 14 days so then whenever he really want to change the fee he would be able to immediately, this would be an attack vector. adding this piece the admin have only 1 day to change the fee after the 14 days have passed, so everything as expected.
    // this snippet gives a 1 day window for the admin change the fee after 14 days passed, after that it should not be valid anymore and `resetTimelock` should be called to start over.
    modifier timeWindowForChangingProtocolFee {
        // require(timelockFinished &&  block.timestamp - timelockOG <= 15 days, "Changing Protocol Fee windows Is closed");
        if(!timelockFinished && block.timestamp - timelockOG > 15 days) revert Main__MinTimelockNotFinished(block.timestamp - timelockOG, 15 days);
        if(protocolFee > MAX_PROTOCOL_FEE) revert Main__ProtocolFeeHasMaxValue();

        // sets currentTimelock to zero so it works again
        timelockFinished = false; // reseting the timelock
        currentTimelock = 0;
        timelockOG = 0;
        _;
    }
   
    modifier isTimelockFinished() {
        // require(timelockFinished, "Timelock is not over");
        if(!timelockFinished) revert Main__MinTimelockNotFinished(block.timestamp - timelockOG, 15 days);
        _;
    }


    // protocol fee starts at 0 and can only be changed by the owner and after 14 days of warning.
    function setProtocolFee(uint256 _newFee) external isTimelockFinished timeWindowForChangingProtocolFee{
        if (owner != msg.sender) revert Main__NotTheOwner(msg.sender, owner);
        protocolFee = _newFee;
        
        // sets currentTimelock to zero so it works again
        timelockFinished = false; // reseting the timelock
        currentTimelock = 0;
    }

    // reset timelock in case the admin lost the 24 hours window after the 14 days, now he must initiate the timelock again and start from scratch.
    // NOT TESTED YET
    function resetTimelock() external {
        if(msg.sender != owner) revert Main__NotTheOwner(msg.sender, owner);
        require(currentTimelock == 0, "Timelock already started");
        // if(currentTimelock != 0) revert Main__MinTimelockNotFinished(block.timestamp - timelockOG, 15 days);

        currentTimelock = 0;
        timelockOG = 0;
        timelockFinished = false;
    }

    // WORKS BUT THERE IS PROBABLY A  BETTER AND MORE CONCIZE WAY
    function startTimelock() public {
        // require(msg.sender == owner, "Not the owner");
        // require(currentTimelock == 0, "Timelock already started");
        
        if(msg.sender != owner) revert Main__NotTheOwner(msg.sender, owner);
        if(currentTimelock != 0) revert Main__MinTimelockNotFinished(block.timestamp - timelockOG, 15 days);

        currentTimelock = block.timestamp;
        timelockOG = block.timestamp;

        timelockFinished = false;
    }

    function endTimelock() public {
        require(msg.sender == owner, "Not the owner");
        require(currentTimelock != 0, "Timelock not started");
        require(block.timestamp >= currentTimelock + MIN_TIMELOCK, "Timelock period not finished");
        currentTimelock = 0;

        timelockFinished = true;
    }


    // setting an address as benefitiary or not.
    // an address if set to true for one category it cant be set for another later, this is intented. it can only be allowed or not allowed.
    // beneficiary will be DAOs which can develop their own logic on how do distribute and delegate the capital, this base layer only forwards the money, maybe in V2 add more options of DAOs for each category.
    // TODO: add more than one DAO for each category, for now it's only one.
    function manageBeneficiaryWhitelist(
        address _oficial,
        Categories _category,
        bool isAllowed
    ) external {
        if (owner != msg.sender) revert Main__NotTheOwner(msg.sender, owner);
        Categories beneficiaryCategory = whichCategoryOficial[_oficial]; // defaults to 0 = UNDEFINED

        // checks if the first this beneficiary is defined
        if (beneficiaryCategory == Categories.UNDEFINED) {
            whichCategoryOficial[_oficial] = _category;
        }

        // checks if is trying to change its category or just allowing and disallowing, revert if changes categories. [working as expected after tests]
        if (
            beneficiaryCategory != _category &&
            beneficiaryCategory != Categories.UNDEFINED
        ) {
            revert Main__oficialAlreadyHasCategory();
        }

        whitelistedOficials[_oficial] = isAllowed;

        if (_category == Categories.INFRASTRUCTURE) {
            INFRASTRUCTURE_DAO = _oficial;
        }else if(_category == Categories.HEALTH){
            HEALTH_DAO = _oficial;
        }else if(_category == Categories.ENVIRONMENT){
            ENVIRONMENT_DAO = _oficial;
        }else if(_category == Categories.ANIMAL_CAUSE){
            ANIMAL_CAUSE_DAO = _oficial;
        }else if(_category == Categories.SOCIAL_CAUSE){
            SOCIAL_CAUSE_DAO = _oficial;
        }

    }

    // distributing rewards, should be called every N times by a Chainlink Keeper. [N yet to be defined]
    function distributeReward() external {
        if (owner != msg.sender) revert Main__NotTheOwner(msg.sender, owner);

        uint fullLiquidityStaked = aaveTokenLP.balanceOf(address(this)); // how much staked there is by this protocol
        if(fullLiquidityStaked == 0) revert Main__NoLiquidityStakedToReap();

        uint256[6] memory categoryWeights;
        uint256[6] memory categoryShares;

        uint valueToLeaveThere;

        // Calculate and sum weights for each user and category
        for (uint i = 0; i < globalUserSnapshot.length; i++) {
            if(!globalUserSnapshot[i].isRetrievable){
                valueToLeaveThere += globalUserSnapshot[i].valueDeposited;
                continue;
            }

            uint256 timeHeld = globalUserSnapshot[i].timeWithdraw - globalUserSnapshot[i].timeDeposit;
            uint256 weight = globalUserSnapshot[i].valueDeposited * timeHeld;
            Categories category = userCurrentCategory[globalUserSnapshot[i].sender];
            categoryWeights[uint(category)] += weight;
        }

            // console.log("tests: ");
            // console.log(fullLiquidityStaked);
            // console.log(valueToLeaveThere);

            uint totalAmount = aavePool.withdraw(address(weth), fullLiquidityStaked - valueToLeaveThere , address(this)); 

            // Calculate each category's share of totalAmount
            for (uint i = 0; i < 6; i++) {
                categoryShares[i] = totalAmount * categoryWeights[i] / sum(categoryWeights);
            }

            // @audit-ok I understand if one of these revert all the others will too, not a problem atm, fix it when in production.
            // Distribute category share to users
            bool success1 = weth.transfer(INFRASTRUCTURE_DAO, categoryShares[uint(Categories.INFRASTRUCTURE)]);
            require(success1, "Transfer failed");
            bool success2 = weth.transfer(HEALTH_DAO, categoryShares[uint(Categories.HEALTH)]);
            require(success2, "Transfer failed");
            bool success3 = weth.transfer(ENVIRONMENT_DAO, categoryShares[uint(Categories.ENVIRONMENT)]);
            require(success3, "Transfer failed");
            bool success4 = weth.transfer(ANIMAL_CAUSE_DAO, categoryShares[uint(Categories.ANIMAL_CAUSE)]);
            require(success4, "Transfer failed");
            bool success5 = weth.transfer(SOCIAL_CAUSE_DAO, categoryShares[uint(Categories.SOCIAL_CAUSE)]);
            require(success5, "Transfer failed");

            
            // weth.transfer(HEALTH_DAO, categoryShares[uint(Categories.HEALTH)]);
            // weth.transfer(ENVIRONMENT_DAO, categoryShares[uint(Categories.ENVIRONMENT)]);
            // weth.transfer(ANIMAL_CAUSE_DAO, categoryShares[uint(Categories.ANIMAL_CAUSE)]);
            // weth.transfer(SOCIAL_CAUSE_DAO, categoryShares[uint(Categories.SOCIAL_CAUSE)]);

            delete globalUserSnapshot;
    }

    // Helper function to sum category weights
    function sum(uint256[6] memory arr) private pure returns (uint256) {
        uint256 total = 0;
        for (uint i = 0; i < arr.length; i++) {
            total += arr[i];
        }
        return total;
    }

    // set tokens that are allowed to stake with, lets just start with 1 or 2 [e.g. usdc, usdt]
    function setTokenAllowed(address _token, bool _isAllowed) public {
        if (msg.sender != owner) revert Main__NotTheOwner(msg.sender, owner);
        allowedTokens[_token] = _isAllowed;
    }
    
    
    // TODO: add a third variable here stating the region/district/country of the staker so its perncetage will go to the correct place further in the subsequent DAO and distributed to the correct people which will be responsable for handling this
    function stakeWithEth(
        Categories _category,
        address _tokenToStakeAddress
    ) public payable nonReentrant {
        if (msg.value <= 0) revert Main__ZeroValue();

        // check if white listed, WETH in this case. already whitelisted in the cosntructor
        bool isTokenAllowed = allowedTokens[_tokenToStakeAddress]; // weth token
        if (!isTokenAllowed) revert Main__TokenNotAllowedForStaking();

        /// check if already has deposited, for now lets only allow one deposit and withdraw at a time, then we set a more complex logic.
        if (totalStaked[msg.sender] > 0)
            revert Main__UserMustFirstWithdrawToStakeAgain();

        totalStaked[msg.sender] += msg.value;

        userCurrentCategory[msg.sender] = _category; // @audit this is being wiped out before the time, change this to an array instead when going more complex, for now I believe this is fine.

        if (_category == Categories.INFRASTRUCTURE) {
            userEachCategory[msg.sender].infrastructure += msg.value;
        } else if (_category == Categories.HEALTH) {
            userEachCategory[msg.sender].health += msg.value;
        } else if (_category == Categories.ENVIRONMENT) {
            userEachCategory[msg.sender].environment += msg.value;
        } else if (_category == Categories.ANIMAL_CAUSE) {
            userEachCategory[msg.sender].animalCause += msg.value;
        } else if (_category == Categories.SOCIAL_CAUSE) {
            userEachCategory[msg.sender].socialCause += msg.value;
        }

        // this whole block deals with the user snapshot ============================
        UserSnapshot[] storage _userSnapshot = userSnapshot[msg.sender];
        uint256 _indexUserSnapshot = indexUserSnapshot[msg.sender];

        UserSnapshot memory tempStruct = UserSnapshot({
            index: _indexUserSnapshot,
            timeDeposit: block.timestamp,
            timeWithdraw: 0,
            valueDeposited: msg.value,
            median: 0,
            token: address(weth),
            sender: msg.sender,
            isRetrievable: false,
            category: _category
        });

        _userSnapshot.push(tempStruct);
        globalUserSnapshot.push(tempStruct);

        weth.deposit{value: msg.value}();
        weth.approve(address(aavePool), msg.value); // approving aavePool to allow it remove the contract's weth // @audit-info can this be only approved once the limit and never ever again to save gas?

        // TODO: this adds the oficial liquid staking token, implement this in v2 because it has to be thought through the bugs that might occur when dealing with it.
        // stakedToken = StakedToken(_tokenToStakeAddress);
        // stakedToken.mint(msg.sender, msg.value, this.stakeWithEth.selector);

        emit AmountStaked(msg.value);

        _stakeToAavePool(address(weth), msg.value); // now after deposited and converted to weth lets stake it to some yield protocol
    }

    // every time a user removes his staked eth he sents 100% of his gains to the beneficiary
    function removeStakedEth() external nonReentrant {
        uint256 sumOfStaked = 0;

        // SOULBOUND NFT HANDLER =======================================
        // _badgeCalculate(); // implement later.
        // =============================================================

        // take 100% of the weth back and send the yield to the chosen categories depending on the percentage, also a small fee for the protocol
        if (userEachCategory[msg.sender].infrastructure > 0) {
            sumOfStaked += userEachCategory[msg.sender].infrastructure;
            userEachCategory[msg.sender].infrastructure = 0;
        } else if (userEachCategory[msg.sender].health > 0) {
            sumOfStaked += userEachCategory[msg.sender].health;
            userEachCategory[msg.sender].health = 0;
        } else if (userEachCategory[msg.sender].environment > 0) {
            sumOfStaked += userEachCategory[msg.sender].environment;
            userEachCategory[msg.sender].environment = 0;
        } else if (userEachCategory[msg.sender].animalCause > 0) {
            sumOfStaked += userEachCategory[msg.sender].animalCause;
            userEachCategory[msg.sender].animalCause = 0;
        } else if (userEachCategory[msg.sender].socialCause > 0) {
            sumOfStaked += userEachCategory[msg.sender].socialCause;
            userEachCategory[msg.sender].socialCause = 0;
        }

        if (sumOfStaked == 0) revert Main__NoAmountStaked(); // for now this seems to prevent anyone from retrieving tokens they didn't stake, not that much tested, though.

        // delete userCurrentCategory[msg.sender]; // @audit fix this..

        totalStaked[msg.sender] = 0;
        emit AmountUnstaked(sumOfStaked);

        // this whole block deals with the user snapshot ============================
        UserSnapshot[] storage _userSnapshot = userSnapshot[msg.sender];
        uint256 _indexUserSnapshot = indexUserSnapshot[msg.sender];

        _userSnapshot[_indexUserSnapshot].timeWithdraw = block.timestamp;

        UserSnapshot memory tempStruct = UserSnapshot({
            index: _indexUserSnapshot,
            timeDeposit: _userSnapshot[_indexUserSnapshot].timeDeposit,
            timeWithdraw: block.timestamp,
            valueDeposited: _userSnapshot[_indexUserSnapshot].valueDeposited,
            median: 0, // measure it later or exclude this since right now is not being used
            token: _userSnapshot[_indexUserSnapshot].token,
            sender: msg.sender,
            isRetrievable: true,
            category: _userSnapshot[_indexUserSnapshot].category
        });

        // CALCULATING POINTS ===============
        uint256 calcualtedPoints = (_userSnapshot[_indexUserSnapshot].timeWithdraw - _userSnapshot[_indexUserSnapshot].timeDeposit ) * _userSnapshot[_indexUserSnapshot].valueDeposited; 
        calculatePoints(calcualtedPoints); 
        // ==================================

        for(uint i; i < globalUserSnapshot.length; i++){
            if(globalUserSnapshot[i].sender == msg.sender){
                globalUserSnapshot[i] = globalUserSnapshot[globalUserSnapshot.length - 1];
                globalUserSnapshot.pop();
            }
        }
        // add this tempStruct to a global array where every X time it's executed by a Chainlink keepers where everything is distributed accordingly and the array is erased
        globalUserSnapshot.push(tempStruct);

        _userSnapshot.pop(); // remove the previous one and the add the complete and updated one
        _userSnapshot.push(tempStruct);

        indexUserSnapshot[msg.sender] += 1; // updates user index
        // ========================================

        /// first unstake from aaveProtocol
        uint256 stakeEtherWithoutYield = _unstakeWeth(sumOfStaked); // type(uint256).max to remove all the from the protocol, maybe can the last user do that?
        // uint256 beneficiaryTokens = allYieldGenerated - sumOfStaked; // All staked - total with yield

        totalAmountStakedEver[msg.sender] += stakeEtherWithoutYield; // an aggregated of all the above. also does not interact with the logic of this function.

        weth.withdraw(stakeEtherWithoutYield); // this converts back all the generated yield to the contract and converts it back to ETH
        // payable(_oficial).transfer(stakeEtherWithoutYield); // gives just the yield amount to the beneficiary
        payable(msg.sender).transfer(sumOfStaked); // gives 100% of the invested tokens to the staker, without any fees, just the amount staked
    }

    // function removeStakedToken() external nonReentrant {}
    
    function calculatePoints(uint256 _calculatedPoints) private {
        // uint256 calcualtedPoints = (_userSnapshot[_indexUserSnapshot].timeWithdraw - _userSnapshot[_indexUserSnapshot].timeDeposit ) * _userSnapshot[_indexUserSnapshot].valueDeposited; 
        // calculatePoints(calcualtedPoints); 
        userPoints[msg.sender] += (_calculatedPoints / POINTS_DENOMINATOR);
        // console.log("calculatePoints: ", userPoints[msg.sender]);
    }
    receive() external payable {
        emit ReceiveFunctionCalled(msg.sender, msg.value);
    } // necessary to receive ethers from the weth protocol and others

    //@audit-info [issue parcially solved!?] ok so the problem is, how do i keep track of every user funds individualy so the protocol can get the percentage of what each user has?
    function _unstakeWeth(
        uint256 _amount
    ) private returns (uint256 _allYieldGenerated) {
        // CHECK IF TOKEN WHITELISTED AND IF THE TOKEN WAS ADDED

        // unstake form aave
        _allYieldGenerated = aavePool.withdraw(
            address(weth),
            // type(uint256).max,
            _amount, // type(uint256).max can be used if we want to remove 100% of the amount
            address(this)
            // msg.sender
        ); // address(weth) or the sender direct???
    }

    function _stakeToAavePool(address _token, uint256 _value) internal {
        if (_token == address(weth)) {
            // aavePool `supply` and `deposit` methods are praticaly the same thing.
            aavePool.supply(address(weth), _value, address(this), 0); // [the onbehalfof here means the address that will receive the LPTokens] asset, amount, onBehalfOf, referralCode .  refferalcode means using a middle man
        } else {
            // check if _token address is whitelisted, for now this condition will not be called since in v1 only weth will be used
            aavePool.supply(_token, _value, address(this), 0);
        }
    }

    // function to get the data about the users collateral
    // is this function really useful? maybe it should be removed
    function _getUserAccountData(
        address _user
    )
        public
        returns (
            uint256 _totalCollateralBase,
            uint256 _totalDebtBase,
            uint256 _availableBorrowsBase,
            uint256 _currentLiquidationThreshold,
            uint256 _ltv,
            uint256 _healthFactor
        )
    {
        (
            _totalCollateralBase,
            _totalDebtBase,
            _availableBorrowsBase,
            _currentLiquidationThreshold,
            _ltv,
            _healthFactor
        ) = aavePool.getUserAccountData(_user);
    }
}

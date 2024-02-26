// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Main} from "../src/Main.sol";
import {Weth} from "../src/mocks/Weth.sol";
// import {WETH9} from "../src/interfaces/IWETH.sol";
// import {IERC20} from "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
// import {AToken} from "../src/interfaces/IAToken.sol";

// import {StakedToken} from "../src/StakedToken.sol";
// import {CommunityBadges} from "../src/CommunityBadges.sol";

// import script
import {MainScript} from "../script/MainScript.s.sol";

contract MainTest is Test, MainScript {

    struct UserSnapshot {
        uint256 index;
        uint256 timeDeposit;
        uint256 timeWithdraw;
        uint256 valueDeposited;
        uint256 median;
        address token;
    }

    event AmountStaked(uint indexed amount);

    function setUp() public override {
        run();
    }

    // this is redundant now because it's set on the MainScript.s.sol
    modifier setOneBeneficiaryForEachCategory() {
        // main.manageBeneficiaryWhitelist(
        //     INFRASTRUCTURE_DAO,
        //     Main.Categories.INFRASTRUCTURE,
        //     true
        // );

        // main.manageBeneficiaryWhitelist(
        //     HEALTH_DAO,
        //     Main.Categories.HEALTH,
        //     true
        // );

        // main.manageBeneficiaryWhitelist(
        //     ENVIRONMENT_DAO,
        //     Main.Categories.ENVIRONMENT,
        //     true
        // );

        // main.manageBeneficiaryWhitelist(
        //     ANIMAL_CAUSE_DAO,
        //     Main.Categories.ANIMAL_CAUSE,
        //     true
        // );

        // main.manageBeneficiaryWhitelist(
        //     SOCIAL_CAUSE_DAO,
        //     Main.Categories.SOCIAL_CAUSE,
        //     true
        // );

        _;
    }

    function testTimelockWindow() external {
        main.startTimelock();
        vm.warp(block.timestamp + 14 days);
        main.endTimelock();

        vm.warp(block.timestamp + 24 hours);
        main.setProtocolFee(100);
    }

    function testTimelock() external {
        main.startTimelock();
        vm.warp(block.timestamp + 14 days);
        main.endTimelock();
        main.setProtocolFee(100);

        vm.expectRevert();
        main.setProtocolFee(100);

        main.startTimelock();
        vm.warp(block.timestamp + 14 days);
        main.endTimelock();
        main.setProtocolFee(100);
    }

    function testDistributeRewards() external {
        vm.expectRevert(Main.Main__NoLiquidityStakedToReap.selector);
        main.distributeReward();
    }

    function testStaking() external {
        hoax(user, 1 ether);
        main.stakeWithEth{value: 1 ether}(Main.Categories.SOCIAL_CAUSE, address(weth));
    }

    function testStakes() external setOneBeneficiaryForEachCategory {
        // this should fail since nothing is added to be reaped.
        vm.expectRevert();
        main.distributeReward();
    }

    function testStakeStressingTheSystem() external setOneBeneficiaryForEachCategory {
        vm.deal(makeAddr("me"), 2 ether);
        vm.deal(makeAddr("two"), 2 ether);
        vm.deal(makeAddr("three"), 10 ether);


        vm.prank(makeAddr("me"));
        main.stakeWithEth{value: 1 ether}(
            Main.Categories.INFRASTRUCTURE,
            address(weth)
        );

        vm.prank(makeAddr("two"));
        main.stakeWithEth{value: 2 ether}(
            Main.Categories.HEALTH,
            address(weth)
        );

        vm.prank(makeAddr("three"));
        main.stakeWithEth{value: 10 ether}(
            Main.Categories.SOCIAL_CAUSE,
            address(weth)
        );

        vm.warp(block.timestamp + 1 weeks); // warping so it has some token to distribute

        vm.prank(makeAddr("two"));
        main.removeStakedEth();
        
        vm.prank(makeAddr("me"));
        main.removeStakedEth();
        
        main.distributeReward();

        // THIS IS ERRORING, CHECK WHY
        // first when removing check if there is something to remove

        // @audit the problem is happening here
        vm.prank(makeAddr("three"));
        main.removeStakedEth();

        assertEq(makeAddr("me").balance, 2 ether);
        assertEq(makeAddr("two").balance, 2 ether);
        assertEq(makeAddr("three").balance, 10 ether);

        console.log("FINAL BALANCES =====================");
        console.log("infrastructure",weth.balanceOf(INFRASTRUCTURE_DAO));
        console.log("health",weth.balanceOf(HEALTH_DAO));
        console.log("environment",weth.balanceOf(ENVIRONMENT_DAO));
        console.log("animal_cause",weth.balanceOf(ANIMAL_CAUSE_DAO));
        console.log("social_cause",weth.balanceOf(SOCIAL_CAUSE_DAO));
    }

    function testStakeMoreThanOne() external setOneBeneficiaryForEachCategory {

        vm.deal(makeAddr("me"), 2 ether);
        vm.deal(makeAddr("two"), 2 ether);

        vm.prank(makeAddr("me"));
        main.stakeWithEth{value: 1 ether}(
            Main.Categories.INFRASTRUCTURE,
            address(weth)
        );

        vm.prank(makeAddr("two"));
        main.stakeWithEth{value: 2 ether}(
            Main.Categories.HEALTH,
            address(weth)
        );

        vm.warp(block.timestamp + 1 weeks); // warping so it has some token to distribute

        vm.prank(makeAddr("two"));
        main.removeStakedEth();
        
        vm.prank(makeAddr("me"));
        main.removeStakedEth();
        
        main.distributeReward();

        assertEq(makeAddr("me").balance, 2 ether);
        assertEq(makeAddr("two").balance, 2 ether);

        console.log("FINAL BALANCES =====================");
        console.log("infrastructure",weth.balanceOf(INFRASTRUCTURE_DAO));
        console.log("health",weth.balanceOf(HEALTH_DAO));
        console.log("environment",weth.balanceOf(ENVIRONMENT_DAO));
        console.log("animal_cause",weth.balanceOf(ANIMAL_CAUSE_DAO));
        console.log("social_cause",weth.balanceOf(SOCIAL_CAUSE_DAO));

        // 
        // 
        // 
        // 
        vm.prank(makeAddr("me"));
        main.stakeWithEth{value: 1 ether}(
            Main.Categories.INFRASTRUCTURE,
            address(weth)
        );

        vm.prank(makeAddr("two"));
        main.stakeWithEth{value: 2 ether}(
            Main.Categories.HEALTH,
            address(weth)
        );

        vm.warp(block.timestamp + 1 weeks); // warping so it has some token to distribute

        vm.prank(makeAddr("two"));
        main.removeStakedEth();
        
        vm.prank(makeAddr("me"));
        main.removeStakedEth();
        
        main.distributeReward();

        assertEq(makeAddr("me").balance, 2 ether);
        assertEq(makeAddr("two").balance, 2 ether);

      console.log("FINAL BALANCES =====================");
        console.log("infrastructure",weth.balanceOf(INFRASTRUCTURE_DAO));
        console.log("health",weth.balanceOf(HEALTH_DAO));
        console.log("environment",weth.balanceOf(ENVIRONMENT_DAO));
        console.log("animal_cause",weth.balanceOf(ANIMAL_CAUSE_DAO));
        console.log("social_cause",weth.balanceOf(SOCIAL_CAUSE_DAO));
    }


    function testStakePoints() external  {
        vm.startPrank(makeAddr("me"));
        vm.deal(makeAddr("me"), 2 ether);

        main.stakeWithEth{value: 0.1 ether}(
            Main.Categories.INFRASTRUCTURE,
            address(weth)
        );

        vm.warp(block.timestamp + 1 days); // warping so it has some token to distribute

        main.removeStakedEth();
        vm.stopPrank();
        
        main.distributeReward();

        assertEq(makeAddr("me").balance, 2 ether);

        console.log("FINAL BALANCES =====================");
        console.log("infrastructure",weth.balanceOf(INFRASTRUCTURE_DAO));
        console.log("health",weth.balanceOf(HEALTH_DAO));
        console.log("environment",weth.balanceOf(ENVIRONMENT_DAO));
        console.log("animal_cause",weth.balanceOf(ANIMAL_CAUSE_DAO));
        console.log("social_cause",weth.balanceOf(SOCIAL_CAUSE_DAO));

        // 
        // 
        // 
        vm.startPrank(makeAddr("me"));

        main.stakeWithEth{value: 1 ether}(
            Main.Categories.INFRASTRUCTURE,
            address(weth)
        );

        vm.warp(block.timestamp + 1 days); // warping so it has some token to distribute

        main.removeStakedEth();
        vm.stopPrank();

        
        main.distributeReward();

        assertEq(makeAddr("me").balance, 2 ether);

        console.log("FINAL BALANCES =====================");
        console.log("infrastructure",weth.balanceOf(INFRASTRUCTURE_DAO));
        console.log("health",weth.balanceOf(HEALTH_DAO));
        console.log("environment",weth.balanceOf(ENVIRONMENT_DAO));
        console.log("animal_cause",weth.balanceOf(ANIMAL_CAUSE_DAO));
        console.log("social_cause",weth.balanceOf(SOCIAL_CAUSE_DAO));
    }

    function testStakeSimple() external setOneBeneficiaryForEachCategory {
        vm.startPrank(makeAddr("me"));
        vm.deal(makeAddr("me"), 2 ether);

        main.stakeWithEth{value: 0.1 ether}(
            Main.Categories.INFRASTRUCTURE,
            address(weth)
        );

        vm.warp(block.timestamp + 1 days); // warping so it has some token to distribute

        main.removeStakedEth();
        vm.stopPrank();
        
        main.distributeReward();

        assertEq(makeAddr("me").balance, 2 ether);

        console.log("FINAL BALANCES =====================");
        console.log("infrastructure",weth.balanceOf(INFRASTRUCTURE_DAO));
        console.log("health",weth.balanceOf(HEALTH_DAO));
        console.log("environment",weth.balanceOf(ENVIRONMENT_DAO));
        console.log("animal_cause",weth.balanceOf(ANIMAL_CAUSE_DAO));
        console.log("social_cause",weth.balanceOf(SOCIAL_CAUSE_DAO));
    }

    modifier asOwner() {
        // vm.startPrank(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38); // [this error is because the broadcaster is not the same as the script/test contract address] [for isolated and crafted things it works] somehow when deploying live this address is the one deploying the contract, not the script/test address
        // vm.startPrank(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496); // [this error is because the broadcaster is not the same as the script/test contract address] [for isolated and crafted things it works] somehow when deploying live this address is the one deploying the contract, not the script/test address
        _;
    }

    receive() external payable {} // necessary to interact with the contract since it sends ethers back

    function testSetTokenAllowed() external {
        // console.log(msg.sender);
        // console.log(address(this));
        // console.log(main.owner());
        main.setTokenAllowed(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, true); // 0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c
    }

    function testManageBeneficiary() external asOwner {
        main.manageBeneficiaryWhitelist(user, Main.Categories.HEALTH, true);
    }

    function testUserSnapshotWarped() external {
        vm.startPrank(user);
        vm.deal(user, 2 ether);

        uint currentTimestamp = block.timestamp;

        main.stakeWithEth{value: 1 ether}(
            Main.Categories.ENVIRONMENT,
            address(weth)
        );
        (
            ,
            uint256 timeDeposited,
            uint256 timeWithdrawed,
            uint256 valueDeposited,
            ,
            address token,,,
        ) = main.userSnapshot(user, 0);

        vm.warp(block.timestamp + 20 days);
        main.removeStakedEth();

        (, timeDeposited, timeWithdrawed, valueDeposited,,,,,) = main
            .userSnapshot(user, 0);

        assertEq(main.indexUserSnapshot(user), 1);
        assertEq(timeDeposited, currentTimestamp);
        assertEq(timeWithdrawed, currentTimestamp + 20 days);
        assertEq(timeWithdrawed, block.timestamp);
        assertEq(valueDeposited, 1 ether);
    }

    function testUserSnapshot() external {
        vm.startPrank(user);
        vm.deal(user, 2 ether);

        main.stakeWithEth{value: 1 ether}(
            Main.Categories.ENVIRONMENT,
            address(weth)
        );

        (
            ,
            uint256 timeDeposited,
            uint256 timeWithdrawed,
            uint256 valueDeposited,
            ,,,,

        ) = main.userSnapshot(user, 0);

        main.removeStakedEth();

        (, timeDeposited, timeWithdrawed, valueDeposited, , , , ,) = main
            .userSnapshot(user, 0);

        assertEq(main.indexUserSnapshot(user), 1);
        assertEq(timeDeposited, block.timestamp);
        assertEq(timeWithdrawed, block.timestamp);
        assertEq(valueDeposited, 1 ether);
    }

    function testSetProtocolFee(address _addr) external {
        vm.assume(_addr != address(this));
        vm.prank(_addr);
        vm.expectRevert();
        main.setProtocolFee(100);
    }

    function testUserTryToStakeTwice() external {
        vm.startPrank(user);
        vm.deal(user, 2 ether);
        main.stakeWithEth{value: 1 ether}(
            Main.Categories.ENVIRONMENT,
            address(weth)
        );

        main.removeStakedEth();
        main.stakeWithEth{value: 1 ether}(
            Main.Categories.ENVIRONMENT,
            address(weth)
        ); // NOW IT WORKS, it was not working before because hoax acts as prank instead of startPrank

        main.removeStakedEth();
    }

    function testAllowBeneficiaryAndThenUnallowIt() external asOwner {
        main.manageBeneficiaryWhitelist(user, Main.Categories.HEALTH, true);
        main.manageBeneficiaryWhitelist(user, Main.Categories.HEALTH, false); // this should work
        main.manageBeneficiaryWhitelist(user, Main.Categories.HEALTH, true); // this should work
        main.manageBeneficiaryWhitelist(user, Main.Categories.HEALTH, false); // this should work
        main.manageBeneficiaryWhitelist(user, Main.Categories.HEALTH, false); // this should work

        vm.expectRevert();
        // this should not work, test should pass because of exapected revert
        main.manageBeneficiaryWhitelist(
            user,
            Main.Categories.ANIMAL_CAUSE,
            true
        );
    }

    function testOverrideManageBeneficiary() external asOwner {
        main.manageBeneficiaryWhitelist(user, Main.Categories.HEALTH, true);
        vm.expectRevert();
        main.manageBeneficiaryWhitelist(
            user,
            Main.Categories.ANIMAL_CAUSE,
            false
        );
    }

    function testStakeWithEth() external {
        uint256 totalStakedBefore = main.totalStaked(user);

        hoax(user, 2 ether);
        main.stakeWithEth{value: 1 ether}(
            Main.Categories.ENVIRONMENT,
            address(weth)
        );

        (uint256 infrastructure, uint256 health, uint256 environment, , ) = main
            .userEachCategory(user);

        assertEq(environment, 1 ether);
        assertEq(infrastructure, 0);
        assertEq(health, 0);

        assertEq(main.totalStaked(user), totalStakedBefore + 1 ether);
    }

    function testStakeWithEth_Event() external {
        hoax(user, 1 ether);
        vm.expectEmit(true, false, false, true);
        emit AmountStaked(1 ether);
        main.stakeWithEth{value: 1 ether}(
            Main.Categories.ENVIRONMENT,
            address(weth)
        );

        // uint256 lpBalance = aaveTokenLP.balanceOf(user);
        // console.logUint(lpBalance);
        // assertEq(lpBalance, 1 ether);
    }

    function testTokenDetails() external {
        uint decimals = aaveTokenLP.decimals();
        string memory name = aaveTokenLP.name();

        console.logUint(decimals);
        console.logString(name);
    }

    // ok so the aaveTokenLp rebalances and accumulates value with time.
    function testCheckYieldGenerated() external {
        hoax(address(user), 1 ether);
        main.stakeWithEth{value: 1 ether}(
            Main.Categories.ENVIRONMENT,
            address(weth)
        );

        uint256 oldLpBalance = aaveTokenLP.balanceOf(address(main));
        // console.logUint(lpBalance);

        vm.warp(block.timestamp + 10 days);
        uint newLpBalance = aaveTokenLP.balanceOf(address(main));

        // assertGt(newLpBalance, oldLpBalance);

        // console.logUint(oldLpBalance);
        // console.logUint(newLpBalance);

        vm.prank(user);
        main.removeStakedEth();

        uint256 userBalance = user.balance;
        uint beneficiaryBalance = beneficiary.balance;

        assertGt(newLpBalance, oldLpBalance);
        // assertEq(userBalance, 1 ether);
        // assertGt(beneficiaryBalance, 0);
        console.log(beneficiaryBalance);

        // uint afterWithdraw = aaveTokenLP.balanceOf(address(main));
        // console.log("after withdrwal", afterWithdraw);
    }

    // function testRemoveAllStakedEth() external {
    //     hoax(user, 1 ether);
    //     main.stakeWithEth{value: 1 ether}(Main.Categories.environment, address(weth));
    // address(weth)
    //     vm.prank(user);
    //     main.removeStakedEth();
    // }

    function testStakeContributeAndTakeItBack_OnePerson() external {
        vm.startPrank(user);
        vm.deal(user, 1 ether);

        main.stakeWithEth{value: 1 ether}(
            Main.Categories.ENVIRONMENT,
            address(weth)
        );
        vm.warp(block.timestamp + 7 days);

        main.removeStakedEth();

        // (
        //     uint256 _totalCollateralBase,
        //     uint256 _totalDebtBase,
        //     uint256 _availableBorrowsBase,
        //     uint256 _currentLiquidationThreshold,
        //     uint256 _ltv,
        //     uint256 _healthFactor
        // ) = main._getUserAccountData(beneficiary);

        // console.log("_totalCollateralBase", _totalCollateralBase);
        // console.log("_ltv", _ltv);
        // console.log("_totalDebtBase", _totalDebtBase);

        // assertEq(user.balance, 1 ether);
        // assertGt(beneficiary.balance, 0);
        // console.log("beneficiary balance", beneficiary.balance);
    }

    function testStakeContributeAndTakeItBack_Group() external {
        address[5] memory users = [
            makeAddr("user1"),
            makeAddr("user2"),
            makeAddr("user3"),
            makeAddr("user4"),
            makeAddr("user5")
        ];

        // fund all the users and stake with them
        for (uint i; i < users.length; i++) {
            address currentUser = users[i];

            vm.startPrank(currentUser);
            vm.deal(currentUser, 1 ether);

            main.stakeWithEth{value: 1 ether}(
                Main.Categories.ENVIRONMENT,
                address(weth)
            ); // add different categories for each user, also different values
        }

        vm.warp(block.timestamp + 7 days); // later try different days for each user

        for (uint i; i < users.length; i++) {
            address currentUser = users[i];

            vm.startPrank(currentUser);
            main.removeStakedEth();

            // do the after checks here
        }

        // assertEq(user.balance, 1 ether);
        // assertGt(beneficiary.balance, 0);
        // console.log("beneficiary balance", beneficiary.balance);

        // address[] memory initialUsers = new address[](2);
    }

    //   (
    //         uint256 _totalCollateralBase,
    //         uint256 _totalDebtBase,
    //         uint256 _availableBorrowsBase,
    //         uint256 _currentLiquidationThreshold,
    //         uint256 _ltv,
    //         uint256 _healthFactor
    //     ) = main._getUserAccountData(address(main));

    //     console.log("_totalCollateralBase", _totalCollateralBase);
    //     console.log("_ltv", _ltv);
    //     console.log("_totalDebtBase", _totalDebtBase);
}

contract DaoTest is Test, MainScript {

    function setUp() public override {
        run();
    }

    function testProposeProject() public {
        vm.prank(user);
        daoInfrastructure.proposeProject(
            "title",
            "shortExpanation",
            "url",
            "metadata",
            "picture",
            1 ether
        );


        vm.deal(makeAddr("me"), 600 ether);
        vm.deal(makeAddr("two"), 600 ether);

        vm.prank(makeAddr("me"));
        main.stakeWithEth{value: 600 ether}(
            Main.Categories.INFRASTRUCTURE,
            address(weth)
        );

        vm.prank(makeAddr("two"));
        main.stakeWithEth{value: 600 ether}(
            Main.Categories.INFRASTRUCTURE,
            address(weth)
        );

        vm.warp(block.timestamp + 5 weeks); // warping so it has some token to distribute

        vm.prank(makeAddr("two"));
        main.removeStakedEth();
        
        vm.prank(makeAddr("me"));
        main.removeStakedEth();
        
        main.distributeReward();

        assertEq(makeAddr("me").balance, 600 ether);
        assertEq(makeAddr("two").balance, 600 ether);

        // console.log("FINAL BALANCES =====================");
        // console.log("infrastructure",weth.balanceOf(INFRASTRUCTURE_DAO));
        // console.log("health",weth.balanceOf(HEALTH_DAO));
        // console.log("environment",weth.balanceOf(ENVIRONMENT_DAO));
        // console.log("animal_cause",weth.balanceOf(ANIMAL_CAUSE_DAO));
        // console.log("social_cause",weth.balanceOf(SOCIAL_CAUSE_DAO));

        
        // current sender is the contract == admin
        daoInfrastructure.delegateTo(payable(makeAddr("delegated")), 0); // starts at index 0

        console.log(makeAddr("delegated").balance);
    }
}

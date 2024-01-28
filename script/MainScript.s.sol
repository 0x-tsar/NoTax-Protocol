// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/Test.sol";

import {Main} from "../src/Main.sol";
import {Weth} from "../src/mocks/Weth.sol";
import {WETH9} from "../src/interfaces/IWETH.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {AToken} from "../src/interfaces/IAToken.sol";

import {StakedToken} from "../src/StakedToken.sol";
import {CommunityBadges} from "../src/CommunityBadges.sol";

import {DaoInfrastructure} from "../src/DaoInfrastructure.sol";

contract MainScript is Script, Test {
    Main public main;
    WETH9 public weth;

    DaoInfrastructure public daoInfrastructure;

    AToken public aaveTokenLP;

    address deployer = makeAddr("deployer");
    address owner = makeAddr("owner");
    address user = makeAddr("user");
    address beneficiary = makeAddr("beneficiary");

    address public INFRASTRUCTURE_DAO = address(100);
    address public HEALTH_DAO = address(101);
    // address public ENVIRONMENT_DAO = address(102);
    address public ENVIRONMENT_DAO;
    address public ANIMAL_CAUSE_DAO = address(103);
    address public SOCIAL_CAUSE_DAO = address(104);

    function setUp() public virtual {}

    function run()
        public
    // returns (WETH9, StakedToken, StakedToken, CommunityBadges, AToken)
    {
        // vm.startBroadcast();
        weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        main = new Main(); // passing the community register as parameter
        main.setTokenAllowed(address(weth), true); // which one should be the correct one? staked or real weth?
        aaveTokenLP = AToken(0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8);
        
        // deploying one infra dao to set as beneficiary, just one, the others were not created
        daoInfrastructure = new DaoInfrastructure();

        // setting the oficial DAOS
        // main.manageBeneficiaryWhitelist(INFRASTRUCTURE_DAO, Main.Categories.INFRASTRUCTURE, true);
        main.manageBeneficiaryWhitelist(address(daoInfrastructure), Main.Categories.INFRASTRUCTURE, true); // updated with the custom one
        main.manageBeneficiaryWhitelist(HEALTH_DAO, Main.Categories.HEALTH, true);
        main.manageBeneficiaryWhitelist(ENVIRONMENT_DAO, Main.Categories.ENVIRONMENT, true);
        main.manageBeneficiaryWhitelist(ANIMAL_CAUSE_DAO, Main.Categories.ANIMAL_CAUSE, true);
        main.manageBeneficiaryWhitelist(SOCIAL_CAUSE_DAO, Main.Categories.SOCIAL_CAUSE, true);
        // vm.stopBroadcast();
    }
}

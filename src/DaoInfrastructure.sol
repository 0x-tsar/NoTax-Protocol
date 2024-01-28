// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {WETH9} from "./interfaces/IWETH.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";

import "forge-std/Test.sol"; // remove for production

// each benefiary/Official/Principal can be a different logic
// this logic includes hiring people.
contract DaoInfrastructure is ReentrancyGuard, Test {
  address payable admin;
  WETH9 public weth;


  struct ProjectStruct {
     string title;
     string shortExplanation;
     string url;
     string metadata;
     string picture;
     uint256 currentAmount;
     uint256 goalAmount;
     address payable creator;
     bool isApproved;
  }

  uint256 public currentProjectIndex;
  mapping (uint256 => ProjectStruct) public projectStructs;

  // events
  event DAO__DelegatedTo(address indexed to, uint256 indexed amount);
  event DAO__ProjectProposed(uint256 indexed projectIndex);

  // errors

  constructor(){
    admin = payable(msg.sender);
    weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // ethereum weth address
  }

  modifier onlyAdmin(){
    require(msg.sender == admin, "DENIED: ONLY ADMIN");
    _;
  }

  // lets just skip the approval part of the proposed project part and assume it's approved for the sake of time since we are going only for the MVP here, then it can be fully implemented
  function delegateTo(address payable _delegated, uint256 _projectIndex) public onlyAdmin {
    ProjectStruct memory p = projectStructs[_projectIndex];
    
    // TODO: CHECK IF PROJECT EXISTS
    // TODO: at this time anyone can be the delegated and anyone can propose

    console.log("WETH BALANCE: ",weth.balanceOf(address(this)));
    console.log("ETH BALANCE:" ,address(this).balance);
    
    // require(address(this).balance >= p.currentAmount, "BALANCE OF THE DAO NOT ENOUGH"); // check if dao has enough funds to cover this project
    require(weth.balanceOf(address(this)) >= p.currentAmount, "BALANCE OF THE DAO NOT ENOUGH"); // check if dao has enough funds to cover this project
    
    delete projectStructs[_projectIndex];


    // everything working exactly was expected
    weth.transfer(_delegated, p.currentAmount);
    console.log("_delegated weth balance:",weth.balanceOf(_delegated));

    // (bool success, ) = _delegated.call{value: p.currentAmount}("");
    // require(success, "NOT POSSIBLE");

    emit DAO__DelegatedTo(_delegated, p.currentAmount); // goalAmount or currentAmount
  }

  // should be added isProposer or anyone can propose?
  // @audit this is already approved for faster tests, change it later.
  function proposeProject() public {
      ProjectStruct memory p = ProjectStruct ({
        title: "New Warehouse",
        shortExplanation: "Necessary for storing packages arriving from all over the state",
        url: "https://more about the project,  could be a X/Youtube video",
        metadata: "",
        picture: "picture here",
        currentAmount: 1 ether,
        goalAmount: 1 ether,
        creator: payable(msg.sender),
        isApproved: true
      });

      projectStructs[currentProjectIndex] = p; // starts at 0
      currentProjectIndex++;

      emit DAO__ProjectProposed(currentProjectIndex);
  }

  receive() external payable {
    console.log("quantity received");
    console.log(msg.value);
  }
}
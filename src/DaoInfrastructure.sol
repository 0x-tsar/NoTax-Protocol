// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {WETH9} from "./interfaces/IWETH.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";

// import "forge-std/Test.sol"; // remove for production [red squiggly line, but it works]

// each benefiary/Official/Principal can be a different logic
// this logic includes hiring people.
contract DaoInfrastructure is ReentrancyGuard{
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
     bool isFunded;
  }

  uint256 public currentProjectIndex;
  uint256 public currentProjectPendingIndex;
  mapping (uint256 => ProjectStruct) public projectStructs;
  mapping (address => bool) public allowedPrincipals; 
  mapping (address => uint256) public totalFundReleasedToPrincipal; 

  // events
  event DAO__DelegatedTo(address indexed to, uint256 indexed amount);
  event DAO__ProjectProposed(uint256 indexed projectIndex);
  event DAO__QuantityReceived(uint256 indexed amount);

  // errors
  error ProjectDoesNotExist();
  error DAO__NotAdmin(address sender);

  constructor(){
    admin = payable(msg.sender);
    weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // ethereum weth address
  }

  modifier onlyAdmin(){
    if(msg.sender != admin) {
      revert DAO__NotAdmin(msg.sender);
    }
    _;
  }

  // lets just skip the approval part of the proposed project part and assume it's approved for the sake of time since we are going only for the MVP here, then it can be fully implemented
  function delegateTo(address payable _delegated, uint256 _projectIndex) public onlyAdmin {
    ProjectStruct memory p = projectStructs[_projectIndex];
    
    if(p.creator == address(0)) {
      revert ProjectDoesNotExist();
    }

    // TODO: at this time anyone can be the delegated and anyone can propose
    // console.log("WETH BALANCE: ",weth.balanceOf(address(this)));
    // console.log("ETH BALANCE:" ,address(this).balance);
    
    // require(address(this).balance >= p.currentAmount, "BALANCE OF THE DAO NOT ENOUGH"); // check if dao has enough funds to cover this project
    require(weth.balanceOf(address(this)) >= p.currentAmount, "BALANCE OF THE DAO NOT ENOUGH"); // check if dao has enough funds to cover this project
    
    delete projectStructs[_projectIndex];

    bool success =  weth.transfer(_delegated, p.currentAmount);
    require(success, "NOT POSSIBLE");

    // console.log("_delegated weth balance:",weth.balanceOf(_delegated));

    // (bool success, ) = _delegated.call{value: p.currentAmount}("");
    // require(success, "NOT POSSIBLE");

    emit DAO__DelegatedTo(_delegated, p.currentAmount); // goalAmount or currentAmount
  }

  // so far anyone can propose. It can be revised this decision later
  function proposeProject(string memory _title, string memory _shortExpanation, string memory _url, string memory _metadata, string memory _picture, uint256 _goalAmount) public returns (uint256 indexProposal) {

      ProjectStruct memory p = ProjectStruct ({
        title: _title,
        shortExplanation: _shortExpanation , //"Necessary for storing packages arriving from all over the state",
        url: _url, //"https://more about the project,  could be a X/Youtube video",
        metadata: _metadata,
        picture: _picture,
        currentAmount: 0,
        goalAmount: _goalAmount,
        creator: payable(msg.sender),
        isFunded: false
      });

      projectStructs[currentProjectIndex] = p; // starts at 0
      indexProposal = currentProjectIndex; // this index is the index of the proposal returned to the caller
      currentProjectIndex++;

      emit DAO__ProjectProposed(currentProjectIndex);
  }

  receive() external payable {
    emit DAO__QuantityReceived(msg.value);
  }
}
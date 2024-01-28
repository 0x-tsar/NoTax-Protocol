// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {WETH9} from "./interfaces/IWETH.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";

import "forge-std/Test.sol"; // remove for production

// this contract is going to be inherited by all the DAOs. this is a MVP.
contract DaoBase is ReentrancyGuard, Test {
  mapping (address user => bool isAllowed) public isPrincipal;
  mapping (string country => uint amount) public country;
  address public admin;

  struct ProjectStruct {
     string title;
     string shortExplanation;
     string url;
     string metadata;
     string picture;
     uint256 currentAmount;
     uint256 goalAmount;
     address creator;
  }

  constructor(string memory _name){
    admin = msg.sender;
  }

  // TODO: allow Principal
  // TODO: timelock?


  // what is sent by the Main contract.
  // @audit-info should onlyMain be added here or not necessary?
  function receiver() payable external {

  }

  fallback() external payable {}
  receive() external payable {}
}
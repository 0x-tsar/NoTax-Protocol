//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Main as NoTax} from "./Main.sol";

contract Tipper {

  // state variables
  address public admin;
  address public wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  NoTax public noTax;

  // events
  event Tip(address indexed from, address indexed category, string location, uint256 amount);

  // errors
  error Tipper__NotOwner();
  error Tipper__ValueIsZero();

  constructor(address payable _noTaxAddress) {
    admin = msg.sender;
    noTax = NoTax(_noTaxAddress);
  }
  
  /*
    some issues with this design:
      1. is it supposed to be more of a cashback or a tip system?
      2. no matter what if one or another, the second time the user triest to tip/stake without removing his stake from the NoTax protocol it will revert because only one at a time is allowed
      3. who is the staker, the user or the contract? because the NoTax function takes the msg.sender as the staker, so it should be modified if any protocol intends to use the user as the Staker, the default is the contract calling it to stake the users' funds
  */
  function router(NoTax.Categories _category) public payable {
    if(msg.value == 0){ // maybe redundant because the stakeWithEth function will revert if the value is 0, BUT if this protocol can be used for different protocols it can be useful
      revert Tipper__ValueIsZero();
    }
    noTax.stakeWithEth{value: msg.value}(_category, wethAddress);
  }

  receive() external payable {}
  fallback() external payable {}
}
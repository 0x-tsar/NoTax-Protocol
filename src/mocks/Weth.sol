// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract Weth is ERC20Mock {
    mapping(address => uint256) public balances;

    // this wrap is very unsafe but it does not mater for test purposes. DO NOT DEPLOY THIS WAY
    function wrap() public payable {
        require(msg.value > 0, "value zero");
        // payable(address(this)).transfer(msg.value); // dont need to do this.
        balances[msg.sender] += msg.value;
        _mint(msg.sender, msg.value);
    }

    function unwrap(uint256 amount) external {
        require(amount > 0, "amount zero");
        balances[msg.sender] -= amount;
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Main} from "./Main.sol";

contract StakedToken is ERC20 {
    address mainAddress;
    enum Categories {
        UNDEFINED,
        INFRASTRUCTURE,
        HEALTH,
        ENVIRONMENT,
        ANIMAL_CAUSE,
        SOCIAL_CAUSE
    }

    address public owner;

    // deploy instances of these for each token e.g. stUSDC, stETH
    constructor(
        string memory _name,
        string memory _ticker
    ) ERC20(_name, _ticker) {
        owner = msg.sender;
    }

    function setMainAddress(address _mainAddress) external {
        require(owner == msg.sender, "msg.sender not the owner");
        mainAddress = _mainAddress;
    }

    // make this function only callable by the Main contract and from a spefici function.
    function mint(address _to, uint256 _amount, bytes4 _selector) external {
        require(_amount > 0, "amount can not be 0");
        require(msg.sender == mainAddress, "Sender is not Main contract");
        // require(_selector == 0xadf6105f, "wrong bytes4"); [implement this later, stakeWithEth and stakeWithToken will be the only two ones allowed to call this function, the signature is not this one anymore because I added another parameter, just get the new one, for now it's fine] // anyone can hardcode this bytes4 but the require above only allows the contract call it

        _mint(_to, _amount);
    }

    function burn(address _to, uint256 _amount, bytes4 _selector) external {
        require(_amount > 0, "amount can not be 0");
        require(msg.sender == mainAddress, "Sender is not Main contract");
        // require(_selector == 0x07a43862, "wrong bytes4"); // anyone can hardcode this bytes4 but the require above only allows the contract call it

        _burn(_to, _amount);
    }
}

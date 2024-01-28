// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract CommunityBadges {
    // string public COMMUNITY_NAME = "";
    // the idea would be have few of these contracts deployed each one with a different achievement.
    // or maybe do this in the Main as a struct keep score?
    // string public COMMUNITY_SYMBOL = "";

    // @audit-info [important] this can be the MAIN nft file where it stores all the points from each nft and then each one can have it's own scores
    // @audit-info this can be the MAIN nft file where it stores all the points from each nft and then each one can have it's own scores
    // @audit-info  each token must be soul-bound
    // each nft category calls this to check it's variables.
    struct Category {
        uint256 infrastructure;
        uint256 health;
        uint256 environment;
        uint256 animalCause;
        uint256 socialCause;
    }

    mapping(address => Category) public badgeScores;

    address public owner;
    address public mainAddress;

    constructor() {
        owner = msg.sender;
    }

    function setMainAddress(address _mainAddress) external {
        require(owner == msg.sender, "msg.sender not the owner");
        mainAddress = _mainAddress;
    }

    // this should only be callable by the Main contract
    function setQualification(
        address _sender,
        Category memory _category
    ) public {
        // this function would be called from Main to check the user send a minimum to classify for this badge
        // require(_amount > 0, "amount can not be 0");
        require(msg.sender == mainAddress, "Sender is not Main contract");

        badgeScores[_sender] = _category;
    }

    // make this function only callable by the Main contract and from a spefici function.
    // function mint(address _to, uint256 _amount, bytes4 _selector) external {
    //     require(_amount > 0, "amount can not be 0");
    //     require(msg.sender == mainAddress, "Sender is not Main contract");
    //     // require(_selector == 0xadf6105f, "wrong bytes4"); [implement this later, stakeWithEth and stakeWithToken will be the only two ones allowed to call this function, the signature is not this one anymore because I added another parameter, just get the new one, for now it's fine] // anyone can hardcode this bytes4 but the require above only allows the contract call it

    //     _mint(_to, _amount);
    // }

    // function burn(address _to, uint256 _amount, bytes4 _selector) external {
    //     require(_amount > 0, "amount can not be 0");
    //     require(msg.sender == mainAddress, "Sender is not Main contract");
    //     // require(_selector == 0x07a43862, "wrong bytes4"); // anyone can hardcode this bytes4 but the require above only allows the contract call it

    //     _burn(_to, _amount);
    // }
}

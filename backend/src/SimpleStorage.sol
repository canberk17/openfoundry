
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 private storedData;
    address private owner;

    constructor() {
        owner = msg.sender; // Set contract creator as owner
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can set value");
        _;
    }

    function set(uint256 x) public onlyOwner {
        storedData = x;
    }

    function get() public view returns (uint256) {
        return storedData;
    }
}
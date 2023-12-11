// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Auction.sol";

contract AuctionTest is Test {
    Auction public auction;
    address payable public alice;
    address payable public bob;

    function setUp() public {
        auction = new Auction();
        alice = payable(address(uint160(uint(keccak256(abi.encodePacked("Alice"))))));
        bob = payable(address(uint160(uint(keccak256(abi.encodePacked("Bob"))))));
    }

    function testInitialHighestBid() public {
        assertEq(auction.highestBid(), 0);
        assertEq(auction.highestBidder(), address(0));
    }

    function testSuccessfulBid() public {
        vm.deal(alice, 1 ether);
        vm.startPrank(alice);
        auction.bid{value: 1 ether}();
        assertEq(auction.highestBid(), 1 ether);
        assertEq(auction.highestBidder(), alice);
        vm.stopPrank();
    }

    function testFailBidLowerThanHighest() public {
        vm.deal(alice, 2 ether);
        vm.deal(bob, 1 ether);

        vm.startPrank(alice);
        auction.bid{value: 2 ether}();
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert("Bid not high enough");
        auction.bid{value: 1 ether}(); // This should fail
        vm.stopPrank();
    }

    function testRefundPreviousBidder() public {
        vm.deal(alice, 2 ether);
        vm.deal(bob, 3 ether);

        vm.startPrank(alice);
        auction.bid{value: 2 ether}();
        uint aliceBalanceAfterBid = alice.balance;
        vm.stopPrank();

        vm.startPrank(bob);
        auction.bid{value: 3 ether}();
        vm.stopPrank();

        assertEq(alice.balance, aliceBalanceAfterBid + 2 ether);
    }

    function testReentrancyAttack() public {
        // Deploy a malicious contract
        MaliciousBidder attacker = new MaliciousBidder(address(auction));

        // Fund the malicious contract
        vm.deal(address(attacker), 4 ether);

        // Perform the attack
        attacker.attack{value: 4 ether}();

        // Check that the auction's highest bidder is not the attacker
        assertNotEq(auction.highestBidder(), address(attacker));
    }
}

contract MaliciousBidder {
    Auction public auction;

    constructor(address _auction) {
        auction = Auction(_auction);
    }

    // Fallback function used to perform reentrancy attack
    receive() external payable {
        if (address(auction).balance >= 1 ether) {
            auction.bid{value: 1 ether}();
        }
    }

    function attack() external payable {
        auction.bid{value: msg.value}();
    }
}
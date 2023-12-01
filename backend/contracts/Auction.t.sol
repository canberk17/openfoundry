// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Auction.sol";

contract AuctionTest is Test {
    Auction public auction;
    address public constant ATTACKER_ADDRESS = 0x20B15741f38e232999462904642E7fde708A40F8;
    address public constant AUCTION_ADDRESS = 0x4beeFbcbCcb053a6130b3d196960200E619FFedd;

    function setUp() public {
        auction = Auction(AUCTION_ADDRESS);
        vm.deal(ATTACKER_ADDRESS, 10 ether);
    }

    function testFrontRunningVulnerability() public {
        uint legitimateBid = 1 ether;
        vm.startPrank(ATTACKER_ADDRESS);
        auction.bid{value: legitimateBid}();
        vm.stopPrank();

        uint attackerBid = legitimateBid + 0.1 ether;
        vm.roll(block.number + 1);
        vm.startPrank(ATTACKER_ADDRESS);
        auction.bid{value: attackerBid}();
        vm.stopPrank();

        assertEq(auction.highestBidder(), ATTACKER_ADDRESS);
        assertEq(auction.highestBid(), attackerBid);
        assertEq(ATTACKER_ADDRESS.balance, 10 ether - attackerBid);
    }

    function testReentrancyAttack() public {
        MaliciousBidder maliciousBidder = new MaliciousBidder(address(auction));
        vm.deal(address(maliciousBidder), 2 ether);

        vm.startPrank(address(maliciousBidder));
        maliciousBidder.placeBid{value: 1 ether}();
        vm.stopPrank();

        bool reentrancyOccurred = maliciousBidder.reentrancyOccurred();
        assertFalse(reentrancyOccurred);
    }
}

contract MaliciousBidder {
    Auction public auction;
    bool public reentrancyOccurred;

    constructor(address _auction) {
        auction = Auction(_auction);
    }

    function placeBid() external payable {
        auction.bid{value: msg.value}();
    }

    receive() external payable {
        if (address(auction).balance >= 1 ether && !reentrancyOccurred) {
            reentrancyOccurred = true;
            auction.bid{value: 1 ether}();
        }
    }
}
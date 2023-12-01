
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Auction {
    address public highestBidder;
    uint public highestBid;

    function bid() external payable {
        require(msg.value > highestBid, "Bid not high enough.");

        if (highestBidder != address(0)) {
            payable(highestBidder).transfer(highestBid); // Refund the previous highest bidder
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
    }
}
        
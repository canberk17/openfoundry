// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/SimpleStorage.sol";

contract SimpleStorageTest is Test {
    SimpleStorage private simpleStorage;
    address private owner;
    address private nonOwner;

    function setUp() public {
        owner = address(this); // Set the test contract itself as the owner
        nonOwner = address(0x2);
        simpleStorage = new SimpleStorage();
        vm.startPrank(owner);
        simpleStorage.set(123);
        vm.stopPrank();
    }

    function testSetByOwner() public {
        uint256 newValue = 456;
        vm.startPrank(owner);
        simpleStorage.set(newValue);
        assertEq(simpleStorage.get(), newValue);
        vm.stopPrank();
    }

    function testFailSetByNonOwner() public {
        vm.startPrank(nonOwner);
        simpleStorage.set(789); // This should fail
        vm.stopPrank();
    }

    function testOnlyOwnerModifier() public {
        vm.startPrank(owner);
        simpleStorage.set(123); // Should succeed
        vm.stopPrank();

        vm.startPrank(nonOwner);
        vm.expectRevert("Only owner can set value");
        simpleStorage.set(123); // Should revert
        vm.stopPrank();
    }
}
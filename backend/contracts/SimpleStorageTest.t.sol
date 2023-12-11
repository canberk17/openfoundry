// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/SimpleStorage.sol";

contract SimpleStorageTest is Test {
    SimpleStorage simpleStorage;
    address nonOwner = address(0x1234);

    function setUp() public {
        simpleStorage = new SimpleStorage();
    }

    function testSetByOwner() public {
        simpleStorage.set(123);
        assertEq(simpleStorage.get(), 123, "Owner should be able to set value");
    }

    function testFailSetByNonOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        simpleStorage.set(123);
    }

    function testGetAfterSet() public {
        simpleStorage.set(456);
        assertEq(simpleStorage.get(), 456, "Value should be updated to 456");
    }
}
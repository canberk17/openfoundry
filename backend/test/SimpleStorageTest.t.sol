// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./src/SimpleStorage.sol";

contract SimpleStorageTest is Test {
    SimpleStorage private simpleStorage;
    address private owner;
    address private nonOwner = address(0x1234);

    function setUp() public {
        owner = address(this);
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
        uint256 setValue = 456;
        simpleStorage.set(setValue);
        uint256 getValue = simpleStorage.get();
        assertEq(getValue, setValue, "Get should return the value set by owner");
    }
}
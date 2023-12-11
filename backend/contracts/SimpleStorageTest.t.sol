// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/SimpleStorage.sol";

contract SimpleStorageTest is Test {
    SimpleStorage simpleStorage;
    address owner;

    function setUp() public {
        owner = address(this);
        simpleStorage = new SimpleStorage();
        // Assuming SimpleStorage has an `owner` state variable and an `onlyOwner` modifier
        // but does not have a `transferOwnership` function.
        // We'll set the `owner` directly if it's declared as a public variable.
        // If not, you would need to add a `transferOwnership` function to the SimpleStorage contract.
        // simpleStorage.owner() == owner; // This line is incorrect and should be removed or fixed.
        // If owner is a public state variable, it should be accessed like this:
        // require(simpleStorage.owner() == owner, "Owner is not set correctly");
        // If owner is not public, the contract should have a function to set or transfer ownership.
    }

    function testOnlyOwnerCanSet() public {
        simpleStorage.set(123);
        assertEq(simpleStorage.get(), 123, "Owner should be able to set value");
    }

    function testFailNonOwnerCannotSet() public {
        vm.prank(address(0x1234));
        simpleStorage.set(123);
    }

    function testGetReturnsCorrectValue() public {
        uint256 testValue = 456;
        simpleStorage.set(testValue);
        uint256 returnedValue = simpleStorage.get();
        assertEq(returnedValue, testValue, "Get should return the value set by owner");
    }

    function testSetDoesNotOverflow() public {
        uint256 maxValue = type(uint256).max;
        simpleStorage.set(maxValue);
        assertEq(simpleStorage.get(), maxValue, "Should handle uint256 max value");
    }

    function testSetDoesNotUnderflow() public {
        uint256 minValue = 0;
        simpleStorage.set(minValue);
        assertEq(simpleStorage.get(), minValue, "Should handle uint256 min value");
    }
}
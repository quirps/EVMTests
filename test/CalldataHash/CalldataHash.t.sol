// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/CalldataHash/CalldataHash.sol"; 

contract CalldataHashTest is Test {
    CalldataHash public calldataHash;

    function setUp() public {
        calldataHash = new CalldataHash();
    }

    /**
     * @notice Tests the gas cost of hashing with abi.encodePacked (memory).
     */
    function test_Gas_HashWithMemory() public {
        calldataHash.hashWithMemory(12345, 67890);
    }

    /**
     * @notice Tests the gas cost of hashing calldata directly with assembly.
     * @dev The gas report will show this is significantly cheaper.
     */
    function test_Gas_HashWithCalldataDirectly() public {
        calldataHash.hashWithCalldataDirectly(12345, 67890);
    }
}

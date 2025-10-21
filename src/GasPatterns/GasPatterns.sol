// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Test 1: Custom Errors vs. Require Strings
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

contract Gas_RequireString {
    // Reverting with a string is expensive because the string
    // data must be stored and returned.
    function test(uint256 a) public pure {
        require(a == 0, "Input must be zero");
    }
}

contract Gas_CustomError {
    // Custom errors are just 4-byte selectors, making them
    // significantly cheaper on the revert path.
    error MustBeZero();

    function test(uint256 a) public pure {
        if (a != 0) {
            revert MustBeZero();
        }
    }
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Test 2: Struct Packing
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

contract Gas_Unpacked {
    // These three variables will occupy three separate 32-byte
    // storage slots because `b` (a uint256) cannot fit in
    // the remaining space of slot 0 with `a`.
    // Slot 0: uint128 a
    // Slot 1: uint256 b
    // Slot 2: uint128 c
    uint128 public a;
    uint256 public b;
    uint128 public c;

    function write() public {
        // This will perform 3 SSTORE operations.
        a = 1;
        b = 2;
        c = 3;
    }
}

contract Gas_Packed {
    // By re-ordering, `a` and `c` are "packed" into a single
    // 32-byte storage slot.
    // Slot 0: uint128 a, uint128 c
    // Slot 1: uint256 b
    uint128 public a;
    uint128 public c;
    uint256 public b;

    function write() public {
        // This will perform only 2 SSTORE operations.
        // The write to `a` and `c` are combined into one.
        a = 1;
        b = 2;
        c = 3;
    }
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Test 3: Caching Storage Variables in Memory
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

contract Gas_StorageCache {
    uint256 public counter = 5;

    // This function performs 10 SLOAD operations.
    // Each `counter` access inside the loop is a cold
    // (2100 gas) or warm (100 gas) storage read.
    function inefficientSum() public view returns (uint256 sum) {
        for (uint256 i = 0; i < 10; i++) {
            sum += counter;
        }
    }

    // This function performs only 1 SLOAD operation.
    // The value is "cached" in a memory variable, and
    // subsequent accesses (MLOAD) are extremely cheap (3 gas).
    function efficientSum() public view returns (uint256 sum) {
        uint256 _counter = counter; // 1 SLOAD
        for (uint256 i = 0; i < 10; i++) {
            sum += _counter; // 10 MLOADs
        }
    }
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Test 4: Calldata vs. Memory
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

contract Gas_DataLocation {
    // Using `memory` forces the EVM to copy the array from
    // calldata into memory. This `calldatacopy` operation
    // costs gas proportional to the size of the array.
    function sumWithMemory(uint256[] memory data)
        external
        pure
        returns (uint256 sum)
    {
        uint256 len = data.length;
        for (uint256 i = 0; i < len; i++) {
            sum += data[i];
        }
    }

    // Using `calldata` (only available for `external` functions)
    // reads directly from the transaction's input data,
    // avoiding the expensive copy to memory.
    function sumWithCalldata(uint256[] calldata data)
        external
        pure
        returns (uint256 sum)
    {
        uint256 len = data.length;
        for (uint256 i = 0; i < len; i++) {
            sum += data[i];
        }
    }
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Test 5: Unchecked Math
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

contract Gas_Unchecked {
    // The default Solidity compiler (>=0.8.0) adds checks
    // for overflow/underflow on every arithmetic operation.
    // `i++` is actually `i = i + 1` with a check.
    function checkedLoop() public pure returns (uint256 sum) {
        for (uint256 i = 0; i < 100; i++) {
            sum += i;
        }
    }

    // When we are *certain* an operation cannot over/underflow
    // (like a loop counter we know won't exceed 2^256),
    // we can use `unchecked` to save the gas from those checks.
    function uncheckedLoop() public pure returns (uint256 sum) {
        unchecked {
            for (uint256 i = 0; i < 100; i++) {
                sum += i;
            }
        }
    }
}
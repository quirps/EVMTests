// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/GasPatterns/GasPatterns.sol"; 
contract GasTest is Test {
    
    // --- Test 1: Custom Errors vs. Require Strings ---
    // Hypothesis: The revert path for custom errors will be
    // significantly cheaper. The success path will be similar.

    function test_Gas_RequireString_Revert() public {
        Gas_RequireString g = new Gas_RequireString();
        vm.expectRevert(bytes("Input must be zero"));
        g.test(1);
    }

    function test_Gas_CustomError_Revert() public {
        Gas_CustomError g = new Gas_CustomError();
        vm.expectRevert(Gas_CustomError.MustBeZero.selector);
        g.test(1);
    }

    function test_Gas_RequireString_Success() public {
        new Gas_RequireString().test(0);
    }

    function test_Gas_CustomError_Success() public {
        new Gas_CustomError().test(0);
    }

    // --- Test 2: Struct Packing ---
    // Hypothesis: Writing to the packed struct will be
    // cheaper due to fewer SSTORE operations.

    function test_Gas_UnpackedStructWrite() public {
        new Gas_Unpacked().write();
    }

    function test_Gas_PackedStructWrite() public {
        new Gas_Packed().write();
    }

    // --- Test 3: Caching Storage Variables ---
    // Hypothesis: Caching the `counter` variable in memory
    // will be much cheaper than reading from storage in a loop.
    
    Gas_StorageCache public g_cache;

    function setUp() public {
        g_cache = new Gas_StorageCache();
    }

    function test_Gas_InefficientStorageSum() public view {
        g_cache.inefficientSum();
    }

    function test_Gas_EfficientMemorySum() public view {
        g_cache.efficientSum();
    }

    // --- Test 4: Calldata vs. Memory ---
    // Hypothesis: Using `calldata` for a large array
    // argument will be much cheaper than `memory`.
    
    Gas_DataLocation public g_data;
    uint256[] public testArray;

    constructor() {
        g_data = new Gas_DataLocation();
        
        // Create a large-ish array to test with
        testArray = new uint256[](100);
        for (uint256 i = 0; i < 100; i++) {
            testArray[i] = i;
        }
    }

    function test_Gas_SumWithMemory() public  {
        // This test is slightly different; we can't use
        // the state variable `testArray` in a pure context.
        // We re-create it here. The gas difference will
        // still be dominated by the calldata vs memory copy.
        uint256[] memory localArray = new uint256[](100);
        for (uint256 i = 0; i < 100; i++) {
            localArray[i] = i;
        }

        new Gas_DataLocation().sumWithMemory(localArray); 
    }

    function test_Gas_SumWithCalldata() public  {
        uint256[] memory localArray = new uint256[](100);
        for (uint256 i = 0; i < 100; i++) {
            localArray[i] = i;
        }

        new Gas_DataLocation().sumWithCalldata(localArray);
    }


    // --- Test 5: Unchecked Math ---
    // Hypothesis: The loop using `unchecked` will be
    // cheaper per-iteration, adding up to a noticeable
    // saving over 100 iterations.

    function test_Gas_CheckedLoop() public  {
        new Gas_Unchecked().checkedLoop();
    }

    function test_Gas_UncheckedLoop() public  {
        new Gas_Unchecked().uncheckedLoop();
    }
    function test_Gas_UncheckedLoop_Counter() public  {
        new Gas_Unchecked().uncheckedLoopCounter();
    }
}
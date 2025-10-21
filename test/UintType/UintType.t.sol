// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/UintType/UintType.sol"; 

contract MemoryGasTest is Test {
    MemoryGas public memoryGas;

    function setUp() public {
        memoryGas = new MemoryGas();
    }

    /**
     * @notice Tests the gas cost of the sumWithUint256 function.
     * Forge's gas reporter will pick this up as a test case.
     */
    function test_Gas_SumWithUint256() public {
        uint256 iterations = 100;
        memoryGas.sumWithUint256(iterations);
    }

    /**
     * @notice Tests the gas cost of the sumWithUint32 function.
     * This will appear as a separate entry in the gas report.
     */
    function test_Gas_SumWithUint32() public {
        // The input parameter must still be uint256 as the function expects it.
        uint256 iterations = 100;
        memoryGas.sumWithUint32(iterations);
    }
}


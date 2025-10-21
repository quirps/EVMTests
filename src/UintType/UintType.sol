// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MemoryGas
 * @notice This contract demonstrates the gas difference between using uint256
 * and smaller integer types (like uint32) for operations in memory.
 * The EVM operates on 256-bit words, so using smaller types for local
 * variables requires extra casting operations, making them less gas-efficient.
 */
contract MemoryGas {
    /**
     * @notice Calculates a sum using a loop with a uint256 local variable.
     * @param iterations The number of times to loop.
     * @return total The final calculated sum.
     */
    function sumWithUint256(uint256 iterations) public pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < iterations; i++) {
            // This is the EVM's native word size.
            // Operations are direct and efficient.
            uint256 valueToAdd = 5;
            total += valueToAdd;
        }
        return total;
    }

    /**
     * @notice Calculates a sum using a loop with a uint32 local variable.
     * @param iterations The number of times to loop.
     * @return total The final calculated sum.
     */
    function sumWithUint32(uint256 iterations) public pure returns (uint32) {
        uint32 total = 0;
        for (uint256 i = 0; i < iterations; i++) {
            // Using a smaller type requires the EVM to perform
            // extra masking/casting operations to ensure the value
            // fits within 32 bits, which costs additional gas.
            uint32 valueToAdd = 5;
            total += valueToAdd;
        }
        return total;
    }
}


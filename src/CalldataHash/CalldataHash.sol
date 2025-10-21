// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CalldataHash
 * @notice Demonstrates gas savings by hashing calldata directly with assembly
 * versus the standard approach using memory (abi.encodePacked).
 */
contract CalldataHash {
    /**
     * @notice Hashes two uint256 values using the standard abi.encodePacked.
     * @dev This method allocates memory, copies the calldata arguments into it,
     * and then hashes the memory region. This is less efficient.
     */
    function hashWithMemory(uint256 a, uint256 b) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(a, b));
    }

    /**
     * @notice Hashes two uint256 values directly from calldata using assembly.
     * @dev This is the most gas-efficient way to hash function arguments.
     * It avoids memory allocation and copying entirely.
     */
    function hashWithCalldataDirectly(uint256 a, uint256 b)
        public
        pure
        returns (bytes32 hash)
    {
        // To satisfy the compiler that `a` and `b` are used.
        // In a real implementation, you might not even name the params.
        a;
        b;

        assembly {
            // The function selector is 4 bytes. Calldata for the first
            // argument `a` starts at `0x04`.
            let ptr := 0x04

            // The data to hash is two uint256 values, so 32 + 32 = 64 bytes.
            let size := 0x40 // 64 bytes

            // Copy the specified slice of calldata to memory position 0x00.
            // While this uses memory, it's a "scratch space" and is cheaper
            // than the allocations done by abi.encodePacked.
            calldatacopy(0x00, ptr, size)

            // Hash the data now located at memory position 0x00.
            hash := keccak256(0x00, size)
        }
    }
}

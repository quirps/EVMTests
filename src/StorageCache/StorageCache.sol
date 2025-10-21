// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title StorageCache
 * @notice Demonstrates gas savings by caching a storage variable on the stack.
 */
contract StorageCache {
    uint256 public counter = 10;

    /**
     * @notice Reads directly from storage multiple times.
     * @dev This function will perform multiple SLOAD operations, making it expensive.
     * The first SLOAD is a "cold" access (~2100 gas), subsequent ones are "warm" (~100 gas).
     */
    function readFromStorageDirectly() public view returns (uint256) {
        uint256 val1 = counter;
        uint256 val2 = counter;
        uint256 val3 = counter;
        return val1 + val2 + val3;
    }

    /**
     * @notice Caches the storage variable on the stack first.
     * @dev This function performs only one SLOAD operation. Subsequent reads of
     * `cachedCounter` are cheap DUP operations on the stack.
     */
    function readFromStorageWithCache() public view returns (uint256) {
        uint256 cachedCounter = counter; // SLOAD once, place on stack
        uint256 val1 = cachedCounter;
        uint256 val2 = cachedCounter;
        uint256 val3 = cachedCounter;
        return val1 + val2 + val3;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/StorageCache/StorageCache.sol";

contract StorageCacheTest is Test {
    StorageCache public storageCache;

    function setUp() public {
        storageCache = new StorageCache();
    }

    /**
     * @notice Tests the gas cost of reading from storage directly.
     */
    function test_Gas_ReadFromStorageDirectly() public view {
        storageCache.readFromStorageDirectly();
    }

    /**
     * @notice Tests the gas cost of caching the storage variable first.
     * @dev This test will show a significantly lower gas cost in the report.
     */
    function test_Gas_ReadFromStorageWithCache() public view {
        storageCache.readFromStorageWithCache();
    }
}

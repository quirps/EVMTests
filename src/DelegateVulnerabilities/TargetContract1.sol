// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title TargetContract1 (DeployedContract1)
 * @dev Constructor writes to its own storage slot 0.
 */
contract TargetContract1 {
    
    // This is TargetContract1's storage slot 0
    uint256 public myStorageSlot0;

    /**
     * @dev Constructor for Test 1 (Storage Clash).
     * It writes a value to its *own* storage (slot 0).
     */
    constructor(uint256 valueToSet) {
        myStorageSlot0 = valueToSet;
    }
}
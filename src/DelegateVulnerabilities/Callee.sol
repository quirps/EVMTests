// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./TargetContract1.sol";
import "./TargetContract2.sol";

/**
 * @title Callee (Contract B)
 * @dev This contract's code is executed in the context of Contract A
 * via delegatecall. It contains the CREATE2 logic.
 */
contract Callee {
    
    // This is Callee's storage slot 0
    // When delegatecalled, it maps to the *caller's* (A's) storage slot 0
    uint256 public storageSlot0;

    /**
     * @dev Test 1: Deploys TargetContract1 (Storage Test).
     * This function writes to storageSlot0 to prove it's
     * operating in the caller's (A's) context.
     */
    function deployStorageContract(bytes32 salt, uint256 valueToSet) public {
        // This write will happen in the CALLER's storage (A's storage)
        storageSlot0 = 111;

        // Deploy C1. Its constructor runs in C1's *own* context.
        new TargetContract1{salt: salt}(valueToSet);

        // This write *also* happens in A's context, overwriting the '111'
        storageSlot0 = 222;
    }

    /**
     * @dev Test 2: Deploys TargetContract2 (Loop Test).
     * The TargetContract2's constructor will immediately call back
     * into this contract, attempting a recursive deployment.
     */
    function deployLoopContract(bytes32 salt) public {
        // We want C2's constructor to call this *same function*
        bytes memory callbackData = abi.encodeWithSelector(
            this.deployLoopContract.selector,
            salt
        );

        // address(this) is A's address (due to delegatecall)
        address callbackTarget = address(this);

        // Deploy C2
        // C2's constructor will call A.deployLoopContract(salt)
        // A will delegatecall B.deployLoopContract(salt)
        // B will try to create2 *again* with the same salt.
        // This second create2 will revert.
        new TargetContract2{salt: salt}(callbackTarget, callbackData);
    }
}
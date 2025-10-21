// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title TargetContract2 (DeployedContract2)
 * @dev Constructor calls back to the deployer to test reentrancy.
 */
contract TargetContract2 {
    
    /**
     * @dev Constructor for Test 2 (Reentrancy Loop).
     * It immediately calls back to the 'callbackTarget' (which will be
     * the test contract A), passing 'data' (which will be the selector
     * to re-run the deployment).
     */
    constructor(address callbackTarget, bytes memory data) {
        // Call back to the original caller (A)
        // This call will re-trigger the delegatecall chain.
        (bool success, ) = callbackTarget.call(data);
        
        // This 'require' is what will fail in Test 2,
        // because the 'call' will revert on the second create2 attempt.
        require(success, "Callback failed");
    }
}
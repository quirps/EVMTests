// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/DelegateVulnerabilities/Callee.sol";
import "../../src/DelegateVulnerabilities/TargetContract1.sol";
import "../../src/DelegateVulnerabilities/TargetContract2.sol"; 

/**
 * @title DelegateCallCreate2Test (Contract A)
 * @dev This is the test contract that initiates the delegatecall.
 */
contract DelegateCallCreate2Test is Test {
    
    Callee public callee;

    // This is DelegateCallCreate2Test's (A's) storage slot 0
    // It shares the same slot as Callee.storageSlot0
    uint256 public storageSlot0;

    function setUp() public {
        // Deploy B (Callee)
        callee = new Callee();
        // Set A's (this contract's) initial storage
        storageSlot0 = 1;
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Test 1: Storage Clash
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    /**
     * @dev Tests if C1's constructor (called from B's delegatecall)
     * writes to A's storage.
     *
     * @notice Expected Outcome:
     * 1. A.storageSlot0 *is* modified by B's code (to 222).
     * 2. C1's constructor writes to C1.myStorageSlot0 (to 999).
     * 3. A's storage and C1's storage do *not* clash.
     */
    function test_DelegateCall_Create2_StorageClash() public {
        bytes32 salt = keccak256("test1");
        uint256 valueToSetInC1 = 999;
        uint256 initialValueInA = storageSlot0;

        // 1. Get the predicted address for C1
        bytes memory bytecode = abi.encodePacked(
            type(TargetContract1).creationCode,
            abi.encode(valueToSetInC1)
        );
        // We use `address(this)` as the deployer, because that's the
        // context `create2` will be run in via delegatecall.
        address c1Address = vm.computeCreate2Address(salt, keccak256(bytecode), address(this));

        // 2. We delegatecall Callee (B)
        // B's code will run in *this* contract's context (A)
        (bool success, ) = address(callee).delegatecall(
            abi.encodeWithSelector(
                Callee.deployStorageContract.selector,
                salt,
                valueToSetInC1
            )
        );
        require(success, "Delegatecall failed");

        // --- Assertions ---

        // 3. Check A's storage (this contract)
        // B's `deployStorageContract` *did* write to slot 0.
        // It should be 222, not the initial 1.
        assertEq(storageSlot0, valueToSetInC1, "A's storage (slot 0) was not updated by delegatecall");
        assertNotEq(storageSlot0, initialValueInA, "A's storage should have changed");

        // 4. Check C1's storage (the new contract)
        // Check if C1 was deployed
        assertTrue(c1Address.code.length > 0, "C1 was not deployed");

        // Check C1's storage
        TargetContract1 c1 = TargetContract1(c1Address);
        assertEq(c1.myStorageSlot0(), valueToSetInC1, "C1's storage (slot 0) was not set by its constructor");

        // 5. The main point: C1's write did *not* affect A's storage.
        assertNotEq(storageSlot0, c1.myStorageSlot0(), "A and C1 storage clashed!");
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Test 2: Recursive Loop
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    /**
     * @dev Tests what happens when C2's constructor calls back
     * into the function that deployed it.
     *
     * @notice Expected Outcome:
     * The transaction MUST REVERT.
     * 1. A delegatecalls B.deployLoopContract(salt)
     * 2. B (in A's context) deploys C2 using create2(salt)
     * 3. C2's constructor runs
     * 4. C2's constructor calls A.deployLoopContract(salt)
     * 5. A delegatecalls B.deployLoopContract(salt) *again*
     * 6. B (in A's context) tries to deploy C2 using create2(salt) *again*
     * 7. create2 *reverts* because an account already exists at that address.
     * 8. The revert bubbles up to C2's constructor's `require(success, ...)` line.
     */
    function test_DelegateCall_Create2_ReentrancyLoop() public {
        bytes32 salt = keccak256("test2");

        // We expect this to REVERT with the message from C2's constructor.
        vm.expectRevert(bytes("Callback failed"));

        address(callee).delegatecall(
            abi.encodeWithSelector(
                Callee.deployLoopContract.selector,
                salt
            )
        );
    }
}
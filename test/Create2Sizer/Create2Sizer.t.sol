// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/Create2Sizer/Create2Sizer.sol"; 

contract Create2SizerTest is Test {
    ContractSizer public sizer;
    Deployer public deployer;

    function setUp() public {
        // 1. Deploy the helper contracts
        sizer = new ContractSizer();
        deployer = new Deployer(address(sizer));
    }

    function test_ConstructorCompletesBeforeRuntimeBytecodeIsSet() public {
        bytes32 salt = keccak256(abi.encodePacked("my-unique-salt", block.timestamp));

        // --- Predict the address before deployment ---
        bytes memory bytecode = deployer.getBytecode(address(sizer));
        address predictedAddress = deployer.getAddress(bytecode, salt);

        // --- Check size *before* deployment ---
        uint256 sizeBefore = sizer.getSize(predictedAddress);
        assertEq(sizeBefore, 0, "Size before deployment should be 0");

        // --- Log the predicted address for clarity ---
        console.log("Predicted Address:", predictedAddress);

        // --- Execute the deployment ---
        vm.prank(address(this));
        deployer.deploy(salt);
        
        // --- Get the results stored in the Deployer contract ---
        
        // This is the size measured *inside* DeployedContract's constructor
        uint256 sizeInConstructor = deployer.sizeFromDeployedContract();
        
        // This is the size measured *after* the constructor finished
        uint256 sizeAfterConstructor = deployer.sizeAfterConstructor();

        // --- Log the results ---
        console.log("Size measured *in* constructor:", sizeInConstructor);
        console.log("Size measured *after* constructor:", sizeAfterConstructor);

        // --- THE CORE ASSERTIONS ---

        // 1. The size *during* construction MUST be 0, because the runtime
        //    bytecode is not yet associated with the address in the EVM state.
        assertEq(sizeInConstructor, 0, "Size *in* constructor should be 0");

        // 2. The size *after* construction MUST be greater than 0,
        //    as the constructor has completed and returned the runtime bytecode.
        assertTrue(sizeAfterConstructor > 0, "Size *after* constructor should be > 0");

        // 3. Sanity check: the address deployed should match the prediction
        assertEq(deployer.lastDeployedAddress(), predictedAddress, "Deployed address mismatch");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ContractSizer
 * @notice A simple utility contract to measure the bytecode size of any address.
 */
contract ContractSizer {
    /**
     * @notice Gets the runtime bytecode size of a given address.
     * @param _addr The address to check.
     * @return The size of the code at _addr.
     */
    function getSize(address _addr) public view returns (uint256) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(0x00, extcodesize(_addr))
            return(0x00, 0x20)
        }
    }
}

/**
 * @title DeployedContract
 * @notice This is the contract that will be deployed via CREATE2.
 * Its constructor will immediately try to measure its own bytecode size.
 */
contract DeployedContract {
    // This will store the size of this contract's address *during* its own construction
    uint256 public sizeInConstructor;
    
    /**
     * @notice When deployed, this constructor immediately calls the Sizer
     * contract to get its own codesize.
     * @param _sizerAddress The address of the ContractSizer.
     */
    constructor(address _sizerAddress) {
        ContractSizer sizer = ContractSizer(_sizerAddress);
        // This is the key part: we measure our *own* size.
        // At this point in execution, the constructor is running,
        // but the runtime bytecode has not yet been placed in state.
        sizeInConstructor = sizer.getSize(address(this));
    }
}


/**
 * @title Deployer
 * @notice This contract uses CREATE2 to deploy an instance of DeployedContract.
 * It coordinates the entire experiment.
 */
contract Deployer {
    ContractSizer public sizer;
    address public lastDeployedAddress;
    
    // The size measured *during* construction (fetched from the child)
    uint256 public sizeFromDeployedContract;
    
    // The size measured *after* construction
    uint256 public sizeAfterConstructor;

    event Deployed(address indexed deployedAddress, uint256 sizeIn, uint256 sizeAfter);

    constructor(address _sizerAddress) {
        sizer = ContractSizer(_sizerAddress);
    }

    /**
     * @notice Gets the creation bytecode for DeployedContract, including constructor args.
     */
    function getBytecode(address _sizerAddress) public pure returns (bytes memory) {
        // This packs the creation bytecode of DeployedContract with its
        // single constructor argument (_sizerAddress).
        return abi.encodePacked(
            type(DeployedContract).creationCode,
            abi.encode(_sizerAddress)
        );
    }

    /**
     * @notice Predicts the CREATE2 address for a given salt.
     */
    function getAddress(bytes memory bytecode, bytes32 salt) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), // CREATE2 prefix
                address(this), // Deployer's address
                salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    /**
     * @notice Deploys DeployedContract using CREATE2 and records the sizes.
     * @param salt A unique salt for the deployment.
     */
    function deploy(bytes32 salt) public {
        bytes memory bytecode = getBytecode(address(sizer));
        address predictedAddress = getAddress(bytecode, salt);

        // 1. --- DEPLOY VIA CREATE2 ---
        address deployedAddress;
        assembly {
            deployedAddress := create2(
                0, // value
                add(bytecode, 0x20), // memory offset (skip length)
                mload(bytecode), // size
                salt
            )
        }
        
        require(deployedAddress != address(0), "Deploy failed");
        require(deployedAddress == predictedAddress, "Address mismatch");
        
        lastDeployedAddress = deployedAddress;

        // 2. --- GET SIZE *AFTER* CONSTRUCTOR ---
        // Now that create2() has returned, the constructor is finished
        // and the runtime bytecode is in state.
        sizeAfterConstructor = sizer.getSize(deployedAddress);

        // 3. --- GET SIZE *DURING* CONSTRUCTOR ---
        // Fetch the value that DeployedContract recorded during its construction.
        DeployedContract deployed = DeployedContract(deployedAddress);
        sizeFromDeployedContract = deployed.sizeInConstructor();

        emit Deployed(deployedAddress, sizeFromDeployedContract, sizeAfterConstructor);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MembershipNFT} from "../src/MembershipNFT.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
 * @title UpgradeMembershipNFT
 * @notice Upgrades the MembershipNFT proxy to a new implementation with auto-delegation on mint
 * @dev Run with: forge script script/UpgradeMembershipNFT.s.sol:UpgradeMembershipNFT --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
 */
contract UpgradeMembershipNFT is Script {
    // Proxy address (from CONTRACT_ADDRESSES.md)
    address constant MEMBERSHIP_PROXY = 0x308bFFa77D93a7c37225De5bcEA492E95293DF29;
    
    // ERC-1967 implementation slot
    bytes32 constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function run() external {
        uint256 deployerKey = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.addr(deployerKey);

        console.log("Deployer:", deployer);
        console.log("Proxy address:", MEMBERSHIP_PROXY);

        vm.startBroadcast(deployerKey);

        // Get current implementation address from storage slot
        bytes32 slotValue = vm.load(MEMBERSHIP_PROXY, IMPLEMENTATION_SLOT);
        address currentImplementation = address(uint160(uint256(slotValue)));
        console.log("Current implementation:", currentImplementation);

        // Deploy new implementation
        console.log("Deploying new MembershipNFT implementation...");
        MembershipNFT newImplementation = new MembershipNFT();
        console.log("New implementation deployed at:", address(newImplementation));

        // Get the proxy instance and cast to UUPSUpgradeable
        UUPSUpgradeable proxy = UUPSUpgradeable(MEMBERSHIP_PROXY);

        // Upgrade the proxy (using upgradeToAndCall with empty data)
        console.log("Upgrading proxy to new implementation...");
        proxy.upgradeToAndCall(address(newImplementation), "");
        console.log("Upgrade completed!");

        // Verify the upgrade by reading storage slot again
        bytes32 newSlotValue = vm.load(MEMBERSHIP_PROXY, IMPLEMENTATION_SLOT);
        address newImplementationAddress = address(uint160(uint256(newSlotValue)));
        console.log("New implementation address:", newImplementationAddress);
        require(
            newImplementationAddress == address(newImplementation),
            "Upgrade verification failed"
        );
        console.log("Upgrade verified successfully!");

        vm.stopBroadcast();
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

/**
 * @title UpgradeMembershipNFT
 * @notice Upgrades the MembershipNFT proxy to a new implementation using OpenZeppelin Foundry Upgrades plugin.
 * @dev Recommended: Use the convenience script: ./script/upgrade-membership.sh (or VERIFY=true ./script/upgrade-membership.sh)
 * @dev Manual: forge script script/UpgradeMembershipNFT.s.sol:UpgradeMembershipNFT --rpc-url $SEPOLIA_RPC_URL --broadcast --sender <PROXY_OWNER> --verify -vvvv
 * @dev Note: Use --sender flag with an address that owns the proxy (has UPGRADER_ROLE or is the proxy admin)
 * @dev Note: Run 'forge clean' before upgrading to ensure fresh build artifacts for validation
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

        // Upgrade the proxy using the Upgrades plugin
        // Empty string "" means no additional call during upgrade
        //
        // Note: If the new contract has @custom:oz-upgrades-from annotation,
        // the plugin will automatically detect the reference contract.
        // Otherwise, uncomment the Options below to specify it manually:
        //
        // Options memory opts;
        // opts.referenceContract = "src/MembershipNFT.sol:MembershipNFT";
        // Upgrades.upgradeProxy(MEMBERSHIP_PROXY, "src/MembershipNFTV2.sol:MembershipNFTV2", "", opts);
        console.log("Upgrading proxy to new MembershipNFT implementation...");
        Upgrades.upgradeProxy(MEMBERSHIP_PROXY, "src/MembershipNFT.sol:MembershipNFT", "");
        console.log("Upgrade completed!");

        // Verify the upgrade by reading storage slot again
        bytes32 newSlotValue = vm.load(MEMBERSHIP_PROXY, IMPLEMENTATION_SLOT);
        address newImplementationAddress = address(uint160(uint256(newSlotValue)));
        console.log("New implementation address:", newImplementationAddress);
        require(
            newImplementationAddress != currentImplementation,
            "Upgrade verification failed: implementation address unchanged"
        );
        console.log("Upgrade verified successfully!");

        vm.stopBroadcast();
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Options} from "openzeppelin-foundry-upgrades/Options.sol";

/**
 * @title UpgradeConstitution
 * @notice Upgrades the Constitution proxy to ConstitutionV2 with enumerable allowed recipients
 * @dev Recommended: Use the convenience script: ./script/upgrade-constitution.sh
 * @dev Manual: forge script script/UpgradeConstitution.s.sol:UpgradeConstitution --rpc-url $SEPOLIA_RPC_URL --broadcast --sender <PROXY_OWNER> -vvvv
 * @dev Note: Use --sender flag with an address that owns the proxy (has DEFAULT_ADMIN_ROLE)
 * @dev Note: Run 'forge clean' before upgrading to ensure fresh build artifacts for validation
 */
contract UpgradeConstitution is Script {
    // Proxy address (from CONTRACT_ADDRESSES.md)
    address constant CONSTITUTION_PROXY = 0x931E702cfdda455f77dAdD55F79D561588FbcD05;

    function run() external {
        uint256 deployerKey = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.addr(deployerKey);

        console.log("Deployer:", deployer);
        console.log("Proxy address:", CONSTITUTION_PROXY);

        vm.startBroadcast(deployerKey);

        console.log("Upgrading proxy to ConstitutionV2...");
        // Upgrade the proxy using the Upgrades plugin
        // The @custom:oz-upgrades-from annotation in ConstitutionV2 will be detected automatically
        Options memory opts;
        opts.referenceContract = "Constitution.sol:Constitution";
        Upgrades.upgradeProxy(CONSTITUTION_PROXY, "ConstitutionV2.sol:ConstitutionV2", "", opts);
        
        console.log("Upgrade completed!");
        console.log("Next step: Call migrateAllowedRecipients() to populate the enumerable list");
        console.log("Use script/MigrateAllowedRecipients.s.sol or call directly on the proxy");

        vm.stopBroadcast();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

/**
 * @title UpgradeDAOGovernor
 * @notice Upgrades the DAOGovernor proxy to the latest implementation using OpenZeppelin Foundry Upgrades plugin.
 * @dev Recommended: Use the convenience script: ./script/upgrade-governor.sh
 * @dev Manual: forge script script/UpgradeDAOGovernor.s.sol:UpgradeDAOGovernor --rpc-url $SEPOLIA_RPC_URL --broadcast --sender <PROXY_OWNER> -vvvv
 * @dev Note: Use --sender flag with an address that owns the proxy (has UPGRADER_ROLE or is the proxy admin)
 * @dev Note: Run 'forge clean' before upgrading to ensure fresh build artifacts for validation
 */
contract UpgradeDAOGovernor is Script {
    // Proxy address (from CONTRACT_ADDRESSES.md)
    address constant GOVERNOR_PROXY = 0xa2e4e3082BEf648D3e996E96A849Dd1D3EF952f1;

    function run() external {
        uint256 deployerKey = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.addr(deployerKey);

        console.log("Deployer:", deployer);
        console.log("Proxy address:", GOVERNOR_PROXY);

        vm.startBroadcast(deployerKey);

        console.log("Upgrading proxy to new DAOGovernor implementation...");
        // Upgrade the proxy using the Upgrades plugin
        // Empty string "" means no additional call during upgrade
        // 
        // Note: If the new contract has @custom:oz-upgrades-from annotation,
        // the plugin will automatically detect the reference contract.
        // Otherwise, uncomment the Options below to specify it manually:
        //
        // Options memory opts;
        // opts.referenceContract = "src/DAOGovernor.sol:DAOGovernor";
        // Upgrades.upgradeProxy(GOVERNOR_PROXY, "src/DAOGovernorV2.sol:DAOGovernorV2", "", opts);
        Upgrades.upgradeProxy(GOVERNOR_PROXY, "src/DAOGovernor.sol:DAOGovernor", "");
        console.log("Upgrade completed!");

        vm.stopBroadcast();
    }
}

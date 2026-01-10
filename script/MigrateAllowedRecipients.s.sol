// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ConstitutionV2} from "../src/ConstitutionV2.sol";

/**
 * @title MigrateAllowedRecipients
 * @notice Helper script to migrate existing allowed recipients to the enumerable list
 * @dev After upgrading Constitution to V2, call this to populate the enumerable list
 * @dev Usage: forge script script/MigrateAllowedRecipients.s.sol:MigrateAllowedRecipients --rpc-url $SEPOLIA_RPC_URL --broadcast --sender <ADMIN> -vvvv
 */
contract MigrateAllowedRecipients is Script {
    address constant CONSTITUTION_PROXY = 0x931E702cfdda455f77dAdD55F79D561588FbcD05;

    function run() external {
        uint256 deployerKey = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.addr(deployerKey);

        console.log("Deployer:", deployer);
        console.log("Constitution proxy:", CONSTITUTION_PROXY);

        vm.startBroadcast(deployerKey);

        ConstitutionV2 constitution = ConstitutionV2(CONSTITUTION_PROXY);

        // List of existing allowed recipients to migrate
        // These should be addresses that are currently allowed (isRecipientAllowed = true)
        address[] memory recipients = new address[](1);
        recipients[0] = 0x5bAdf5882cE7c088E77A71ED15DACBaa08E0660F; // Currently allowed recipient

        console.log("Migrating", recipients.length, "recipient(s)...");
        constitution.migrateAllowedRecipients(recipients);
        
        uint256 count = constitution.getAllowedRecipientsCount();
        console.log("Migration complete! Total allowed recipients:", count);

        vm.stopBroadcast();
    }
}

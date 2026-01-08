// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {
    TimelockControllerUpgradeable
} from "@openzeppelin/contracts-upgradeable/governance/TimelockControllerUpgradeable.sol";

/**
 * @title GrantProposerRole
 * @notice Script to grant PROPOSER_ROLE to DAOGovernor on TimelockController
 */
contract GrantProposerRole is Script {
    // TimelockController address on Sepolia
    address constant TIMELOCK = 0x6dfc323b65eE7D48f7913892Ff9d9B73436d2942;
    
    // DAOGovernor proxy address on Sepolia
    address constant GOVERNOR = 0xa2e4e3082BEf648D3e996E96A849Dd1D3EF952f1;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        TimelockControllerUpgradeable timelock = TimelockControllerUpgradeable(payable(TIMELOCK));
        
        bytes32 PROPOSER_ROLE = timelock.PROPOSER_ROLE();
        bytes32 CANCELLER_ROLE = timelock.CANCELLER_ROLE();
        
        // Check current status
        bool hasProposerRole = timelock.hasRole(PROPOSER_ROLE, GOVERNOR);
        bool hasCancellerRole = timelock.hasRole(CANCELLER_ROLE, GOVERNOR);
        
        console.log("Current status:");
        console.log("Governor has PROPOSER_ROLE:", hasProposerRole);
        console.log("Governor has CANCELLER_ROLE:", hasCancellerRole);
        
        if (!hasProposerRole) {
            console.log("Granting PROPOSER_ROLE to Governor...");
            timelock.grantRole(PROPOSER_ROLE, GOVERNOR);
            console.log("PROPOSER_ROLE granted!");
        } else {
            console.log("Governor already has PROPOSER_ROLE");
        }
        
        if (!hasCancellerRole) {
            console.log("Granting CANCELLER_ROLE to Governor...");
            timelock.grantRole(CANCELLER_ROLE, GOVERNOR);
            console.log("CANCELLER_ROLE granted!");
        } else {
            console.log("Governor already has CANCELLER_ROLE");
        }
        
        // Verify
        bool hasProposerRoleAfter = timelock.hasRole(PROPOSER_ROLE, GOVERNOR);
        bool hasCancellerRoleAfter = timelock.hasRole(CANCELLER_ROLE, GOVERNOR);
        
        console.log("\nFinal status:");
        console.log("Governor has PROPOSER_ROLE:", hasProposerRoleAfter);
        console.log("Governor has CANCELLER_ROLE:", hasCancellerRoleAfter);
        
        require(hasProposerRoleAfter, "Failed to grant PROPOSER_ROLE");
        require(hasCancellerRoleAfter, "Failed to grant CANCELLER_ROLE");

        vm.stopBroadcast();
    }
}


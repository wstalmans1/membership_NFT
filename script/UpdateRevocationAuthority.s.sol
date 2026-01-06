// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Constitution} from "../src/Constitution.sol";

/**
 * Script to update the revocationAuthority in the Constitution contract.
 * 
 * Usage:
 * 1. Set NEW_REVOCATION_AUTHORITY in .env or modify the address below
 * 2. Run: forge script script/UpdateRevocationAuthority.s.sol:UpdateRevocationAuthority --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
 */
contract UpdateRevocationAuthority is Script {
    // Constitution Proxy address (update if needed)
    address public constant CONSTITUTION_PROXY = 0x931E702cfdda455f77dAdD55F79D561588FbcD05;
    
    // New revocation authority address
    // Option 1: Set via environment variable
    // Option 2: Hardcode your address here
    address public newRevocationAuthority;

    function setUp() public {
        // Try to get from environment variable first
        try vm.envAddress("NEW_REVOCATION_AUTHORITY") returns (address addr) {
            newRevocationAuthority = addr;
        } catch {
            // Fallback: use deployer address
            uint256 deployerKey = vm.envUint("DEPLOYER_KEY");
            newRevocationAuthority = vm.addr(deployerKey);
        }
    }

    function run() external {
        uint256 deployerKey = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.addr(deployerKey);

        console.log("Deployer:", deployer);
        console.log("Constitution Proxy:", CONSTITUTION_PROXY);
        console.log("Current revocationAuthority will be updated to:", newRevocationAuthority);

        vm.startBroadcast(deployerKey);

        Constitution constitution = Constitution(CONSTITUTION_PROXY);

        // Check current revocation authority
        address current = constitution.revocationAuthority();
        console.log("Current revocationAuthority:", current);

        // Update revocation authority
        // Note: This requires GOVERNANCE_ROLE
        constitution.setRevocationAuthority(newRevocationAuthority);

        // Verify update
        address updated = constitution.revocationAuthority();
        console.log("Updated revocationAuthority:", updated);

        require(updated == newRevocationAuthority, "Update failed!");

        vm.stopBroadcast();

        console.log("Successfully updated revocationAuthority!");
    }
}


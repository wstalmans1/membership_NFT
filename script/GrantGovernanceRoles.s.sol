// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {Constitution} from "../src/Constitution.sol";
import {TreasuryExecutor} from "../src/TreasuryExecutor.sol";
import {MembershipNFT} from "../src/MembershipNFT.sol";

/**
 * @title GrantGovernanceRoles
 * @notice Grants timelock the roles required to execute governance actions.
 */
contract GrantGovernanceRoles is Script {
    // Sepolia proxy addresses
    address constant TIMELOCK = 0x6dfc323b65eE7D48f7913892Ff9d9B73436d2942;
    address constant CONSTITUTION = 0x931E702cfdda455f77dAdD55F79D561588FbcD05;
    address constant TREASURY = 0xDD21739Ec074C8C3480C689dDDbA2C7451169F33;
    address constant MEMBERSHIP = 0x308bFFa77D93a7c37225De5bcEA492E95293DF29;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Constitution constitution = Constitution(CONSTITUTION);
        TreasuryExecutor treasury = TreasuryExecutor(payable(TREASURY));
        MembershipNFT membership = MembershipNFT(MEMBERSHIP);

        bytes32 governanceRole = constitution.GOVERNANCE_ROLE();
        bytes32 executorRole = treasury.EXECUTOR_ROLE();
        bytes32 treasuryRole = membership.TREASURY_ROLE();

        if (!constitution.hasRole(governanceRole, TIMELOCK)) {
            console.log("Granting Constitution.GOVERNANCE_ROLE to timelock...");
            constitution.grantRole(governanceRole, TIMELOCK);
        } else {
            console.log("Timelock already has Constitution.GOVERNANCE_ROLE");
        }

        if (!treasury.hasRole(executorRole, TIMELOCK)) {
            console.log("Granting TreasuryExecutor.EXECUTOR_ROLE to timelock...");
            treasury.grantRole(executorRole, TIMELOCK);
        } else {
            console.log("Timelock already has TreasuryExecutor.EXECUTOR_ROLE");
        }

        if (!membership.hasRole(treasuryRole, TIMELOCK)) {
            console.log("Granting MembershipNFT.TREASURY_ROLE to timelock...");
            membership.grantRole(treasuryRole, TIMELOCK);
        } else {
            console.log("Timelock already has MembershipNFT.TREASURY_ROLE");
        }

        vm.stopBroadcast();
    }
}

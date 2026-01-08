// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DAOGovernor} from "../src/DAOGovernor.sol";

/**
 * @title ProposeSetVotingDelay
 * @notice Script to create a governance proposal to set voting delay to zero
 */
contract ProposeSetVotingDelay is Script {
    // DAOGovernor proxy address on Sepolia
    address constant GOVERNOR = 0xa2e4e3082BEf648D3e996E96A849Dd1D3EF952f1;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DAOGovernor governor = DAOGovernor(payable(GOVERNOR));

        // Prepare proposal parameters
        address[] memory targets = new address[](1);
        targets[0] = GOVERNOR;

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory calldatas = new bytes[](1);
        // Encode: setVotingDelay(uint48) with value 0
        calldatas[0] = abi.encodeWithSignature("setVotingDelay(uint48)", uint48(0));

        string memory description = "Set voting delay to zero blocks. This will allow proposals to start voting immediately after creation, without any delay period.";

        // Create the proposal
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        console.log("Proposal created!");
        console.log("Proposal ID:", proposalId);
        console.log("Target:", GOVERNOR);
        console.log("Function: setVotingDelay(uint48)");
        console.log("New Voting Delay: 0 blocks");

        vm.stopBroadcast();
    }
}


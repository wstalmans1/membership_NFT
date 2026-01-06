// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {
    TimelockControllerUpgradeable
} from "@openzeppelin/contracts-upgradeable/governance/TimelockControllerUpgradeable.sol";
import {Constitution} from "../src/Constitution.sol";
import {MembershipNFT} from "../src/MembershipNFT.sol";
import {TreasuryExecutor} from "../src/TreasuryExecutor.sol";
import {DAOGovernor} from "../src/DAOGovernor.sol";

contract Deploy is Script {
    // --- Config: adjust as needed before running ---
    uint256 public minDonationWei = 0.01 ether;
    string public baseUri = "ipfs://base/";
    // NOTE: revocationAuthority is now set in run() function using deployer directly
    // This avoids Foundry's DEFAULT_SENDER issue with state variable initialization
    uint256 public perTxSpendCapWei = 0.1 ether;
    uint256 public epochSpendCapWei = 0.3 ether;
    uint64 public epochDuration = 5 minutes;
    address[] public initialAllowedRecipients;

    // Governor params (blocks)
    uint256 public votingDelay = 1; // blocks
    uint256 public votingPeriod = 20; // 15s blocks
    uint256 public proposalThreshold = 0;
    uint256 public quorumNumerator = 10; // 10% if denominator is 100

    function run() external {
        uint256 deployerKey = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        // Set revocationAuthority to deployer address
        // Using deployer directly instead of msg.sender to avoid Foundry's DEFAULT_SENDER
        // (State variable initialization happens before vm.startBroadcast(), so msg.sender would be DEFAULT_SENDER)
        address revocationAuthority = deployer;
        console.log("Revocation Authority set to:", revocationAuthority);

        // Constitution
        Constitution implConst = new Constitution();
        bytes memory constInit = abi.encodeWithSelector(
            Constitution.initialize.selector,
            deployer,
            minDonationWei,
            baseUri,
            revocationAuthority,
            perTxSpendCapWei,
            epochSpendCapWei,
            epochDuration,
            initialAllowedRecipients
        );
        Constitution constitution = Constitution(address(new ERC1967Proxy(address(implConst), constInit)));

        // TreasuryExecutor
        TreasuryExecutor implTreasury = new TreasuryExecutor();
        bytes memory treasInit =
            abi.encodeWithSelector(TreasuryExecutor.initialize.selector, deployer, address(constitution));
        TreasuryExecutor treasury =
            TreasuryExecutor(payable(address(new ERC1967Proxy(address(implTreasury), treasInit))));

        // TimelockController (non-proxy for simplicity)
        address[] memory proposers = new address[](1);
        proposers[0] = deployer; // will be updated to Governor later
        address[] memory executors = new address[](1);
        executors[0] = address(0); // anyone can execute
        TimelockControllerUpgradeable timelock = new TimelockControllerUpgradeable();
        timelock.initialize(3, proposers, executors, deployer); // minDelay = 3 blocks

        // MembershipNFT
        MembershipNFT implMember = new MembershipNFT();
        bytes memory memInit = abi.encodeWithSelector(
            MembershipNFT.initialize.selector, deployer, payable(address(treasury)), address(constitution)
        );
        MembershipNFT membership = MembershipNFT(address(new ERC1967Proxy(address(implMember), memInit)));

        // Governor with membership token set
        DAOGovernor implGov = new DAOGovernor();
        bytes memory govInit = abi.encodeWithSelector(
            DAOGovernor.initialize.selector,
            membership,
            timelock,
            deployer,
            votingDelay,
            votingPeriod,
            proposalThreshold,
            quorumNumerator
        );
        DAOGovernor governor = DAOGovernor(payable(address(new ERC1967Proxy(address(implGov), govInit))));

        // Log addresses
        console.log("Deployer", deployer);
        console.log("Constitution", address(constitution));
        console.log("TreasuryExecutor", address(treasury));
        console.log("Timelock", address(timelock));
        console.log("Governor", address(governor));
        console.log("MembershipNFT", address(membership));

        vm.stopBroadcast();
    }
}


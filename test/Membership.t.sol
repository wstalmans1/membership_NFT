// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Constitution} from "../src/Constitution.sol";
import {MembershipNFT} from "../src/MembershipNFT.sol";
import {TreasuryExecutor} from "../src/TreasuryExecutor.sol";

contract MembershipTest is Test {
    Constitution private constitution;
    MembershipNFT private membership;
    TreasuryExecutor private treasury;
    address private admin = address(0xA11CE);
    address private treasuryAdmin = address(0xBEEF);
    address private user = address(0x1234);

    uint256 private constant MIN_DONATION = 1 ether;
    string private constant BASE_URI = "ipfs://base/";

    function setUp() public {
        // Deploy Constitution via proxy
        Constitution implConst = new Constitution();
        bytes memory constInit = abi.encodeWithSelector(
            Constitution.initialize.selector,
            admin,
            MIN_DONATION,
            BASE_URI,
            admin,
            5 ether, // perTxCap
            10 ether, // epochCap
            uint64(1 days),
            new address[](0)
        );
        constitution = Constitution(address(new ERC1967Proxy(address(implConst), constInit)));

        // Deploy Treasury via proxy
        TreasuryExecutor implTreasury = new TreasuryExecutor();
        bytes memory treasInit =
            abi.encodeWithSelector(TreasuryExecutor.initialize.selector, treasuryAdmin, address(constitution));
        treasury = TreasuryExecutor(payable(address(new ERC1967Proxy(address(implTreasury), treasInit))));

        // Allow treasury address for spends
        vm.prank(admin);
        constitution.setRecipientAllowed(address(treasury), true);

        // Deploy Membership via proxy
        MembershipNFT implMember = new MembershipNFT();
        bytes memory memInit = abi.encodeWithSelector(
            MembershipNFT.initialize.selector, admin, payable(address(treasury)), address(constitution)
        );
        membership = MembershipNFT(address(new ERC1967Proxy(address(implMember), memInit)));
    }

    function testMintRespectsMinimumDonation() public {
        vm.deal(user, 2 ether);
        vm.prank(user);
        vm.expectRevert("Below minimum donation");
        membership.mint{value: 0.5 ether}();

        vm.prank(user);
        membership.mint{value: MIN_DONATION}();
        assertEq(membership.balanceOf(user), 1, "Mint failed");
    }

    function testMintForwardsToTreasury() public {
        vm.deal(user, 2 ether);
        uint256 beforeBal = address(treasury).balance;
        vm.prank(user);
        membership.mint{value: MIN_DONATION}();
        assertEq(address(treasury).balance - beforeBal, MIN_DONATION, "Treasury did not receive funds");
    }

    function testSoulboundTransferReverts() public {
        vm.deal(user, 2 ether);
        vm.prank(user);
        membership.mint{value: MIN_DONATION}();
        vm.prank(user);
        vm.expectRevert("Soulbound");
        membership.transferFrom(user, address(0xB0B), 1);
    }

    function testSingleMintPerAddress() public {
        vm.deal(user, 3 ether);
        vm.prank(user);
        membership.mint{value: MIN_DONATION}();
        vm.prank(user);
        vm.expectRevert("Already minted");
        membership.mint{value: MIN_DONATION}();
    }

    function testMinDonationUpdatesFromConstitution() public {
        vm.prank(admin);
        constitution.setMinDonationWei(2 ether);

        vm.deal(user, 3 ether);
        vm.prank(user);
        vm.expectRevert("Below minimum donation");
        membership.mint{value: 1 ether}();

        vm.prank(user);
        membership.mint{value: 2 ether}();
        assertEq(membership.balanceOf(user), 1);
    }
}


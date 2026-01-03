// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {
    ERC721VotesUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721VotesUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {IConstitution} from "./interfaces/IConstitution.sol";

contract MembershipNFT is
    Initializable,
    ERC721Upgradeable,
    EIP712Upgradeable,
    ERC721VotesUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuard
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant REVOKER_ROLE = keccak256("REVOKER_ROLE");
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    IConstitution public constitution;
    address payable public treasury;

    uint256 private _tokenIdTracker;
    mapping(address => bool) public hasMinted;

    event MemberMinted(address indexed to, uint256 tokenId, uint256 amountPaid);
    event MemberRevoked(address indexed member, uint256 tokenId);
    event TreasuryUpdated(address indexed treasury);
    event ConstitutionUpdated(address indexed constitution);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin, address payable _treasury, address _constitution) external initializer {
        __ERC721_init("DAO Membership", "DAOM");
        __EIP712_init("DAO Membership", "1");
        __ERC721Votes_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(REVOKER_ROLE, admin);
        _grantRole(TREASURY_ROLE, admin);

        treasury = _treasury;
        constitution = IConstitution(_constitution);

        emit TreasuryUpdated(_treasury);
        emit ConstitutionUpdated(_constitution);
    }

    // --- Minting ---

    function mint() external payable nonReentrant {
        require(!hasMinted[msg.sender], "Already minted");
        uint256 minDonation = constitution.minDonationWei();
        require(msg.value >= minDonation, "Below minimum donation");

        hasMinted[msg.sender] = true;
        _tokenIdTracker++;
        uint256 tokenId = _tokenIdTracker;
        _safeMint(msg.sender, tokenId);

        (bool sent,) = treasury.call{value: msg.value}("");
        require(sent, "Treasury transfer failed");

        emit MemberMinted(msg.sender, tokenId, msg.value);
    }

    // --- Revocation / burn ---

    function revoke(address member) external onlyRole(REVOKER_ROLE) {
        uint256 tokenId = tokenOfOwner(member);
        _burn(tokenId);
        hasMinted[member] = false;
        emit MemberRevoked(member, tokenId);
    }

    // --- Admin updates ---

    function setTreasury(address payable newTreasury) external onlyRole(TREASURY_ROLE) {
        treasury = newTreasury;
        emit TreasuryUpdated(newTreasury);
    }

    function setConstitution(address newConst) external onlyRole(DEFAULT_ADMIN_ROLE) {
        constitution = IConstitution(newConst);
        emit ConstitutionUpdated(newConst);
    }

    // --- Views ---

    function tokenOfOwner(address owner) public view returns (uint256) {
        uint256 balance = balanceOf(owner);
        require(balance > 0, "No token");
        // Only one token per address; iterate small because 1.
        // Loop to find token; cost OK because only one.
        for (uint256 i = 1; i <= _tokenIdTracker; i++) {
            if (_ownerOf(i) != address(0) && ownerOf(i) == owner) {
                return i;
            }
        }
        revert("Token not found");
    }

    // forge-lint: disable-next-line(mixed-case-function)
    function _baseURI() internal view override returns (string memory) {
        return constitution.baseURI();
    }

    // --- Soulbound enforcement ---

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721Upgradeable, ERC721VotesUpgradeable)
        returns (address)
    {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            revert("Soulbound");
        }
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721Upgradeable, ERC721VotesUpgradeable)
    {
        super._increaseBalance(account, value);
    }

    // --- Overrides ---

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}


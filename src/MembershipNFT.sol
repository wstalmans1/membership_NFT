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
    
    // Delegation tracking: maps delegate address to list of addresses that delegated to them
    mapping(address => address[]) public delegators;

    event MemberMinted(address indexed to, uint256 tokenId, uint256 amountPaid);
    event MemberRevoked(address indexed member, uint256 tokenId);
    event TreasuryUpdated(address indexed treasury);
    event ConstitutionUpdated(address indexed constitution);
    event DelegationReturned(address indexed delegator, address indexed previousDelegate, uint256 timestamp);

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

        // Auto-delegate to self to activate voting power
        // This will track delegators automatically via our override
        delegate(msg.sender);

        (bool sent,) = treasury.call{value: msg.value}("");
        require(sent, "Treasury transfer failed");

        emit MemberMinted(msg.sender, tokenId, msg.value);
    }
    
    // --- Delegation tracking ---
    
    /**
     * @dev Override delegate function to track delegators on-chain
     */
    function delegate(address delegatee) public virtual override {
        address account = msg.sender;
        address currentDelegate = delegates(account);
        
        // Remove from old delegate's list
        if (currentDelegate != address(0)) {
            removeFromDelegators(currentDelegate, account);
        }
        
        // Add to new delegate's list (if not delegating to zero address)
        if (delegatee != address(0)) {
            delegators[delegatee].push(account);
        }
        
        // Call parent delegate function
        super.delegate(delegatee);
    }
    
    /**
     * @dev Remove a delegator from a delegate's list
     */
    function removeFromDelegators(address delegateAddress, address delegator) internal {
        address[] storage list = delegators[delegateAddress];
        uint256 length = list.length;
        for (uint256 i = 0; i < length; i++) {
            if (list[i] == delegator) {
                // Move last element to current position
                list[i] = list[length - 1];
                // Remove last element
                list.pop();
                break;
            }
        }
    }
    
    /**
     * @dev Get the number of delegators for a given delegate
     */
    function getDelegatorCount(address delegateAddress) public view returns (uint256) {
        return delegators[delegateAddress].length;
    }

    // --- Revocation / burn ---
    
    /**
     * @dev Handle delegation cleanup before burning an NFT
     * This ensures delegators maintain control and no voting power is orphaned
     */
    function _handleDelegationCleanup(address owner) internal {
        // Get all addresses that delegated to this address
        address[] memory delegatorsList = delegators[owner];
        
        // For each delegator, redelegate to themselves (auto-activate their voting power)
        for (uint256 i = 0; i < delegatorsList.length; i++) {
            address delegator = delegatorsList[i];
            
            // Skip if delegator's NFT was also burned (shouldn't happen, but safety check)
            if (balanceOf(delegator) == 0) {
                continue;
            }
            
            // Redelegate to themselves (this will automatically move their voting power)
            _delegate(delegator, delegator);
            
            // Remove from delegators list
            removeFromDelegators(owner, delegator);
            
            // Emit event for frontend notifications
            emit DelegationReturned(delegator, owner, block.timestamp);
        }
        
        // Clear own delegation if delegated elsewhere
        address currentDelegate = delegates(owner);
        if (currentDelegate != address(0) && currentDelegate != owner) {
            // Clear delegation (delegate to zero address)
            // The _burn will handle moving voting power from currentDelegate to zero
            _delegate(owner, address(0));
        }
    }

    /**
     * @dev User-initiated NFT burn with delegation cleanup
     */
    function burn() external nonReentrant {
        uint256 tokenId = tokenOfOwner(msg.sender);
        address owner = msg.sender;
        
        // Handle delegation cleanup before burning
        _handleDelegationCleanup(owner);
        
        // Burn the NFT (this will automatically handle voting power transfer via _transferVotingUnits)
        _burn(tokenId);
        
        // Reset hasMinted to allow re-minting
        hasMinted[owner] = false;
        
        emit MemberRevoked(owner, tokenId);
    }

    /**
     * @dev Authority-initiated NFT revocation with delegation cleanup
     */
    function revoke(address member) external onlyRole(REVOKER_ROLE) {
        uint256 tokenId = tokenOfOwner(member);
        
        // Handle delegation cleanup before burning
        _handleDelegationCleanup(member);
        
        // Burn the NFT (this will automatically handle voting power transfer via _transferVotingUnits)
        _burn(tokenId);
        
        // Reset hasMinted to allow re-minting
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


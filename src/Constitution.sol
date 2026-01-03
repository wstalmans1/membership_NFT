// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IConstitution} from "./interfaces/IConstitution.sol";

contract Constitution is Initializable, AccessControlUpgradeable, UUPSUpgradeable, IConstitution {
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    uint256 public override minDonationWei;
    string public override baseURI;
    address public override revocationAuthority;

    uint256 public override perTxSpendCapWei;
    uint256 public override epochSpendCapWei;
    uint64 public override epochDuration;
    bool public override guardianEnabled;

    mapping(address => bool) public override isRecipientAllowed;

    event MinDonationUpdated(uint256 minDonationWei);
    event BaseURIUpdated(string baseURI);
    event RevocationAuthorityUpdated(address revocationAuthority);
    event RecipientAllowlistUpdated(address indexed account, bool allowed);
    event SpendCapsUpdated(uint256 perTxSpendCapWei, uint256 epochSpendCapWei, uint64 epochDuration);
    event GuardianToggled(bool enabled);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin,
        uint256 _minDonationWei,
        string calldata _baseUri,
        address _revocationAuthority,
        uint256 _perTxSpendCapWei,
        uint256 _epochSpendCapWei,
        uint64 _epochDuration,
        address[] calldata initialAllowedRecipients
    ) external initializer {
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(GOVERNANCE_ROLE, admin);

        minDonationWei = _minDonationWei;
        baseURI = _baseUri;
        revocationAuthority = _revocationAuthority;
        perTxSpendCapWei = _perTxSpendCapWei;
        epochSpendCapWei = _epochSpendCapWei;
        epochDuration = _epochDuration;

        for (uint256 i = 0; i < initialAllowedRecipients.length; i++) {
            isRecipientAllowed[initialAllowedRecipients[i]] = true;
            emit RecipientAllowlistUpdated(initialAllowedRecipients[i], true);
        }

        emit MinDonationUpdated(_minDonationWei);
        emit BaseURIUpdated(_baseUri);
        emit RevocationAuthorityUpdated(_revocationAuthority);
        emit SpendCapsUpdated(_perTxSpendCapWei, _epochSpendCapWei, _epochDuration);
    }

    // --- Governance setters ---

    function setMinDonationWei(uint256 value) external onlyRole(GOVERNANCE_ROLE) {
        minDonationWei = value;
        emit MinDonationUpdated(value);
    }

    function setBaseURI(string calldata value) external onlyRole(GOVERNANCE_ROLE) {
        baseURI = value;
        emit BaseURIUpdated(value);
    }

    function setRevocationAuthority(address value) external onlyRole(GOVERNANCE_ROLE) {
        revocationAuthority = value;
        emit RevocationAuthorityUpdated(value);
    }

    function setSpendCaps(uint256 perTxCapWei, uint256 epochCapWei, uint64 durationSeconds)
        external
        onlyRole(GOVERNANCE_ROLE)
    {
        perTxSpendCapWei = perTxCapWei;
        epochSpendCapWei = epochCapWei;
        epochDuration = durationSeconds;
        emit SpendCapsUpdated(perTxCapWei, epochCapWei, durationSeconds);
    }

    function setRecipientAllowed(address account, bool allowed) external onlyRole(GOVERNANCE_ROLE) {
        isRecipientAllowed[account] = allowed;
        emit RecipientAllowlistUpdated(account, allowed);
    }

    function setGuardianEnabled(bool enabled) external onlyRole(GOVERNANCE_ROLE) {
        guardianEnabled = enabled;
        emit GuardianToggled(enabled);
    }

    // --- Upgrade authorization ---

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}


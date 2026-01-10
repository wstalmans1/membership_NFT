// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IConstitution} from "./interfaces/IConstitution.sol";
import {Constitution} from "./Constitution.sol";

/// @custom:oz-upgrades-from Constitution
contract ConstitutionV2 is Constitution {
    // New storage variables - must be added after existing ones
    address[] private _allowedRecipients;
    mapping(address => uint256) private _recipientIndex; // 1-indexed, 0 means not in array

    // New function to get all allowed recipients
    function getAllowedRecipients() external view returns (address[] memory) {
        return _allowedRecipients;
    }

    // New function to get the count of allowed recipients
    function getAllowedRecipientsCount() external view returns (uint256) {
        return _allowedRecipients.length;
    }

    // Override setRecipientAllowed to maintain the enumerable list
    function setRecipientAllowed(address account, bool allowed) public override {
        // Call parent's internal function to update mapping and emit event
        _setRecipientAllowed(account, allowed);
        
        // Maintain the enumerable list
        uint256 index = _recipientIndex[account];
        bool isInList = index > 0;
        
        if (allowed && !isInList) {
            // Add to list
            _allowedRecipients.push(account);
            _recipientIndex[account] = _allowedRecipients.length; // 1-indexed
        } else if (!allowed && isInList) {
            // Remove from list (swap with last element and pop)
            uint256 lastIndex = _allowedRecipients.length - 1;
            address lastRecipient = _allowedRecipients[lastIndex];
            
            _allowedRecipients[index - 1] = lastRecipient; // index - 1 because we store 1-indexed
            _recipientIndex[lastRecipient] = index;
            _allowedRecipients.pop();
            _recipientIndex[account] = 0;
        }
    }

    // Migration function to populate the enumerable list from existing state
    // This should be called after upgrade to sync the list with existing recipients
    // Can be called multiple times - will only add recipients that aren't already in the list
    function migrateAllowedRecipients(address[] calldata recipients) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            // Only add if: recipient is allowed in mapping AND not already in the enumerable list
            if (isRecipientAllowed[recipient] && _recipientIndex[recipient] == 0) {
                _allowedRecipients.push(recipient);
                _recipientIndex[recipient] = _allowedRecipients.length; // 1-indexed
            }
        }
    }
}

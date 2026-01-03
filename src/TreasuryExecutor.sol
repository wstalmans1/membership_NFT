// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IConstitution} from "./interfaces/IConstitution.sol";

contract TreasuryExecutor is Initializable, AccessControlUpgradeable, UUPSUpgradeable, ReentrancyGuard {
    using Address for address payable;

    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    IConstitution public constitution;
    uint64 public currentEpochStart;
    uint256 public currentEpochSpent;

    event ConstitutionUpdated(address indexed constitution);
    event PayoutExecuted(address indexed to, uint256 amount, bytes data);
    event GuardianCancel(address indexed proposer, address indexed target, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin, address _constitution) external initializer {
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(EXECUTOR_ROLE, admin);
        _grantRole(GUARDIAN_ROLE, admin);

        constitution = IConstitution(_constitution);
        currentEpochStart = uint64(block.timestamp);

        emit ConstitutionUpdated(_constitution);
    }

    function executePayout(address payable to, uint256 amount, bytes calldata data)
        external
        nonReentrant
        onlyRole(EXECUTOR_ROLE)
    {
        _enforceEpochWindow();
        _enforceSpendCaps(to, amount);

        (bool ok,) = to.call{value: amount}(data);
        require(ok, "Transfer failed");

        currentEpochSpent += amount;
        emit PayoutExecuted(to, amount, data);
    }

    function guardianCancel(address proposer, address target, uint256 amount) external onlyRole(GUARDIAN_ROLE) {
        require(constitution.guardianEnabled(), "Guardian off");
        require(!constitution.isRecipientAllowed(target) || amount > constitution.perTxSpendCapWei(), "No violation");
        emit GuardianCancel(proposer, target, amount);
        // No state change; execution should be blocked by Governor/Timelock cancellation upstream.
    }

    function setConstitution(address newConst) external onlyRole(DEFAULT_ADMIN_ROLE) {
        constitution = IConstitution(newConst);
        emit ConstitutionUpdated(newConst);
    }

    function _enforceSpendCaps(address to, uint256 amount) internal view {
        require(constitution.isRecipientAllowed(to), "Recipient not allowed");
        uint256 perTxCap = constitution.perTxSpendCapWei();
        if (perTxCap > 0) {
            require(amount <= perTxCap, "Per-tx cap exceeded");
        }
        uint256 epochCap = constitution.epochSpendCapWei();
        if (epochCap > 0) {
            require(currentEpochSpent + amount <= epochCap, "Epoch cap exceeded");
        }
    }

    function _enforceEpochWindow() internal {
        uint64 duration = constitution.epochDuration();
        if (duration == 0) {
            return;
        }
        if (block.timestamp >= currentEpochStart + duration) {
            currentEpochStart = uint64(block.timestamp);
            currentEpochSpent = 0;
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // Accept ETH
    receive() external payable {}
}


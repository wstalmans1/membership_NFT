// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IConstitution {
    // Membership parameters
    function minDonationWei() external view returns (uint256);
    function baseURI() external view returns (string memory);
    function revocationAuthority() external view returns (address);

    // Treasury parameters
    function isRecipientAllowed(address account) external view returns (bool);
    function perTxSpendCapWei() external view returns (uint256);
    function epochSpendCapWei() external view returns (uint256);
    function epochDuration() external view returns (uint64);

    // Guardian toggle for treasury
    function guardianEnabled() external view returns (bool);
}


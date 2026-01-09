# Roles and Permissions (Qawl2)

This doc explains who can do what, in plain language.

## Roles 101

- Roles are named permissions managed by OpenZeppelin AccessControl.
- `DEFAULT_ADMIN_ROLE` is the superuser for a contract. It can grant/revoke any other role.
- The timelock is the executor for governance proposals. That means the timelock must hold the right roles on target contracts, or execution will revert.

## How Governance Execution Works (Rookie View)

1. A proposal is created in the Governor.
2. Members vote.
3. If it passes, the Governor queues the action in the Timelock.
4. After the delay, the Timelock executes the action on the target contract.

If execution fails with “missing role,” it usually means the Timelock does not hold the required role on the target contract.

## Main Actors (Sepolia)

- Deployer/admin: `0xD78C12137087D394c0FA49634CAa80D0a1985A8A`
- Governor proxy: `0xa2e4e3082BEf648D3e996E96A849Dd1D3EF952f1`
- Timelock: `0x6dfc323b65eE7D48f7913892Ff9d9B73436d2942`

## Roles by Contract

### DAOGovernor (proxy)

- `DEFAULT_ADMIN_ROLE`: upgrade authority for the Governor (UUPS). Current holder: deployer/admin.
- `GOVERNANCE_ROLE`: currently granted to deployer/admin; not used for proposal execution.

### TimelockController

- `PROPOSER_ROLE`: can schedule operations. Intended holder: Governor proxy.
- `EXECUTOR_ROLE`: can execute ready operations. In this deployment it is open to everyone (address(0)).
- `CANCELLER_ROLE`: can cancel queued operations. Intended holder: Governor proxy.
- `DEFAULT_ADMIN_ROLE`: can grant/revoke roles. Current holder: deployer/admin.

### Constitution (proxy)

- `GOVERNANCE_ROLE`: can change constitution parameters (min donation, base URI, spend caps, allowlist, guardian toggle).
  - Current holders: deployer/admin and timelock.
  - Recommended holder: timelock (admin kept for emergencies).
- `DEFAULT_ADMIN_ROLE`: upgrades and role management. Current holder: deployer/admin.
- `GUARDIAN_ROLE`: reserved for future use (not used in code today).

### TreasuryExecutor (proxy)

- `EXECUTOR_ROLE`: can execute payouts. Current holders: deployer/admin and timelock.
- `GUARDIAN_ROLE`: can call `guardianCancel`. Current holder: deployer/admin.
- `DEFAULT_ADMIN_ROLE`: upgrades and `setConstitution`. Current holder: deployer/admin.

### MembershipNFT (proxy)

- `TREASURY_ROLE`: can call `setTreasury`. Current holders: deployer/admin and timelock.
- `REVOKER_ROLE`: can revoke memberships. Current holder: deployer/admin.
- `MINTER_ROLE`: reserved for future use (mint is currently open with donation checks).
- `DEFAULT_ADMIN_ROLE`: upgrades and `setConstitution`. Current holder: deployer/admin.

## Roles Granted to Timelock (Confirmed)

- Constitution: `GOVERNANCE_ROLE`
- TreasuryExecutor: `EXECUTOR_ROLE`
- MembershipNFT: `TREASURY_ROLE`

## If You See a “Missing Role” Error

1. Identify the target contract from the proposal.
2. Check the required role from the table above.
3. Ensure the Timelock has that role on the target contract.

## How to Verify Roles On-Chain (Optional)

Example (replace role hash as needed):

```bash
cast call <contract> "hasRole(bytes32,address)(bool)" <roleHash> 0x6dfc323b65eE7D48f7913892Ff9d9B73436d2942 --rpc-url $SEPOLIA_RPC_URL
```

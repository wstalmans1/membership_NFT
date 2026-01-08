# Proposal Execution Issue Report

## Problem Summary

Users are unable to execute queued governance proposals. When clicking the "Execute Proposal" button, the transaction fails during gas estimation with the error: "Execution reverted for an unknown reason." The wallet interface shows a warning: "This transaction is likely to fail."

## Confirmed Root Causes

1. **Timelock lacks execution roles on target contracts**
   - `Constitution` requires `GOVERNANCE_ROLE`
   - `TreasuryExecutor` requires `EXECUTOR_ROLE`
   - `MembershipNFT` requires `TREASURY_ROLE`
   - Since timelock is the executor, these calls revert unless timelock is granted the roles.

2. **Description-only proposals always revert on execute**
   - The frontend uses the Governor proxy as a dummy target with empty calldata.
   - `GovernorUpgradeable`'s `receive()` reverts whenever the executor is a timelock.
   - Result: proposals with empty calldata cannot execute unless the Governor implementation is updated to allow an empty call via governance.

## Technical Context

### Architecture
- **Governor Contract**: `DAOGovernor` (OpenZeppelin GovernorTimelockControlUpgradeable)
- **Timelock Contract**: `TimelockControllerUpgradeable` at `0x6dfc323b65eE7D48f7913892Ff9d9B73436d2942`
- **Governor Proxy**: `0xa2e4e3082BEf648D3e996E96A849Dd1D3EF952f1`
- **Network**: Sepolia Testnet

### Proposal Flow
1. Proposal created → **Pending**
2. Voting period → **Active**
3. Voting ends → **Succeeded**
4. Proposal queued to timelock → **Queued**
5. Timelock delay passes → Operation becomes **Ready**
6. Proposal executed → **Executed**

## Symptoms

### Error Messages
```
EstimateGasExecutionError: Execution reverted for an unknown reason.
Details: execution reverted
```

### Console Logs
- Gas estimation fails when attempting to execute
- RPC returns 429 (Too Many Requests) errors when checking timelock operation state
- Proposal state shows as "Queued" (state 5)
- Proposal ETA appears to have passed (based on block timestamps)

### User Experience
- Clicking "Execute Proposal" button triggers gas estimation
- Gas estimation fails silently
- Wallet shows "transaction is likely to fail" warning
- No clear error message explaining why execution would fail

## Root Cause Analysis

### Prior Hypothesis (Superseded)
The timelock operation is not in the "Ready" state when execution is attempted. This is now considered less likely than the access control and empty-calldata causes above.

### Why This Happens
OpenZeppelin's `GovernorTimelockControl` uses a two-stage process:
1. **Queueing**: Proposal is scheduled on the timelock with a delay
2. **Execution**: The timelock operation must be in "Ready" state before execution

The timelock checks operation readiness using:
- `getOperationState(bytes32 id)` which compares `timestamp <= block.timestamp`
- Operations can be in states: `Unset`, `Waiting`, `Ready`, or `Done`

### Potential Issues

1. **Timestamp vs Block Number Mismatch**
   - Timelock uses timestamps, but block times can vary
   - The ETA might be based on expected block time, but actual block time differs
   - Proposal might be queued but operation not yet ready

2. **Operation ID Mismatch**
   - The operation ID is computed as: `keccak256(abi.encode(targets, values, calldatas, predecessor, salt))`
   - Salt is computed as: `bytes20(governorAddress) ^ descriptionHash`
   - If the operation ID doesn't match, the check fails

3. **RPC Rate Limiting**
   - Attempts to check `isOperationReady()` on timelock fail with 429 errors
   - Cannot reliably verify operation state before execution

## Attempted Solutions

### 1. Gas Limit Adjustments
- **Attempt**: Reduced gas limit from 30M to 15M to stay under RPC cap (16,777,216)
- **Result**: Still fails during gas estimation
- **Reason**: Gas estimation fails when execution would revert, regardless of gas limit

### 2. Pre-execution State Checks
- **Attempt**: Check proposal state and ETA before execution
- **Result**: Checks pass, but execution still fails
- **Reason**: Proposal state "Queued" doesn't guarantee timelock operation is "Ready"

### 3. Timelock Operation Readiness Check
- **Attempt**: Directly check `isOperationReady()` on timelock contract
- **Result**: RPC rate limiting (429 errors) prevents reliable checks
- **Reason**: Thirdweb RPC endpoint has rate limits that block these checks

### 4. Skip Gas Estimation
- **Attempt**: Use fixed gas limit and let execution fail with blockchain error
- **Result**: Transaction sent but wallet shows "likely to fail" warning
- **Reason**: Gas estimation still runs by wallet, detects revert

## Current Implementation

### Code Location
`qawl2-frontend/components/GovernancePage.tsx` - `handleExecute()` function

### Current Flow
1. Verify proposal state is "Queued"
2. Check proposal ETA has passed
3. Skip gas estimation (use fixed 15M gas limit)
4. Attempt execution via `writeExecute()`

### Limitations
- Cannot reliably check timelock operation readiness due to RPC limits
- Gas estimation still runs by wallet and detects revert
- No clear error message when operation isn't ready

## What Needs Investigation

### 1. Verify Timelock Operation State
**Question**: Is the timelock operation actually in "Ready" state when execution is attempted?

**How to Check**:
```solidity
// On TimelockController contract
bytes32 operationId = timelock.hashOperationBatch(targets, values, calldatas, 0, salt);
OperationState state = timelock.getOperationState(operationId);
uint256 timestamp = timelock.getTimestamp(operationId);
```

**Expected**: `state == OperationState.Ready` and `timestamp <= block.timestamp`

### 2. Verify Operation ID Calculation
**Question**: Is the operation ID being computed correctly?

**How to Check**:
- Verify salt calculation: `bytes20(governorAddress) ^ descriptionHash`
- Verify operation ID matches what's stored in `_timelockIds[proposalId]` mapping
- Check if `predecessor` is correctly set to `0`

### 3. Check Timelock Delay Configuration
**Question**: What is the actual timelock delay, and has it truly passed?

**How to Check**:
```solidity
uint256 minDelay = timelock.getMinDelay();
uint256 proposalEta = governor.proposalEta(proposalId);
uint256 currentTimestamp = block.timestamp;
```

**Expected**: `proposalEta <= currentTimestamp` AND operation is in Ready state

### 4. Investigate Block Time vs Timestamp
**Question**: Is there a discrepancy between expected block time and actual block time?

**How to Check**:
- Compare proposal ETA with actual block timestamps
- Check if Sepolia block time matches expected 12 seconds
- Verify if timelock delay is configured in blocks or seconds

## Recommended Next Steps

### Immediate Actions
1. **Grant roles to timelock on target contracts**
   - `Constitution.GOVERNANCE_ROLE`
   - `TreasuryExecutor.EXECUTOR_ROLE`
   - `MembershipNFT.TREASURY_ROLE`
   - Use `script/GrantGovernanceRoles.s.sol` for the current Sepolia deployment

2. **Upgrade Governor implementation to allow empty calldata execution**
   - Override `receive()` with `onlyGovernance` to accept empty calldata proposals
   - Or remove "description-only" proposals from the UI
   - Use `script/UpgradeDAOGovernor.s.sol` for the current Sepolia deployment

3. **Add Better Error Handling**
   - Catch execution errors and decode revert reasons
   - Display specific error messages (e.g., AccessControl missing role, timelock not ready)
   - Show operation state and timestamp in UI

### Long-term Solutions

1. **Use Alternative RPC Provider**
   - Switch from Thirdweb RPC to Alchemy/Infura for better rate limits
   - Or implement RPC failover/retry logic

2. **Implement Operation State Polling**
   - Poll timelock operation state periodically
   - Update UI when operation becomes Ready
   - Auto-enable execute button when ready

3. **Add Operation State to Proposal Data**
   - Fetch operation state when loading proposals
   - Cache operation state to reduce RPC calls
   - Display state in proposal card

## Code References

### Relevant Contracts
- `src/DAOGovernor.sol` - Governor contract with timelock integration
- `lib/openzeppelin-contracts-upgradeable/contracts/governance/extensions/GovernorTimelockControlUpgradeable.sol` - Timelock integration
- `lib/openzeppelin-contracts-upgradeable/contracts/governance/TimelockControllerUpgradeable.sol` - Timelock implementation

### Relevant Frontend Code
- `qawl2-frontend/components/GovernancePage.tsx` - Lines 661-765 (handleExecute function)
- `qawl2-frontend/components/GovernancePage.tsx` - Lines 1526-1620 (QueuedProposalStatus component)

## Test Case

### Proposal Details
- **Proposal ID**: `43118535744178474410665232227128007342069162379135006411759753664739956485474`
- **State**: Queued (5)
- **Vote Start Block**: 9997057
- **Current Block**: ~9997248
- **Description Hash**: `0xab0d78b3f51c629ff8334bd9443320b94d707ef83635f59bc43cf95e2046c027`

### Expected Behavior
- Proposal should be executable after timelock delay passes
- Execute button should work when operation is Ready
- Clear error message if operation not ready

### Actual Behavior
- Execute button triggers gas estimation
- Gas estimation fails with "execution reverted"
- No clear indication of why execution would fail

## Conclusion

The core issue is that we cannot reliably determine if a timelock operation is ready for execution before attempting it. Gas estimation fails when execution would revert, but we don't have visibility into the specific revert reason. The timelock operation state check is blocked by RPC rate limiting.

**Key Questions for Codex**:
1. How can we reliably check timelock operation readiness without hitting RPC rate limits?
2. How can we decode the specific revert reason when gas estimation fails?
3. Is there a better way to determine when a proposal is ready for execution?
4. Should we implement operation state polling or caching?

**Priority**: High - This blocks users from executing governance proposals, which is a core DAO function.

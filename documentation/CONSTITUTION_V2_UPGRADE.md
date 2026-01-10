# Constitution V2 Upgrade - Enumerable Allowed Recipients

## Overview

This upgrade adds enumerability to the `isRecipientAllowed` mapping in the Constitution contract, allowing direct on-chain queries of all authorized recipients without needing to parse events.

## What Changed

### New Features

1. **Enumerable Recipients List**: Added `_allowedRecipients` array to track all allowed addresses
2. **Index Mapping**: Added `_recipientIndex` mapping for efficient lookups and removals
3. **New Functions**:
   - `getAllowedRecipients()`: Returns array of all currently allowed recipient addresses
   - `getAllowedRecipientsCount()`: Returns the count of allowed recipients
4. **Enhanced `setRecipientAllowed()`**: Now automatically maintains the enumerable list when recipients are added/removed

### Storage Layout

New storage variables are added **after** existing ones (required for upgrade safety):
- `address[] private _allowedRecipients`
- `mapping(address => uint256) private _recipientIndex`

## Upgrade Process

### Step 1: Upgrade the Contract

```bash
# Set environment variables
export SEPOLIA_RPC_URL=<your_rpc_url>
export DEPLOYER_KEY=<your_private_key>

# Run the upgrade script
./script/upgrade-constitution.sh
```

Or manually:
```bash
forge clean
forge build
forge script script/UpgradeConstitution.s.sol:UpgradeConstitution \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --sender <PROXY_OWNER> \
    -vvvv
```

### Step 2: Migrate Existing Recipients

After the upgrade, you need to populate the enumerable list with existing recipients. You have two options:

#### Option A: Use Migration Script

1. Edit `script/MigrateAllowedRecipients.s.sol` and add all existing recipient addresses to the `recipients` array
2. Run the migration script:

```bash
forge script script/MigrateAllowedRecipients.s.sol:MigrateAllowedRecipients \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --sender <ADMIN> \
    -vvvv
```

#### Option B: Query Events and Call Directly

1. Query `RecipientAllowlistUpdated` events to get all recipients that were ever added
2. Filter to only those currently allowed (last event for each address)
3. Call `migrateAllowedRecipients(recipients)` on the Constitution proxy with the list

**Note**: The migration function can be called multiple times - it will only add recipients that aren't already in the list.

## Frontend Updates

After the upgrade, update the TreasuryPage component to use the new `getAllowedRecipients()` function instead of querying events:

```typescript
// Old approach (querying events)
const { data: allowedRecipients } = useQuery({
  queryKey: ['allowedRecipients'],
  queryFn: async () => {
    // ... complex event querying logic
  }
});

// New approach (direct contract call)
const { data: allowedRecipients } = useReadContract({
  address: CONTRACTS.SEPOLIA.CONSTITUTION_PROXY,
  abi: ConstitutionV2, // Updated ABI
  functionName: 'getAllowedRecipients',
});
```

## Benefits

1. **Simpler Frontend Code**: No need to query and parse events
2. **More Reliable**: Direct on-chain query, no RPC rate limiting issues
3. **Faster**: Single contract call instead of multiple event queries
4. **Real-time**: Always reflects current state, no need to track events

## Important Notes

- **Storage Compatibility**: New variables are added after existing ones, maintaining storage layout compatibility
- **Migration Required**: Existing recipients must be migrated after upgrade
- **Future Recipients**: All new recipients added via `setRecipientAllowed()` will automatically be added to the enumerable list
- **Backward Compatible**: The `isRecipientAllowed` mapping still works as before

## Contract Addresses

- **Proxy**: `0x931E702cfdda455f77dAdD55F79D561588FbcD05` (unchanged)
- **New Implementation**: Will be updated after deployment

## Verification

After upgrade, verify:
1. Contract compiles and deploys successfully
2. `getAllowedRecipients()` returns empty array initially
3. After migration, `getAllowedRecipients()` returns the correct list
4. Adding/removing recipients via `setRecipientAllowed()` updates the list correctly

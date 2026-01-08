# Upgrade Plugin Migration Summary

## Quick Answer: What Should We Do?

**✅ Use the plugin for ALL future upgrades, even for contracts that were upgraded manually before.**

**❌ Don't redeploy existing contracts** - they work fine, just use the plugin for upgrades going forward.

## Key Recommendations

### 1. **For Existing Contracts (DAOGovernor, MembershipNFT, etc.)**

**Current State:**
- These contracts were deployed/upgraded before the plugin was set up
- They're working fine and don't need to be redeployed

**Going Forward:**
- Use the plugin for all future upgrades
- When creating a new version, add `@custom:oz-upgrades-from` annotation to the contract
- Or use `referenceContract` option in the upgrade script

**Example:**
```solidity
/// @custom:oz-upgrades-from MembershipNFT
contract MembershipNFTV2 is MembershipNFT {
    // New functionality here
}
```

### 2. **For New Deployments**

Always use the plugin:
```solidity
address proxy = Upgrades.deployUUPSProxy(
    "src/MyContract.sol:MyContract",
    abi.encodeCall(MyContract.initialize, (args))
);
```

### 3. **For Contracts That Haven't Been Upgraded Yet**

If you need to upgrade Constitution or TreasuryExecutor for the first time:
- Use the plugin (scripts are already updated)
- The plugin will validate the upgrade is safe
- No need to reference a previous version (first upgrade)

## Practical Steps

### When Upgrading an Existing Contract:

1. **Create new contract version** with `@custom:oz-upgrades-from`:
   ```solidity
   /// @custom:oz-upgrades-from DAOGovernor
   contract DAOGovernorV2 is DAOGovernor {
       // Changes here
   }
   ```

2. **Run upgrade script** (choose one method):

   **Option A: Use convenience script (Recommended)**
   ```bash
   ./script/upgrade-governor.sh
   # or for MembershipNFT:
   ./script/upgrade-membership.sh
   ```

   **Option B: Manual forge commands**
   ```bash
   forge clean
   forge script script/UpgradeDAOGovernor.s.sol:UpgradeDAOGovernor \
     --rpc-url $SEPOLIA_RPC_URL \
     --broadcast \
     --sender <PROXY_OWNER> \
     -vvvv
   ```

3. **Verify upgrade**:
   - Check implementation address changed
   - Test functionality
   - Update `CONTRACT_ADDRESSES.md`

### If You Don't Want to Keep Old Code:

Use the `referenceContract` option in your upgrade script:
```solidity
Options memory opts;
opts.referenceContract = "src/MembershipNFT.sol:MembershipNFT";
Upgrades.upgradeProxy(proxy, "src/MembershipNFTV2.sol:MembershipNFTV2", "", opts);
```

## Benefits of This Approach

1. **No disruption**: Existing contracts continue working
2. **Safety**: Plugin validates all future upgrades
3. **Consistency**: Standardized upgrade process
4. **No migration needed**: Just use plugin going forward

## What NOT to Do

- ❌ Don't redeploy contracts just to use the plugin
- ❌ Don't skip validations with `unsafeSkipAllChecks` unless absolutely necessary
- ❌ Don't upgrade without `forge clean` first
- ❌ Don't forget to test on testnet before mainnet

## Files Updated

- ✅ `foundry.toml` - Added plugin configuration
- ✅ `script/UpgradeDAOGovernor.s.sol` - Updated to use plugin
- ✅ `script/UpgradeMembershipNFT.s.sol` - Updated to use plugin
- ✅ `documentation/FOUNDRY_UPGRADES_PLUGIN.md` - Plugin setup guide
- ✅ `documentation/UPGRADE_BEST_PRACTICES.md` - Detailed best practices

## Next Steps

1. **For your next upgrade**: Use the existing upgrade scripts with the plugin
2. **When creating new versions**: Add `@custom:oz-upgrades-from` annotations
3. **For new contracts**: Use `Upgrades.deployUUPSProxy()` in deployment scripts

That's it! The plugin is ready to use, and you don't need to change anything about your existing deployments.

# Upgrade Best Practices - Migration Guide

## Current State

### Already Deployed & Upgraded Contracts
- **DAOGovernor**: UUPS proxy, has been upgraded before
- **MembershipNFT**: UUPS proxy, has been upgraded multiple times (3 implementations)
- **Constitution**: UUPS proxy, deployed but may not have been upgraded yet
- **TreasuryExecutor**: UUPS proxy, deployed but may not have been upgraded yet

### Non-Upgradeable Contracts
- **TimelockController**: Direct deployment (not upgradeable)

## Recommended Approach

### ✅ **Use Plugin for ALL Future Upgrades**

**Even though some contracts were upgraded manually before, use the plugin for all future upgrades going forward.**

**Why?**
- The plugin provides safety validations that catch dangerous upgrade patterns
- It ensures storage layout compatibility
- It provides better error messages
- It standardizes the upgrade process
- No need to redeploy existing contracts - just use the plugin for upgrades

### 📋 **Migration Strategy**

#### 1. **For Future Upgrades of Existing Contracts**

When upgrading contracts that were deployed/upgraded before the plugin:

**Option A: Keep Old Implementation Code (Recommended)**
- Keep the current implementation contract code in your repository
- When creating a new version, add `@custom:oz-upgrades-from` annotation:

```solidity
/// @custom:oz-upgrades-from MembershipNFT
contract MembershipNFTV2 is MembershipNFT {
    // New functionality
}
```

**Option B: Use `referenceContract` Option**
- If you don't want to keep old code, specify the reference contract when upgrading:

```solidity
Options memory opts;
opts.referenceContract = "src/MembershipNFT.sol:MembershipNFT";
Upgrades.upgradeProxy(proxy, "src/MembershipNFTV2.sol:MembershipNFTV2", "", opts);
```

**Option C: Use Build Info Directory**
- If you have build artifacts from previous deployments, reference them:

```solidity
Options memory opts;
opts.referenceBuildInfoDir = "out/build-info";
opts.referenceContract = "build-info:MembershipNFT";
Upgrades.upgradeProxy(proxy, "src/MembershipNFTV2.sol:MembershipNFTV2", "", opts);
```

#### 2. **For New Deployments**

**Always use the plugin for new upgradeable contract deployments:**

```solidity
// Deploy new UUPS proxy
address proxy = Upgrades.deployUUPSProxy(
    "src/MyNewContract.sol:MyNewContract",
    abi.encodeCall(MyNewContract.initialize, (args))
);
```

#### 3. **For Contracts That Don't Need Upgrades**

If a contract doesn't need to be upgradeable, deploy it normally (no proxy). The plugin is only for upgradeable contracts.

### 🔄 **Upgrade Workflow Going Forward**

1. **Before Upgrading**:
   ```bash
   forge clean
   ```

2. **Create New Contract Version**:
   - Create new file or update existing contract
   - Add `@custom:oz-upgrades-from` annotation if keeping old code
   - Ensure storage layout compatibility

3. **Run Upgrade Script**:
   ```bash
   forge script script/Upgrade<Contract>.s.sol:Upgrade<Contract> \
     --rpc-url $SEPOLIA_RPC_URL \
     --broadcast \
     --sender <PROXY_OWNER> \
     --verify \
     -vvvv
   ```

4. **Verify Upgrade**:
   - Check implementation address changed
   - Test new functionality
   - Verify on Blockscout

### 📝 **Script Template for Existing Contracts**

When creating upgrade scripts for contracts that were deployed before the plugin:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Options} from "openzeppelin-foundry-upgrades/Options.sol";

contract UpgradeMyContract is Script {
    address constant PROXY = 0x...; // From CONTRACT_ADDRESSES.md

    function run() external {
        uint256 deployerKey = vm.envUint("DEPLOYER_KEY");
        vm.startBroadcast(deployerKey);

        // Option 1: Use annotation in contract (recommended)
        Upgrades.upgradeProxy(
            PROXY,
            "src/MyContractV2.sol:MyContractV2",
            "" // or abi.encodeCall(MyContractV2.reinitialize, (args))
        );

        // Option 2: Specify reference contract
        // Options memory opts;
        // opts.referenceContract = "src/MyContract.sol:MyContract";
        // Upgrades.upgradeProxy(PROXY, "src/MyContractV2.sol:MyContractV2", "", opts);

        vm.stopBroadcast();
    }
}
```

### ⚠️ **Important Considerations**

#### 1. **Storage Layout Compatibility**

The plugin validates storage layout. When upgrading:
- ✅ **Safe**: Adding new state variables at the end
- ✅ **Safe**: Modifying functions (not state variables)
- ❌ **Unsafe**: Removing state variables
- ❌ **Unsafe**: Changing order of state variables
- ❌ **Unsafe**: Changing types of state variables

#### 2. **Reference Contract Handling**

For contracts upgraded before the plugin:
- **Best**: Keep old implementation code in repo with `@custom:oz-upgrades-from`
- **Alternative**: Use `referenceContract` option in upgrade script
- **Last resort**: Use `unsafeSkipAllChecks` (NOT recommended)

#### 3. **Access Control**

Ensure the `--sender` address has upgrade permissions:
- For UUPS proxies: Must have `UPGRADER_ROLE` (or whatever role `_authorizeUpgrade` checks)
- For transparent proxies: Must be the ProxyAdmin owner

#### 4. **Testing Upgrades**

Before upgrading on mainnet:
1. Test upgrade on testnet
2. Verify storage layout compatibility
3. Test all critical functions after upgrade
4. Verify implementation address changed

### 📚 **Documentation Updates**

When upgrading:
1. Update `CONTRACT_ADDRESSES.md` with new implementation address
2. Keep old implementation addresses for reference
3. Document what changed in the upgrade
4. Update any relevant documentation

### 🎯 **Summary**

**Do:**
- ✅ Use plugin for all future upgrades (even of existing contracts)
- ✅ Keep old implementation code or use `referenceContract` option
- ✅ Run `forge clean` before upgrades
- ✅ Test upgrades on testnet first
- ✅ Document all upgrades

**Don't:**
- ❌ Don't redeploy existing contracts just to use the plugin
- ❌ Don't use `unsafeSkipAllChecks` unless absolutely necessary
- ❌ Don't skip storage layout validation
- ❌ Don't upgrade without testing first

### 🔗 **Related Documentation**

- [Foundry Upgrades Plugin Setup](./FOUNDRY_UPGRADES_PLUGIN.md)
- [Contract Addresses](./CONTRACT_ADDRESSES.md)
- [OpenZeppelin Upgrade Safety](https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable)

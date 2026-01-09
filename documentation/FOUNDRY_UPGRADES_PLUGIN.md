# Foundry Upgrades Plugin Setup

This project now uses the [OpenZeppelin Foundry Upgrades plugin](https://docs.openzeppelin.com/upgrades-plugins/foundry-upgrades) for managing contract upgrades.

## Installation

The plugin has been installed via:
```bash
forge install OpenZeppelin/openzeppelin-foundry-upgrades
```

## Configuration

### `foundry.toml`

The following settings have been added to enable upgrade safety validations:

```toml
[profile.default]
ffi = true
ast = true
build_info = true
extra_output = ["storageLayout"]
```

### Remappings

Updated remappings in `foundry.toml`:

```toml
remappings = [
    "@openzeppelin/contracts/=lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/",
    "@openzeppelin/contracts-upgradeable/=lib/openzeppelin-contracts-upgradeable/contracts/",
    "forge-std/=lib/forge-std/src/",
    "openzeppelin-foundry-upgrades/=lib/openzeppelin-foundry-upgrades/src/"
]
```

**Important**: The `@openzeppelin/contracts/` remapping now points to the contracts within the upgradeable package. This is required for Etherscan verification to work correctly.

## Updated Scripts

### `script/UpgradeDAOGovernor.s.sol`

**Before**: Used direct `UUPSUpgradeable` interface calls
**After**: Uses `Upgrades.upgradeProxy()` from the plugin

**Usage**:
```bash
forge script script/UpgradeDAOGovernor.s.sol:UpgradeDAOGovernor \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --sender <PROXY_OWNER> \
  -vvvv
```

**Note**: Use `--sender` flag with an address that has `UPGRADER_ROLE` on the Governor proxy.

### `script/UpgradeMembershipNFT.s.sol`

**Before**: Used direct `UUPSUpgradeable` interface calls
**After**: Uses `Upgrades.upgradeProxy()` from the plugin

**Usage**:
```bash
forge script script/UpgradeMembershipNFT.s.sol:UpgradeMembershipNFT \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --sender <PROXY_OWNER> \
  --verify \
  -vvvv
```

**Note**: Use `--sender` flag with an address that has `UPGRADER_ROLE` on the MembershipNFT proxy.

## Benefits

1. **Upgrade Safety Validations**: The plugin automatically validates:
   - Storage layout compatibility
   - Constructor usage
   - Initializer patterns
   - Other upgrade safety checks

2. **Better Error Messages**: Clear error messages when upgrades would be unsafe

3. **Standardized Approach**: Consistent upgrade process across all contracts

4. **Etherscan Verification**: Proper remappings ensure proxy contracts can be verified on Etherscan

## Requirements

### Node.js

The plugin uses the OpenZeppelin Upgrades CLI for validations, which requires Node.js. Install it if you haven't already:
- [Node.js Installation](https://nodejs.org/)

### Clean Builds

Before running upgrade scripts, always run a full clean build:
```bash
forge clean
forge build
```

This prevents the upgrades CLI from seeing partial build-info files (which can happen if only a subset of sources
recompiles during `forge script`).

**Convenience Scripts:**

We provide shell script wrappers that automatically handle `forge clean`:

- `./script/upgrade-governor.sh` - Upgrades DAOGovernor
- `./script/upgrade-membership.sh` - Upgrades MembershipNFT (use `VERIFY=true` prefix for verification)

These scripts automatically:
- Run `forge clean` and `forge build` before upgrading
- Load environment variables from `.env`
- Handle sender address detection
- Provide clear progress output

## Reference Contracts

When upgrading contracts, the plugin needs to know the previous implementation to validate compatibility. This can be done in two ways:

### Option 1: `@custom:oz-upgrades-from` Annotation

Add this annotation to your new contract version:
```solidity
/// @custom:oz-upgrades-from <PreviousContractName>
contract MyContractV2 is MyContractV1 {
    // ...
}
```

### Option 2: `referenceContract` Option

Specify the reference contract when calling `upgradeProxy`:
```solidity
Options memory opts;
opts.referenceContract = "MyContractV1.sol";
Upgrades.upgradeProxy(proxy, "MyContractV2.sol", "", opts);
```

## Skipping Validations (Not Recommended)

If you need to skip validations (dangerous!), you can use:

```solidity
Options memory opts;
opts.unsafeSkipAllChecks = true;
Upgrades.upgradeProxy(proxy, "MyContractV2.sol", "", opts);
```

Or use `UnsafeUpgrades` library:
```solidity
import {UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
```

**Warning**: Only use these options as a last resort. They bypass all safety checks.

## Additional Resources

- [OpenZeppelin Foundry Upgrades Documentation](https://docs.openzeppelin.com/upgrades-plugins/foundry-upgrades)
- [Foundry Upgrades API Reference](https://docs.openzeppelin.com/upgrades-plugins/api-foundry-upgrades)
- [Upgrade Safety Checks](https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable)

# Qawl2 Deployed Contract Addresses - Sepolia

**Network**: Sepolia Testnet (Chain ID: 11155111)  
**Deployment Block**: 9944847  
**Deployer**: 0xD78C12137087D394c0FA49634CAa80D0a1985A8A

## Proxy Contracts (Main Entry Points)

| Contract | Address | Blockscout Link |
|----------|---------|----------------|
| **Constitution** | `0x931E702cfdda455f77dAdD55F79D561588FbcD05` | [View on Blockscout](https://eth-sepolia.blockscout.com/address/0x931E702cfdda455f77dAdD55F79D561588FbcD05) |
| **TreasuryExecutor** | `0xDD21739Ec074C8C3480C689dDDbA2C7451169F33` | [View on Blockscout](https://eth-sepolia.blockscout.com/address/0xDD21739Ec074C8C3480C689dDDbA2C7451169F33) |
| **TimelockController** | `0x6dfc323b65eE7D48f7913892Ff9d9B73436d2942` | [View on Blockscout](https://eth-sepolia.blockscout.com/address/0x6dfc323b65eE7D48f7913892Ff9d9B73436d2942) |
| **DAOGovernor** | `0xa2e4e3082BEf648D3e996E96A849Dd1D3EF952f1` | [View on Blockscout](https://eth-sepolia.blockscout.com/address/0xa2e4e3082BEf648D3e996E96A849Dd1D3EF952f1) |
| **MembershipNFT** | `0x308bFFa77D93a7c37225De5bcEA492E95293DF29` | [View on Blockscout](https://eth-sepolia.blockscout.com/address/0x308bFFa77D93a7c37225De5bcEA492E95293DF29) |

## Implementation Contracts

| Contract | Implementation Address | Blockscout Link |
|----------|----------------------|----------------|
| **Constitution** | `0x87107551ef75e5e1eb89f79a47fee4184d3d9b12` | [View on Blockscout](https://eth-sepolia.blockscout.com/address/0x87107551ef75e5e1eb89f79a47fee4184d3d9b12) |
| **TreasuryExecutor** | `0x4d0eae63a10b91ee118ca4fd2b22e5552f4b2cca` | [View on Blockscout](https://eth-sepolia.blockscout.com/address/0x4d0eae63a10b91ee118ca4fd2b22e5552f4b2cca) |
| **DAOGovernor** | `0x6d387233bc3b04Fe3cEd13090c470438FD11b8D4` | [View on Blockscout](https://eth-sepolia.blockscout.com/address/0x6d387233bc3b04Fe3cEd13090c470438FD11b8D4) |
| **DAOGovernor (Previous)** | `0x3e855073fa698e723c06Da904FE05e6D00Ef874E` | [View on Blockscout](https://eth-sepolia.blockscout.com/address/0x3e855073fa698e723c06Da904FE05e6D00Ef874E) |
| **DAOGovernor (Older)** | `0x86576b61dd6549d9af76f26b937fc7870d590321` | [View on Blockscout](https://eth-sepolia.blockscout.com/address/0x86576b61dd6549d9af76f26b937fc7870d590321) |
| **MembershipNFT** | `0xD39f23282Ab319C0D0Bf87B46B86a892EA0f3B1a` | [View on Blockscout](https://eth-sepolia.blockscout.com/address/0xD39f23282Ab319C0D0Bf87B46B86a892EA0f3B1a) |
| **MembershipNFT (Previous)** | `0x1E1dEb14A4F39bdD79629D4238fA55b3E5Bc09c4` | [View on Blockscout](https://eth-sepolia.blockscout.com/address/0x1E1dEb14A4F39bdD79629D4238fA55b3E5Bc09c4) |
| **MembershipNFT (Old)** | `0x889ac10e5346faa142badc4a2e6ccb96dc17d878` | [View on Blockscout](https://eth-sepolia.blockscout.com/address/0x889ac10e5346faa142badc4a2e6ccb96dc17d878) |

## Quick Verification Commands

To verify contracts using Foundry, run:

```bash
export SEPOLIA_RPC_URL=<your_rpc_url>

# Verify Constitution Implementation
forge verify-contract \
    --rpc-url $SEPOLIA_RPC_URL \
    --verifier blockscout \
    --verifier-url https://eth-sepolia.blockscout.com/api \
    0x87107551ef75e5e1eb89f79a47fee4184d3d9b12 \
    "src/Constitution.sol:Constitution" \
    --constructor-args $(cast abi-encode "constructor()")

# Verify TreasuryExecutor Implementation
forge verify-contract \
    --rpc-url $SEPOLIA_RPC_URL \
    --verifier blockscout \
    --verifier-url https://eth-sepolia.blockscout.com/api \
    0x4d0eae63a10b91ee118ca4fd2b22e5552f4b2cca \
    "src/TreasuryExecutor.sol:TreasuryExecutor" \
    --constructor-args $(cast abi-encode "constructor()")

# Verify DAOGovernor Implementation
forge verify-contract \
    --rpc-url $SEPOLIA_RPC_URL \
    --verifier blockscout \
    --verifier-url https://eth-sepolia.blockscout.com/api \
    0x6d387233bc3b04Fe3cEd13090c470438FD11b8D4 \
    "src/DAOGovernor.sol:DAOGovernor" \
    --constructor-args $(cast abi-encode "constructor()")

# Verify MembershipNFT Implementation (Current)
forge verify-contract \
    --rpc-url $SEPOLIA_RPC_URL \
    --verifier blockscout \
    --verifier-url https://eth-sepolia.blockscout.com/api \
    0x1E1dEb14A4F39bdD79629D4238fA55b3E5Bc09c4 \
    "src/MembershipNFT.sol:MembershipNFT" \
    --constructor-args $(cast abi-encode "constructor()")

# Verify TimelockController (Direct deployment)
forge verify-contract \
    --rpc-url $SEPOLIA_RPC_URL \
    --verifier blockscout \
    --verifier-url https://eth-sepolia.blockscout.com/api \
    0x6dfc323b65eE7D48f7913892Ff9d9B73436d2942 \
    "@openzeppelin/contracts-upgradeable/governance/TimelockControllerUpgradeable.sol:TimelockControllerUpgradeable" \
    --constructor-args $(cast abi-encode "constructor()")
```

## Verification Status

Check the verification status by visiting each contract address on Blockscout using the links above.

For detailed verification instructions, see [VERIFICATION.md](./VERIFICATION.md).

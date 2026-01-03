## DAO Member NFT (Sepolia-first)

Contracts are upgradeable UUPS proxies governed by Governor + Timelock. Constitution stores DAO parameters (min donation floor, base URI pointer, treasury allowlist/caps, guardian toggle). Treasury executor enforces Constitution on outbound spends. Membership NFT is soulbound, 1 per address, votes = 1 per NFT.

### Quickstart (Sepolia)
1) Copy `env.example` to `.env` and fill:
   - `SEPOLIA_RPC_URL` = your Sepolia RPC endpoint (e.g., Infura/Alchemy).
   - `DEPLOYER_KEY` = private key for funded deployer (test ETH).
   - Optional for verification: `BLOCKSCOUT_API=https://eth-sepolia.blockscout.com/api` (or `/api/v2` if required by that instance), `BLOCKSCOUT_API_KEY` if your Blockscout host requires one.
2) Install deps: `forge install`.
3) Build: `forge build`.
4) Deploy in order: Constitution -> TreasuryExecutor -> TimelockController (OZ) -> DAOGovernor -> MembershipNFT. Then wire roles (Timelock gets admin/governance/executor).

### Contracts
- `src/Constitution.sol`: parameter store; governance-controlled.
- `src/MembershipNFT.sol`: soulbound ERC721Votes, payable mint, forwards ETH to treasury.
- `src/TreasuryExecutor.sol`: holds ETH, enforces allowlist + spend caps from Constitution; callable by Timelock.
- `src/DAOGovernor.sol`: Governor + Timelock Control + Votes quorum fraction.

### Build & test
```
forge install
forge build
```
(via-IR enabled in `foundry.toml`)

### Deployment order (Sepolia)
1) Deploy `Constitution` proxy with:
   - admin = multisig/Timelock admin
   - `minDonationWei`, `baseURI`, `revocationAuthority`, spend caps, epoch duration, allowed recipients
2) Deploy `TreasuryExecutor` proxy:
   - admin = Timelock admin
   - constitution = Constitution address
   - grant `EXECUTOR_ROLE` to Timelock once deployed
3) Deploy `TimelockControllerUpgradeable` (via OZ) separately with proposers = Governor, executors = open role or Governor, admin = multisig.
4) Deploy `DAOGovernor` proxy with:
   - token = MembershipNFT (votes)
   - timelock = TimelockController
   - admin = Timelock admin
   - voting params: delay/period/threshold/quorum numerator
5) Deploy `MembershipNFT` proxy:
   - admin = Timelock admin
   - treasury = TreasuryExecutor
   - constitution = Constitution
6) Wire roles:
   - Transfer Constitution `GOVERNANCE_ROLE`/`DEFAULT_ADMIN_ROLE` to Timelock.
   - TreasuryExecutor: grant `EXECUTOR_ROLE` to Timelock; optional `GUARDIAN_ROLE` to guardian.
   - MembershipNFT: grant `DEFAULT_ADMIN_ROLE`/`TREASURY_ROLE`/`REVOKER_ROLE` to Timelock (and guardian if any).
7) Point frontend config to proxy addresses and Sepolia RPC set.

### Infra (decentralization-forward)
- RPC: primary self-hosted/ODoS node; fallbacks (e.g., Infura/Alchemy) via client-side multi-provider selection.
- Storage: IPFS metadata pinned via Storacha + secondary pinning + Filecoin deals; baseURI stored in Constitution.
- Frontend: static build pinned to IPFS/Arweave; reference via ENS content hash.
- Wallets: prefer injected (Frame, MetaMask, Rainbow); WalletConnect optional with multiple relays.
- Monitoring: use public explorers + self-hosted watcher for timelock queue/execution events.

### Treasury policy (encoded)
- Allowlisted recipients (governance-controlled).
- Per-tx and per-epoch spend caps; epoch duration set in Constitution.
- Optional guardian veto toggle in Constitution; guardian can only signal non-compliance (cannot redirect funds).

### Governance parameters
- Quorum = fraction of total votes (set in governor init).
- Proposal threshold configurable at deploy time.
- Voting delay/period set at deploy; can be changed via upgrade or, if desired, via settings upgrade.

### Launch runbook (Sepolia dry-run)
1) Prepare metadata JSON, pin via Storacha + secondary; set baseURI in Constitution init.
2) Deploy proxies per order above; verify implementations.
3) Grant/renounce roles to hand off to Timelock/Governor; keep break-glass guardian if desired.
4) Fund deployer for gas; seed TreasuryExecutor with test ETH after mint flow check.
5) Mint test memberships (pay floor) and verify events, treasury receipt, token non-transferability.
6) Create/test governance proposal that queues TreasuryExecutor payout to allowed recipient; observe timelock delay and execution.
7) Test revoke flow (guardian revokes member) and ensure votes drop.
8) Snapshot config for mainnet: reuse params, set mainnet addresses for Constitution/Treasury allowlists.
## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

# Revocation Authority Investigation & Fix

## Issue Summary

The `revocationAuthority` in the Constitution contract was set to `0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38` instead of the deployer address (`0xD78C12137087D394c0FA49634CAa80D0a1985A8A`).

## Investigation Steps

### 1. Check the Suspicious Address

**Address**: `0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38`

**Check on Blockscout**:
- [View Address on Blockscout](https://eth-sepolia.blockscout.com/address/0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38)

**What to look for**:
- ✅ **No transactions** = Likely unused/unintended
- ❌ **Has transactions** = Suspicious, investigate further
- ❌ **Has balance** = Could be a real wallet
- ❌ **Contract code** = Could be malicious

### 2. Verify Current State

Check current revocationAuthority:
```bash
cast call 0x931E702cfdda455f77dAdD55F79D561588FbcD05 \
  "revocationAuthority()(address)" \
  --rpc-url $SEPOLIA_RPC_URL
```

### 3. Check Your Permissions

Verify you have GOVERNANCE_ROLE (needed to update):
```bash
cast call 0x931E702cfdda455f77dAdD55F79D561588FbcD05 \
  "hasRole(bytes32,address)(bool)" \
  $(cast sig "GOVERNANCE_ROLE()") \
  0xD78C12137087D394c0FA49634CAa80D0a1985A8A \
  --rpc-url $SEPOLIA_RPC_URL
```

Should return: `true`

## Fix: Update Revocation Authority

### Option 1: Using the Update Script (Recommended)

1. **Set your desired address** (or use deployer address):
   ```bash
   # Option A: Use deployer address (default)
   # Script will automatically use deployer address
   
   # Option B: Set specific address in .env
   echo "NEW_REVOCATION_AUTHORITY=0xD78C12137087D394c0FA49634CAa80D0a1985A8A" >> .env
   ```

2. **Run the update script**:
   ```bash
   forge script script/UpdateRevocationAuthority.s.sol:UpdateRevocationAuthority \
     --rpc-url $SEPOLIA_RPC_URL \
     --broadcast \
     --verify
   ```

3. **Verify the update**:
   ```bash
   cast call 0x931E702cfdda455f77dAdD55F79D561588FbcD05 \
     "revocationAuthority()(address)" \
     --rpc-url $SEPOLIA_RPC_URL
   ```

### Option 2: Direct Cast Command

```bash
cast send 0x931E702cfdda455f77dAdD55F79D561588FbcD05 \
  "setRevocationAuthority(address)" \
  0xD78C12137087D394c0FA49634CAa80D0a1985A8A \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $DEPLOYER_KEY
```

## Security Check Checklist

- [ ] Check address `0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38` on Blockscout
- [ ] Verify it has no suspicious activity
- [ ] Check if you have GOVERNANCE_ROLE
- [ ] Update revocationAuthority to your address
- [ ] Verify the update succeeded
- [ ] Check git history for any unauthorized changes
- [ ] Review deployment logs for anomalies

## Current Risk Assessment

**Risk Level**: 🟡 **LOW-MEDIUM**

**Why Low Risk**:
- `revocationAuthority` is currently **not actively used** in the code
- Actual revocation uses `REVOKER_ROLE` which you control
- You can update it via governance

**Why Medium Risk**:
- If governance code later uses `revocationAuthority`, this could be a problem
- Unknown address suggests potential compromise or mistake

## Next Steps

1. ✅ **Immediate**: Check the address on Blockscout
2. ✅ **Immediate**: Update revocationAuthority to your address
3. ⚠️ **If suspicious**: Investigate further (malware scan, review access logs)
4. ✅ **Ongoing**: Monitor the address for any activity

## Prevention

To prevent this in the future:
- Always verify deployment parameters before broadcasting
- Use explicit addresses instead of `msg.sender` in scripts
- Review transaction data before signing
- Keep deployment logs for audit trail


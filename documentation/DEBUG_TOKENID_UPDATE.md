# Debug: tokenId Not Updating in Supabase

## Problem
Metadata is created, NFT is minted, but `token_id` remains `NULL` in Supabase.

## Possible Causes

### 1. Event Parsing Failed (Silent Failure)
The code catches errors but doesn't show them. Check browser console for errors.

### 2. UPDATE Policy Issue
The UPDATE policy might be blocking the update. Check if UPDATE policy allows `anon` role.

### 3. Query Not Finding Record
The update query uses:
- `.eq('owner_address', ownerAddress.toLowerCase())`
- `.is('token_id', null)`

If the `owner_address` doesn't match exactly, or if there's a data type mismatch, it won't find the record.

## Debugging Steps

### Step 1: Check Browser Console
1. Open browser DevTools (F12)
2. Go to Console tab
3. Look for errors when minting
4. Look for "Error parsing event logs" or "Failed to update metadata"

### Step 2: Verify Event Was Found
Add console.log to see if event was found:

```typescript
if (memberMintedEvent && memberMintedEvent.args) {
  const tokenId = Number(memberMintedEvent.args.tokenId);
  console.log('Found tokenId:', tokenId); // Add this
  // ... rest of code
} else {
  console.log('MemberMinted event not found!'); // Add this
}
```

### Step 3: Check UPDATE Policy
Go to Supabase → Table Editor → `member_metadata` → Policies
- Make sure UPDATE policy allows `anon` role
- Policy definition should be `true` (for MVP)

### Step 4: Manual Test Update
Try updating manually in Supabase:
1. Go to Table Editor → `member_metadata`
2. Find your record (where `token_id` is NULL)
3. Click Edit
4. Set `token_id` to the minted token ID
5. Save

If this works, the issue is with the code. If it fails, it's a policy issue.

## Quick Fix: Add Better Error Handling

The current code silently fails. We should add better logging and error messages.


# Manual token_id Update Guide

## Problem
The `token_id` column is not updating automatically after minting.

## Quick Manual Fix

### Option 1: Update via Supabase Dashboard

1. Go to Supabase → Table Editor → `member_metadata`
2. Find your record (by `owner_address`)
3. Click Edit
4. Set `token_id` to your minted token ID (check Blockscout or your wallet)
5. Save

### Option 2: Use SQL

```sql
-- Replace with your actual values
UPDATE public.member_metadata
SET token_id = 1,  -- Your actual token ID
    updated_at = NOW()
WHERE owner_address = '0xYourAddressHere';  -- Your wallet address (lowercase)
```

### Option 3: Check What Token ID You Have

1. Go to Blockscout: https://eth-sepolia.blockscout.com
2. Search for your MembershipNFT contract: `0x308bFFa77D93a7c37225De5bcEA492E95293DF29`
3. Go to "Token Transfers" tab
4. Find your mint transaction
5. Note the token ID from the transaction

## Debugging: Check Console Logs

When you mint, check browser console (F12) for:
- "🔍 Starting metadata update"
- "📋 Existing record"
- "💾 Updating record"
- Any error messages

## Most Likely Issue: UPDATE Policy

The UPDATE policy might still be blocking. Run this SQL:

```sql
-- Drop existing UPDATE policy
DROP POLICY IF EXISTS "Owner can update metadata" ON public.member_metadata;
DROP POLICY IF EXISTS "Anon can update metadata" ON public.member_metadata;

-- Create new permissive UPDATE policy
CREATE POLICY "Anon can update metadata"
ON public.member_metadata
FOR UPDATE
TO anon
USING (true)
WITH CHECK (true);
```


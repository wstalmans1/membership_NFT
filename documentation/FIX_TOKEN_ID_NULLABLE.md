# Fix: Make token_id Column Nullable

## Problem
Error: "null value in column "token_id" of relation "member_metadata" violates not-null constraint"

**Root Cause:** The `token_id` column in your `member_metadata` table is set to `NOT NULL`, but your workflow creates metadata BEFORE minting (so `token_id` is `null` initially), then updates it after minting.

## Solution: Make token_id Nullable

### Steps to Fix:

1. **Go to Supabase Dashboard**
   - Navigate to: **Table Editor** → `member_metadata` table

2. **Edit the token_id Column**
   - Find the `token_id` column in the table
   - Click on the column (or click the edit icon)
   - Find the "Is Nullable" or "Nullable" setting
   - **Change it from `false` (NOT NULL) to `true` (NULL allowed)**

3. **Save the Changes**

### Alternative: Using SQL Editor

If you prefer SQL, go to **SQL Editor** and run:

```sql
ALTER TABLE public.member_metadata 
ALTER COLUMN token_id DROP NOT NULL;
```

## Why This Works

Your workflow is:
1. User fills form → Create metadata in Supabase (`token_id = null`)
2. User mints NFT → Get `tokenId` from blockchain
3. Update metadata → Set `token_id = tokenId`

This requires `token_id` to be nullable initially, then updated after minting.

## After Fixing

Try submitting your form again. The metadata should be created successfully with `token_id = null`, then updated after minting.


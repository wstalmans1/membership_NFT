# Troubleshoot: token_id Not Updating

## Critical Checks

### 1. Check Browser Console (MOST IMPORTANT)

Open DevTools (F12) → Console tab and look for:
- 🔍 "Starting metadata update" - confirms function is called
- 📋 "All records for address" - shows what records exist
- 📝 "Records with null token_id" - shows which records can be updated
- ❌ Any error messages

**Share these logs with me!**

### 2. Verify UPDATE Policy

Go to Supabase → Table Editor → `member_metadata` → Policies tab

**Check UPDATE policy:**
- Policy Name: `Owner can update metadata` (or similar)
- Command: `UPDATE`
- Target Roles: `anon` (NOT `authenticated`)
- Policy Definition: `true` (NOT `((auth.uid())::text = owner_address)`)

**If policy is wrong:**
1. Click Edit on the UPDATE policy
2. Change Target Roles to `anon`
3. Change Policy Definition to `true`
4. Save

### 3. Manual Test in Supabase

Try updating manually:
1. Go to Table Editor → `member_metadata`
2. Find your record (where `token_id` is NULL)
3. Click Edit
4. Set `token_id` to your minted token ID (e.g., `1`)
5. Click Save

**If manual update works:** The issue is with the code/query
**If manual update fails:** The issue is with the UPDATE policy

### 4. Check Data Types

In Supabase Table Editor, check:
- `token_id` column type should be `int8` or `bigint`
- `owner_address` should match your wallet address exactly (lowercase)

### 5. Quick Fix: Update Policy to Allow All Updates

If nothing works, temporarily make UPDATE policy very permissive:

```sql
-- Run this in SQL Editor
DROP POLICY IF EXISTS "Owner can update metadata" ON public.member_metadata;

CREATE POLICY "Anon can update metadata"
ON public.member_metadata
FOR UPDATE
TO anon
USING (true)
WITH CHECK (true);
```

## What to Share

When asking for help, share:
1. **Console logs** (copy/paste the 🔍 📋 📝 ❌ messages)
2. **UPDATE policy screenshot** (from Supabase Policies tab)
3. **Manual update result** (did it work when you tried manually?)
4. **Your wallet address** (to verify owner_address matches)


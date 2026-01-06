# Fix: Supabase Table RLS Policy for member_metadata

## Problem
Error: "new row violates row-level security policy for table 'member_metadata'"

**Root Cause:** The `member_metadata` table's INSERT policy is blocking anonymous inserts.

## Solution: Update Table RLS Policy

### Steps to Fix:

1. **Go to Supabase Dashboard**
   - Navigate to: **Table Editor** → `member_metadata` table → **Policies** tab

2. **Check Current Policies**
   - Look for an INSERT policy (or create one if missing)
   - The policy might require `authenticated` role or have a condition that blocks inserts

3. **Create/Update INSERT Policy:**

   **Policy Name:** `Anyone can insert metadata` (or `Anon can insert metadata`)
   
   **Allowed Operation:** `INSERT`
   
   **Target Roles:** `anon` (or `public`)
   
   **Policy Definition:** `true`

4. **Save the Policy**

### Complete Policy Set (Recommended for MVP):

For the `member_metadata` table, you should have these policies:

**Policy 1: Public Read**
- Name: `Public can read metadata`
- Operation: `SELECT`
- Roles: `public`
- Definition: `true`

**Policy 2: Anon Insert** ⬅️ **THIS IS WHAT YOU NEED TO FIX**
- Name: `Anon can insert metadata`
- Operation: `INSERT`
- Roles: `anon`
- Definition: `true`

**Policy 3: Owner Update** (Optional for now)
- Name: `Owner can update metadata`
- Operation: `UPDATE`
- Roles: `anon` (or `authenticated` if you add auth later)
- Definition: `true` (or add ownership check later)

**Policy 4: Owner Delete** (Optional for now)
- Name: `Owner can delete metadata`
- Operation: `DELETE`
- Roles: `anon` (or `authenticated` if you add auth later)
- Definition: `true` (or add ownership check later)

## Why This Works

- Your frontend uses `NEXT_PUBLIC_SUPABASE_ANON_KEY` (anon role)
- The table INSERT policy was blocking anon inserts
- Changing to allow `anon` INSERT with `true` condition allows your frontend to create metadata

## Security Note

For MVP, allowing `anon` inserts is fine. Later, you can:
- Add wallet signature verification
- Use Supabase Auth with wallet connection
- Add ownership checks in the policy definition

But for now, `anon` inserts will work!

## After Fixing

Try submitting the form again. Both the photo upload AND metadata creation should work!


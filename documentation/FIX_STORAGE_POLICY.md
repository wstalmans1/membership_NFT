# Fix: Supabase Storage Upload Policy

## Problem
Error: "new row violates row-level security policy"

**Root Cause:** Your storage bucket policy requires `authenticated` role, but your frontend uses the `anon` key (no Supabase authentication).

## Solution: Update Storage Policy

### Steps to Fix:

1. **Go to Supabase Dashboard**
   - Navigate to: Storage → `member_photos` bucket → Policies tab

2. **Find the Upload Policy**
   - Look for policy named: "Authenticated can upload photos" or similar
   - Or create a new policy if it doesn't exist

3. **Update/Create Policy:**

   **Policy Name:** `Anyone can upload photos` (or `Anon can upload photos`)
   
   **Allowed Operation:** `INSERT`
   
   **Target Roles:** `anon` (change from `authenticated` to `anon`)
   
   **Policy Definition:** `true`

4. **Save the Policy**

### Alternative: Allow Both Anon and Authenticated

If you want to keep authenticated users AND allow anonymous uploads:

**Policy 1:** `Anon can upload photos`
- Operation: `INSERT`
- Roles: `anon`
- Definition: `true`

**Policy 2:** `Authenticated can upload photos`
- Operation: `INSERT`
- Roles: `authenticated`
- Definition: `true`

## Why This Works

- Your frontend uses `NEXT_PUBLIC_SUPABASE_ANON_KEY` (anon role)
- Storage policies were set to `authenticated` only
- Changing to `anon` allows your frontend to upload

## Security Note

For MVP, allowing `anon` uploads is fine. Later, you can:
- Add wallet signature verification
- Use Supabase Auth with wallet connection
- Add rate limiting

But for now, `anon` uploads will work!

## After Fixing

Try uploading the photo again. The error should disappear.


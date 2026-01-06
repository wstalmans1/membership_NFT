# baseURI Options - Which Should You Use?

## Your Current Setup

You have:
- **Supabase table**: `member_metadata` with `token_id` as identity
- **Next.js API route**: `/app/api/metadata/[tokenId]/route.ts` that queries Supabase
- **Supabase URL**: `https://enquhynxaibtkjinzfvh.supabase.co`

---

## Option 1: Use Next.js API Route (RECOMMENDED) ✅

### baseURI Format:
```
https://your-nextjs-app-domain.com/api/metadata/
```

### How It Works:
1. Wallet calls `tokenURI(1)` → Returns `https://your-app.com/api/metadata/1`
2. Your Next.js API route receives the request
3. API route queries Supabase: `SELECT metadata_json FROM member_metadata WHERE token_id = 1`
4. API route returns the JSON to the wallet

### Advantages:
- ✅ GDPR compliance (you control updates/deletes)
- ✅ CORS configured for wallets
- ✅ Can add authentication/rate limiting
- ✅ Can transform data before returning

### Requirements:
- Your Next.js app must be **deployed** and publicly accessible
- Cannot use `localhost` (wallets can't access localhost)

---

## Option 2: Use Supabase REST API Directly (NOT RECOMMENDED) ⚠️

### baseURI Format:
```
https://enquhynxaibtkjinzfvh.supabase.co/rest/v1/member_metadata?token_id=eq.{id}&select=metadata_json
```

**Wait, this won't work!** Supabase REST API doesn't support `{id}` placeholders.

### Actual Supabase REST URL:
```
https://enquhynxaibtkjinzfvh.supabase.co/rest/v1/member_metadata?token_id=eq.1&select=metadata_json
```

### Problems:
- ❌ ERC-721 expects `tokenURI(1)` to return a single URL, not a query string
- ❌ CORS might not be configured for wallets
- ❌ No GDPR compliance layer
- ❌ Direct database exposure
- ❌ Returns array `[{metadata_json: {...}}]` not just `{...}`

### Why This Doesn't Work:
ERC-721 `tokenURI()` must return a **single URL** that directly serves the JSON. Supabase REST API requires query parameters, which breaks the standard.

---

## What You Need to Do

### Step 1: Deploy Your Next.js Frontend

**Question for you:** Is your Next.js frontend deployed? If yes, what's the URL?

If not, deploy it to:
- **Vercel** (easiest): `https://your-app.vercel.app`
- **Netlify**: `https://your-app.netlify.app`
- **Custom domain**: `https://your-domain.com`

### Step 2: Set baseURI

Once deployed, your baseURI should be:
```
https://your-deployed-app.com/api/metadata/
```

### Step 3: Test It

After setting baseURI, test:
```bash
# This should return your Next.js API route URL
cast call 0x931E702cfdda455f77dAdD55F79D561588FbcD05 "tokenURI(uint256)(string)" 1 --rpc-url $SEPOLIA_RPC_URL

# Should return: https://your-app.com/api/metadata/1

# Then manually fetch it:
curl https://your-app.com/api/metadata/1
# Should return JSON metadata
```

---

## Summary

**Use Option 1 (Next.js API Route)** because:
1. It's the standard way (ERC-721 compatible)
2. You already have it set up
3. It provides GDPR compliance
4. It's more secure

**Don't use Supabase REST API directly** because:
1. It doesn't match ERC-721 `tokenURI()` expectations
2. No GDPR compliance layer
3. Security concerns

---

## Next Steps

**Please tell me:**
1. Is your Next.js frontend deployed? (Yes/No)
2. If yes, what's the URL?
3. If no, do you want help deploying it?

Then I'll give you the exact `cast send` command to set the baseURI.


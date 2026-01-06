# Understanding baseURI - What It Should Be

## ❌ What baseURI is NOT

**Supabase URL** (`https://enquhynxaibtkjinzfvh.supabase.co`) is:
- Used in `.env.local` for your **frontend** to connect to Supabase database
- Used by your Next.js API route to query Supabase
- **NOT** what should be in `baseURI`

## ✅ What baseURI SHOULD Be

**Your Next.js App URL** + `/api/metadata/`

### The Flow:

```
Wallet/Marketplace
  ↓
Calls: tokenURI(1)
  ↓
Gets: baseURI + "1" = "https://your-app.com/api/metadata/1"
  ↓
Fetches: GET https://your-app.com/api/metadata/1
  ↓
Your Next.js API Route (/app/api/metadata/[tokenId]/route.ts)
  ↓
Queries Supabase (using Supabase URL from .env.local)
  ↓
Returns: JSON metadata
```

## Examples

### If your app is deployed on Vercel:
```
baseURI = "https://your-app.vercel.app/api/metadata/"
```

### If your app is deployed on a custom domain:
```
baseURI = "https://qawl-dao.com/api/metadata/"
```

### If testing locally (not recommended for production):
```
baseURI = "http://localhost:3000/api/metadata/"
```

## How to Find Your baseURI

1. **Deploy your Next.js frontend** (Vercel, Netlify, etc.)
2. **Get your app's public URL** (e.g., `https://qawl-dao.vercel.app`)
3. **Add `/api/metadata/`** to it
4. **Set that as baseURI** in your Constitution contract

## Summary

- **Supabase URL**: Used internally by your API route (stays in `.env.local`)
- **baseURI**: Your Next.js app URL + `/api/metadata/` (set on-chain)

They serve different purposes:
- Supabase URL = Where your API queries data FROM
- baseURI = Where wallets query metadata FROM


# baseURI Clarification - Two Separate Flows

## Your Current Understanding (INCORRECT) ❌

You think:
- Frontend uses `baseURI` to read/write to Supabase
- `baseURI + tokenId` indicates which entry in Supabase

**This is NOT how it works!**

---

## Correct Understanding ✅

There are **TWO SEPARATE FLOWS**:

### Flow 1: Frontend ↔ Supabase (NO baseURI involved!)

```
┌─────────────────┐                    ┌──────────────┐
│   Your Frontend │                    │   Supabase   │
│  (Next.js App)  │                    │   Database   │
└────────┬────────┘                    └──────┬───────┘
         │                                    │
         │ Uses Supabase Client Library       │
         │ (lib/supabase.ts)                  │
         │                                    │
         ├─── Write: createMetadata() ────────>│
         │                                    │
         ├─── Read: getMetadata(tokenId) ────>│
         │                                    │
         │<─── Returns JSON ──────────────────┤
         │                                    │
```

**Key Points:**
- ✅ Frontend uses `supabase.from('member_metadata')` directly
- ✅ Uses Supabase client from `lib/supabase.ts`
- ✅ Uses Supabase URL from `.env.local`
- ❌ **NO baseURI involved here!**

**Code Example:**
```typescript
// In MembershipPage.tsx or NFTDisplay.tsx
import { getMetadata } from '@/lib/metadata';

// This calls Supabase DIRECTLY, no baseURI
const metadata = await getMetadata(tokenId);
```

---

### Flow 2: Wallet/Marketplace → Contract → baseURI → Next.js API → Supabase

```
┌──────────────────┐
│ Wallet/Marketplace│
│  (MetaMask, etc.) │
└────────┬─────────┘
         │
         │ Calls: tokenURI(1)
         │
         ▼
┌──────────────────┐
│ Smart Contract   │
│ (MembershipNFT)  │
└────────┬─────────┘
         │
         │ Returns: baseURI + "1"
         │ = "https://your-app.com/api/metadata/1"
         │
         ▼
┌──────────────────┐
│  Next.js API     │
│ /api/metadata/1  │
└────────┬─────────┘
         │
         │ Queries Supabase:
         │ SELECT metadata_json FROM member_metadata
         │ WHERE token_id = 1
         │
         ▼
┌──────────────────┐
│   Supabase       │
│   Database       │
└────────┬─────────┘
         │
         │ Returns JSON
         │
         ▼
┌──────────────────┐
│ Wallet/Marketplace│
│  (displays NFT)  │
└──────────────────┘
```

**Key Points:**
- ✅ Wallet calls `tokenURI(1)` on the smart contract
- ✅ Contract returns `baseURI + "1"`
- ✅ Wallet fetches that URL (your Next.js API)
- ✅ Your API queries Supabase and returns JSON
- ✅ **baseURI is ONLY used here!**

---

## Where baseURI is Used

### In the Smart Contract:

```solidity
// In MembershipNFT.sol (inherited from ERC721)
function tokenURI(uint256 tokenId) public view returns (string memory) {
    // Gets baseURI from Constitution contract
    string memory base = IConstitution(constitution).baseURI();
    // Returns: baseURI + tokenId
    return string(abi.encodePacked(base, _toString(tokenId)));
}
```

**Example:**
- `baseURI = "https://your-app.com/api/metadata/"`
- `tokenURI(1)` returns `"https://your-app.com/api/metadata/1"`

---

## Where baseURI is NOT Used

### In Your Frontend:

```typescript
// ❌ WRONG - This is NOT how it works
const metadata = await fetch(baseURI + tokenId);

// ✅ CORRECT - Frontend uses Supabase client directly
import { getMetadata } from '@/lib/metadata';
const metadata = await getMetadata(tokenId);
```

**Your frontend code:**
- `MembershipPage.tsx` → Uses `getMetadata()` from `lib/metadata.ts`
- `lib/metadata.ts` → Uses `supabase.from('member_metadata')` directly
- **Never touches baseURI!**

---

## Summary Table

| Who | What They Use | Purpose |
|-----|--------------|---------|
| **Your Frontend** | Supabase Client Library (`lib/supabase.ts`) | Read/write metadata directly |
| **Wallets/Marketplaces** | `baseURI` (from contract) | Fetch metadata via HTTP |
| **Your Next.js API** | Supabase Client Library | Query database when wallet requests metadata |

---

## Why Two Flows?

1. **Frontend Flow (Direct Supabase):**
   - Fast, direct access
   - Can use authentication
   - Can update/delete (GDPR compliance)

2. **Wallet Flow (via baseURI):**
   - Standard ERC-721 way
   - Works with any wallet/marketplace
   - No authentication needed (public read)

---

## What You Need to Do

1. **For Frontend:** ✅ Already done! Your frontend uses Supabase directly.

2. **For baseURI:** Set it to your Next.js API URL:
   ```
   baseURI = "https://your-deployed-app.com/api/metadata/"
   ```

3. **Deploy your Next.js app** so wallets can access the API route.

---

## Final Answer

**baseURI is NOT used by your frontend.**

- **Frontend** → Uses Supabase client directly (no baseURI)
- **Wallets** → Use baseURI to fetch metadata via your Next.js API

They are **two separate systems** that both read from the same Supabase table!


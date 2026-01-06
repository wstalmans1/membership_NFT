# Supabase Integration Plan for GDPR-Compliant NFT Metadata

## Overview
This plan outlines how we'll integrate Supabase as a GDPR-compliant metadata storage backend for the Membership NFT system, while keeping the frontend deployed on IPFS.

---

## Phase 1: Supabase Setup (YOU DO THIS - Manual Steps)

### Step 1.1: Create Supabase Account
**What you'll do:**
1. Go to https://supabase.com
2. Sign up for a free account (GitHub/Google login)
3. Create a new project
4. Choose a project name (e.g., "qawl-dao-metadata")
5. Set a database password (save it securely!)
6. Choose a region closest to you
7. Wait ~2 minutes for project to initialize

**What you'll get:**
- Project URL: `https://xxxxx.supabase.co`
- API Key (anon/public): `eyJhbGc...` (long string)
- Service Role Key: `eyJhbGc...` (keep secret!)

**Where to find these:**
- Go to Project Settings → API
- Copy "Project URL" and "anon public" key

---

### Step 1.2: Create Database Table
**What you'll do:**
1. In Supabase dashboard, go to "Table Editor"
2. Click "New Table"
3. Name it: `nft_metadata`
4. Add these columns:

| Column Name | Type | Default | Nullable | Description |
|------------|------|---------|----------|-------------|
| `token_id` | `bigint` | - | NO (Primary Key) | NFT token ID |
| `owner_address` | `text` | - | NO | Ethereum address of owner |
| `metadata_json` | `jsonb` | - | NO | Full metadata JSON object |
| `created_at` | `timestamptz` | `now()` | NO | When metadata was created |
| `updated_at` | `timestamptz` | `now()` | NO | Last update timestamp |
| `deleted_at` | `timestamptz` | NULL | YES | GDPR deletion timestamp (NULL = not deleted) |

5. Set `token_id` as Primary Key
6. Click "Save"

**What this does:**
- Stores all NFT metadata in a database
- Allows soft deletion (GDPR compliance)
- Tracks creation/update times

---

### Step 1.3: Enable Row Level Security (RLS)
**What you'll do:**
1. In Table Editor, click on `nft_metadata` table
2. Go to "Policies" tab
3. Click "Enable RLS" (Row Level Security)
4. Add these policies:

**Policy 1: Public Read (anyone can view metadata)**
- Policy Name: `Public can read metadata`
- Allowed Operation: `SELECT`
- Target Roles: `public`
- Policy Definition: `true` (allow all reads)

**Policy 2: Owner can update (only owner can modify)**
- Policy Name: `Owner can update metadata`
- Allowed Operation: `UPDATE`
- Target Roles: `authenticated`
- Policy Definition: `auth.uid()::text = owner_address` (we'll use Ethereum address as auth)

**Policy 3: Owner can delete (only owner can delete)**
- Policy Name: `Owner can delete metadata`
- Allowed Operation: `DELETE`
- Target Roles: `authenticated`
- Policy Definition: `auth.uid()::text = owner_address`

**What this does:**
- Anyone can read metadata (needed for NFT display)
- Only owner can update/delete (GDPR compliance)

---

### Step 1.4: Create Storage Bucket for Photos
**What you'll do:**
1. In Supabase dashboard, go to "Storage"
2. Click "New bucket"
3. Name it: `nft-photos`
4. Set as: **Public bucket** (so photos can be accessed via URL)
5. Click "Create bucket"

**Storage Policies (for GDPR compliance):**
1. Go to "Policies" tab for the `nft-photos` bucket
2. Click "New Policy"
3. Add these policies:

**Policy 1: Public Read (anyone can view photos)**
- Policy Name: `Public can read photos`
- Allowed Operation: `SELECT`
- Target Roles: `public`
- Policy Definition: `true` (allow all reads)

**Policy 2: Authenticated Upload (only authenticated users can upload)**
- Policy Name: `Authenticated can upload photos`
- Allowed Operation: `INSERT`
- Target Roles: `authenticated`
- Policy Definition: `true` (we'll verify ownership in application code)

**Policy 3: Owner can update (only owner can modify their photo)**
- Policy Name: `Owner can update photos`
- Allowed Operation: `UPDATE`
- Target Roles: `authenticated`
- Policy Definition: `(bucket_id = 'nft-photos')` (we'll verify ownership in app)

**Policy 4: Owner can delete (only owner can delete their photo)**
- Policy Name: `Owner can delete photos`
- Allowed Operation: `DELETE`
- Target Roles: `authenticated`
- Policy Definition: `(bucket_id = 'nft-photos')` (we'll verify ownership in app)

**What this does:**
- Stores photos in Supabase Storage (keeps everything in one place!)
- Public access for displaying NFTs
- Owner-only update/delete for GDPR compliance
- Photos accessible via URL: `https://xxxxx.supabase.co/storage/v1/object/public/nft-photos/{tokenId}.jpg`

---

### Step 1.5: Create API Functions (Optional - for easier access)
**What you'll do:**
1. Go to "Database" → "Functions"
2. We'll create helper functions later (I'll provide SQL)

**What this does:**
- Makes it easier to query/update metadata
- Can be skipped for MVP (we'll use direct REST API)

---

## Phase 2: Environment Configuration (I'LL DO THIS)

### Step 2.1: Add Supabase Environment Variables
**What I'll do:**
1. Create `.env.local` file in frontend (if not exists)
2. Add Supabase credentials:
   ```
   NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...
   ```

**What you'll do:**
- Copy your Supabase URL and anon key from Step 1.1
- Paste them into `.env.local` (I'll create template)

---

### Step 2.2: Install Supabase Client Library
**What I'll do:**
1. Install `@supabase/supabase-js` package
2. Create Supabase client configuration file

**What this does:**
- Allows frontend to communicate with Supabase

---

## Phase 3: Frontend Integration (I'LL DO THIS)

### Step 3.1: Create Supabase Client and Storage Functions
**What I'll do:**
1. Create `lib/supabase.ts` - Supabase client setup (database + storage)
2. Create `lib/storage.ts` - Functions to:
   - Upload photo to Supabase Storage
   - Get photo URL from Supabase Storage
   - Delete photo from Supabase Storage (GDPR erasure)
3. Create `lib/metadata.ts` - Functions to:
   - Upload metadata to Supabase (includes photo URL)
   - Fetch metadata from Supabase
   - Update metadata (GDPR rectification)
   - Delete metadata (GDPR erasure)

**What this does:**
- Provides easy-to-use functions for both photos and metadata
- Everything stored in Supabase (simple for MVP!)

---

### Step 3.2: Create Metadata Collection Form
**What I'll do:**
1. Create `components/MintMembershipForm.tsx` component
2. Form fields:
   - Name (text input)
   - Date of Birth (date picker)
   - Photo upload (file input) - will upload to Supabase Storage
   - Citizenship details (text input)
   - Other fields as needed
3. Form validation
4. Photo handling:
   - User selects photo file
   - Upload to Supabase Storage bucket `nft-photos`
   - Get public URL from Supabase
   - Include URL in metadata JSON

**What this does:**
- Collects user data before minting
- Uploads photo to Supabase Storage
- Gets photo URL to include in metadata

---

### Step 3.3: Integrate Minting Flow
**What I'll do:**
1. Update `components/MembershipPage.tsx` or create new mint component
2. Flow:
   ```
   User fills form → Upload photo to Supabase Storage → Upload metadata (with photo URL) to Supabase → Mint NFT → Link tokenId to metadata
   ```
3. Handle transaction flow:
   - Show form
   - On submit:
     a. Upload photo to Supabase Storage → get photo URL
     b. Create metadata JSON (include photo URL)
     c. Upload metadata to Supabase (without tokenId initially)
     d. Call `mint()` on contract
     e. Extract `tokenId` from transaction receipt
     f. Update Supabase record with `tokenId` and link to photo file

**What this does:**
- Connects photo upload → metadata storage → minting
- Everything stored in Supabase (photos + metadata)

---

### Step 3.4: Create NFT Display Component
**What I'll do:**
1. Update NFT display to fetch from Supabase
2. Use `tokenURI()` from contract (points to Supabase API)
3. Fetch metadata JSON from Supabase
4. Render NFT card using HTML template (from `nft-template-example.html`)

**What this does:**
- Displays NFT with metadata from Supabase

---

## Phase 4: Contract Updates (I'LL CHECK IF NEEDED)

### Step 4.1: Verify BaseURI Setup
**What I'll check:**
1. Current `baseURI` in Constitution contract
2. How `tokenURI()` works in MembershipNFT
3. If we need to update `baseURI` to point to Supabase API

**What might need to change:**
- Update `baseURI` in Constitution to: `https://xxxxx.supabase.co/rest/v1/nft_metadata?token_id=eq.{tokenId}&select=metadata_json`
- OR create a simpler endpoint (we'll use Supabase REST API directly)

**What this does:**
- Makes `tokenURI(tokenId)` return Supabase API endpoint
- Wallets/marketplaces can fetch metadata automatically

---

## Phase 5: GDPR Compliance Features (I'LL DO THIS)

### Step 5.1: Create Update Metadata Function
**What I'll do:**
1. Add function to update metadata in `lib/metadata.ts`
2. Verify ownership (check `owner_address` matches signer)
3. Update `metadata_json` and `updated_at` in Supabase

**What this does:**
- Implements GDPR "Right to Rectification"

---

### Step 5.2: Create Delete Metadata Function
**What I'll do:**
1. Add function to delete metadata in `lib/metadata.ts`
2. Also delete photo from Supabase Storage
3. Implement soft delete (set `deleted_at` timestamp)
4. OR hard delete (remove row entirely + delete photo file)
5. Verify ownership before deletion

**What this does:**
- Implements GDPR "Right to Erasure"
- Deletes both metadata AND photo from Supabase

---

### Step 5.3: Create Data Export Function
**What I'll do:**
1. Add function to export all user's metadata
2. Returns JSON file download
3. Includes all metadata for user's tokens

**What this does:**
- Implements GDPR "Right to Data Portability"

---

### Step 5.4: Add UI for GDPR Actions
**What I'll do:**
1. Create "Manage My NFT" page/component
2. Buttons:
   - "Update Metadata"
   - "Delete Metadata" (with confirmation)
   - "Export My Data"
3. Show current metadata
4. Form to update fields

**What this does:**
- User-friendly interface for GDPR rights

---

## Phase 6: Testing (WE DO THIS TOGETHER)

### Step 6.1: Test Metadata Upload
**What we'll test:**
1. Fill form with test data
2. Upload to Supabase
3. Verify data appears in Supabase dashboard
4. Check JSON structure

---

### Step 6.2: Test Minting Flow
**What we'll test:**
1. Complete minting flow end-to-end
2. Verify metadata is linked to correct `tokenId`
3. Check transaction on Blockscout

---

### Step 6.3: Test NFT Display
**What we'll test:**
1. View NFT with metadata
2. Verify `tokenURI()` returns correct Supabase URL
3. Check metadata renders correctly

---

### Step 6.4: Test GDPR Features
**What we'll test:**
1. Update metadata → verify changes
2. Delete metadata → verify soft/hard delete
3. Export data → verify JSON download

---

## Phase 7: Documentation (I'LL DO THIS)

### Step 7.1: Create Setup Guide
**What I'll create:**
1. `documentation/SUPABASE_SETUP.md` - Step-by-step Supabase setup
2. Screenshots/instructions for manual steps
3. Troubleshooting guide

---

## Summary: What You Do vs What I Do

### YOU DO (Manual Steps):
1. ✅ Create Supabase account
2. ✅ Create database table (`nft_metadata`)
3. ✅ Set up Row Level Security policies
4. ✅ Create Storage bucket (`nft-photos`) for photos
5. ✅ Set up Storage policies
6. ✅ Copy Supabase credentials to `.env.local`

### I DO (Code Implementation):
1. ✅ Install Supabase client library
2. ✅ Create Supabase client configuration (database + storage)
3. ✅ Create photo upload/delete functions for Supabase Storage
4. ✅ Create metadata upload/fetch/update/delete functions
5. ✅ Create metadata collection form (with photo upload)
6. ✅ Integrate minting flow (photo → metadata → mint)
7. ✅ Update NFT display to use Supabase (fetch metadata + photo)
8. ✅ Add GDPR compliance features (delete metadata + photo)
9. ✅ Create documentation

---

## Files That Will Be Created/Modified

### New Files:
- `qawl2-frontend/lib/supabase.ts` - Supabase client (database + storage)
- `qawl2-frontend/lib/storage.ts` - Photo upload/delete functions
- `qawl2-frontend/lib/metadata.ts` - Metadata operations
- `qawl2-frontend/components/MintMembershipForm.tsx` - Metadata collection form (with photo upload)
- `qawl2-frontend/components/ManageNFT.tsx` - GDPR management UI
- `documentation/SUPABASE_SETUP.md` - Setup guide

### Modified Files:
- `qawl2-frontend/components/MembershipPage.tsx` - Add minting flow
- `qawl2-frontend/package.json` - Add Supabase dependency
- `qawl2-frontend/.env.local` - Add Supabase credentials (template)

---

## Estimated Time

- **Your manual steps:** ~15-20 minutes
- **My implementation:** ~1-2 hours of coding
- **Testing together:** ~30 minutes

---

## Next Steps

1. **You read this plan** ✅ (you're doing this now)
2. **You approve/ask questions**
3. **You complete Phase 1** (Supabase setup)
4. **I implement Phases 2-5** (code)
5. **We test together** (Phase 6)
6. **I create documentation** (Phase 7)

---

## Decisions Made

✅ **Photo storage:** Supabase Storage (keeps everything in one place - simple for MVP!)

**Still to decide:**
1. **Deletion strategy:** Soft delete (keep record, mark deleted) or hard delete (remove entirely)?
   - **Recommendation for MVP:** Hard delete (simpler, fully GDPR compliant)

2. **Authentication:** How to verify ownership?
   - Option A: Sign message with wallet, verify signature (more secure)
   - Option B: Simple address check (less secure but OK for MVP)
   - **Recommendation for MVP:** Option B (simpler, we can upgrade later)

Let me know your preferences, or I'll use the recommendations above!
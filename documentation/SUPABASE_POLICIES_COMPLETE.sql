-- ============================================
-- Complete Supabase RLS Policies for member_metadata
-- ============================================
-- This script drops all existing policies and creates fresh ones
-- Run this in Supabase SQL Editor

-- ============================================
-- STEP 1: Drop ALL existing policies
-- ============================================
DROP POLICY IF EXISTS "Public can read metadata" ON public.member_metadata;
DROP POLICY IF EXISTS "Owner can update metadata" ON public.member_metadata;
DROP POLICY IF EXISTS "Owner can delete metadata" ON public.member_metadata;
DROP POLICY IF EXISTS "Anon can insert metadata" ON public.member_metadata;
DROP POLICY IF EXISTS "Anon can update metadata" ON public.member_metadata;
DROP POLICY IF EXISTS "Anon can delete metadata" ON public.member_metadata;
-- Drop any other policies that might exist
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'member_metadata' AND schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON public.member_metadata';
    END LOOP;
END $$;

-- ============================================
-- STEP 2: Create correct policies
-- ============================================

-- Policy 1: Public Read (anyone can view metadata)
CREATE POLICY "Public can read metadata"
ON public.member_metadata
FOR SELECT
TO public
USING (true);

-- Policy 2: Anon Insert (frontend can create metadata)
CREATE POLICY "Anon can insert metadata"
ON public.member_metadata
FOR INSERT
TO anon
WITH CHECK (true);

-- Policy 3: Anon Update (frontend can update token_id after minting)
CREATE POLICY "Anon can update metadata"
ON public.member_metadata
FOR UPDATE
TO anon
USING (true)
WITH CHECK (true);

-- Policy 4: Anon Delete (for GDPR compliance - frontend can delete)
CREATE POLICY "Anon can delete metadata"
ON public.member_metadata
FOR DELETE
TO anon
USING (true);

-- ============================================
-- Verify policies were created
-- ============================================
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'member_metadata' 
AND schemaname = 'public'
ORDER BY cmd, policyname;


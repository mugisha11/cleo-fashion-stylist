-- ============================================
-- Supabase Storage Policy for 'uploads' Bucket
-- Run this in Supabase SQL Editor
-- ============================================

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Allow public to read uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow public to upload files" ON storage.objects;
DROP POLICY IF EXISTS "Allow public to update files" ON storage.objects;
DROP POLICY IF EXISTS "Allow public to delete files" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to read uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to upload files" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to update their files" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete their files" ON storage.objects;

-- ============================================
-- Create Policies for 'uploads' bucket
-- Using 'public' role works with Firebase Auth
-- ============================================

-- Policy: Allow public to SELECT (read) files
CREATE POLICY "Allow public to read uploads"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id = 'uploads'::text
);

-- Policy: Allow public to INSERT (upload) files
-- This works with Firebase Auth since public role is used
CREATE POLICY "Allow public to upload files"
ON storage.objects
FOR INSERT
TO public
WITH CHECK (
  bucket_id = 'uploads'::text
);

-- Policy: Allow public to UPDATE files
CREATE POLICY "Allow public to update files"
ON storage.objects
FOR UPDATE
TO public
USING (
  bucket_id = 'uploads'::text
)
WITH CHECK (
  bucket_id = 'uploads'::text
);

-- Policy: Allow public to DELETE files
CREATE POLICY "Allow public to delete files"
ON storage.objects
FOR DELETE
TO public
USING (
  bucket_id = 'uploads'::text
);

-- ============================================
-- Verify policies were created
-- ============================================
SELECT * FROM pg_policies WHERE tablename = 'objects' AND policyname LIKE '%uploads%';

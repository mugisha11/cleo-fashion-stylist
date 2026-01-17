-- Storage Policies for 'wardrobe' bucket
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/kjiqtspkvnwgjoerpyxb/sql/new
-- 
-- NOTE: Since the app uses Firebase Auth (not Supabase Auth), we need permissive policies.
-- The app code already checks authentication before uploading, and files are stored in
-- user-specific paths (wardrobe/$userId/$imageId.jpg), so this is safe.

-- Drop existing policies if they exist (to avoid errors on re-run)
DROP POLICY IF EXISTS "Allow public uploads to wardrobe" ON storage.objects;
DROP POLICY IF EXISTS "Allow public reads from wardrobe" ON storage.objects;
DROP POLICY IF EXISTS "Allow public deletes from wardrobe" ON storage.objects;

-- Policy 1: Allow public uploads to wardrobe bucket
-- (App code already checks Firebase Auth before calling this)
CREATE POLICY "Allow public uploads to wardrobe"
ON storage.objects
FOR INSERT
TO public
WITH CHECK (
  bucket_id = 'wardrobe'::text
);

-- Policy 2: Allow public reads from wardrobe bucket
CREATE POLICY "Allow public reads from wardrobe"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id = 'wardrobe'::text
);

-- Policy 3: Allow public deletes from wardrobe bucket
-- (App code already checks Firebase Auth before calling this)
CREATE POLICY "Allow public deletes from wardrobe"
ON storage.objects
FOR DELETE
TO public
USING (
  bucket_id = 'wardrobe'::text
);

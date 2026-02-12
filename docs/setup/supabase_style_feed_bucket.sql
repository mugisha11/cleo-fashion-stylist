-- Create the style_feed bucket for Post Look images
-- Run in Supabase Dashboard → SQL Editor (once per project).
-- If policies already exist, drop them first or you'll get "already exists" errors.

-- 1. Create the bucket (public so image URLs work without signed URLs)
INSERT INTO storage.buckets (id, name, public)
VALUES ('style_feed', 'style_feed', true)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  public = EXCLUDED.public;

-- 2. Allow anon to upload (INSERT) into style_feed
DROP POLICY IF EXISTS "Allow uploads to style_feed" ON storage.objects;
CREATE POLICY "Allow uploads to style_feed"
ON storage.objects
FOR INSERT
TO anon
WITH CHECK (bucket_id = 'style_feed');

-- 3. Allow public read (SELECT) so feed images display
DROP POLICY IF EXISTS "Allow public read style_feed" ON storage.objects;
CREATE POLICY "Allow public read style_feed"
ON storage.objects
FOR SELECT
TO anon
USING (bucket_id = 'style_feed');

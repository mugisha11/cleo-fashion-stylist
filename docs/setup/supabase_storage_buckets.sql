-- Create Supabase Storage buckets used by the app
-- Run in Supabase Dashboard → SQL Editor (once per project).
-- If a policy already exists, the DROP POLICY IF EXISTS avoids errors.

-- ========== 1. generated_outfits (My Outfits / Try-On saves) ==========
INSERT INTO storage.buckets (id, name, public)
VALUES ('generated_outfits', 'generated_outfits', true)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  public = EXCLUDED.public;

DROP POLICY IF EXISTS "Allow uploads to generated_outfits" ON storage.objects;
CREATE POLICY "Allow uploads to generated_outfits"
ON storage.objects FOR INSERT TO anon
WITH CHECK (bucket_id = 'generated_outfits');

DROP POLICY IF EXISTS "Allow public read generated_outfits" ON storage.objects;
CREATE POLICY "Allow public read generated_outfits"
ON storage.objects FOR SELECT TO anon
USING (bucket_id = 'generated_outfits');

-- ========== 2. uploads (Try-On user photos, temporary uploads) ==========
INSERT INTO storage.buckets (id, name, public)
VALUES ('uploads', 'uploads', true)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  public = EXCLUDED.public;

DROP POLICY IF EXISTS "Allow uploads to uploads bucket" ON storage.objects;
CREATE POLICY "Allow uploads to uploads bucket"
ON storage.objects FOR INSERT TO anon
WITH CHECK (bucket_id = 'uploads');

DROP POLICY IF EXISTS "Allow public read uploads" ON storage.objects;
CREATE POLICY "Allow public read uploads"
ON storage.objects FOR SELECT TO anon
USING (bucket_id = 'uploads');

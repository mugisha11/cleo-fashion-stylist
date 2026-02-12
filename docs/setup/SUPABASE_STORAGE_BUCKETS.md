# Supabase Storage: Create buckets so uploads work

If **saving to the bucket** fails (e.g. "Bucket not found", "Permission denied", or 400 on upload), create the buckets and policies in Supabase.

## Quick fix: run the SQL (recommended)

1. Open **Supabase Dashboard** → your project.
2. Go to **SQL Editor**.
3. Copy the contents of **`docs/setup/supabase_storage_buckets.sql`** and run it.

This creates (or updates):

- **`generated_outfits`** – used when you save a try-on result to **My Outfits**.
- **`uploads`** – used when you pick/upload a photo on the Try-On page.

Both are **public** buckets with **anon** INSERT and SELECT so the app can upload and read without Supabase Auth.

## Manual setup (if you prefer the UI)

### 1. Create each bucket

1. In Supabase: **Storage** → **New bucket**.
2. Create:
   - **Name:** `generated_outfits` → **Public bucket:** ON → Create.
   - **Name:** `uploads` → **Public bucket:** ON → Create.

### 2. Add policies per bucket

For **each** bucket (`generated_outfits` and `uploads`):

1. Open the bucket → **Policies**.
2. **New policy** → **For full customization**.
3. **INSERT** policy:
   - Name: e.g. `Allow uploads to generated_outfits`
   - Operation: **INSERT**
   - Target: this bucket
   - Definition: **true** (or `bucket_id = 'generated_outfits'`) and allow **anon**.
4. **SELECT** policy:
   - Name: e.g. `Allow public read generated_outfits`
   - Operation: **SELECT**
   - Definition: **true** (or same `bucket_id`) and allow **anon**.

Save and repeat for the other bucket.

## After setup

Try again in the app:

- **My Outfits** – save a try-on result; it should upload to `generated_outfits`.
- **Try-On** – change photo; it should upload to `uploads`.

If it still fails, check the browser/IDE console for the exact Supabase error (e.g. "Bucket not found" vs "new row violates row-level security").

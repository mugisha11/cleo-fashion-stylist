# Supabase Storage Setup Guide - Fix Upload Issues

## Problem
The app is failing to upload wardrobe items because the `wardrobe` storage bucket doesn't exist in Supabase.

## Solution: Create Storage Buckets

### Step 1: Access Supabase Dashboard

1. Go to: **https://supabase.com/dashboard**
2. Sign in with your account
3. Select your project: **`kjiqtspkvnwgjoerpyxb`**

### Step 2: Navigate to Storage

1. In the left sidebar, click **"Storage"**
2. You'll see a list of existing buckets (if any)

### Step 3: Create the "wardrobe" Bucket

1. Click **"New bucket"** button (top right)
2. Fill in the details:
   - **Name**: `wardrobe` (exactly this name, lowercase)
   - **Public bucket**: ✅ **Check this** (toggle ON)
   - **File size limit**: `5242880` (5MB in bytes)
   - **Allowed MIME types**: `image/jpeg,image/png,image/webp`
3. Click **"Create bucket"**

### Step 4: Set Up Storage Policies (Important!)

After creating the bucket, you need to set up policies so authenticated users can upload:

1. Click on the **`wardrobe`** bucket you just created
2. Go to the **"Policies"** tab
3. Click **"New Policy"**

#### Policy 1: Allow Authenticated Users to Upload

1. **Policy Name**: `Allow authenticated uploads`
2. **Allowed operation**: `INSERT`
3. **Policy definition**: Use this SQL:

```sql
(
  (bucket_id = 'wardrobe'::text) AND 
  (auth.role() = 'authenticated'::text)
)
```

4. Click **"Review"** then **"Save policy"**

#### Policy 2: Allow Authenticated Users to Read

1. **Policy Name**: `Allow authenticated reads`
2. **Allowed operation**: `SELECT`
3. **Policy definition**: Use this SQL:

```sql
(
  (bucket_id = 'wardrobe'::text) AND 
  (auth.role() = 'authenticated'::text)
)
```

4. Click **"Review"** then **"Save policy"**

#### Policy 3: Allow Users to Delete Their Own Files

1. **Policy Name**: `Allow users to delete own files`
2. **Allowed operation**: `DELETE`
3. **Policy definition**: Use this SQL:

```sql
(
  (bucket_id = 'wardrobe'::text) AND 
  (auth.role() = 'authenticated'::text) AND
  (auth.uid()::text = (storage.foldername(name))[1])
)
```

4. Click **"Review"** then **"Save policy"**

### Step 5: Create Other Required Buckets (Optional but Recommended)

Create these buckets with the same settings:

1. **`avatars`** - For user avatars
   - Public: Yes
   - File size limit: 10MB
   - MIME types: `image/jpeg,image/png,model/gltf-binary,model/gltf+json`

2. **`outfits`** - For outfit previews
   - Public: Yes
   - File size limit: 5MB
   - MIME types: `image/jpeg,image/png,image/webp`

3. **`uploads`** - For VTON uploads (if using)
   - Public: No (private)
   - File size limit: 10MB
   - MIME types: `image/jpeg,image/png`

Apply the same policies to these buckets.

## Verify Supabase Connection

### Check Your Supabase Configuration

Your app is configured with:
- **Supabase URL**: `https://kjiqtspkvnwgjoerpyxb.supabase.co`
- **Anon Key**: `sb_publishable_A4DglmUBJorcilVMduJA4Q_ZTguPkKI`

These are set in `lib/main.dart` (lines 44-45).

### Test the Connection

1. After creating the bucket, try uploading a wardrobe item again
2. The error should disappear
3. If you still see errors, check:
   - You're logged in (authentication required)
   - The bucket name is exactly `wardrobe` (lowercase, no spaces)
   - The bucket is set to Public
   - The policies are created correctly

## Quick SQL Script (Alternative Method)

If you prefer using SQL, you can also create buckets via SQL Editor:

```sql
-- Note: Buckets must be created via Dashboard or API
-- But you can verify they exist:
SELECT * FROM storage.buckets WHERE name = 'wardrobe';

-- If the bucket doesn't exist, create it via Dashboard
```

## Troubleshooting

### Error: "Bucket not found"
- ✅ Solution: Create the bucket in Supabase Dashboard > Storage

### Error: "Permission denied"
- ✅ Solution: Add storage policies (see Step 4 above)

### Error: "File too large"
- ✅ Solution: Check file size limit in bucket settings (should be 5MB for wardrobe)

### Error: "Invalid MIME type"
- ✅ Solution: Check allowed MIME types in bucket settings

## After Setup

Once the bucket is created:
1. ✅ Restart the app
2. ✅ Try uploading a wardrobe item
3. ✅ The upload should work!

## Need Help?

If you still have issues:
1. Check the browser console for detailed error messages
2. Verify you're logged in (authentication required)
3. Check Supabase Dashboard > Storage > wardrobe bucket exists
4. Verify policies are set correctly

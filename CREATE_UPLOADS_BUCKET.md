# How to Create 'uploads' Bucket in Supabase

## Quick Steps

1. **Go to Supabase Dashboard**
   - Visit: https://supabase.com/dashboard
   - Select your project

2. **Navigate to Storage**
   - Click on **"Storage"** in the left sidebar
   - Or go directly to: `https://supabase.com/dashboard/project/YOUR_PROJECT_ID/storage/buckets`

3. **Create New Bucket**
   - Click the **"New bucket"** button (usually top right)
   - Enter bucket name: `uploads`
   - Make it **Public**: ✅ (toggle ON)
   - Click **"Create bucket"**

4. **Configure Bucket Settings** (Optional but Recommended)
   - Click on the `uploads` bucket to open settings
   - **File size limit**: 10MB (or higher if needed)
   - **Allowed MIME types**: 
     - `image/jpeg`
     - `image/png`
     - `image/webp`
   - **Public**: Yes ✅

5. **Set Bucket Policies** (Important for Security)
   - Go to **"Policies"** tab in the bucket settings
   - Click **"New Policy"**
   - Choose **"For full customization"**
   - Policy name: `Allow authenticated uploads`
   - Policy definition:
   ```sql
   (bucket_id = 'uploads'::text) AND (auth.role() = 'authenticated'::text)
   ```
   - Operations: SELECT, INSERT, UPDATE, DELETE
   - Click **"Review"** then **"Save policy"**

## Alternative: Use Existing 'wardrobe' Bucket

**Good news!** I've already updated the code to use the existing `wardrobe` bucket instead. 

**To use the fix:**
1. Hot restart the Flutter app (press `R` in terminal)
2. The Try-On feature should now work without creating a new bucket

**If you still want to create the 'uploads' bucket:**
- Follow the steps above
- Then I can update the code to use it specifically for try-on uploads

## Current Setup

The code now uses:
- **Bucket**: `wardrobe`
- **Path**: `tryon-uploads/{userId}/{timestamp}.jpg`

This works because:
- ✅ The `wardrobe` bucket already exists
- ✅ It's configured for public image uploads
- ✅ The path prefix keeps try-on photos organized separately

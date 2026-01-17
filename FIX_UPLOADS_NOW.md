# 🚀 Fix 'uploads' Bucket Permission - DO THIS NOW

## Quick Fix (Choose One)

### Option A: Run SQL Script (2 minutes) ⭐ RECOMMENDED

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard
   - Select your project
   - Click **"SQL Editor"** in left sidebar

2. **Run the Script**
   - Open file: `supabase_uploads_policy.sql`
   - Copy ALL the SQL code
   - Paste into SQL Editor
   - Click **"Run"** button

3. **Restart App**
   - Press `R` in terminal (hot restart)
   - Try uploading photo again

### Option B: Use Dashboard (3 minutes)

1. **Go to Storage**
   - Supabase Dashboard → **Storage** → Click **`uploads`** bucket

2. **Create Policy**
   - Click **"Policies"** tab
   - Click **"New Policy"**
   - Choose **"For full customization"**

3. **Fill in:**
   - **Name:** `Allow public uploads`
   - **Definition:** `bucket_id = 'uploads'::text`
   - **Operations:** ✅ SELECT, ✅ INSERT, ✅ UPDATE, ✅ DELETE
   - **Target roles:** `public`
   - Click **"Review"** → **"Save policy"**

4. **Restart App**
   - Press `R` in terminal
   - Try uploading photo again

## ✅ Done!

After either option, the upload should work. The error will be gone!

## Why This Works

Your app uses **Firebase Auth**, not Supabase Auth. So we use `public` role instead of `authenticated` role. This allows Firebase-authenticated users to upload files.

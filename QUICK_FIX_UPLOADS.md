# Quick Fix for 'uploads' Bucket Permission Error

## 🚨 Problem
The error shows: "Permission denied for bucket 'uploads'". This happens because:
1. The bucket exists ✅
2. But policies don't allow INSERT operations ❌
3. Your app uses **Firebase Auth**, not Supabase Auth, so `auth.role() = 'authenticated'` won't work

## ✅ Solution 1: Use SQL Script (Recommended)

I've created `supabase_uploads_policy.sql` - run it in Supabase SQL Editor:

1. **Go to Supabase Dashboard** → **SQL Editor**
2. **Copy the entire contents** of `supabase_uploads_policy.sql`
3. **Paste and Run** the script
4. **Hot restart** the Flutter app (press `R`)

This creates policies that work with Firebase Auth.

## ✅ Solution 2: Use Dashboard (Quick Fix)

1. **Go to Supabase Dashboard** → **Storage** → **`uploads` bucket**
2. **Click "Policies" tab**
3. **Click "New Policy"**
4. **Choose "For full customization"**
5. **Policy Name:** `Allow public uploads (Firebase Auth)`
6. **Policy Definition:**
   ```sql
   bucket_id = 'uploads'::text
   ```
7. **Operations:** ✅ SELECT, ✅ INSERT, ✅ UPDATE, ✅ DELETE
8. **Target roles:** `public` (this works with Firebase Auth)
9. **Click "Review"** → **"Save policy"**

⚠️ **Note:** This allows any authenticated user to upload. For production, restrict by user ID.

## ✅ Solution 3: Use Existing 'wardrobe' Bucket (Fastest)

If you want to test immediately without fixing policies:

I can update the code to use the `wardrobe` bucket which already has working policies. Just let me know!

## 🧪 After Fixing

1. Hot restart app (press `R` in terminal)
2. Try uploading a photo again
3. Should work now! ✅

# Fix 'uploads' Bucket Upload Issues

## ✅ Code Updated
The code now uses the `uploads` bucket. Hot restart the app (press `R` in terminal) to apply changes.

## 🔍 Check Bucket Permissions

If uploads still fail, check these in Supabase Dashboard:

### 1. Verify Bucket Exists
- Go to **Storage** → **Buckets**
- Confirm `uploads` bucket is listed
- Check it's marked as **Public** ✅

### 2. Check Bucket Policies (CRITICAL)

The bucket needs policies to allow authenticated users to upload:

1. **Go to Storage** → Click on `uploads` bucket
2. **Click "Policies" tab**
3. **Check if policies exist:**
   - If NO policies → Create one (see below)
   - If policies exist → Verify they allow INSERT

### 3. Create Upload Policy (If Missing)

**Policy Name:** `Allow authenticated uploads`

**Policy Definition:**
```sql
(bucket_id = 'uploads'::text) AND (auth.role() = 'authenticated'::text)
```

**Operations to Enable:**
- ✅ SELECT (read files)
- ✅ INSERT (upload files) ← **MOST IMPORTANT**
- ✅ UPDATE (optional)
- ✅ DELETE (optional)

**Steps:**
1. Click **"New Policy"**
2. Choose **"For full customization"**
3. Paste the policy definition above
4. Select **INSERT** operation (at minimum)
5. Click **"Review"** → **"Save policy"**

### 4. Quick Test Policy (Alternative)

If you want a simpler policy for testing:

**Policy Name:** `Public uploads (testing)`

**Policy Definition:**
```sql
true
```

**Operations:** SELECT, INSERT

⚠️ **Warning:** This allows anyone to upload. Use only for testing, then restrict to authenticated users.

### 5. Verify User is Authenticated

Make sure the user is logged in:
- Check Firebase Auth is working
- User should have a valid session
- Check console logs for auth errors

## 🧪 Test Upload

After fixing policies:
1. Hot restart app (press `R`)
2. Try uploading a photo again
3. Check error message - it should be more specific now

## 📋 Common Issues

**Error: "Permission denied"**
→ Bucket policies missing or don't allow INSERT

**Error: "Bucket not found"**
→ Bucket name typo or doesn't exist

**Error: "File too large"**
→ Check bucket file size limit (should be 10MB+)

**Error: "Invalid MIME type"**
→ Check bucket allowed MIME types include `image/jpeg`

## 🔧 Current Code Settings

- **Bucket:** `uploads`
- **Path:** `tryon-uploads/{userId}/{timestamp}.jpg`
- **Content Type:** `image/jpeg`
- **Upsert:** Enabled (overwrites if file exists)

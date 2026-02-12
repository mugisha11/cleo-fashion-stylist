# Supabase Storage: Style Feed (Post Look images)

**Post Look uses Supabase for images only.** Post metadata (caption, likes, comments, feed list) is still in **Firebase Firestore**. So you may see Firestore/WebChannel messages in the console when the network is flaky; those are from Firestore, not Supabase. Post Look images are stored in **Supabase Storage** (bucket `style_feed`). A **400 Bad Request** on upload usually means the bucket doesn't exist or Storage policies are blocking the request.

## Fix 400 Bad Request: Create bucket and policies (one-time)

### 1. Create the bucket

1. Open **Supabase Dashboard**: https://supabase.com/dashboard  
2. Select your project (e.g. **kjiqtspkvnwgjoerpyxb**).  
3. Go to **Storage** in the left sidebar.  
4. Click **New bucket**.  
5. **Name:** `style_feed` (exact name, no spaces).  
6. **Public bucket:** turn **ON** so feed image URLs work without signed URLs.  
7. Click **Create bucket**.

### 2. Add policies so the app can upload

The app uses the Supabase **anon** key (no Supabase auth). You must allow uploads for that role.

1. In **Storage**, open the **style_feed** bucket.  
2. Click **Policies** (or the bucket menu → **Policies**).  
3. Click **New policy** → **For full customization** (or use a template).  
4. Add an **INSERT** policy:
   - **Policy name:** `Allow uploads to style_feed`
   - **Allowed operation:** `INSERT` (or **All** if you prefer)
   - **Target:** bucket `style_feed`
   - **Policy definition (INSERT):**  
     Use: **true** (allow all)  
     Or with RLS: `bucket_id = 'style_feed'`  
     So that the **anon** role can upload.  
5. Add a **SELECT** policy so images can be read:
   - **Policy name:** `Allow public read style_feed`
   - **Allowed operation:** `SELECT`
   - **Policy definition:** **true** (or `bucket_id = 'style_feed'`)

If your UI uses **RLS policy expression**:

- **INSERT:** `(bucket_id = 'style_feed')`
- **SELECT:** `(bucket_id = 'style_feed')`

Ensure the **anon** role is allowed for these (no “authenticated only” restriction if the app doesn’t sign in with Supabase).

### 3. Save and test

Save the policies, then try **Post Look** again in the app. Upload should succeed and the image URL will point to Supabase.

---

## Summary

- **400 on POST** → bucket missing or policy blocking. Create `style_feed` and add INSERT (and SELECT) for anon.  
- **ReadyPlayerMe 400** → different issue (avatar URL expired); not related to Post Look.  
- Firestore still stores post metadata; only the image file is in Supabase Storage.

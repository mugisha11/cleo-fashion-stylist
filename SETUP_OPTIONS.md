# 🎯 Supabase Bucket Setup - Choose Your Method

## Your Current Setup ✅

Your Flutter app is **already correctly configured** with:
- **Supabase URL**: `https://kjiqtspkvnwgjoerpyxb.supabase.co`
- **Anon Key**: `sb_publishable_A4DglmUBJorcilVMduJA4Q_ZTguPkKI`

This is correct for your Flutter app! ✅

## What You Need Now

To create the `wardrobe` bucket, you need the **SERVICE ROLE KEY** (different from anon key).

**Get it here**: https://supabase.com/dashboard/project/kjiqtspkvnwgjoerpyxb/settings/api
- Look for **"service_role"** key (secret, starts with `eyJ...`)

---

## Setup Methods (Choose One)

### Option 1: JavaScript/Node.js Script ⭐ (If you prefer JS)

```bash
# Install dependencies
npm install

# Run interactively (will prompt for key)
npm run setup-bucket

# Or run directly
node setup_supabase_bucket.js --interactive
node setup_supabase_bucket.js --key "your_service_role_key"
```

### Option 2: Python Script ⭐ (If you prefer Python)

```bash
# Run interactively
python setup_supabase_bucket.py --interactive

# Or with key
python setup_supabase_bucket.py --key "your_service_role_key"
```

### Option 3: Manual (Via Dashboard)

Follow instructions in `QUICK_FIX_SUPABASE.md`

---

## After Running Script

The script creates the bucket, but you still need to set up **3 storage policies**:

1. Go to: https://supabase.com/dashboard/project/kjiqtspkvnwgjoerpyxb/storage/buckets/wardrobe/policies
2. Create these policies:

**Policy 1: INSERT**
- SQL: `(bucket_id = 'wardrobe'::text) AND (auth.role() = 'authenticated'::text)`

**Policy 2: SELECT**
- SQL: `(bucket_id = 'wardrobe'::text) AND (auth.role() = 'authenticated'::text)`

**Policy 3: DELETE**
- SQL: `(bucket_id = 'wardrobe'::text) AND (auth.role() = 'authenticated'::text)`

---

## Key Differences

| Key Type | Used For | Where to Find |
|----------|----------|---------------|
| **Anon Key** | Client-side operations (Flutter app) | Already in your `main.dart` ✅ |
| **Service Role Key** | Admin operations (creating buckets) | Dashboard > Settings > API > service_role |

Your Flutter app is correct! You just need the service role key to create the bucket.

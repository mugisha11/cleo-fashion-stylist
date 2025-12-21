# Supabase Database Setup Guide

## Quick Setup

1. **Go to your Supabase Dashboard**: https://supabase.com/dashboard
2. **Select your project**: `kjiqtspkvnwgjoerpyxb`
3. **Navigate to SQL Editor**
4. **Copy and paste the contents of `supabase_migrations.sql`**
5. **Run the migration**

## Tables Created

### 1. `users`
- Stores user profiles
- Links to Supabase Auth via `id` (UUID)
- Fields: email, display_name, avatar_url, avatar_model_url

### 2. `onboarding_data`
- Stores user onboarding preferences
- One-to-one with users
- Fields: fashion_style, favorite_colors, occasion, budget, shopping_frequency, style_inspiration
- Body measurements: height_cm, gender, body_type

### 3. `wardrobe_items`
- Stores user's clothing items
- Fields: image_url, category, color_tags (array), brand, notes
- Indexed by user_id, category, and color_tags for fast filtering

### 4. `outfits`
- Stores saved outfits and AI recommendations
- Fields: name, item_ids (array of wardrobe_item UUIDs), preview_image_url, is_recommended

## Storage Buckets

Create these buckets in Supabase Storage:

1. **`avatars`** - For user avatar images and 3D models
   - Public: Yes
   - File size limit: 10MB
   - Allowed MIME types: image/jpeg, image/png, model/gltf-binary, model/gltf+json

2. **`wardrobe`** - For wardrobe item images
   - Public: Yes
   - File size limit: 5MB
   - Allowed MIME types: image/jpeg, image/png, image/webp

3. **`outfits`** - For outfit preview images
   - Public: Yes
   - File size limit: 5MB
   - Allowed MIME types: image/jpeg, image/png, image/webp

## Row Level Security (RLS)

All tables have RLS enabled with policies that:
- Users can only view/insert/update/delete their own data
- Uses `auth.uid()` to match user_id

## Indexes

Performance indexes created on:
- `users.email` - Fast login lookups
- `wardrobe_items.user_id, category, color_tags` - Fast filtering
- `outfits.user_id, is_recommended` - Fast recommendation queries

## Usage in Flutter

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// Insert user
await supabase.from('users').insert({
  'id': userId,
  'email': email,
  'display_name': displayName,
});

// Insert wardrobe item
await supabase.from('wardrobe_items').insert({
  'user_id': userId,
  'image_url': imageUrl,
  'category': 'shirt',
  'color_tags': ['red', 'blue'],
});

// Query user's wardrobe
final items = await supabase
  .from('wardrobe_items')
  .select()
  .eq('user_id', userId)
  .order('created_at', ascending: false);
```

## Notes

- All UUIDs use `uuid_generate_v4()` for auto-generation
- `created_at` and `updated_at` timestamps are auto-managed
- Triggers automatically update `updated_at` on row changes
- Arrays (color_tags, item_ids) use PostgreSQL array types for efficient storage


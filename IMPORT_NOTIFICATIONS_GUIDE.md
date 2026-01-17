# How to Import Notifications CSV into Supabase

## Issue
Supabase CSV import requires the table to exist first with matching column names.

## ✅ QUICK FIX (Step-by-Step)

### Step 1: Check if Table Exists
Run this in Supabase SQL Editor:
```sql
-- File: check_notifications_table.sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'notifications'
ORDER BY ordinal_position;
```

### Step 2: Create Table (if missing)
Run this in Supabase SQL Editor:
```sql
-- File: create_notifications_table_if_missing.sql
-- This creates the table with exact column names matching the CSV
```

### Step 3: Import CSV
1. Go to Supabase Dashboard > Table Editor > `notifications`
2. Click "Insert" > "Import data from CSV"
3. Upload `sample_notifications.csv`

## Solution Options

### Option 1: Create Table First (Recommended)

1. **Run the SQL schema** in Supabase SQL Editor:
   ```sql
   -- Run: create_notifications_table_if_missing.sql
   -- OR: supabase_notifications_schema.sql
   ```

2. **Verify table exists**:
   ```sql
   SELECT column_name, data_type 
   FROM information_schema.columns 
   WHERE table_name = 'notifications';
   ```

3. **Then import CSV** via Supabase Dashboard:
   - Go to Table Editor > `notifications`
   - Click "Insert" > "Import data from CSV"
   - Upload `sample_notifications.csv`

### Option 2: Use SQL INSERT (Alternative)

If CSV import still fails, use SQL INSERT statements:

```sql
INSERT INTO notifications (
  id, user_id, type, title, body, payload, 
  is_read, is_sent, sent_at, content_value_score, 
  same_type_sent_today, created_at, read_at
) VALUES
(
  'a1b2c3d4-e5f6-4789-a012-b3c4d5e6f789',
  'firebase_user_abc123xyz',
  'daily_outfit',
  '✨ Your 3 outfits for today are ready',
  'Perfectly matched for your plans — see your AI-styled looks!',
  '{"deepLink": "dashboard", "screen": "daily_recommendations", "date": "2025-01-15", "recommendationsCount": 3}'::jsonb,
  false,
  true,
  '2025-01-15 06:30:00+00'::timestamptz,
  0.85,
  false,
  '2025-01-15 06:00:00+00'::timestamptz,
  NULL
),
(
  'b2c3d4e5-f6a7-4890-b123-c4d5e6f7a890',
  'firebase_user_abc123xyz',
  'event_outfit',
  '👔 Your outfit for ''Client Meeting'' is ready',
  'Want to review or try it on?',
  '{"deepLink": "calendar", "screen": "event_detail", "eventId": "c7d8e9f0-a1b2-4c5d-6e7f-8a9b0c1d2e3", "outfitId": "d8e9f0a1-b2c3-4d5e-6f7a-8b9c0d1e2f3"}'::jsonb,
  false,
  true,
  '2025-01-15 14:00:00+00'::timestamptz,
  0.90,
  false,
  '2025-01-15 14:00:00+00'::timestamptz,
  NULL
);
-- Add more rows as needed
```

### Option 3: Check Existing Table Structure

If the table already exists but with different columns:

1. **Check current columns**:
   ```sql
   SELECT column_name, data_type, is_nullable
   FROM information_schema.columns
   WHERE table_name = 'notifications'
   ORDER BY ordinal_position;
   ```

2. **Update CSV headers** to match existing columns

3. **Or alter table** to match schema:
   ```sql
   -- Add missing columns if needed
   ALTER TABLE notifications 
   ADD COLUMN IF NOT EXISTS content_value_score DECIMAL(3, 2) DEFAULT 0.8,
   ADD COLUMN IF NOT EXISTS same_type_sent_today BOOLEAN DEFAULT FALSE;
   ```

## Common Issues

### Issue: "Columns not present in your table"
**Cause**: Table doesn't exist or has different structure
**Fix**: Run `supabase_notifications_schema.sql` first

### Issue: "Invalid UUID format"
**Cause**: UUIDs must be proper format (8-4-4-4-12 hex)
**Fix**: Use the UUIDs from `sample_notifications_fixed.csv`

### Issue: "Invalid JSONB"
**Cause**: Payload must be valid JSON
**Fix**: Ensure payload column uses proper JSON syntax with escaped quotes

### Issue: "Timestamp format error"
**Cause**: Timestamps must be ISO 8601 format
**Fix**: Use format like `2025-01-15T06:30:00Z` or `2025-01-15 06:30:00+00`

## Verification

After importing, verify data:

```sql
-- Check row count
SELECT COUNT(*) FROM notifications;

-- Check sample data
SELECT id, type, title, is_read, created_at 
FROM notifications 
ORDER BY created_at DESC 
LIMIT 5;

-- Check by user
SELECT type, COUNT(*) 
FROM notifications 
WHERE user_id = 'firebase_user_abc123xyz'
GROUP BY type;
```

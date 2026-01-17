-- Check Notifications Table Structure
-- Run this in Supabase SQL Editor to see what columns exist

-- Option 1: Check if table exists and show columns
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'notifications'
ORDER BY ordinal_position;

-- Option 2: Check if table exists at all
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'notifications'
) AS table_exists;

-- Option 3: Show all tables with 'notification' in name
SELECT table_name 
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name LIKE '%notification%';

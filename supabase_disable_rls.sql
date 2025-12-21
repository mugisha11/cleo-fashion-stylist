-- ============================================
-- DISABLE RLS FOR DEVELOPMENT
-- Run this in Supabase SQL Editor to fix the RLS policy error
-- ============================================

-- Step 1: Drop all existing policies
DROP POLICY IF EXISTS "Users can view their own conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can create their own conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can update their own conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can delete their own conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can view their own messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can create their own messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON chat_messages;
DROP POLICY IF EXISTS "Allow all for authenticated users - conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Allow all for authenticated users - messages" ON chat_messages;

-- Step 2: Disable RLS completely (for development only)
ALTER TABLE chat_conversations DISABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages DISABLE ROW LEVEL SECURITY;

-- Step 3: Verify RLS is disabled
-- You can check this by running:
-- SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename IN ('chat_conversations', 'chat_messages');
-- rowsecurity should be 'f' (false) for both tables

-- ⚠️ WARNING: This disables all security checks!
-- Only use this for development. For production, you need to:
-- 1. Configure Supabase to accept Firebase Auth tokens, OR
-- 2. Use service role key for server-side operations, OR
-- 3. Implement proper RLS policies that work with Firebase Auth


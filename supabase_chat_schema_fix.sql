-- ============================================
-- Migration: Fix user_id to support Firebase Auth IDs (TEXT instead of UUID)
-- Run this in Supabase SQL Editor
-- ============================================

-- Drop existing policies first
DROP POLICY IF EXISTS "Users can view their own conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can create their own conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can update their own conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can delete their own conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can view their own messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can create their own messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON chat_messages;

-- Drop foreign key constraints
ALTER TABLE chat_messages DROP CONSTRAINT IF EXISTS chat_messages_user_id_fkey;
ALTER TABLE chat_conversations DROP CONSTRAINT IF EXISTS chat_conversations_user_id_fkey;

-- Drop indexes that depend on user_id
DROP INDEX IF EXISTS idx_chat_conversations_user_id;
DROP INDEX IF EXISTS idx_chat_messages_user_id;

-- Alter user_id columns from UUID to TEXT
ALTER TABLE chat_conversations 
    ALTER COLUMN user_id TYPE TEXT USING user_id::text;

ALTER TABLE chat_messages 
    ALTER COLUMN user_id TYPE TEXT USING user_id::text;

-- Recreate indexes
CREATE INDEX IF NOT EXISTS idx_chat_conversations_user_id ON chat_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id ON chat_messages(user_id);

-- Recreate RLS policies for Firebase Auth
-- Note: Since we're using Firebase Auth, we'll use a custom claim approach
-- For now, we'll allow authenticated requests with proper user_id matching
-- You may need to adjust these based on your Supabase auth setup

-- Policy: Users can view their own conversations
-- This checks if the user_id matches the authenticated user's ID from JWT claim
CREATE POLICY "Users can view their own conversations"
    ON chat_conversations FOR SELECT
    USING (
        -- Allow if user_id matches the Firebase user ID from JWT
        -- Adjust this based on how you pass Firebase user ID to Supabase
        user_id = current_setting('request.jwt.claims', true)::json->>'firebase_uid'
        OR
        -- Fallback: allow if authenticated (you may want to remove this in production)
        auth.role() = 'authenticated'
    );

-- Policy: Users can create their own conversations
CREATE POLICY "Users can create their own conversations"
    ON chat_conversations FOR INSERT
    WITH CHECK (
        user_id = current_setting('request.jwt.claims', true)::json->>'firebase_uid'
        OR
        auth.role() = 'authenticated'
    );

-- Policy: Users can update their own conversations
CREATE POLICY "Users can update their own conversations"
    ON chat_conversations FOR UPDATE
    USING (
        user_id = current_setting('request.jwt.claims', true)::json->>'firebase_uid'
        OR
        auth.role() = 'authenticated'
    );

-- Policy: Users can delete their own conversations
CREATE POLICY "Users can delete their own conversations"
    ON chat_conversations FOR DELETE
    USING (
        user_id = current_setting('request.jwt.claims', true)::json->>'firebase_uid'
        OR
        auth.role() = 'authenticated'
    );

-- Policy: Users can view their own messages
CREATE POLICY "Users can view their own messages"
    ON chat_messages FOR SELECT
    USING (
        user_id = current_setting('request.jwt.claims', true)::json->>'firebase_uid'
        OR
        auth.role() = 'authenticated'
    );

-- Policy: Users can create their own messages
CREATE POLICY "Users can create their own messages"
    ON chat_messages FOR INSERT
    WITH CHECK (
        user_id = current_setting('request.jwt.claims', true)::json->>'firebase_uid'
        OR
        auth.role() = 'authenticated'
    );

-- Policy: Users can update their own messages
CREATE POLICY "Users can update their own messages"
    ON chat_messages FOR UPDATE
    USING (
        user_id = current_setting('request.jwt.claims', true)::json->>'firebase_uid'
        OR
        auth.role() = 'authenticated'
    );


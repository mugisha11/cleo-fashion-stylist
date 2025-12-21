-- ============================================
-- Simple Migration: Fix user_id to support Firebase Auth IDs
-- Run this in Supabase SQL Editor
-- ============================================

-- Step 1: Drop existing policies
DROP POLICY IF EXISTS "Users can view their own conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can create their own conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can update their own conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can delete their own conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can view their own messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can create their own messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON chat_messages;

-- Step 2: Drop foreign key constraints (since we're not using Supabase auth.users)
ALTER TABLE chat_messages DROP CONSTRAINT IF EXISTS chat_messages_user_id_fkey;
ALTER TABLE chat_conversations DROP CONSTRAINT IF EXISTS chat_conversations_user_id_fkey;

-- Step 3: Drop indexes
DROP INDEX IF EXISTS idx_chat_conversations_user_id;
DROP INDEX IF EXISTS idx_chat_messages_user_id;

-- Step 4: Alter user_id columns from UUID to TEXT
-- If tables don't exist yet, this will fail - that's OK, just run the main schema file first
DO $$ 
BEGIN
    -- Check if column exists and is UUID type, then alter it
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chat_conversations' 
        AND column_name = 'user_id' 
        AND data_type = 'uuid'
    ) THEN
        ALTER TABLE chat_conversations ALTER COLUMN user_id TYPE TEXT USING user_id::text;
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chat_messages' 
        AND column_name = 'user_id' 
        AND data_type = 'uuid'
    ) THEN
        ALTER TABLE chat_messages ALTER COLUMN user_id TYPE TEXT USING user_id::text;
    END IF;
END $$;

-- Step 5: Recreate indexes
CREATE INDEX IF NOT EXISTS idx_chat_conversations_user_id ON chat_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id ON chat_messages(user_id);

-- Step 6: For development, create permissive RLS policies
-- These allow any authenticated request (you can tighten this later)
-- IMPORTANT: In production, you should implement proper Firebase token validation

-- Temporarily disable RLS for development (uncomment if needed)
-- ALTER TABLE chat_conversations DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE chat_messages DISABLE ROW LEVEL SECURITY;

-- OR create permissive policies (allows any authenticated user)
CREATE POLICY "Allow all for authenticated users - conversations"
    ON chat_conversations
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow all for authenticated users - messages"
    ON chat_messages
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Note: Since we're using Firebase Auth, Supabase's auth.role() = 'authenticated' 
-- won't work unless you configure Supabase to accept Firebase tokens.
-- For now, you may need to use the service role key or disable RLS.
-- To use service role key, update your ChatService to use:
-- Supabase.instance.client.from('chat_conversations').insert(...).auth(serviceRoleKey)


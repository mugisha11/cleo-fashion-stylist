-- ============================================
-- Chat Messages Schema for Cleo Fashion App
-- Stores AI conversation history with context
-- Uses TEXT for user_id to support Firebase Auth IDs
-- ============================================

-- Chat conversations table
CREATE TABLE IF NOT EXISTS chat_conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL, -- Firebase Auth user ID (string, not UUID)
    title TEXT, -- Auto-generated from first message
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_message_at TIMESTAMPTZ,
    message_count INTEGER DEFAULT 0
);

-- Chat messages table
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL, -- Firebase Auth user ID (string, not UUID)
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    metadata JSONB, -- {tokens_used, model, reasoning, etc.}
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sequence_number INTEGER NOT NULL -- Order within conversation
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_chat_conversations_user_id ON chat_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_conversations_updated_at ON chat_conversations(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation_id ON chat_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id ON chat_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sequence ON chat_messages(conversation_id, sequence_number);

-- RLS Policies
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Note: RLS policies need to be configured based on your auth setup
-- If using Firebase Auth with Supabase, you'll need to pass Firebase user ID
-- as a JWT claim or use service role key for inserts
-- For development, you may temporarily disable RLS or use permissive policies

-- Conversations policies (using Firebase user ID from JWT claim)
CREATE POLICY "Users can view their own conversations"
    ON chat_conversations FOR SELECT
    USING (
        user_id = current_setting('request.jwt.claims', true)::json->>'firebase_uid'
        OR auth.role() = 'authenticated'
    );

CREATE POLICY "Users can create their own conversations"
    ON chat_conversations FOR INSERT
    WITH CHECK (
        user_id = current_setting('request.jwt.claims', true)::json->>'firebase_uid'
        OR auth.role() = 'authenticated'
    );

CREATE POLICY "Users can update their own conversations"
    ON chat_conversations FOR UPDATE
    USING (
        user_id = current_setting('request.jwt.claims', true)::json->>'firebase_uid'
        OR auth.role() = 'authenticated'
    );

CREATE POLICY "Users can delete their own conversations"
    ON chat_conversations FOR DELETE
    USING (
        user_id = current_setting('request.jwt.claims', true)::json->>'firebase_uid'
        OR auth.role() = 'authenticated'
    );

-- Messages policies
CREATE POLICY "Users can view their own messages"
    ON chat_messages FOR SELECT
    USING (
        user_id = current_setting('request.jwt.claims', true)::json->>'firebase_uid'
        OR auth.role() = 'authenticated'
    );

CREATE POLICY "Users can create their own messages"
    ON chat_messages FOR INSERT
    WITH CHECK (
        user_id = current_setting('request.jwt.claims', true)::json->>'firebase_uid'
        OR auth.role() = 'authenticated'
    );

CREATE POLICY "Users can update their own messages"
    ON chat_messages FOR UPDATE
    USING (
        user_id = current_setting('request.jwt.claims', true)::json->>'firebase_uid'
        OR auth.role() = 'authenticated'
    );

-- Triggers
CREATE TRIGGER update_chat_conversations_updated_at 
    BEFORE UPDATE ON chat_conversations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update conversation metadata when message is added
CREATE OR REPLACE FUNCTION update_conversation_on_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE chat_conversations
    SET 
        message_count = message_count + 1,
        last_message_at = NEW.created_at,
        updated_at = NOW()
    WHERE id = NEW.conversation_id;
    
    -- Auto-generate title from first user message
    IF NEW.role = 'user' AND NEW.sequence_number = 1 THEN
        UPDATE chat_conversations
        SET title = LEFT(NEW.content, 50)
        WHERE id = NEW.conversation_id AND title IS NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_conversation_on_message_trigger
    AFTER INSERT ON chat_messages
    FOR EACH ROW EXECUTE FUNCTION update_conversation_on_message();

-- Comments
COMMENT ON TABLE chat_conversations IS 'AI chat conversations with context';
COMMENT ON TABLE chat_messages IS 'Individual messages in conversations with full history';

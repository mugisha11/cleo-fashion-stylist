-- User Preferences Table Migration
-- For storing questionnaire responses and user preferences

-- Create user_preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL UNIQUE, -- Firebase Auth UID (string)
  preferences JSONB NOT NULL DEFAULT '{}',
  questionnaire_answers JSONB,
  completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON user_preferences(user_id);

-- Row Level Security
-- Note: Since we use Firebase Auth, RLS is handled at application level
-- Security is enforced at the service layer via user_id filtering
ALTER TABLE user_preferences DISABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON user_preferences TO authenticated;


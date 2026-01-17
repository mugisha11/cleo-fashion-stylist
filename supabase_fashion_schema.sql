-- Fashion AI System Database Schema
-- User Preferences Table
CREATE TABLE IF NOT EXISTS user_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL UNIQUE,
  preferences JSONB NOT NULL DEFAULT '{}',
  questionnaire_answers JSONB,
  completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Outfit Feedback Table
CREATE TABLE IF NOT EXISTS outfit_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  outfit_id TEXT NOT NULL,
  liked BOOLEAN NOT NULL,
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, outfit_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_outfit_feedback_user_id ON outfit_feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_outfit_feedback_outfit_id ON outfit_feedback(outfit_id);

-- RLS Policies
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE outfit_feedback ENABLE ROW LEVEL SECURITY;

-- User can only access their own preferences
CREATE POLICY "Users can view own preferences"
  ON user_preferences FOR SELECT
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own preferences"
  ON user_preferences FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own preferences"
  ON user_preferences FOR UPDATE
  USING (auth.uid()::text = user_id);

-- User can only access their own feedback
CREATE POLICY "Users can view own feedback"
  ON outfit_feedback FOR SELECT
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own feedback"
  ON outfit_feedback FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);


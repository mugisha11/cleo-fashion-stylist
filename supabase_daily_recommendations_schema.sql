-- Daily Outfit Recommendations Schema
-- Stores AI-generated daily outfit recommendations per user

CREATE TABLE IF NOT EXISTS daily_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL, -- Firebase Auth UID (string)
  recommended_for DATE NOT NULL, -- Date for which recommendations are generated
  
  -- Recommendations array (exactly 3)
  recommendations JSONB NOT NULL DEFAULT '[]',
  
  -- Metadata
  weather_data JSONB, -- Weather conditions at generation time
  calendar_context JSONB, -- Calendar events considered
  tryon_history_count INTEGER DEFAULT 0, -- Number of try-ons considered
  
  -- Status
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'generated', 'notified', 'failed'
  error_message TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  notified_at TIMESTAMPTZ,
  
  -- Constraints
  UNIQUE(user_id, recommended_for),
  CONSTRAINT valid_recommendations_count CHECK (jsonb_array_length(recommendations) = 3)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_daily_recommendations_user_id ON daily_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_recommendations_date ON daily_recommendations(recommended_for);
CREATE INDEX IF NOT EXISTS idx_daily_recommendations_user_date ON daily_recommendations(user_id, recommended_for);
CREATE INDEX IF NOT EXISTS idx_daily_recommendations_status ON daily_recommendations(status);
CREATE INDEX IF NOT EXISTS idx_daily_recommendations_created_at ON daily_recommendations(created_at DESC);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_daily_recommendations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER trigger_update_daily_recommendations_updated_at
  BEFORE UPDATE ON daily_recommendations
  FOR EACH ROW
  EXECUTE FUNCTION update_daily_recommendations_updated_at();

-- Row Level Security
-- Note: Since we use Firebase Auth (not Supabase Auth), RLS cannot use auth.uid()
-- Security is enforced at the application/service layer via user_id filtering
ALTER TABLE daily_recommendations ENABLE ROW LEVEL SECURITY;

-- Policy: Allow service role to manage all recommendations
CREATE POLICY "Service role can manage all recommendations"
  ON daily_recommendations
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Comments for documentation
COMMENT ON TABLE daily_recommendations IS 'Stores daily AI-generated outfit recommendations (exactly 3 per user per day)';
COMMENT ON COLUMN daily_recommendations.recommendations IS 'JSONB array of exactly 3 recommendation objects';
COMMENT ON COLUMN daily_recommendations.recommended_for IS 'Date for which recommendations are generated (YYYY-MM-DD)';
COMMENT ON COLUMN daily_recommendations.status IS 'Status: pending, generated, notified, failed';

-- Calendar Feature Database Schema
-- Fashion AI Outfit Planning Calendar

-- Calendar Days Table
-- Stores outfit assignments for specific dates
CREATE TABLE IF NOT EXISTS calendar_days (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL, -- Firebase Auth UID (string)
  date DATE NOT NULL,
  
  -- Outfit data
  outfit_id TEXT,
  outfit_name TEXT,
  outfit_image_url TEXT,
  
  -- Event data
  event_type TEXT, -- 'work', 'casual', 'event', 'formal', etc.
  event_name TEXT,
  
  -- AI metadata
  source TEXT NOT NULL DEFAULT 'manual', -- 'ai' or 'manual'
  confidence_score DECIMAL(3, 2), -- 0.00 to 1.00
  is_recommended BOOLEAN NOT NULL DEFAULT FALSE,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(user_id, date)
);

-- Outfit Events Table
-- Stores events that can be associated with outfit planning
CREATE TABLE IF NOT EXISTS outfit_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL, -- Firebase Auth UID (string)
  date DATE NOT NULL,
  
  event_type TEXT, -- 'work', 'casual', 'event', 'formal', etc.
  event_name TEXT,
  description TEXT,
  location TEXT,
  
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_calendar_days_user_id ON calendar_days(user_id);
CREATE INDEX IF NOT EXISTS idx_calendar_days_date ON calendar_days(date);
CREATE INDEX IF NOT EXISTS idx_calendar_days_user_date ON calendar_days(user_id, date);

CREATE INDEX IF NOT EXISTS idx_outfit_events_user_id ON outfit_events(user_id);
CREATE INDEX IF NOT EXISTS idx_outfit_events_date ON outfit_events(date);
CREATE INDEX IF NOT EXISTS idx_outfit_events_user_date ON outfit_events(user_id, date);

-- Row Level Security
-- Note: Since we use Firebase Auth (not Supabase Auth), RLS cannot use auth.uid()
-- Security is enforced at the application/service layer via user_id filtering
ALTER TABLE calendar_days DISABLE ROW LEVEL SECURITY;
ALTER TABLE outfit_events DISABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON calendar_days TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON outfit_events TO authenticated;

-- Comments
COMMENT ON TABLE calendar_days IS 'Stores outfit assignments for calendar dates';
COMMENT ON TABLE outfit_events IS 'Stores events that can be used for outfit planning';
COMMENT ON COLUMN calendar_days.user_id IS 'Firebase Auth UID (string, not UUID)';
COMMENT ON COLUMN calendar_days.confidence_score IS 'AI confidence score from 0.00 to 1.00';
COMMENT ON COLUMN calendar_days.source IS 'Source of outfit: ai or manual';


-- Supabase Schema for Calendar and Outfit Planning
-- Run this in Supabase SQL Editor

-- Ensure UUID extension is available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table to store per-day calendar planning and AI outfit suggestions
CREATE TABLE IF NOT EXISTS calendar_days (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL,
    date DATE NOT NULL,
    outfit_id TEXT,
    outfit_name TEXT,
    outfit_image_url TEXT,
    event_type TEXT,
    event_name TEXT,
    source TEXT DEFAULT 'manual',
    confidence_score FLOAT,
    is_recommended BOOLEAN DEFAULT FALSE,
    linked_outfit_id TEXT,
    linked_outfit_name TEXT,
    linked_outfit_image_url TEXT,
    linked_tryon_image_url TEXT,
    outfit_linking_method TEXT,
    outfit_linked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_calendar_days_user_date ON calendar_days(user_id, date);
CREATE INDEX IF NOT EXISTS idx_calendar_days_user_id ON calendar_days(user_id);
CREATE INDEX IF NOT EXISTS idx_calendar_days_date ON calendar_days(date);

ALTER TABLE calendar_days ENABLE ROW LEVEL SECURITY;

-- For development: Allow all operations (not secure for production)
-- TODO: Set up proper Firebase auth integration
CREATE POLICY "Allow all operations on calendar_days"
    ON calendar_days FOR ALL
    USING (true)
    WITH CHECK (true);

CREATE OR REPLACE FUNCTION update_calendar_days_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_calendar_days_updated_at ON calendar_days;
CREATE TRIGGER update_calendar_days_updated_at
    BEFORE UPDATE ON calendar_days
    FOR EACH ROW
    EXECUTE FUNCTION update_calendar_days_updated_at();

-- Table for user outfit events in the calendar
CREATE TABLE IF NOT EXISTS outfit_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL,
    date DATE NOT NULL,
    event_type TEXT,
    event_name TEXT,
    description TEXT,
    location TEXT,
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_outfit_events_user_id ON outfit_events(user_id);
CREATE INDEX IF NOT EXISTS idx_outfit_events_date ON outfit_events(date);

ALTER TABLE outfit_events ENABLE ROW LEVEL SECURITY;

-- For development: Allow all operations (not secure for production)
-- TODO: Set up proper Firebase auth integration
CREATE POLICY "Allow all operations on outfit_events"
    ON outfit_events FOR ALL
    USING (true)
    WITH CHECK (true);

CREATE OR REPLACE FUNCTION update_outfit_events_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_outfit_events_updated_at ON outfit_events;
CREATE TRIGGER update_outfit_events_updated_at
    BEFORE UPDATE ON outfit_events
    FOR EACH ROW
    EXECUTE FUNCTION update_outfit_events_updated_at();

-- Table to log outfit linking actions for audit/history
CREATE TABLE IF NOT EXISTS outfit_linking_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL,
    calendar_event_id UUID,
    outfit_id TEXT NOT NULL,
    linking_method TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_outfit_linking_history_user_id ON outfit_linking_history(user_id);
CREATE INDEX IF NOT EXISTS idx_outfit_linking_history_calendar_event_id ON outfit_linking_history(calendar_event_id);

ALTER TABLE outfit_linking_history ENABLE ROW LEVEL SECURITY;

-- For development: Allow all operations (not secure for production)
-- TODO: Set up proper Firebase auth integration
CREATE POLICY "Allow all operations on outfit_linking_history"
    ON outfit_linking_history FOR ALL
    USING (true)
    WITH CHECK (true);


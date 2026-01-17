-- Supabase Schema for Clothing Recognition Results
-- Run this in Supabase SQL Editor

-- Table to store clothing recognition results
CREATE TABLE IF NOT EXISTS clothing_recognitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT,
    image_url TEXT NOT NULL,
    category TEXT NOT NULL,
    subcategory TEXT,
    colors TEXT[] DEFAULT '{}',
    patterns TEXT[] DEFAULT '{}',
    fit TEXT,
    occasion TEXT[] DEFAULT '{}',
    style TEXT,
    confidence FLOAT NOT NULL,
    bbox JSONB,  -- {x, y, w, h}
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for fast queries
CREATE INDEX IF NOT EXISTS idx_clothing_recognitions_user_id ON clothing_recognitions(user_id);
CREATE INDEX IF NOT EXISTS idx_clothing_recognitions_category ON clothing_recognitions(category);
CREATE INDEX IF NOT EXISTS idx_clothing_recognitions_created_at ON clothing_recognitions(created_at DESC);

-- Enable Row Level Security
ALTER TABLE clothing_recognitions ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own recognitions
CREATE POLICY "Users can view their own recognitions"
    ON clothing_recognitions FOR SELECT
    USING (
        user_id IS NULL OR 
        user_id = current_setting('request.jwt.claims', true)::json->>'sub' OR
        auth.role() = 'authenticated'
    );

-- Policy: Users can insert their own recognitions
CREATE POLICY "Users can insert their own recognitions"
    ON clothing_recognitions FOR INSERT
    WITH CHECK (
        user_id IS NULL OR 
        user_id = current_setting('request.jwt.claims', true)::json->>'sub' OR
        auth.role() = 'authenticated'
    );

-- Policy: Users can update their own recognitions
CREATE POLICY "Users can update their own recognitions"
    ON clothing_recognitions FOR UPDATE
    USING (
        user_id IS NULL OR 
        user_id = current_setting('request.jwt.claims', true)::json->>'sub' OR
        auth.role() = 'authenticated'
    );

-- Policy: Users can delete their own recognitions
CREATE POLICY "Users can delete their own recognitions"
    ON clothing_recognitions FOR DELETE
    USING (
        user_id IS NULL OR 
        user_id = current_setting('request.jwt.claims', true)::json->>'sub' OR
        auth.role() = 'authenticated'
    );

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_clothing_recognitions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
DROP TRIGGER IF EXISTS update_clothing_recognitions_updated_at ON clothing_recognitions;
CREATE TRIGGER update_clothing_recognitions_updated_at
    BEFORE UPDATE ON clothing_recognitions
    FOR EACH ROW
    EXECUTE FUNCTION update_clothing_recognitions_updated_at();

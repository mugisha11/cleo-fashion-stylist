-- ============================================
-- Supabase Database Schema for Virtual Twin App
-- PostgreSQL Migration Script
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    avatar_model_url TEXT, -- GLB/GLTF URL for 3D avatar
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- ONBOARDING DATA TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS onboarding_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fashion_style TEXT NOT NULL,
    favorite_colors TEXT NOT NULL,
    occasion TEXT NOT NULL,
    budget TEXT NOT NULL,
    shopping_frequency TEXT NOT NULL,
    style_inspiration TEXT NOT NULL,
    -- Body inputs
    height_cm DECIMAL(5,2) NOT NULL,
    gender TEXT NOT NULL,
    body_type TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id)
);

-- ============================================
-- WARDROBE ITEMS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS wardrobe_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    category TEXT NOT NULL,
    color_tags TEXT[] NOT NULL DEFAULT '{}', -- Array of color strings
    brand TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- OUTFITS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS outfits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    item_ids UUID[] NOT NULL DEFAULT '{}', -- Array of wardrobe_item IDs
    preview_image_url TEXT,
    is_recommended BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- INDEXES for Performance
-- ============================================

-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- Onboarding data indexes
CREATE INDEX IF NOT EXISTS idx_onboarding_user_id ON onboarding_data(user_id);

-- Wardrobe items indexes
CREATE INDEX IF NOT EXISTS idx_wardrobe_user_id ON wardrobe_items(user_id);
CREATE INDEX IF NOT EXISTS idx_wardrobe_category ON wardrobe_items(category);
CREATE INDEX IF NOT EXISTS idx_wardrobe_created_at ON wardrobe_items(created_at);
CREATE INDEX IF NOT EXISTS idx_wardrobe_color_tags ON wardrobe_items USING GIN(color_tags);

-- Outfits indexes
CREATE INDEX IF NOT EXISTS idx_outfits_user_id ON outfits(user_id);
CREATE INDEX IF NOT EXISTS idx_outfits_is_recommended ON outfits(is_recommended);
CREATE INDEX IF NOT EXISTS idx_outfits_created_at ON outfits(created_at);
CREATE INDEX IF NOT EXISTS idx_outfits_item_ids ON outfits USING GIN(item_ids);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE onboarding_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE wardrobe_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE outfits ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view their own profile"
    ON users FOR SELECT
    USING (auth.uid()::text = id::text);

CREATE POLICY "Users can update their own profile"
    ON users FOR UPDATE
    USING (auth.uid()::text = id::text);

CREATE POLICY "Users can insert their own profile"
    ON users FOR INSERT
    WITH CHECK (auth.uid()::text = id::text);

-- Onboarding data policies
CREATE POLICY "Users can view their own onboarding data"
    ON onboarding_data FOR SELECT
    USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert their own onboarding data"
    ON onboarding_data FOR INSERT
    WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update their own onboarding data"
    ON onboarding_data FOR UPDATE
    USING (auth.uid()::text = user_id::text);

-- Wardrobe items policies
CREATE POLICY "Users can view their own wardrobe items"
    ON wardrobe_items FOR SELECT
    USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert their own wardrobe items"
    ON wardrobe_items FOR INSERT
    WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update their own wardrobe items"
    ON wardrobe_items FOR UPDATE
    USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can delete their own wardrobe items"
    ON wardrobe_items FOR DELETE
    USING (auth.uid()::text = user_id::text);

-- Outfits policies
CREATE POLICY "Users can view their own outfits"
    ON outfits FOR SELECT
    USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert their own outfits"
    ON outfits FOR INSERT
    WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update their own outfits"
    ON outfits FOR UPDATE
    USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can delete their own outfits"
    ON outfits FOR DELETE
    USING (auth.uid()::text = user_id::text);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers to auto-update updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_onboarding_data_updated_at BEFORE UPDATE ON onboarding_data
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wardrobe_items_updated_at BEFORE UPDATE ON wardrobe_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_outfits_updated_at BEFORE UPDATE ON outfits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- STORAGE BUCKETS (for Supabase Storage)
-- ============================================
-- Note: These need to be created via Supabase Dashboard or API
-- Bucket: 'avatars' - for user avatar images and 3D models
-- Bucket: 'wardrobe' - for wardrobe item images
-- Bucket: 'outfits' - for outfit preview images

-- ============================================
-- COMMENTS
-- ============================================
COMMENT ON TABLE users IS 'User profiles with authentication info';
COMMENT ON TABLE onboarding_data IS 'User onboarding preferences and body measurements';
COMMENT ON TABLE wardrobe_items IS 'User wardrobe clothing items';
COMMENT ON TABLE outfits IS 'User saved outfits and AI recommendations';

COMMENT ON COLUMN wardrobe_items.color_tags IS 'Array of color strings for filtering';
COMMENT ON COLUMN outfits.item_ids IS 'Array of wardrobe_item UUIDs that make up this outfit';
COMMENT ON COLUMN outfits.is_recommended IS 'True if this outfit was AI-recommended';


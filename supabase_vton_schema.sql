-- ============================================
-- Supabase Schema for Cleo Fashion VTON System
-- Production-ready database schema
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- QUIZ & PREFERENCES
-- ============================================

-- Quiz questions metadata (curated fashion images)
CREATE TABLE IF NOT EXISTS quiz_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_number INTEGER NOT NULL,
    image_url TEXT NOT NULL,
    image_id TEXT UNIQUE NOT NULL,
    occasion TEXT,
    tags TEXT[] DEFAULT '{}',
    style_category TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE(question_number, is_active)
);

-- User quiz answers
CREATE TABLE IF NOT EXISTS quiz_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES quiz_questions(id),
    image_id TEXT NOT NULL,
    choice TEXT NOT NULL CHECK (choice IN ('like', 'dislike')),
    answered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, question_id)
);

-- User style profile (computed from quiz answers)
CREATE TABLE IF NOT EXISTS user_style_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    style_vector JSONB NOT NULL, -- {colors: [], silhouettes: [], patterns: [], risk_level: float}
    preferred_colors TEXT[] DEFAULT '{}',
    preferred_silhouettes TEXT[] DEFAULT '{}',
    preferred_patterns TEXT[] DEFAULT '{}',
    risk_level DECIMAL(3,2) DEFAULT 0.5, -- 0.0 conservative to 1.0 bold
    computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- WARDROBE ENHANCED
-- ============================================

-- Enhanced wardrobe items with segmentation
ALTER TABLE wardrobe_items ADD COLUMN IF NOT EXISTS segmentation_url TEXT;
ALTER TABLE wardrobe_items ADD COLUMN IF NOT EXISTS category_tags TEXT[] DEFAULT '{}';
ALTER TABLE wardrobe_items ADD COLUMN IF NOT EXISTS quality_score DECIMAL(3,2);
ALTER TABLE wardrobe_items ADD COLUMN IF NOT EXISTS has_transparency BOOLEAN DEFAULT FALSE;

-- ============================================
-- TRY-ON SESSIONS
-- ============================================

CREATE TABLE IF NOT EXISTS tryon_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id TEXT UNIQUE NOT NULL,
    
    -- Input data
    raw_photo_url TEXT NOT NULL,
    raw_photo_metadata JSONB, -- {width, height, format, quality_score, landmarks}
    outfit_source TEXT NOT NULL CHECK (outfit_source IN ('wardrobe', 'web')),
    outfit_id UUID REFERENCES wardrobe_items(id), -- if from wardrobe
    outfit_url TEXT, -- if from web/catalog
    outfit_metadata JSONB,
    
    -- Processing
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'fallback')),
    job_id TEXT,
    model_name TEXT, -- 'vitron', 'cp-vton', 'commercial-api', 'opencv-fallback'
    
    -- Results
    result_url TEXT,
    result_metadata JSONB, -- {width, height, format, processing_time, quality_metrics}
    
    -- Quality metrics
    quality_score DECIMAL(3,2),
    processing_time_seconds INTEGER,
    error_message TEXT,
    
    -- Feedback
    user_feedback TEXT CHECK (user_feedback IN ('like', 'dislike', NULL)),
    feedback_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- ============================================
-- INDEXES for Performance
-- ============================================

CREATE INDEX IF NOT EXISTS idx_quiz_answers_user_id ON quiz_answers(user_id);
CREATE INDEX IF NOT EXISTS idx_quiz_answers_question_id ON quiz_answers(question_id);
CREATE INDEX IF NOT EXISTS idx_quiz_questions_active ON quiz_questions(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_tryon_sessions_user_id ON tryon_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_tryon_sessions_status ON tryon_sessions(status);
CREATE INDEX IF NOT EXISTS idx_tryon_sessions_session_id ON tryon_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_tryon_sessions_created_at ON tryon_sessions(created_at DESC);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE quiz_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_style_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tryon_sessions ENABLE ROW LEVEL SECURITY;

-- Quiz answers policies
DROP POLICY IF EXISTS "Users can view their own quiz answers" ON quiz_answers;
CREATE POLICY "Users can view their own quiz answers"
    ON quiz_answers FOR SELECT
    USING (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "Users can insert their own quiz answers" ON quiz_answers;
CREATE POLICY "Users can insert their own quiz answers"
    ON quiz_answers FOR INSERT
    WITH CHECK (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "Users can update their own quiz answers" ON quiz_answers;
CREATE POLICY "Users can update their own quiz answers"
    ON quiz_answers FOR UPDATE
    USING (auth.uid()::text = user_id::text);

-- Style profiles policies
DROP POLICY IF EXISTS "Users can view their own style profile" ON user_style_profiles;
CREATE POLICY "Users can view their own style profile"
    ON user_style_profiles FOR SELECT
    USING (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "Users can insert their own style profile" ON user_style_profiles;
CREATE POLICY "Users can insert their own style profile"
    ON user_style_profiles FOR INSERT
    WITH CHECK (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "Users can update their own style profile" ON user_style_profiles;
CREATE POLICY "Users can update their own style profile"
    ON user_style_profiles FOR UPDATE
    USING (auth.uid()::text = user_id::text);

-- Try-on sessions policies
DROP POLICY IF EXISTS "Users can view their own try-on sessions" ON tryon_sessions;
CREATE POLICY "Users can view their own try-on sessions"
    ON tryon_sessions FOR SELECT
    USING (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "Users can insert their own try-on sessions" ON tryon_sessions;
CREATE POLICY "Users can insert their own try-on sessions"
    ON tryon_sessions FOR INSERT
    WITH CHECK (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "Users can update their own try-on sessions" ON tryon_sessions;
CREATE POLICY "Users can update their own try-on sessions"
    ON tryon_sessions FOR UPDATE
    USING (auth.uid()::text = user_id::text);

-- Quiz questions are public (read-only)
ALTER TABLE quiz_questions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view active quiz questions" ON quiz_questions;
CREATE POLICY "Anyone can view active quiz questions"
    ON quiz_questions FOR SELECT
    USING (is_active = TRUE);

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

-- Triggers
DROP TRIGGER IF EXISTS update_user_style_profiles_updated_at ON user_style_profiles;
CREATE TRIGGER update_user_style_profiles_updated_at 
    BEFORE UPDATE ON user_style_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_tryon_sessions_updated_at ON tryon_sessions;
CREATE TRIGGER update_tryon_sessions_updated_at 
    BEFORE UPDATE ON tryon_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to compute style profile after quiz completion
CREATE OR REPLACE FUNCTION compute_style_profile(p_user_id UUID)
RETURNS void AS $$
DECLARE
    v_liked_tags TEXT[];
    v_style_vector JSONB;
BEGIN
    -- Aggregate tags from liked images
    SELECT ARRAY_AGG(DISTINCT tag)
    INTO v_liked_tags
    FROM quiz_answers qa
    JOIN quiz_questions qq ON qa.question_id = qq.id
    CROSS JOIN LATERAL unnest(qq.tags) AS tag
    WHERE qa.user_id = p_user_id AND qa.choice = 'like';
    
    -- Build style vector (simplified - LLM will enhance this)
    v_style_vector := jsonb_build_object(
        'tags', COALESCE(v_liked_tags, ARRAY[]::TEXT[]),
        'computed_at', NOW()
    );
    
    -- Upsert style profile
    INSERT INTO user_style_profiles (user_id, style_vector, preferred_colors, preferred_silhouettes, preferred_patterns)
    VALUES (
        p_user_id,
        v_style_vector,
        ARRAY[]::TEXT[],
        ARRAY[]::TEXT[],
        ARRAY[]::TEXT[]
    )
    ON CONFLICT (user_id) 
    DO UPDATE SET
        style_vector = EXCLUDED.style_vector,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- STORAGE BUCKETS
-- ============================================
-- Create these buckets in Supabase Storage Dashboard:
-- 1. 'quiz-images' - Public, for quiz question images
-- 2. 'uploads' - Private, for user raw photos
-- 3. 'tryon-results' - Private, for try-on result images
-- 4. 'wardrobe-segmentation' - Private, for garment segmentation masks

-- ============================================
-- COMMENTS
-- ============================================
COMMENT ON TABLE quiz_questions IS 'Curated fashion images for style preference quiz';
COMMENT ON TABLE quiz_answers IS 'User responses to quiz questions';
COMMENT ON TABLE user_style_profiles IS 'Computed style preferences from quiz answers';
COMMENT ON TABLE tryon_sessions IS 'Virtual try-on processing sessions and results';


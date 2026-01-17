-- Calendar ↔ Outfit Linking Schema Updates
-- Enables AI-aware fashion calendar with outfit linking

-- Add outfit linking columns to calendar_days if they don't exist
ALTER TABLE calendar_days 
  ADD COLUMN IF NOT EXISTS linked_outfit_id TEXT,
  ADD COLUMN IF NOT EXISTS linked_outfit_name TEXT,
  ADD COLUMN IF NOT EXISTS linked_outfit_image_url TEXT,
  ADD COLUMN IF NOT EXISTS linked_tryon_image_url TEXT,
  ADD COLUMN IF NOT EXISTS outfit_linking_method TEXT DEFAULT 'manual', -- 'ai_auto', 'user_confirmed', 'chat_based', 'manual'
  ADD COLUMN IF NOT EXISTS outfit_linked_at TIMESTAMPTZ;

-- Create index for outfit linking queries
CREATE INDEX IF NOT EXISTS idx_calendar_days_linked_outfit_id ON calendar_days(linked_outfit_id);
CREATE INDEX IF NOT EXISTS idx_calendar_days_linking_method ON calendar_days(outfit_linking_method);

-- Outfit linking history (for analytics and undo)
CREATE TABLE IF NOT EXISTS outfit_linking_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  calendar_event_id UUID REFERENCES calendar_days(id) ON DELETE CASCADE,
  outfit_id TEXT NOT NULL,
  linking_method TEXT NOT NULL, -- 'ai_auto', 'user_confirmed', 'chat_based', 'manual'
  previous_outfit_id TEXT, -- For tracking changes
  confidence_score DECIMAL(3, 2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT valid_linking_method CHECK (linking_method IN (
    'ai_auto',
    'user_confirmed',
    'chat_based',
    'manual'
  ))
);

-- Index for linking history
CREATE INDEX IF NOT EXISTS idx_outfit_linking_history_user_id ON outfit_linking_history(user_id);
CREATE INDEX IF NOT EXISTS idx_outfit_linking_history_calendar_event_id ON outfit_linking_history(calendar_event_id);
CREATE INDEX IF NOT EXISTS idx_outfit_linking_history_created_at ON outfit_linking_history(created_at DESC);

-- Function to auto-update outfit when wardrobe item is deleted
CREATE OR REPLACE FUNCTION handle_wardrobe_item_deletion()
RETURNS TRIGGER AS $$
BEGIN
  -- Find calendar events linked to outfits containing this item
  UPDATE calendar_days
  SET 
    linked_outfit_id = NULL,
    linked_outfit_name = NULL,
    linked_outfit_image_url = NULL,
    linked_tryon_image_url = NULL,
    outfit_linking_method = NULL,
    outfit_linked_at = NULL,
    updated_at = NOW()
  WHERE 
    linked_outfit_id IN (
      SELECT id FROM outfits 
      WHERE OLD.id = ANY(item_ids)
    );
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Trigger to handle wardrobe item deletion
CREATE TRIGGER trigger_handle_wardrobe_item_deletion
  AFTER DELETE ON wardrobe_items
  FOR EACH ROW
  EXECUTE FUNCTION handle_wardrobe_item_deletion();

-- Comments
COMMENT ON COLUMN calendar_days.linked_outfit_id IS 'ID of outfit linked to this calendar event';
COMMENT ON COLUMN calendar_days.outfit_linking_method IS 'How the outfit was linked: ai_auto, user_confirmed, chat_based, or manual';
COMMENT ON TABLE outfit_linking_history IS 'Tracks all outfit linking/unlinking events for analytics';

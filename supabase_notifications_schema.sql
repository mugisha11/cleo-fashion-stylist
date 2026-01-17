-- Smart Notifications System Schema
-- Fashion-aware, non-spammy, intelligent notifications

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL, -- Firebase Auth UID (string)
  
  -- Notification metadata
  type TEXT NOT NULL, -- 'daily_outfit', 'event_outfit', 'weather_alert', 'wardrobe_intelligence'
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  payload JSONB DEFAULT '{}', -- Deep link data, outfit IDs, event IDs, etc.
  
  -- Status
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  is_sent BOOLEAN NOT NULL DEFAULT FALSE,
  sent_at TIMESTAMPTZ,
  
  -- Spam prevention
  content_value_score DECIMAL(3, 2) DEFAULT 0.8, -- 0.0 to 1.0
  same_type_sent_today BOOLEAN DEFAULT FALSE,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  read_at TIMESTAMPTZ,
  
  -- Constraints
  CONSTRAINT valid_notification_type CHECK (type IN (
    'daily_outfit',
    'event_outfit',
    'weather_alert',
    'wardrobe_intelligence',
    'outfit_update',
    'calendar_reminder'
  )),
  CONSTRAINT valid_content_score CHECK (content_value_score >= 0.0 AND content_value_score <= 1.0)
);

-- Add missing columns if table already exists (migration support)
DO $$
BEGIN
  -- Add is_read column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'is_read'
  ) THEN
    ALTER TABLE notifications ADD COLUMN is_read BOOLEAN NOT NULL DEFAULT FALSE;
  END IF;
  
  -- Add is_sent column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'is_sent'
  ) THEN
    ALTER TABLE notifications ADD COLUMN is_sent BOOLEAN NOT NULL DEFAULT FALSE;
  END IF;
  
  -- Add sent_at column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'sent_at'
  ) THEN
    ALTER TABLE notifications ADD COLUMN sent_at TIMESTAMPTZ;
  END IF;
  
  -- Add content_value_score column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'content_value_score'
  ) THEN
    ALTER TABLE notifications ADD COLUMN content_value_score DECIMAL(3, 2) DEFAULT 0.8;
  END IF;
  
  -- Add same_type_sent_today column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'same_type_sent_today'
  ) THEN
    ALTER TABLE notifications ADD COLUMN same_type_sent_today BOOLEAN DEFAULT FALSE;
  END IF;
  
  -- Add read_at column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'read_at'
  ) THEN
    ALTER TABLE notifications ADD COLUMN read_at TIMESTAMPTZ;
  END IF;
END $$;

-- User notification preferences
CREATE TABLE IF NOT EXISTS user_notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL UNIQUE, -- Firebase Auth UID (string)
  
  -- Global settings
  notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  
  -- Per-type preferences
  daily_outfit_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  event_outfit_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  weather_alert_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  wardrobe_intelligence_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  
  -- Timing preferences
  quiet_hours_start TIME DEFAULT '22:00:00', -- 10 PM
  quiet_hours_end TIME DEFAULT '07:00:00', -- 7 AM
  timezone TEXT DEFAULT 'UTC',
  
  -- Timestamps
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Notification delivery log (for analytics and spam prevention)
-- Note: Foreign key is added separately after both tables exist to ensure type compatibility
CREATE TABLE IF NOT EXISTS notification_delivery_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID NOT NULL,
  user_id TEXT NOT NULL,
  
  -- Delivery details
  delivery_method TEXT NOT NULL DEFAULT 'fcm', -- 'fcm', 'email', 'sms'
  delivery_status TEXT NOT NULL, -- 'sent', 'failed', 'bounced'
  fcm_token TEXT,
  error_message TEXT,
  
  -- Timestamps
  attempted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  delivered_at TIMESTAMPTZ,
  
  -- Constraints
  CONSTRAINT valid_delivery_method CHECK (delivery_method IN ('fcm', 'email', 'sms')),
  CONSTRAINT valid_delivery_status CHECK (delivery_status IN ('sent', 'failed', 'bounced', 'pending'))
);

-- Indexes for performance
-- Note: Create indexes only if columns exist (for compatibility with existing tables)
DO $$
BEGIN
  -- Check if notifications table exists and has required columns before creating indexes
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'notifications'
  ) THEN
    -- User ID index
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'notifications' AND column_name = 'user_id'
    ) THEN
      CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
    END IF;
    
    -- Type index
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'notifications' AND column_name = 'type'
    ) THEN
      CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
    END IF;
    
    -- Is read index
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'notifications' AND column_name = 'is_read'
    ) THEN
      CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
      CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
    END IF;
    
    -- Created at index
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'notifications' AND column_name = 'created_at'
    ) THEN
      CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
    END IF;
    
    -- User type date index
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'notifications' 
      AND column_name = 'user_id' 
      AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notifications' AND column_name = 'type')
      AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notifications' AND column_name = 'created_at')
    ) THEN
      CREATE INDEX IF NOT EXISTS idx_notifications_user_type_date ON notifications(user_id, type, created_at);
    END IF;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_user_notification_preferences_user_id ON user_notification_preferences(user_id);

CREATE INDEX IF NOT EXISTS idx_notification_delivery_log_notification_id ON notification_delivery_log(notification_id);
CREATE INDEX IF NOT EXISTS idx_notification_delivery_log_user_id ON notification_delivery_log(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_delivery_log_attempted_at ON notification_delivery_log(attempted_at DESC);

-- Add foreign key constraint after both tables are created
-- This ensures type compatibility and handles cases where tables already exist
DO $$
BEGIN
  -- Check if constraint already exists
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'notification_delivery_log_notification_id_fkey'
  ) THEN
    -- Check if notifications table exists and has UUID id column
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'notifications' 
      AND column_name = 'id' 
      AND data_type = 'uuid'
    ) THEN
      ALTER TABLE notification_delivery_log
        ADD CONSTRAINT notification_delivery_log_notification_id_fkey 
        FOREIGN KEY (notification_id) 
        REFERENCES notifications(id) 
        ON DELETE CASCADE;
    END IF;
  END IF;
END $$;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_user_notification_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER trigger_update_user_notification_preferences_updated_at
  BEFORE UPDATE ON user_notification_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_user_notification_preferences_updated_at();

-- Function to check if same notification type was sent today
CREATE OR REPLACE FUNCTION check_same_type_sent_today(
  p_user_id TEXT,
  p_type TEXT
) RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM notifications
    WHERE user_id = p_user_id
      AND type = p_type
      AND created_at::DATE = CURRENT_DATE
      AND is_sent = TRUE
  );
END;
$$ LANGUAGE plpgsql;

-- Row Level Security
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_delivery_log ENABLE ROW LEVEL SECURITY;

-- Policy: Service role can manage all notifications
CREATE POLICY "Service role can manage all notifications"
  ON notifications
  FOR ALL
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Service role can manage all notification preferences"
  ON user_notification_preferences
  FOR ALL
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Service role can manage all delivery logs"
  ON notification_delivery_log
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Comments for documentation
COMMENT ON TABLE notifications IS 'Stores all app notifications with spam prevention and value scoring';
COMMENT ON TABLE user_notification_preferences IS 'User preferences for notification types and timing';
COMMENT ON TABLE notification_delivery_log IS 'Logs notification delivery attempts for analytics and debugging';

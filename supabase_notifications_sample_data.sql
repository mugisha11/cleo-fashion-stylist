-- Sample Notifications Data
-- Fashion AI-aware notification examples
-- Run this in Supabase SQL Editor to populate test notifications

-- Note: Replace 'YOUR_USER_ID' with an actual Firebase Auth UID from your users
-- You can get this from Firebase Console or from your app's authentication

-- Sample User ID (replace with actual user ID)
-- For testing, you can use: SELECT id FROM auth.users LIMIT 1;

-- ============================================
-- NOTIFICATION TYPE: Outfit Ready 👗
-- ============================================
INSERT INTO notifications (id, user_id, type, title, message, created_at, state, icon_emoji, accent_color, metadata) VALUES
(
  'notif_001',
  'YOUR_USER_ID', -- Replace with actual user ID
  'outfit_ready',
  'New Outfit Ready!',
  'We found 3 outfits that match your style perfectly. Check them out!',
  NOW() - INTERVAL '5 minutes',
  'unread',
  '👗',
  '#4A90E2',
  '{"outfit_count": 3, "confidence": 0.92}'::jsonb
),
(
  'notif_002',
  'YOUR_USER_ID',
  'outfit_ready',
  'Weekend Outfit Suggestion',
  'Perfect casual outfit for your weekend plans is ready!',
  NOW() - INTERVAL '2 hours',
  'unread',
  '👗',
  '#4A90E2',
  '{"occasion": "casual", "outfit_id": "outfit_123"}'::jsonb
);

-- ============================================
-- NOTIFICATION TYPE: Try-On Completed 📸
-- ============================================
INSERT INTO notifications (id, user_id, type, title, message, created_at, state, icon_emoji, accent_color, metadata, action_url) VALUES
(
  'notif_003',
  'YOUR_USER_ID',
  'tryon_completed',
  'Try-On Complete!',
  'Your virtual try-on is ready. See how this outfit looks on you!',
  NOW() - INTERVAL '10 minutes',
  'unread',
  '📸',
  '#7C3AED',
  '{"session_id": "session_456", "quality_score": 0.95}'::jsonb,
  '/tryon/session_456'
),
(
  'notif_004',
  'YOUR_USER_ID',
  'tryon_completed',
  'New Try-On Available',
  'Check out how this dress looks on your avatar!',
  NOW() - INTERVAL '1 day',
  'read',
  '📸',
  '#7C3AED',
  '{"session_id": "session_789"}'::jsonb,
  '/tryon/session_789'
);

-- ============================================
-- NOTIFICATION TYPE: Style Learned 🧠
-- ============================================
INSERT INTO notifications (id, user_id, type, title, message, created_at, state, icon_emoji, accent_color, metadata) VALUES
(
  'notif_005',
  'YOUR_USER_ID',
  'style_learned',
  'AI Learned Your Style!',
  'Based on your preferences, we now understand you love minimalist, modern looks.',
  NOW() - INTERVAL '3 hours',
  'unread',
  '🧠',
  '#10B981',
  '{"style_tags": ["minimalist", "modern"], "confidence": 0.88}'::jsonb
),
(
  'notif_006',
  'YOUR_USER_ID',
  'style_learned',
  'Style Profile Updated',
  'Your style profile has been enhanced with new insights from your recent choices.',
  NOW() - INTERVAL '2 days',
  'read',
  '🧠',
  '#10B981',
  '{"updates": ["color_preferences", "silhouette_preferences"]}'::jsonb
);

-- ============================================
-- NOTIFICATION TYPE: Event Reminder 🗓
-- ============================================
INSERT INTO notifications (id, user_id, type, title, message, created_at, state, icon_emoji, accent_color, metadata, action_url) VALUES
(
  'notif_007',
  'YOUR_USER_ID',
  'event_reminder',
  'Wedding Outfit Reminder',
  'Your friend''s wedding is in 3 days. Need outfit suggestions?',
  NOW() - INTERVAL '30 minutes',
  'unread',
  '🗓',
  '#F59E0B',
  '{"event_date": "2025-12-16", "event_type": "wedding"}'::jsonb,
  '/outfits?occasion=wedding'
),
(
  'notif_008',
  'YOUR_USER_ID',
  'event_reminder',
  'Date Night Outfit',
  'Don''t forget to plan your outfit for tonight!',
  NOW() - INTERVAL '6 hours',
  'read',
  '🗓',
  '#F59E0B',
  '{"event_type": "date_night"}'::jsonb,
  '/outfits?occasion=date'
);

-- ============================================
-- NOTIFICATION TYPE: Wardrobe Match 🛍
-- ============================================
INSERT INTO notifications (id, user_id, type, title, message, created_at, state, icon_emoji, accent_color, metadata, action_url) VALUES
(
  'notif_009',
  'YOUR_USER_ID',
  'wardrobe_match',
  'New Wardrobe Match Found!',
  'We found a perfect match for your existing wardrobe items.',
  NOW() - INTERVAL '15 minutes',
  'unread',
  '🛍',
  '#EF4444',
  '{"matched_items": ["shirt_123", "pants_456"], "match_score": 0.91}'::jsonb,
  '/wardrobe/matches'
),
(
  'notif_010',
  'YOUR_USER_ID',
  'wardrobe_match',
  'Complete Outfit from Your Wardrobe',
  'You can create a complete outfit using items you already own!',
  NOW() - INTERVAL '4 hours',
  'unread',
  '🛍',
  '#EF4444',
  '{"outfit_items": 4}'::jsonb,
  '/wardrobe/outfits'
);

-- ============================================
-- NOTIFICATION TYPE: System 🔔
-- ============================================
INSERT INTO notifications (id, user_id, type, title, message, created_at, state, icon_emoji, accent_color, metadata) VALUES
(
  'notif_011',
  'YOUR_USER_ID',
  'system',
  'Welcome to StyleApp!',
  'Thanks for joining! Complete your style quiz to get personalized recommendations.',
  NOW() - INTERVAL '1 week',
  'read',
  '🔔',
  '#6B7280',
  '{"action": "complete_quiz"}'::jsonb
),
(
  'notif_012',
  'YOUR_USER_ID',
  'system',
  'New Features Available',
  'Check out our new virtual try-on feature! Try it now.',
  NOW() - INTERVAL '2 days',
  'read',
  '🔔',
  '#6B7280',
  '{"feature": "virtual_tryon"}'::jsonb
);

-- ============================================
-- QUICK INSERT FOR TESTING (Single User)
-- ============================================
-- Uncomment and replace YOUR_USER_ID to quickly insert all notifications:

/*
DO $$
DECLARE
  test_user_id TEXT := 'YOUR_USER_ID'; -- Replace with actual user ID
BEGIN
  -- Outfit Ready
  INSERT INTO notifications (id, user_id, type, title, message, created_at, state, icon_emoji, accent_color, metadata)
  VALUES ('notif_001', test_user_id, 'outfit_ready', 'New Outfit Ready!', 'We found 3 outfits that match your style perfectly.', NOW() - INTERVAL '5 minutes', 'unread', '👗', '#4A90E2', '{"outfit_count": 3}'::jsonb);
  
  -- Try-On Completed
  INSERT INTO notifications (id, user_id, type, title, message, created_at, state, icon_emoji, accent_color, metadata, action_url)
  VALUES ('notif_002', test_user_id, 'tryon_completed', 'Try-On Complete!', 'Your virtual try-on is ready. See how this outfit looks on you!', NOW() - INTERVAL '10 minutes', 'unread', '📸', '#7C3AED', '{"session_id": "session_456"}'::jsonb, '/tryon/session_456');
  
  -- Style Learned
  INSERT INTO notifications (id, user_id, type, title, message, created_at, state, icon_emoji, accent_color, metadata)
  VALUES ('notif_003', test_user_id, 'style_learned', 'AI Learned Your Style!', 'Based on your preferences, we now understand you love minimalist looks.', NOW() - INTERVAL '3 hours', 'unread', '🧠', '#10B981', '{"style_tags": ["minimalist"]}'::jsonb);
  
  -- Event Reminder
  INSERT INTO notifications (id, user_id, type, title, message, created_at, state, icon_emoji, accent_color, metadata, action_url)
  VALUES ('notif_004', test_user_id, 'event_reminder', 'Wedding Outfit Reminder', 'Your friend''s wedding is in 3 days. Need outfit suggestions?', NOW() - INTERVAL '30 minutes', 'unread', '🗓', '#F59E0B', '{"event_type": "wedding"}'::jsonb, '/outfits?occasion=wedding');
  
  -- Wardrobe Match
  INSERT INTO notifications (id, user_id, type, title, message, created_at, state, icon_emoji, accent_color, metadata, action_url)
  VALUES ('notif_005', test_user_id, 'wardrobe_match', 'New Wardrobe Match Found!', 'We found a perfect match for your existing wardrobe items.', NOW() - INTERVAL '15 minutes', 'unread', '🛍', '#EF4444', '{"matched_items": 2}'::jsonb, '/wardrobe/matches');
END $$;
*/

-- ============================================
-- GET YOUR USER ID (Helper Query)
-- ============================================
-- Run this to get a user ID from your Firebase Auth users:
-- (Note: This assumes you have a users table that stores Firebase UIDs)

-- Option 1: If you have a users table with Firebase UIDs:
-- SELECT id FROM users LIMIT 1;

-- Option 2: If you're using Firebase Auth, get the UID from your app:
-- The user_id should be the Firebase Auth UID (string format)

-- ============================================
-- VERIFY NOTIFICATIONS
-- ============================================
-- After inserting, verify with:
-- SELECT * FROM notifications WHERE user_id = 'YOUR_USER_ID' ORDER BY created_at DESC;

-- Count unread notifications:
-- SELECT COUNT(*) FROM notifications WHERE user_id = 'YOUR_USER_ID' AND state = 'unread';


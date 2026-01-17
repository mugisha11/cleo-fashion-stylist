-- Quick Insert: Sample Notifications
-- Replace 'YOUR_USER_ID' with your Firebase Auth UID and run

-- Get your user ID from Firebase Console or your app
-- Format: A long string like "abc123def456ghi789..."

-- Insert 5 sample notifications (mix of types and states)
INSERT INTO notifications (id, user_id, type, title, message, created_at, state, icon_emoji, accent_color, metadata, action_url) VALUES
-- Outfit Ready (Unread)
(
  'notif_' || extract(epoch from now())::text || '_1',
  'YOUR_USER_ID', -- ⚠️ REPLACE THIS
  'outfit_ready',
  'New Outfit Ready!',
  'We found 3 outfits that match your style perfectly. Check them out!',
  NOW() - INTERVAL '5 minutes',
  'unread',
  '👗',
  '#4A90E2',
  '{"outfit_count": 3, "confidence": 0.92}'::jsonb,
  '/outfits'
),
-- Try-On Completed (Unread)
(
  'notif_' || extract(epoch from now())::text || '_2',
  'YOUR_USER_ID', -- ⚠️ REPLACE THIS
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
-- Style Learned (Unread)
(
  'notif_' || extract(epoch from now())::text || '_3',
  'YOUR_USER_ID', -- ⚠️ REPLACE THIS
  'style_learned',
  'AI Learned Your Style!',
  'Based on your preferences, we now understand you love minimalist, modern looks.',
  NOW() - INTERVAL '3 hours',
  'unread',
  '🧠',
  '#10B981',
  '{"style_tags": ["minimalist", "modern"], "confidence": 0.88}'::jsonb,
  NULL
),
-- Event Reminder (Unread)
(
  'notif_' || extract(epoch from now())::text || '_4',
  'YOUR_USER_ID', -- ⚠️ REPLACE THIS
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
-- Wardrobe Match (Unread)
(
  'notif_' || extract(epoch from now())::text || '_5',
  'YOUR_USER_ID', -- ⚠️ REPLACE THIS
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
-- Try-On Completed (Read - for testing read state)
(
  'notif_' || extract(epoch from now())::text || '_6',
  'YOUR_USER_ID', -- ⚠️ REPLACE THIS
  'tryon_completed',
  'Previous Try-On',
  'Check out how this dress looks on your avatar!',
  NOW() - INTERVAL '1 day',
  'read',
  '📸',
  '#7C3AED',
  '{"session_id": "session_789"}'::jsonb,
  '/tryon/session_789'
),
-- System Notification (Read)
(
  'notif_' || extract(epoch from now())::text || '_7',
  'YOUR_USER_ID', -- ⚠️ REPLACE THIS
  'system',
  'Welcome to StyleApp!',
  'Thanks for joining! Complete your style quiz to get personalized recommendations.',
  NOW() - INTERVAL '1 week',
  'read',
  '🔔',
  '#6B7280',
  '{"action": "complete_quiz"}'::jsonb,
  '/questionnaire'
);

-- After inserting, verify with:
-- SELECT * FROM notifications WHERE user_id = 'YOUR_USER_ID' ORDER BY created_at DESC;

-- Count unread:
-- SELECT COUNT(*) as unread_count FROM notifications WHERE user_id = 'YOUR_USER_ID' AND state = 'unread';


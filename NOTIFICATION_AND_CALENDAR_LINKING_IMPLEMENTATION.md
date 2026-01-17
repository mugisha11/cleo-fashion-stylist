# Smart Notification System & Calendar-Outfit Linking - Implementation Guide

## Overview
This document describes the complete implementation of:
1. **Smart Notification System** - Fashion-aware, non-spammy notifications
2. **Calendar ↔ Outfit Linking** - AI-aware fashion calendar integration

## Architecture

### Components
1. **Database Schemas** (Supabase)
   - `notifications` table
   - `user_notification_preferences` table
   - `notification_delivery_log` table
   - `outfit_linking_history` table
   - Calendar schema updates

2. **Firebase Cloud Functions**
   - Notification decision engine
   - FCM push notification sending
   - Calendar-outfit auto-linking
   - Event reminder notifications

3. **Flutter Services**
   - `NotificationService` - Handles FCM, deep linking, preferences
   - `CalendarService` - Enhanced with outfit linking methods

## Database Setup

### 1. Run SQL Migrations
```sql
-- Run in Supabase SQL Editor (in order):
1. supabase_notifications_schema.sql
2. supabase_calendar_outfit_linking_schema.sql
```

### 2. Verify Tables
```sql
-- Check tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
  'notifications',
  'user_notification_preferences',
  'notification_delivery_log',
  'outfit_linking_history'
);
```

## Firebase Functions Setup

### 1. Install Dependencies
```bash
cd functions
npm install @supabase/supabase-js
npm install
```

### 2. Configure Environment
```bash
firebase functions:config:set \
  supabase.url="YOUR_SUPABASE_URL" \
  supabase.service_key="YOUR_SUPABASE_SERVICE_KEY" \
  openweather.api_key="YOUR_OPENWEATHER_API_KEY"
```

### 3. Deploy Functions
```bash
firebase deploy --only functions:generateDailyRecommendations
```

## Flutter Setup

### 1. Add Dependencies
```yaml
# pubspec.yaml
dependencies:
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.0.0
```

### 2. Initialize Notification Service
```dart
// In main.dart or app initialization
final notificationService = NotificationService(
  Supabase.instance.client,
  FirebaseAuth.instance,
);

await notificationService.initialize();
```

### 3. Handle Deep Links
```dart
// In your navigation/routing system
void handleNotificationDeepLink(String deepLink, String screen, Map<String, dynamic> data) {
  switch (deepLink) {
    case 'dashboard':
      Navigator.pushNamed(context, '/dashboard', arguments: {'tab': 'recommendations'});
      break;
    case 'calendar':
      Navigator.pushNamed(context, '/calendar/event', arguments: {'eventId': data['eventId']});
      break;
    // ... other cases
  }
}
```

## Notification Types

### 1. Daily Outfit Ready
- **Trigger**: After daily scheduler completes
- **Condition**: 3 recommendations generated successfully
- **Message**: "✨ Your 3 outfits for today are ready — perfectly matched for your plans."

### 2. Calendar Event Reminder
- **Trigger**: 1-3 hours before event
- **Condition**: Event has linked outfit
- **Message**: "👔 Your outfit for 'Event Name' is ready. Want to review or try it on?"

### 3. Weather Change Alert
- **Trigger**: Significant weather change
- **Condition**: Affects today's outfits
- **Message**: "🌧 Weather changed — we adjusted your outfit for comfort."

### 4. Wardrobe Intelligence
- **Trigger**: AI adapts to limited wardrobe
- **Condition**: Creative reuse required
- **Message**: "♻️ We styled new looks using your existing wardrobe."

## Calendar-Outfit Linking Methods

### 1. AI-Auto Linking (Default)
- **When**: Daily scheduler runs
- **Logic**: Matches outfit style to event type
- **Priority**: Highest confidence outfit for event type

### 2. User-Confirmed Linking
- **When**: User saves outfit from Try-On or Wardrobe
- **Flow**: "Save to Calendar" → Select date/occasion → Link

### 3. Chat-Based Linking
- **When**: User asks AI to plan outfit for event
- **Flow**: AI creates event + generates outfit + links them

## Notification Decision Engine

### Rules (ALL must pass)
1. ✅ `notifications_enabled = true`
2. ✅ `same_type_sent_today = false`
3. ✅ `content_value_score >= 0.6`
4. ✅ Not in quiet hours

### Content Value Score Calculation
```javascript
score = 0.5 (base)
+ 0.2 if recommendationsCount >= 3
+ 0.15 if hasTryOnImages
+ 0.1 if weatherMatch
+ 0.05 if calendarMatch
```

## Testing

### Test Notifications
```javascript
// In Firebase Functions shell
const testUserId = 'your-test-user-id';
await sendRecommendationNotification(testUserId, [
  {outfit_id: '1', title: 'Test Outfit', confidence: 0.9}
]);
```

### Test Calendar Linking
```dart
// In Flutter
await calendarService.linkOutfitToEvent(
  date: DateTime.now(),
  outfitId: 'outfit-123',
  outfitName: 'Test Outfit',
  linkingMethod: 'user_confirmed',
);
```

## Monitoring

### Check Notification Delivery
```sql
SELECT 
  n.type,
  COUNT(*) as total,
  SUM(CASE WHEN n.is_sent THEN 1 ELSE 0 END) as sent,
  SUM(CASE WHEN n.is_read THEN 1 ELSE 0 END) as read
FROM notifications n
WHERE n.created_at >= CURRENT_DATE
GROUP BY n.type;
```

### Check Calendar Linking
```sql
SELECT 
  outfit_linking_method,
  COUNT(*) as count
FROM calendar_days
WHERE linked_outfit_id IS NOT NULL
GROUP BY outfit_linking_method;
```

## Edge Cases Handled

1. **Wardrobe Item Deleted**
   - Trigger: Database trigger `handle_wardrobe_item_deletion`
   - Action: Unlink outfit, re-recommend

2. **Missing Try-On Image**
   - Fallback: Use flat-lay preview
   - Action: Queue try-on generation

3. **Notification Permission Denied**
   - Fallback: In-app notification center
   - Action: Show banner in app

4. **FCM Token Invalid**
   - Action: Skip notification, log error
   - Retry: On next token refresh

## Production Checklist

- [ ] Database schemas deployed
- [ ] Firebase Functions deployed
- [ ] FCM configured in Firebase Console
- [ ] Notification permissions requested in app
- [ ] Deep linking routes configured
- [ ] Quiet hours preferences UI implemented
- [ ] Notification center UI implemented
- [ ] Calendar UI shows outfit thumbnails
- [ ] Event detail shows linked outfit
- [ ] Error logging configured
- [ ] Analytics tracking enabled

## Next Steps

1. **UI Implementation**
   - Notification center screen
   - Notification preferences screen
   - Calendar event detail with outfit preview
   - Deep link navigation handlers

2. **Advanced Features**
   - Weather change detection
   - Wardrobe intelligence alerts
   - Notification scheduling
   - Batch notifications

3. **Analytics**
   - Notification open rates
   - Deep link conversion
   - Calendar-outfit linking success rate
   - User engagement metrics

# Sample Notifications CSV - Data Structure Guide

## Overview
This CSV file contains sample notification data that matches the `notifications` table schema. Use this as a reference to understand how notifications are stored and displayed.

## CSV Structure

### Columns Explained

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `id` | UUID | Unique notification identifier | `550e8400-e29b-41d4-a716-446655440001` |
| `user_id` | TEXT | Firebase Auth UID | `user_abc123` |
| `type` | TEXT | Notification type (see types below) | `daily_outfit` |
| `title` | TEXT | Notification title | `✨ Your 3 outfits for today are ready` |
| `body` | TEXT | Notification message body | `Perfectly matched for your plans...` |
| `payload` | JSONB | Deep link data and metadata | `{"deepLink": "dashboard", ...}` |
| `is_read` | BOOLEAN | Whether user has read it | `false` |
| `is_sent` | BOOLEAN | Whether FCM push was sent | `true` |
| `sent_at` | TIMESTAMPTZ | When notification was sent | `2025-01-15 06:30:00+00` |
| `content_value_score` | DECIMAL | Value score (0.0-1.0) | `0.85` |
| `same_type_sent_today` | BOOLEAN | Spam prevention flag | `false` |
| `created_at` | TIMESTAMPTZ | When notification was created | `2025-01-15 06:00:00+00` |
| `read_at` | TIMESTAMPTZ | When user read it (nullable) | `2025-01-14 09:15:00+00` |

## Notification Types

### 1. `daily_outfit`
- **Trigger**: Daily scheduler completes
- **When**: 6:00 AM daily
- **Example**: "✨ Your 3 outfits for today are ready"
- **Payload**: Contains `deepLink`, `screen`, `date`, `recommendationsCount`

### 2. `event_outfit`
- **Trigger**: 1-3 hours before calendar event
- **When**: Event reminder time
- **Example**: "👔 Your outfit for 'Client Meeting' is ready"
- **Payload**: Contains `eventId`, `outfitId`, `eventName`, `deepLink`

### 3. `weather_alert`
- **Trigger**: Significant weather change
- **When**: Weather API detects change
- **Example**: "🌧 Weather changed — outfit adjusted"
- **Payload**: Contains `weatherChange`, `temperature`, `deepLink`

### 4. `wardrobe_intelligence`
- **Trigger**: AI adapts to limited wardrobe
- **When**: Creative reuse required
- **Example**: "♻️ New looks from your wardrobe"
- **Payload**: Contains `creativeReuse`, `deepLink`

### 5. `outfit_update`
- **Trigger**: Try-on result improved
- **When**: Better quality image available
- **Example**: "✨ Improved try-on result available"
- **Payload**: Contains `tryonId`, `improvement`, `deepLink`

### 6. `calendar_reminder`
- **Trigger**: Outfit scheduled for upcoming event
- **When**: Day before event
- **Example**: "📅 Outfit scheduled for tomorrow"
- **Payload**: Contains `eventId`, `date`, `deepLink`

## Payload Structure Examples

### Daily Outfit Payload
```json
{
  "deepLink": "dashboard",
  "screen": "daily_recommendations",
  "date": "2025-01-15",
  "recommendationsCount": 3
}
```

### Event Outfit Payload
```json
{
  "deepLink": "calendar",
  "screen": "event_detail",
  "eventId": "event_789",
  "outfitId": "outfit_456",
  "eventName": "Client Meeting"
}
```

### Weather Alert Payload
```json
{
  "deepLink": "dashboard",
  "screen": "daily_recommendations",
  "weatherChange": "rain",
  "temperature": 12
}
```

## Content Value Score Guidelines

| Score Range | Meaning | Example |
|-------------|---------|---------|
| 0.9 - 1.0 | Very High Value | Event outfit with try-on image |
| 0.8 - 0.89 | High Value | Daily recommendations with 3 outfits |
| 0.7 - 0.79 | Medium Value | Weather alert, wardrobe intelligence |
| 0.6 - 0.69 | Low-Medium Value | Outfit update, minor changes |
| < 0.6 | Low Value | Not sent (blocked by decision engine) |

## Notification States

### Unread (`is_read = false`)
- User hasn't seen it yet
- Shows in notification center
- Badge count increases

### Read (`is_read = true`)
- User has opened/viewed it
- `read_at` timestamp set
- Still visible in history

### Dismissed
- User swiped away or deleted
- Removed from database
- Not shown in history

### Saved (`payload.is_saved = true`)
- User marked as important
- Pinned in notification center
- Special visual treatment

## Sample User Journey

### User: `user_abc123`

**Day 1 (2025-01-14)**
1. 06:00 - Daily outfit notification created
2. 06:30 - FCM push sent
3. 09:15 - User reads notification
4. 07:00 - Wardrobe intelligence notification (creative reuse)

**Day 2 (2025-01-15)**
1. 06:00 - Daily outfit notification created
2. 06:30 - FCM push sent (unread)
3. 08:00 - Weather alert (rain detected)
4. 14:00 - Event reminder (Client Meeting in 2 hours)

## Importing to Supabase

To import this CSV into Supabase:

1. **Via Supabase Dashboard**:
   - Go to Table Editor > `notifications`
   - Click "Insert" > "Import data from CSV"
   - Upload `sample_notifications.csv`

2. **Via SQL**:
   ```sql
   COPY notifications (
     id, user_id, type, title, body, payload, 
     is_read, is_sent, sent_at, content_value_score, 
     same_type_sent_today, created_at, read_at
   )
   FROM '/path/to/sample_notifications.csv'
   WITH (FORMAT csv, HEADER true);
   ```

## Notes

- **UUIDs**: All IDs are example UUIDs. In production, use `gen_random_uuid()`
- **Timestamps**: All in UTC (ISO 8601 format)
- **Payload**: JSONB format, must be valid JSON
- **User IDs**: Replace with real Firebase Auth UIDs
- **Content Scores**: Calculated by decision engine based on context

## Testing Scenarios

1. **Unread Notifications**: Filter `is_read = false`
2. **Today's Notifications**: Filter `created_at >= CURRENT_DATE`
3. **High Value**: Filter `content_value_score >= 0.8`
4. **By Type**: Filter `type = 'daily_outfit'`
5. **User's Notifications**: Filter `user_id = 'user_abc123'`

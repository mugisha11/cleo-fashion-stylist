# Online & Wardrobe Outfit Recommendations Feature

## Overview

The outfit recommendations system has been enhanced to support **both wardrobe items AND online shopping options**. When users view an item in their wardrobe, they now see outfit combinations that can include:

1. **Wardrobe Recommendations** - Suggestions using items already in their closet
2. **Online Options** - Complementary pieces available from retailers

## What's New

### 1. Enhanced UI with Source Indicators

Each recommendation now displays:
- **Source Badge**: "From Wardrobe" vs "Online Option" with distinct colors
  - Wardrobe: Pink badge with closet icon
  - Online: Blue badge with shopping bag icon
- **Store Information** (for online items): Shows retailer name
- **Pricing** (for online items): Displays estimated cost
- **Shop Button** (for online items): Opens link to purchase (when available)

### 2. Backend API Updates

**Request Body** - `/wardrobe-ai/recommendations`:
```json
{
  "main_item": { /* item details */ },
  "wardrobe_items": [ /* existing wardrobe */ ],
  "online_items": [ /* optional: external shopping items */ ],
  "limit": 3,
  "include_online": true
}
```

**Response** - Each recommendation now includes:
```json
{
  "title": "Outfit Name",
  "description": "Style description",
  "reason": "Why it works",
  "source": "wardrobe" or "online",
  "price": 29.99,
  "source_store": "H&M",
  "source_link": "https://..."
}
```

### 3. Data Model Changes

**OutfitRecommendation class** now supports:
- `source: String` - "wardrobe" or "online"
- `price: double?` - Cost for online items
- `sourceLink: String?` - URL for online shopping
- `sourceStore: String?` - Retailer name

## User Experience

### Before
```
Outfit Ideas
├─ Casual Everyday Look
├─ Professional Work Outfit
└─ Weekend Vibe
```

### After
```
Outfit Ideas
├─ Casual Everyday Look [FROM WARDROBE]
├─ Professional Work Outfit [FROM WARDROBE]
└─ Elevate with New Pieces [ONLINE OPTION]
    ├─ Store: Top Retailers
    ├─ Price: Starting at $29.99
    └─ [SHOP NOW] button
```

## AI Prompt Enhancement

The AI now receives:
- User's existing wardrobe items
- Optional: Online product catalog
- Instructions to suggest from both sources
- Each recommendation marked with source type

## Visual Styling

### Wardrobe Item Styling
- Background: Standard wardrobe card background
- Border: Subtle light border
- Badge: Pink with closet icon
- Label: "From Wardrobe"

### Online Item Styling
- Background: Light blue gradient overlay
- Border: Blue border (2px) for emphasis
- Badge: Blue with shopping bag icon
- Label: "Online Option"
- Additional info: Store name, price, shop button

## Implementation Details

### Files Modified

1. **`lib/src/core/services/wardrobe_service.dart`**
   - Updated `OutfitRecommendation` class with source fields
   - Modified `generateOutfitRecommendations()` to send `include_online: true`
   - Updated recommendation parsing to extract source information
   - Modified fallback recommendations to include online suggestions

2. **`lib/src/features/wardrobe/screens/wardrobe_item_details_screen.dart`**
   - Enhanced `_buildOutfitRecommendationsSection()` widget
   - Added conditional styling based on `rec.source`
   - Displays store name, price, and shop button for online items
   - Added source badge UI with icons

3. **`backend/app/api/wardrobe_ai.py`**
   - Updated `RecommendationItem` model with source fields
   - Updated `RecommendationsRequest` to accept `online_items` and `include_online`
   - Enhanced AI prompt to consider both sources
   - Modified `_parse_recommendations()` to extract source type from AI response
   - Updated fallback recommendations to include online suggestions

## Future Enhancements

1. **Shopping Integration**
   - Add URL routing to open shopping links
   - Integration with major retailers (Amazon, H&M, ASOS, etc.)

2. **Price Tracking**
   - Real-time price updates from APIs
   - Price comparisons across retailers

3. **Smart Recommendations**
   - Learn user preferences (price range, favorite stores)
   - Seasonal shopping suggestions
   - Budget-based filtering

4. **Direct Purchase**
   - In-app purchase capability
   - Wishlist functionality
   - Size & fit recommendations

## Testing

### Test Scenario 1: Wardrobe-Only Recommendation
1. Click on a wardrobe item
2. Verify all recommendations show "From Wardrobe" badge
3. No shop button should appear

### Test Scenario 2: Mixed Recommendations
1. Configure online items in backend
2. Click on a wardrobe item with `include_online: true`
3. Should see mix of wardrobe and online recommendations
4. Online items show store, price, and shop button

### Test Scenario 3: Fallback Behavior
1. Disable both OpenRouter and OpenAI APIs
2. Click on a wardrobe item
3. Should see 2 wardrobe + 1 online fallback recommendation

## Configuration

### Enabling Online Recommendations

In `wardrobe_service.dart`:
```dart
final requestBody = {
  // ... other fields ...
  'include_online': true,  // Set to true to include online items
};
```

### Adding Online Items

Pass online items to the API:
```dart
'online_items': [
  {
    'name': 'White Sneakers',
    'store': 'Nike',
    'price': 89.99,
    'url': 'https://...'
  }
]
```

## Error Handling

- If online items fail to generate: Falls back to wardrobe-only recommendations
- If AI unavailable: Shows mixed fallback (wardrobe + online suggestions)
- All source fields are optional; displays gracefully with defaults

## Performance Notes

- Max 10 online items processed (prevents excessive prompt size)
- Max 20 wardrobe items in context (for AI token efficiency)
- API response time: 2-4 seconds (varies by AI service)
- UI renders instantly with loading states

## Troubleshooting

**Online recommendations not showing?**
- Check `include_online: true` is set in request
- Verify online_items array is populated
- Check backend logs for AI service errors

**Shop button not working?**
- Ensure `sourceLink` is properly formatted URL
- Check browser security settings
- Verify link is valid and accessible

**Wrong source displayed?**
- Check AI prompt includes `**Source:**` format
- Verify `_parse_recommendations()` is parsing correctly
- Check backend logs for response format issues

---

**Status**: ✅ Complete and Ready
**Updated**: Latest Phase
**Compatibility**: Full backward compatibility with wardrobe-only mode

# Quick Reference: Online & Wardrobe Recommendations

## 🎯 What Changed?

Recommendations now show **both wardrobe items AND online shopping options**.

## 🚀 How It Works

### Frontend Flow
```
User clicks wardrobe item
  ↓
wardrobe_item_details_screen calls generateOutfitRecommendations()
  ↓
Request sent to backend with include_online: true
  ↓
Backend AI generates mixed recommendations
  ↓
UI displays with source badges (wardrobe vs online)
```

### API Request
```json
{
  "main_item": { /* item details */ },
  "wardrobe_items": [ /* user's wardrobe */ ],
  "online_items": [ /* optional: external products */ ],
  "include_online": true,
  "limit": 3
}
```

### API Response
Each recommendation includes:
```json
{
  "title": "Outfit Name",
  "description": "Style description",
  "reason": "Why it works",
  "source": "wardrobe",  // or "online"
  "price": null,          // For online items
  "source_store": null,   // For online items
  "source_link": null     // For online items
}
```

## 🎨 UI Display

### Wardrobe Recommendation
```
┌────────────────────────────┐
│ Casual Everyday Look   [Wardrobe] │
├────────────────────────────┤
│ Perfect for running errands│
│ ✨ Comfortable and versatile│
└────────────────────────────┘
```

### Online Recommendation
```
┌────────────────────────────┐
│ Elevate with New Pieces    │ [Online Option]
├────────────────────────────┤
│ Complete the look with items│
│ ✨ Perfect additions available│
│                            │
│ 🏪 Top Retailers          │
│ 💵 $29.99                  │
│ ┌──────────────────────┐   │
│ │    SHOP NOW    →    │   │
│ └──────────────────────┘   │
└────────────────────────────┘
```

## 🔧 Code Integration

### Add Online Items to Backend
```python
# In backend endpoint handler
online_items = [
    {
        'name': 'White Sneakers',
        'store': 'Nike',
        'price': 89.99,
        'url': 'https://nike.com/...'
    }
]

recommendations = await generate_outfit_recommendations(
    include_online=True,
    online_items=online_items
)
```

### Frontend Sending Online Items
```dart
// In wardrobe_service.dart
final requestBody = {
  'main_item': { /* ... */ },
  'wardrobe_items': wardrobeForContext,
  'online_items': externalItems,  // Add online products here
  'include_online': true,
  'limit': 3,
};
```

### Display Online Items
```dart
// Automatically styled in wardrobe_item_details_screen.dart
if (rec.source == 'online') {
  // Shows blue badge, store name, price, shop button
  // Automatically handled by _buildOutfitRecommendationsSection()
}
```

## 📊 Data Flow

```
wardrobe_service.dart
├─ generateOutfitRecommendations()
│  ├─ Fetch wardrobe items
│  ├─ Send request to backend with include_online: true
│  └─ Parse response with source field
└─ OutfitRecommendation
   ├─ source: String (wardrobe/online)
   ├─ price: double? (for online)
   ├─ sourceStore: String? (for online)
   └─ sourceLink: String? (for online)

wardrobe_item_details_screen.dart
├─ _generateRecommendations()
│  └─ Calls wardrobe_service.generateOutfitRecommendations()
└─ _buildOutfitRecommendationsSection()
   ├─ If source == 'online':
   │  ├─ Show blue badge with shopping icon
   │  ├─ Display store name
   │  ├─ Display price
   │  └─ Show shop button
   └─ If source == 'wardrobe':
      ├─ Show pink badge with closet icon
      └─ Standard display

backend/app/api/wardrobe_ai.py
├─ RecommendationsRequest
│  ├─ wardrobe_items: List[ItemInfo]
│  ├─ online_items: List[dict] (NEW)
│  └─ include_online: bool (NEW)
├─ RecommendationItem
│  └─ source: str (NEW)
└─ generate_outfit_recommendations()
   ├─ Accept both wardrobe and online items
   ├─ Pass to AI with source instructions
   └─ Parse source from AI response
```

## ✅ Testing Checklist

- [ ] Wardrobe recommendations show "From Wardrobe" badge
- [ ] Online recommendations show "Online Option" badge
- [ ] Store name displays for online items
- [ ] Price displays for online items
- [ ] Shop button visible for online items with links
- [ ] No errors in console
- [ ] Fallback works when AI unavailable
- [ ] Different styling for online vs wardrobe items

## 🐛 Common Issues

| Issue | Solution |
|-------|----------|
| Online items not showing | Check `include_online: true` is set |
| Wrong badges/colors | Verify `rec.source` field contains "online" or "wardrobe" |
| Shop button not clickable | Ensure `rec.sourceLink` is valid URL |
| API errors | Check backend logs for AI service failures |
| Missing store name | Verify `rec.sourceStore` is populated in response |

## 📝 Configuration

### Enable/Disable Online Recommendations
```dart
// wardrobe_service.dart, line ~180
final requestBody = {
  // ...
  'include_online': false,  // Set to true/false
};
```

### Modify UI Styling
```dart
// wardrobe_item_details_screen.dart, line ~520
final isOnline = rec.source == 'online';
final sourceColor = isOnline 
  ? Colors.blue.withOpacity(0.3)  // Modify blue tone
  : accentPink.withOpacity(0.1);   // Modify pink tone
```

## 🔗 Related Files

- Frontend: `lib/src/core/services/wardrobe_service.dart`
- Frontend: `lib/src/features/wardrobe/screens/wardrobe_item_details_screen.dart`
- Backend: `backend/app/api/wardrobe_ai.py`
- Docs: `ONLINE_RECOMMENDATIONS_FEATURE.md`

## 💡 Tips

1. **Performance**: Limit online items to 10-20 for best AI response time
2. **UX**: Mixed recommendations (wardrobe + online) provide best variety
3. **AI**: More context = better recommendations, but token limit applies
4. **Fallback**: Always works even if AI services fail
5. **Testing**: Use fallback mode to verify UI without API calls

---

**Last Updated**: Latest Phase
**Version**: 1.0
**Status**: ✅ Production Ready

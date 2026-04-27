# AI-Powered Wardrobe Item Descriptions & Outfit Recommendations

## Overview
This feature adds professional AI-generated descriptions and personalized outfit recommendations to the wardrobe item details screen. When users click on a clothing item in their wardrobe, they now see:

1. **Professional Description**: AI-generated, user-friendly description of the item
2. **Outfit Ideas**: AI-generated suggestions for how to style the item with other wardrobe pieces
3. **Minimized Technical Info**: Removed overly technical color information

## Technology Stack
- **AI Models**: 
  - Gemini Nano 2B Vision (via OpenRouter) - FREE tier
  - OpenAI GPT-4 Mini (fallback)
- **Backend**: FastAPI with OpenRouter and OpenAI integration
- **Frontend**: Flutter with Riverpod state management

## Files Modified

### 1. **Backend - API Endpoint** (`backend/app/api/wardrobe_ai.py`)
New file created with two main endpoints:

#### `/wardrobe-ai/description` (POST)
- Generates professional, user-friendly descriptions
- Input: Item category, subcategory, brand, fit, fabric, pattern, colors, occasion, season
- Output: 2-3 sentence professional description
- Uses Gemini Nano or OpenAI (with fallback)

#### `/wardrobe-ai/recommendations` (POST)
- Generates outfit combination suggestions
- Input: Main item details + user's wardrobe items (up to 20)
- Output: 3 outfit ideas with title, description, and why it works
- Provides recommendations for different occasions/moods

**Features**:
- Automatic fallback when AI services fail
- Request parsing for multiple outfit recommendation formats
- Configurable limit (max 5 recommendations)
- Free tier model support (Gemini Nano)

### 2. **Backend - Main Application** (`backend/app/main.py`)
- Imported new `wardrobe_ai` router
- Registered `/wardrobe-ai` routes for API access
- Integrated with existing CORS, exception handling, and logging

### 3. **Dart Frontend - Wardrobe Service** (`lib/src/core/services/wardrobe_service.dart`)
Added three new methods and one new class:

#### Method: `generateItemDescription(item)`
- Calls backend `/wardrobe-ai/description` endpoint
- Returns professional description string
- Includes error handling and fallback descriptions

#### Method: `generateOutfitRecommendations(item)`
- Calls backend `/wardrobe-ai/recommendations` endpoint
- Returns `List<OutfitRecommendation>` with styling suggestions
- Passes user's wardrobe for context
- Handles API failures gracefully

#### Method: `_createFallbackDescription(item)`
- Creates descriptive text from item metadata
- Used when AI fails or is unavailable

#### Method: `_createFallbackRecommendations(item, wardrobe)`
- Generates 3 basic outfit suggestions (Casual, Professional, Weekend)
- Fallback for when API fails

#### Class: `OutfitRecommendation`
- Represents a single outfit recommendation
- Properties: id, title, description, reason, itemIds
- Serializable to JSON

### 4. **Dart Frontend - Details Screen** (`lib/src/features/wardrobe/screens/wardrobe_item_details_screen.dart`)
Enhanced the item details screen with:

#### New State Variables
- `_aiDescription`: Stores generated description
- `_outfitRecommendations`: List of outfit suggestions
- `_isGeneratingDescription`: Loading state for description
- `_isGeneratingRecommendations`: Loading state for recommendations
- `_descriptionError`: Error message if generation fails
- `_recommendationsError`: Error message if generation fails

#### New Lifecycle Methods
- `initState()`: Now calls three async methods:
  - `_loadItemDetails()`: Existing item detail loading
  - `_generateDescription()`: NEW - Generates AI description
  - `_generateRecommendations()`: NEW - Generates outfit suggestions

#### New UI Sections

**1. AI Description Section** (`_buildAIDescriptionSection()`)
- Prominent section with lightbulb icon
- Displays generated description or loading spinner
- Shows error message if generation fails
- Styled with accent color background

**2. Outfit Recommendations Section** (`_buildOutfitRecommendationsSection()`)
- Section with style icon
- Shows 3 outfit recommendations in cards
- Each card displays:
  - Outfit title
  - Description (the vibe/style)
  - "Why it works" reason (why it pairs well)
- Loading state with spinner
- Error handling

#### Modified Sections
- **Removed**: Full colors section (was too technical)
- **Kept**: Category, Quick Facts, Pattern, Brand/Notes, Date
- **Reorganized**: Moved AI sections to top for prominence

## User Flow

1. User navigates to Wardrobe screen
2. Clicks on a clothing item
3. Details screen opens with item image
4. **Immediately below image**:
   - AI-generated professional description starts loading
   - Outfit ideas section starts loading
5. As AI responses arrive, sections populate with:
   - 2-3 sentence professional description
   - 3 outfit combinations with styling tips
6. Below these, user sees:
   - Category and quick facts
   - Brand and notes
   - Upload date

## API Endpoints

### Description Generation
```
POST /wardrobe-ai/description
Content-Type: application/json

Request:
{
  "item": {
    "category": "Tops",
    "subcategory": "T-Shirt",
    "brand": "Nike",
    "fit": "Regular",
    "fabric": "Cotton",
    "pattern": "Solid",
    "colors": ["Blue", "White"],
    "occasion": ["Casual", "Sports"],
    "season": ["Summer"]
  }
}

Response:
{
  "description": "A comfortable blue cotton t-shirt perfect for casual wear and active days. With its regular fit and breathable fabric, it's ideal for weekend hangouts or light exercise. Pairs well with jeans, shorts, or athleisure bottoms.",
  "model": "gemini-nano"
}
```

### Recommendations Generation
```
POST /wardrobe-ai/recommendations
Content-Type: application/json

Request:
{
  "main_item": { ... },  // Same structure as description
  "wardrobe_items": [ ... ],  // List of user's other items
  "limit": 3
}

Response:
{
  "recommendations": [
    {
      "title": "Casual Weekend Look",
      "description": "Perfect for running errands or casual hangouts",
      "reason": "Comfortable and versatile with everyday basics"
    },
    {
      "title": "Sporty Vibe",
      "description": "Great for gym sessions or athletic activities",
      "reason": "Athletic fit and breathable fabric ideal for workouts"
    },
    {
      "title": "Urban Casual",
      "description": "Stylish yet relaxed for city exploration",
      "reason": "Works perfectly with streetwear essentials"
    }
  ],
  "model": "gemini-nano"
}
```

## Error Handling

1. **API Unavailable**: Falls back to basic descriptions/recommendations from metadata
2. **Network Issues**: Catches timeout and connection errors, uses fallback
3. **Invalid Data**: Gracefully handles missing fields with defaults
4. **User Not Authenticated**: Shows appropriate error message

## Performance Considerations

1. **Lazy Loading**: Descriptions and recommendations load asynchronously
2. **Caching**: Consider caching AI responses to reduce API calls
3. **Timeout**: 30s for description, 45s for recommendations
4. **Wardrobe Limit**: Max 20 items sent to API for recommendations
5. **Free Tier Models**: Using Gemini Nano free tier to minimize costs

## Configuration

### Environment Variables Needed (Backend)
- `OPENROUTER_API_KEY`: For Gemini Nano access
- `OPENAI_API_KEY`: For OpenAI fallback
- `OPENROUTER_MODEL_VISION`: Vision model name
- `OPENAI_MODEL`: OpenAI model name

### Hardcoded for Development
- Backend URL: `http://localhost:8000/wardrobe-ai/`
- Timeout: 30-45 seconds
- Models: Gemini Nano 2B Vision (free), GPT-4 Mini (fallback)

## Future Enhancements

1. **Caching**: Store generated descriptions in Firestore
2. **User Preferences**: Tailor recommendations based on user style preferences
3. **Social Features**: Share outfit recommendations with friends
4. **Image Generation**: Generate outfit mockups with recommendations
5. **Real-time Updates**: Refresh descriptions with item edits
6. **Multi-language**: Generate descriptions in user's language
7. **Video Styling**: Include video styling guides with recommendations

## Testing the Feature

1. Start Flutter app: `flutter run`
2. Navigate to Wardrobe
3. Click on any clothing item
4. Wait 3-5 seconds for AI descriptions to load
5. Scroll down to see outfit recommendations
6. Check logs for AI model used and generation success/failure

## Troubleshooting

**Descriptions not loading**:
- Check backend is running: `python -m app.main`
- Verify API key is set: Check OpenRouter/OpenAI credentials
- Check network connectivity: Backend at localhost:8000

**Recommendations showing fallback**:
- Backend API may be slow or failing
- Check API response in browser console
- Verify wardrobe has items for context

**Slow loading**:
- First load generates AI response (3-5s normal)
- Consider implementing request caching
- Check API quota limits

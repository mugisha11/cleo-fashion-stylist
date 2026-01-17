# OpenAI API Setup

## Configuration

The OpenAI API key has been securely configured in the app. The key is stored in secure storage and will be automatically initialized on first launch.

## Model

- **Model**: `gpt-5-mini-2025-08-07`
- **API Key**: Configured and stored securely

## Usage

### Flutter/Dart

```dart
// Get OpenAI service
final openAIService = await ref.read(openAIServiceProvider.future);

// Generate text
final response = await openAIService.generateText(
  prompt: 'Your prompt here',
);

// Generate fashion advice
final advice = await openAIService.generateFashionAdvice(
  context: 'User wardrobe context',
  question: 'What should I wear?',
);

// Analyze outfit
final analysis = await openAIService.analyzeOutfit(
  clothingItems: ['dress', 'shoes', 'jacket'],
  occasion: 'formal',
);
```

### Backend (Python)

```python
from app.services.openai_service import get_openai_service

# Get service
service = get_openai_service()

# Generate text
response = await service.generate_text("Your prompt")

# Generate fashion advice
advice = await service.generate_fashion_advice(
    context="User context",
    question="Fashion question"
)
```

## Security

- ✅ API key stored in secure storage (SharedPreferences)
- ✅ Never hardcoded in source code
- ✅ `.env` files are gitignored
- ✅ Backend reads from environment variables

## Changing the API Key

### Flutter App

The API key is automatically initialized on first launch. To change it:

1. Use the ConfigService:
```dart
await ConfigService.setOpenAIApiKey('your_new_key');
```

2. Or clear and reinitialize:
```dart
await ConfigService.clearAllKeys();
await ConfigService.initializeDefaultKeys();
```

### Backend

Set the environment variable:
```bash
export OPENAI_API_KEY=your_new_key
```

Or create a `.env` file in the backend directory:
```
OPENAI_API_KEY=your_new_key
OPENAI_MODEL=gpt-5-mini-2025-08-07
```

## Notes

- The API key is initialized automatically on first app launch
- All API calls are made securely over HTTPS
- The service handles errors gracefully
- Rate limiting is handled by OpenAI's API

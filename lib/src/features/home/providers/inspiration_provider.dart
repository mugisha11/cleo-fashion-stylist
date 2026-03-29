import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/open_router_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/services/backend_config_service.dart';

/// Inspiration service that generates personalized outfit ideas
/// based on user preferences and trending fashion
class InspirationService {
  final OpenRouterService _openRouter = OpenRouterService();

  /// Generate 2 personalized inspiration outfits with images based on user preferences
  Future<List<InspirationOutfit>> generateInspiration({
    required Map<String, dynamic> userPreferences,
  }) async {
    try {
      // First generate text descriptions using OpenRouter
      final outfits = await _generateOutfitDescriptions(userPreferences);

      // Then generate images for each outfit
      final outfitsWithImages = <InspirationOutfit>[];

      for (final outfit in outfits) {
        try {
          final imageUrl = await _generateOutfitImage(outfit, userPreferences);
          outfitsWithImages.add(InspirationOutfit(
            title: outfit.title,
            description: outfit.description,
            keyPieces: outfit.keyPieces,
            colors: outfit.colors,
            occasion: outfit.occasion,
            imageUrl: imageUrl,
          ));
        } catch (e) {
          // If image generation fails, keep the outfit without image
          outfitsWithImages.add(outfit);
        }
      }

      return outfitsWithImages;
    } catch (e) {
      // Fallback to trending outfits
      return await _getTrendingOutfits();
    }
  }

  Future<List<InspirationOutfit>> _generateOutfitDescriptions(
      Map<String, dynamic> userPreferences) async {
    if (userPreferences.isEmpty) {
      return await _getTrendingOutfits();
    }

    final systemPrompt = _buildInspirationSystemPrompt(userPreferences);
    final userPrompt = _buildInspirationUserPrompt();

    final response = await _openRouter.chat(
      messages: [
        {'role': 'user', 'content': userPrompt},
      ],
      systemPrompt: systemPrompt,
      temperature: 0.7,
      maxTokens: 800,
    );

    return _parseInspirationResponse(response);
  }

  Future<String?> _generateOutfitImage(
      InspirationOutfit outfit, Map<String, dynamic> userPreferences) async {
    try {
      // Create a detailed prompt for image generation
      final imagePrompt = _buildImagePrompt(outfit, userPreferences);

      // Call the backend inspiration API
      final backendUrl = await BackendConfigService.getBackendUrl();

      final response = await http.post(
        Uri.parse('$backendUrl/inspiration/generate-outfit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': imagePrompt,
          'user_preferences': userPreferences,
          'style': outfit.occasion.toLowerCase(),
          'gender': userPreferences['gender'] ?? 'unisex',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['image_base64'];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  String _buildImagePrompt(
      InspirationOutfit outfit, Map<String, dynamic> userPreferences) {
    final gender = userPreferences['gender'] ?? 'person';
    final colors =
        outfit.colors.isNotEmpty ? outfit.colors.join(', ') : 'fashion colors';

    return '''
Photorealistic fashion image of a $gender wearing ${outfit.keyPieces.join(', ')}. 
${outfit.description}. 
Colors: $colors. 
Style: ${outfit.occasion}. 
Professional fashion photography, high quality, detailed fabrics, realistic lighting.
'''
        .trim();
  }

  /// Get trending outfits as fallback
  Future<List<InspirationOutfit>> _getTrendingOutfits() async {
    const systemPrompt = '''
You are a fashion trend expert. Generate 2 trending outfit inspiration ideas for current.
Each outfit should include:
- Title: Catchy, trendy name
- Description: Brief description of the look
- Key pieces: Main clothing items
- Colors: Dominant colors
- Occasion: When to wear it

Format as JSON array of objects with keys: title, description, keyPieces, colors, occasion.
''';

    const userPrompt =
        'Generate 2 trending outfit inspirations for modern fashion.';

    try {
      final response = await _openRouter.chat(
        messages: [
          {'role': 'user', 'content': userPrompt},
        ],
        systemPrompt: systemPrompt,
        temperature: 0.8,
        maxTokens: 600,
      );

      return _parseInspirationResponse(response);
    } catch (e) {
      // Return hardcoded defaults if API fails
      return [
        const InspirationOutfit(
          title: 'Urban Minimalist',
          description:
              'Clean lines and neutral tones for the modern professional',
          keyPieces: ['Tailored blazer', 'White button-up', 'Slim trousers'],
          colors: ['Black', 'White', 'Gray'],
          occasion: 'Office wear',
          imageUrl: null,
        ),
        const InspirationOutfit(
          title: 'Casual Chic',
          description: 'Effortless style with a touch of elegance',
          keyPieces: ['Oversized sweater', 'High-waisted jeans', 'Sneakers'],
          colors: ['Beige', 'White', 'Blue'],
          occasion: 'Weekend outings',
          imageUrl: null,
        ),
      ];
    }
  }

  String _buildInspirationSystemPrompt(Map<String, dynamic> preferences) {
    final gender = preferences['gender'] ?? 'unisex';
    final stylePrefs = preferences['style_preferences'] ?? [];
    final colors = preferences['preferred_colors'] ?? [];
    final bodyType = preferences['body_type'] ?? 'average';

    return '''
You are a personal fashion stylist. Create 2 personalized outfit inspiration ideas based on the user's preferences.

User Profile:
- Gender: $gender
- Style Preferences: ${stylePrefs.join(', ')}
- Preferred Colors: ${colors.join(', ')}
- Body Type: $bodyType

Each outfit should:
- Match their style preferences and color choices
- Be appropriate for their body type
- Include current fashion trends
- Be practical and wearable

Format as JSON array of objects with keys: title, description, keyPieces (array), colors (array), occasion.
''';
  }

  String _buildInspirationUserPrompt() {
    return 'Generate 2 personalized outfit inspiration ideas that match my fashion preferences and current trends.';
  }

  List<InspirationOutfit> _parseInspirationResponse(String response) {
    try {
      // Extract JSON from response
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;
      if (jsonStart == -1 || jsonEnd == 0) {
        throw Exception('No JSON found in response');
      }

      final jsonStr = response.substring(jsonStart, jsonEnd);
      final List<dynamic> data = jsonDecode(jsonStr);

      return data.map((item) {
        return InspirationOutfit(
          title: item['title'] ?? 'Fashion Inspiration',
          description: item['description'] ?? 'A trendy outfit idea',
          keyPieces: List<String>.from(item['keyPieces'] ?? []),
          colors: List<String>.from(item['colors'] ?? []),
          occasion: item['occasion'] ?? 'Casual',
          imageUrl: null,
        );
      }).toList();
    } catch (e) {
      // Return fallback outfits
      return [
        const InspirationOutfit(
          title: 'Personalized Look',
          description: 'An outfit tailored to your preferences',
          keyPieces: ['Custom pieces based on your style'],
          colors: ['Your favorite colors'],
          occasion: 'Everyday wear',
          imageUrl: null,
        ),
      ];
    }
  }
}

/// Inspiration outfit model
class InspirationOutfit {
  final String title;
  final String description;
  final List<String> keyPieces;
  final List<String> colors;
  final String occasion;
  final String? imageUrl; // Base64 encoded image or URL

  const InspirationOutfit({
    required this.title,
    required this.description,
    required this.keyPieces,
    required this.colors,
    required this.occasion,
    this.imageUrl,
  });
}

/// Provider for inspiration service
final inspirationServiceProvider = Provider<InspirationService>((ref) {
  return InspirationService();
});

/// Provider for inspiration outfits
final inspirationOutfitsProvider =
    FutureProvider<List<InspirationOutfit>>((ref) async {
  final inspirationService = ref.read(inspirationServiceProvider);
  final userPreferencesAsync = ref.watch(userPreferencesProvider);
  final userPreferences = userPreferencesAsync.maybeWhen(
    data: (data) => data ?? <String, dynamic>{},
    orElse: () => <String, dynamic>{},
  );
  return inspirationService.generateInspiration(
      userPreferences: userPreferences);
});

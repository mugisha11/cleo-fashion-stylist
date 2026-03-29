import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/trusted_retailers.dart';
import 'config_service.dart';

/// OpenRouter API service for Fashion AI Assistant.
/// Uses https://openrouter.ai/docs (Chat Completions).
/// For end users: uses a built-in key so chat works with no setup.
/// Optional: key can be overridden in Settings (for admins/partners).
class OpenRouterService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static const String _prefsKey = 'open_router_api_key';

  /// Built-in key so end users get Cleo chat with no setup (no API knowledge needed).
  static const String _defaultApiKey =
      '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';

  /// Default model: capable, fast, good for fashion reasoning.
  static const String defaultModel = 'openai/gpt-4o-mini';

  /// Vision model for image-based outfit scoring (supports image_url in content).
  static const String visionModel = 'openai/gpt-4o-mini';

  /// Get API key: user override from Settings, or built-in default for end users.
  static Future<String?> getApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefsKey);
      return stored != null && stored.isNotEmpty ? stored : _defaultApiKey;
    } catch (_) {
      return _defaultApiKey;
    }
  }

  /// Set API key (optional override in Settings, for admins only).
  static Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, key);
  }

  /// Clear stored override (reverts to built-in key).
  static Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// Build system prompt for fashion stylist with wardrobe context.
  /// [userCountryCode]: optional device/locale country (e.g. "DE", "US") so Cleo suggests retailers based on user's location first.
  /// [userPreferencesSummary]: CRITICAL — gender (male/female/etc.), body type, style preferences, colors, events. AI must read this first and never assume gender or style.
  static String buildFashionSystemPrompt({
    String userName = 'User',
    List<Map<String, String>>? wardrobeSummary,
    String? savedPhotoHint,
    String? userCountryCode,
    String? userPreferencesSummary,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
        'You are Nikonyx, a professional fashion stylist AI inside a fashion try-on app.');
    buffer.writeln(
        'You help users pick outfits, try them virtually, see outfit previews, save looks, and schedule outfits.');
    buffer.writeln(
        'Be friendly, stylish, helpful, confident, and modern. Keep responses short but meaningful.');
    buffer.writeln('');
    if (userPreferencesSummary != null && userPreferencesSummary.isNotEmpty) {
      buffer.writeln(
          '## CRITICAL — User preferences (read first, never assume):');
      buffer.writeln(userPreferencesSummary);
      buffer.writeln('');
      buffer.writeln(
          'Always use the above preferences. Do not assume the user\'s gender, body type, or style — only use what is stated. Suggest outfits and products that match their profile.');
      buffer.writeln('');
    }
    buffer.writeln('IMPORTANT — how to show outfits and links:');
    buffer.writeln(
        '- Do NOT paste or show retailer/shop URLs in your normal messages. The app shows outfits and clothes as images; the user can try them on here.');
    buffer.writeln(
        '- Suggest outfits from their wardrobe (use SHOW_WARDROBE or TRY_ON_ITEM_ID so they see images and can try on).');
    buffer.writeln(
        '- Only when the user explicitly asks "where can I buy this", "I want to buy it", "link to buy", "where to buy", etc., give a buy link: end your reply with exactly one line BUY_LINK=<full_url> (one retailer URL). The app will show it as a tappable "Buy this outfit" link.');
    buffer.writeln(
        '- When the user pastes a product link (e.g. from Zalando, ASOS, any shop), the app will fetch and display the product image automatically. You can say something like "I see you shared a link — the app will show the product image so you can try it on or buy."');
    buffer.writeln(
        '- SHOPPING SEARCH: When the user wants to buy clothes, needs shopping help, or asks "find me X", "what am I missing", "I need a blazer", etc., you MUST search for them. End your reply with exactly one line: SEARCH_PRODUCTS=<search query> (e.g. SEARCH_PRODUCTS=white blazer women, SEARCH_PRODUCTS=summer dress). Use a short product search query (2–5 words). The app will search and show product images; the user can try them on or buy. Always output SEARCH_PRODUCTS when suggesting something to buy or when they ask for shopping help.');
    buffer.writeln(
        '- WARDROBE ANALYSIS: When the user asks for outfit advice, "what am I missing", or "help me dress for X", first suggest outfits they already have from their wardrobe (use SHOW_WARDROBE or TRY_ON_ITEM_ID). Then say what piece is missing (e.g. "You have the shirt and pants; you\'re missing a blazer. I\'ll find some for you.") and end with SEARCH_PRODUCTS=<that item> so the app shows options they can try on.');
    buffer.writeln('');
    buffer.writeln('User: $userName');
    if (userCountryCode != null && userCountryCode.isNotEmpty) {
      buffer.writeln(
          'User\'s current location: $userCountryCode (suggest shops and retailers in this country first when they ask where to buy).');
    }
    if (savedPhotoHint != null && savedPhotoHint.isNotEmpty) {
      buffer.writeln(savedPhotoHint);
    }
    if (wardrobeSummary != null && wardrobeSummary.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('## User\'s wardrobe (id, name, category):');
      for (final item in wardrobeSummary) {
        buffer.writeln(
            '- id: ${item['id']}, name: ${item['name']}, category: ${item['category']}');
      }
      buffer.writeln('');
      buffer.writeln(
          'When the user wants to try on a specific item, end your reply with exactly one line: TRY_ON_ITEM_ID=<id>');
      buffer.writeln(
          'When the user asks to see their wardrobe, show their clothes, list their wardrobe, or similar: do NOT list the items in text. Say only one short line (e.g. "Here\'s your wardrobe for you to browse:") and end your reply with exactly this line: SHOW_WARDROBE');
      buffer.writeln(
          'When the user wants to schedule an outfit for a date (e.g. tomorrow, Friday), end your reply with: SCHEDULE_FOR=<date_iso> (e.g. SCHEDULE_FOR=2025-01-15)');
    }
    buffer.writeln(
        'When the user says they want to post their look, share this outfit, show my followers, can I post this, or similar, end your reply with exactly one line: POST_THIS_LOOK');
    buffer.writeln('');
    buffer.writeln(
        'Do not make up item ids. Only use TRY_ON_ITEM_ID with an id from the wardrobe list above.');
    buffer.writeln('');
    buffer.writeln(
        getTrustedRetailersPromptText(userCountryCode: userCountryCode));
    return buffer.toString();
  }

  /// Send chat completion request to OpenRouter.
  /// [messages]: list of {role: 'user'|'assistant'|'system', content: string}.
  /// Returns assistant content or throws.
  Future<String> chat({
    required List<Map<String, String>> messages,
    String? systemPrompt,
    String model = defaultModel,
    double temperature = 0.7,
    int maxTokens = 1024,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw OpenRouterException(
          'Something went wrong. Please try again later.');
    }

    final body = <String, dynamic>{
      'model': model,
      'messages': _buildMessages(messages, systemPrompt),
      'temperature': temperature,
      'max_tokens': maxTokens,
    };

    final response = await http
        .post(
          Uri.parse('$_baseUrl/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
            'HTTP-Referer': 'https://cleofashion.app',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      final err = response.body.isNotEmpty
          ? (jsonDecode(response.body) as Map<String, dynamic>?)?.toString() ??
              response.body
          : response.reasonPhrase ?? 'Unknown error';
      throw OpenRouterException(
          'OpenRouter error (${response.statusCode}): $err');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw OpenRouterException('OpenRouter returned no choices');
    }
    final content = (choices.first as Map<String, dynamic>)['message']
        ?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw OpenRouterException('OpenRouter returned empty content');
    }
    return content.trim();
  }

  /// Same as [chat] but falls back to OpenAI when OpenRouter fails
  /// (timeout, rate limit, token exhaustion, etc.).
  Future<String> chatWithFallback({
    required List<Map<String, String>> messages,
    String? systemPrompt,
    String model = defaultModel,
    double temperature = 0.7,
    int maxTokens = 1024,
  }) async {
    try {
      return await chat(
        messages: messages,
        systemPrompt: systemPrompt,
        model: model,
        temperature: temperature,
        maxTokens: maxTokens,
      );
    } catch (_) {
      return _chatViaOpenAI(
        messages: messages,
        systemPrompt: systemPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
      );
    }
  }

  static const String _openAIFallbackModel = 'gpt-4o-mini';

  /// Call OpenAI API directly (fallback when OpenRouter fails).
  Future<String> _chatViaOpenAI({
    required List<Map<String, String>> messages,
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 1024,
  }) async {
    final apiKey = await ConfigService.getOpenAIApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw OpenRouterException(
        'OpenRouter failed and no OpenAI key set. Add OpenAI key in Settings as fallback.',
      );
    }

    final openaiModel = await ConfigService.getOpenAIModel();
    final built = _buildMessages(messages, systemPrompt);

    // Try configured model first; on 404 (invalid model) retry with gpt-4o-mini
    try {
      return await _postOpenAI(
          apiKey, openaiModel, built, temperature, maxTokens);
    } catch (e) {
      final err = e.toString();
      if (err.contains('404') ||
          (err.toLowerCase().contains('model') &&
              err.toLowerCase().contains('invalid'))) {
        return _postOpenAI(
            apiKey, _openAIFallbackModel, built, temperature, maxTokens);
      }
      rethrow;
    }
  }

  Future<String> _postOpenAI(
    String apiKey,
    String model,
    List<Map<String, dynamic>> messages,
    double temperature,
    int maxTokens,
  ) async {
    final body = <String, dynamic>{
      'model': model,
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens,
    };

    final response = await http
        .post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      final err = response.body.isNotEmpty
          ? (jsonDecode(response.body) as Map<String, dynamic>?)?.toString() ??
              response.body
          : response.reasonPhrase ?? 'Unknown error';
      throw OpenRouterException('OpenAI error (${response.statusCode}): $err');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw OpenRouterException('OpenAI returned no choices');
    }
    final content = (choices.first as Map<String, dynamic>)['message']
        ?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw OpenRouterException('OpenAI returned empty content');
    }
    return content.trim();
  }

  List<Map<String, dynamic>> _buildMessages(
    List<Map<String, String>> messages,
    String? systemPrompt,
  ) {
    final list = <Map<String, dynamic>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      list.add({'role': 'system', 'content': systemPrompt});
    }
    for (final m in messages) {
      list.add({'role': m['role'], 'content': m['content'] ?? ''});
    }
    return list;
  }

  /// Call a vision model with one image URL (data: or https:) and a text prompt.
  /// Used for outfit scoring. Returns raw assistant text.
  Future<String> chatWithImage({
    required String imageUrl,
    required String userPrompt,
    required String systemPrompt,
    String model = visionModel,
    double temperature = 0.3,
    int maxTokens = 512,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw OpenRouterException(
          'Something went wrong. Please try again later.');
    }

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': userPrompt},
          {
            'type': 'image_url',
            'image_url': {'url': imageUrl}
          },
        ],
      },
    ];

    final body = <String, dynamic>{
      'model': model,
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens,
    };

    final response = await http
        .post(
          Uri.parse('$_baseUrl/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
            'HTTP-Referer': 'https://cleofashion.app',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      final err = response.body.isNotEmpty
          ? (jsonDecode(response.body) as Map<String, dynamic>?)?.toString() ??
              response.body
          : response.reasonPhrase ?? 'Unknown error';
      throw OpenRouterException(
          'OpenRouter error (${response.statusCode}): $err');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw OpenRouterException('OpenRouter returned no choices');
    }
    final content = (choices.first as Map<String, dynamic>)['message']
        ?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw OpenRouterException('OpenRouter returned empty content');
    }
    return content.trim();
  }

  /// Get trending outfit suggestions with titles and image URLs
  Future<List<Map<String, String>>> getTrendingOutfits() async {
    const systemPrompt = '''
You are a fashion stylist AI. Generate 2 trending outfit suggestions that would fit a user's wardrobe.
For each outfit, provide:
- A catchy title (max 30 characters)
- A realistic image URL from unsplash.com showing the outfit

Format your response as JSON:
[
  {"title": "Title 1", "image": "https://images.unsplash.com/photo-..."},
  {"title": "Title 2", "image": "https://images.unsplash.com/photo-..."}
]
''';

    final response = await chat(
      messages: [
        {'role': 'user', 'content': 'Generate trending outfit suggestions'}
      ],
      systemPrompt: systemPrompt,
      temperature: 0.8,
      maxTokens: 512,
    );

    try {
      // Parse JSON response
      final jsonResponse = jsonDecode(response) as List<dynamic>;
      return jsonResponse
          .map((item) => {
                'title': item['title'] as String,
                'image': item['image'] as String,
              })
          .toList();
    } catch (e) {
      // If JSON parsing fails, return fallback data
      return [
        {
          'title': 'Elevated Formal Confidence',
          'image':
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=600&fit=crop',
        },
        {
          'title': 'Smart Casual Made Effortless',
          'image':
              'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&h=600&fit=crop',
        },
      ];
    }
  }
}

class OpenRouterException implements Exception {
  final String message;
  OpenRouterException(this.message);
  @override
  String toString() => message;
}

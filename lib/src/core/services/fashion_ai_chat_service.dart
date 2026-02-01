import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/wardrobe_item_model.dart';
import '../models/tryon_session_model.dart';
import 'weather_service.dart';
import 'tryon_memory_service.dart';
import 'wardrobe_service.dart';
import '../../features/calendar/providers/calendar_provider.dart';
import '../services/calendar_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fashion AI Chat Service - ChatGPT-level reasoning for fashion
/// Only generates outfits when explicitly requested
class FashionAIChatService {
  final SupabaseClient _supabase;
  final FirebaseAuth _auth;
  final WeatherService _weatherService;
  final TryOnMemoryService _tryOnMemory;
  final WardrobeService _wardrobeService;
  final Ref _ref;
  
  // Lazy-loaded calendar service
  CalendarService? _calendarService;

  FashionAIChatService(
    this._supabase,
    this._auth,
    this._weatherService,
    this._tryOnMemory,
    this._wardrobeService,
    this._ref,
  );

  String get _userId => _auth.currentUser?.uid ?? '';

  /// Process user message and determine intent
  Future<Map<String, dynamic>> processMessage(String message) async {
    try {
      // Analyze intent
      final intent = await _analyzeIntent(message);

      if (intent['type'] == 'outfit_request') {
        // Generate outfit recommendations
        return await _generateOutfitRecommendations(intent);
      } else {
        // Conversational response
        return await _generateConversationalResponse(message, intent);
      }
    } catch (e) {
      return {
        'type': 'error',
        'content': 'I apologize, but I encountered an error. Please try again.',
      };
    }
  }

  /// Analyze user intent
  Future<Map<String, dynamic>> _analyzeIntent(String message) async {
    final lowerMessage = message.toLowerCase();

    // Keywords that indicate outfit request
    final outfitKeywords = [
      'outfit',
      'wear',
      'what should i wear',
      'recommend',
      'suggest',
      'plan outfit',
      'what to wear',
      'dress',
      'clothes',
    ];

    final isOutfitRequest = outfitKeywords.any((keyword) =>
        lowerMessage.contains(keyword));

    if (isOutfitRequest) {
      // Extract date if mentioned
      DateTime? targetDate;
      if (lowerMessage.contains('today')) {
        targetDate = DateTime.now();
      } else if (lowerMessage.contains('tomorrow')) {
        targetDate = DateTime.now().add(const Duration(days: 1));
      } else if (lowerMessage.contains('week')) {
        // Plan for week
        return {
          'type': 'week_planning',
          'targetDate': null,
        };
      }

      return {
        'type': 'outfit_request',
        'targetDate': targetDate ?? DateTime.now(),
        'count': 5,
      };
    }

    return {
      'type': 'conversation',
      'message': message,
    };
  }

  /// Generate outfit recommendations with try-on images
  Future<Map<String, dynamic>> _generateOutfitRecommendations(
    Map<String, dynamic> intent,
  ) async {
    try {
      // Gather context
      final context = await _gatherContext(intent['targetDate'] as DateTime?);

      // Call AI service
      final recommendations = await _callFashionAI(context, intent);

      // Ensure try-on images exist
      final recommendationsWithTryOns = await _ensureTryOnImages(
        recommendations,
        context,
      );

      return {
        'type': 'outfit_recommendations',
        'date': (intent['targetDate'] as DateTime?)
                ?.toIso8601String()
                .split('T')[0] ??
            DateTime.now().toIso8601String().split('T')[0],
        'recommendations': recommendationsWithTryOns,
      };
    } catch (e) {
      print('Error generating recommendations: $e');
      return {
        'type': 'error',
        'content': 'I had trouble generating recommendations. Please try again.',
      };
    }
  }

  /// Gather all context for AI reasoning
  Future<Map<String, dynamic>> _gatherContext(DateTime? targetDate) async {
    final date = targetDate ?? DateTime.now();

    // Get user profile
    final userDoc = await _supabase
        .from('users')
        .select()
        .eq('id', _userId)
        .maybeSingle();

    // Get wardrobe
    final wardrobe = await _wardrobeService.getUserWardrobe();

    // Get calendar events
    _calendarService ??= _ref.read(calendarServiceProvider);
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = startDate.add(const Duration(days: 1));
    final events = await _calendarService!.getEvents(
      startDate: startDate,
      endDate: endDate,
    );

    // Get weather
    final weather = await _weatherService.getCurrentWeather();

    // Get recent try-ons
    final tryOns = await _tryOnMemory.getSavedTryOns(limit: 10);

    return {
      'user': userDoc ?? {},
      'wardrobe': wardrobe,
      'calendar': events,
      'weather': weather,
      'tryOns': tryOns,
      'date': date,
    };
  }

  /// Call fashion AI service
  Future<List<Map<String, dynamic>>> _callFashionAI(
    Map<String, dynamic> context,
    Map<String, dynamic> intent,
  ) async {
    try {
      // Try Supabase Edge Function first
      try {
        final response = await _supabase.functions.invoke(
          'fashion-ai-reasoning',
          body: {
            'user_id': _userId,
            'context': context,
            'intent': intent,
          },
        );

        if (response.status == 200 && response.data != null) {
          final data = response.data as Map<String, dynamic>;
          return (data['recommendations'] as List<dynamic>?)
                  ?.map((r) => r as Map<String, dynamic>)
                  .toList() ??
              [];
        }
      } catch (e) {
        print('Edge function failed, trying OpenAI directly: $e');
      }

      // Fallback to OpenAI directly
      return await _callOpenAIDirectly(context, intent);
    } catch (e) {
      print('AI service failed: $e');
      return _generateFallbackRecommendations(context);
    }
  }

  /// Call OpenAI directly
  Future<List<Map<String, dynamic>>> _callOpenAIDirectly(
    Map<String, dynamic> context,
    Map<String, dynamic> intent,
  ) async {
    const apiKey = 'YOUR_OPENAI_API_KEY'; // TODO: Move to config

    const systemPrompt = '''You are a world-class AI fashion stylist with the reasoning ability of ChatGPT and the taste of a luxury fashion consultant.

CRITICAL RULES:
- Generate exactly 5 outfit recommendations
- Every outfit MUST have a try-on image (user wearing it)
- Match weather conditions
- Match calendar events
- Use only items from the user's wardrobe
- Be realistic and practical
- Explain reasoning briefly (1-2 sentences)

Respond ONLY in this JSON format:
{
  "recommendations": [
    {
      "outfit_id": "uuid",
      "title": "Outfit Name",
      "reasoning": "Brief explanation",
      "weather_match": "Weather description",
      "event_match": "Event type or null",
      "outfit_item_ids": ["item_id1", "item_id2"],
      "confidence": 0.95
    }
  ]
}''';

    final userPrompt = '''Generate 5 outfit recommendations for ${(context['date'] as DateTime).toIso8601String().split('T')[0]}.

Context:
- Weather: ${jsonEncode(context['weather'])}
- Calendar: ${jsonEncode(context['calendar'])}
- Wardrobe: ${(context['wardrobe'] as List).length} items
- Try-Ons: ${(context['tryOns'] as List).length} saved''';

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.7,
        'max_tokens': 2000,
        'response_format': {'type': 'json_object'},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = jsonDecode(
        data['choices'][0]['message']['content'] as String,
      ) as Map<String, dynamic>;
      return (content['recommendations'] as List<dynamic>?)
              ?.map((r) => r as Map<String, dynamic>)
              .toList() ??
          [];
    }

    throw Exception('OpenAI API error');
  }

  /// Ensure try-on images exist for recommendations
  Future<List<Map<String, dynamic>>> _ensureTryOnImages(
    List<Map<String, dynamic>> recommendations,
    Map<String, dynamic> context,
  ) async {
    final updated = <Map<String, dynamic>>[];

    for (final rec in recommendations) {
      final outfitIds = (rec['outfit_item_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      // Check if try-on exists
      final tryOns = context['tryOns'] as List<TryOnSession>;
      final matchingTryOn = tryOns.firstWhere(
        (t) =>
            t.outfitIds.length == outfitIds.length &&
            t.outfitIds.every((id) => outfitIds.contains(id)),
        orElse: () => tryOns.isNotEmpty ? tryOns.first : TryOnSession(
              id: '',
              userId: '',
              baseImageUrl: '',
              resultImageUrl: '',
              outfitIds: const [],
              createdAt: DateTime.now(),
            ),
      );

      if (matchingTryOn.resultImageUrl.isNotEmpty) {
        rec['tryon_image_url'] = matchingTryOn.resultImageUrl;
      } else {
        // Generate try-on image
        rec['tryon_image_url'] = await _generateTryOnImage(outfitIds, context);
      }

      updated.add(rec);
    }

    return updated;
  }

  /// Generate try-on image for outfit
  Future<String?> _generateTryOnImage(
    List<String> outfitIds,
    Map<String, dynamic> context,
  ) async {
    try {
      final tryOns = context['tryOns'] as List<TryOnSession>;
      if (tryOns.isEmpty) {
        return null; // No base image available
      }

      final baseImageUrl = tryOns.first.baseImageUrl;
      final wardrobe = context['wardrobe'] as List<WardrobeItemModel>;
      final outfitItems = wardrobe
          .where((item) => outfitIds.contains(item.id))
          .toList();

      if (outfitItems.isEmpty) {
        return null;
      }

      // Call try-on service
      // TODO: Integrate with actual try-on API
      return null;
    } catch (e) {
      print('Error generating try-on: $e');
      return null;
    }
  }

  /// Generate conversational response
  Future<Map<String, dynamic>> _generateConversationalResponse(
    String message,
    Map<String, dynamic> intent,
  ) async {
    // Use existing chat service for conversational responses
    // This keeps the AI friendly and helpful without generating outfits
    return {
      'type': 'conversation',
      'content':
          'I\'m here to help with your fashion needs! Ask me about outfits, styling tips, or what to wear for specific occasions.',
    };
  }

  /// Fallback recommendations when AI fails
  List<Map<String, dynamic>> _generateFallbackRecommendations(
    Map<String, dynamic> context,
  ) {
    final wardrobe = context['wardrobe'] as List<WardrobeItemModel>;
    if (wardrobe.isEmpty) {
      return [];
    }

    return wardrobe.take(5).map((item) {
      return {
        'outfit_id': 'fallback_${item.id}',
        'title': '${item.category} Outfit',
        'reasoning': 'A stylish look from your wardrobe',
        'weather_match': 'Comfortable',
        'event_match': null,
        'outfit_item_ids': [item.id],
        'confidence': 0.7,
        'tryon_image_url': null,
      };
    }).toList();
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/tryon_session_model.dart';
import '../models/wardrobe_item_model.dart';
import '../models/calendar_day_model.dart';
import 'weather_service.dart';
import 'tryon_memory_service.dart';
import 'wardrobe_service.dart';
import 'calendar_service.dart';

/// AI Recommendation Engine - Generates 5 daily outfit recommendations
/// Uses weather, calendar, wardrobe, and user behavior
class AIRecommendationEngine {
  final SupabaseClient _supabase;
  final FirebaseAuth _auth;
  final WeatherService _weatherService;
  final TryOnMemoryService _tryOnMemory;
  final WardrobeService _wardrobeService;
  late final CalendarService _calendarService;

  AIRecommendationEngine(
    this._supabase,
    this._auth,
    this._weatherService,
    this._tryOnMemory,
    this._wardrobeService,
  ) : _calendarService = CalendarService(_supabase, _auth);

  String get _userId => _auth.currentUser?.uid ?? '';

  /// Generate 5 daily outfit recommendations
  Future<List<OutfitRecommendation>> generateDailyRecommendations({
    DateTime? forDate,
  }) async {
    try {
      if (_userId.isEmpty) return [];

      final targetDate = forDate ?? DateTime.now();
      
      // Check cache first
      final cached = await _getCachedRecommendations(targetDate);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }

      // Gather all input signals
      final weather = await _weatherService.getCurrentWeather();
      final calendarEvents = await _getCalendarEvents(targetDate);
      final wardrobe = await _wardrobeService.getUserWardrobe();
      final userPreferences = await _getUserPreferences();
      final pastTryOns = await _tryOnMemory.getSavedTryOns(limit: 10);

      // Generate recommendations using AI reasoning
      final recommendations = await _generateRecommendationsWithAI(
        weather: weather,
        calendarEvents: calendarEvents,
        wardrobe: wardrobe,
        userPreferences: userPreferences,
        pastTryOns: pastTryOns,
        targetDate: targetDate,
      );

      // Ensure each recommendation has a try-on image
      final recommendationsWithTryOns = await _ensureTryOnImages(
        recommendations,
        wardrobe,
      );

      // Cache results
      await _cacheRecommendations(targetDate, recommendationsWithTryOns);

      return recommendationsWithTryOns;
    } catch (e) {
      print('Error generating recommendations: $e');
      return [];
    }
  }

  Future<List<OutfitRecommendation>> _generateRecommendationsWithAI({
    required WeatherData? weather,
    required List<CalendarDay> calendarEvents,
    required List<WardrobeItemModel> wardrobe,
    required Map<String, dynamic> userPreferences,
    required List<TryOnSession> pastTryOns,
    required DateTime targetDate,
  }) async {
    try {
      // Build context for AI
      final context = _buildAIContext(
        weather: weather,
        calendarEvents: calendarEvents,
        wardrobe: wardrobe,
        userPreferences: userPreferences,
        pastTryOns: pastTryOns,
        targetDate: targetDate,
      );

      // Call AI service (OpenAI via Supabase Edge Function or local server)
      final response = await _callAIRecommendationService(context);

      // Parse AI response into recommendations
      return _parseAIResponse(response, wardrobe, targetDate);
    } catch (e) {
      print('AI recommendation error: $e');
      // Fallback to rule-based recommendations
      return _generateFallbackRecommendations(
        weather: weather,
        calendarEvents: calendarEvents,
        wardrobe: wardrobe,
        targetDate: targetDate,
      );
    }
  }

  Map<String, dynamic> _buildAIContext({
    required WeatherData? weather,
    required List<CalendarDay> calendarEvents,
    required List<WardrobeItemModel> wardrobe,
    required Map<String, dynamic> userPreferences,
    required List<TryOnSession> pastTryOns,
    required DateTime targetDate,
  }) {
    return {
      'date': targetDate.toIso8601String(),
      'weather': weather != null
          ? {
              'temperature': weather.temperature,
              'condition': weather.condition,
              'description': weather.description,
              'is_cold': weather.isCold,
              'is_warm': weather.isWarm,
              'is_hot': weather.isHot,
              'is_raining': weather.isRaining,
            }
          : null,
      'calendar_events': calendarEvents.map((e) => {
            'date': e.date.toIso8601String(),
            'event_type': e.eventType,
            'event_name': e.eventName,
            'occasion': e.eventType,
          }).toList(),
      'wardrobe_summary': {
        'total_items': wardrobe.length,
        'categories': wardrobe.map((w) => w.category).toSet().toList(),
        'colors': wardrobe.expand((w) => w.colorTags ?? []).toSet().toList(),
      },
      'user_preferences': userPreferences,
      'past_tryons_count': pastTryOns.length,
    };
  }

  Future<Map<String, dynamic>> _callAIRecommendationService(
    Map<String, dynamic> context,
  ) async {
    try {
      // Try Supabase Edge Function first
      try {
        final response = await _supabase.functions.invoke(
          'generate-outfit-recommendations',
          body: {
            'user_id': _userId,
            'context': context,
            'count': 5,
          },
        );

        if (response.status == 200 && response.data != null) {
          return response.data as Map<String, dynamic>;
        }
      } catch (e) {
        print('Edge function failed, trying local server: $e');
      }

      // Fallback to local server
      const apiBaseUrl = 'http://localhost:8000';
      final httpResponse = await http
          .post(
            Uri.parse('$apiBaseUrl/ai/generate-recommendations'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': _userId,
              'context': context,
              'count': 5,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (httpResponse.statusCode == 200) {
        return jsonDecode(httpResponse.body) as Map<String, dynamic>;
      }

      throw Exception('AI service unavailable');
    } catch (e) {
      throw Exception('Failed to call AI service: $e');
    }
  }

  List<OutfitRecommendation> _parseAIResponse(
    Map<String, dynamic> response,
    List<WardrobeItemModel> wardrobe,
    DateTime targetDate,
  ) {
    try {
      final recommendations = response['recommendations'] as List<dynamic>?;
      if (recommendations == null || recommendations.isEmpty) {
        return [];
      }

      return recommendations
          .take(5)
          .map((item) {
            final data = item as Map<String, dynamic>;
            final outfitIds = (data['outfit_item_ids'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];

            return OutfitRecommendation(
              id: data['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
              name: data['name'] as String? ?? 'Recommended Outfit',
              reasoning: data['reasoning'] as String? ?? 'AI recommended outfit',
              weatherMatch: data['weather_match'] as String?,
              eventMatch: data['event_match'] as String?,
              outfitItemIds: outfitIds,
              confidence: (data['confidence'] as num?)?.toDouble() ?? 0.8,
              recommendedFor: targetDate,
              metadata: data['metadata'] as Map<String, dynamic>?,
            );
          })
          .toList();
    } catch (e) {
      print('Error parsing AI response: $e');
      return [];
    }
  }

  Future<List<OutfitRecommendation>> _ensureTryOnImages(
    List<OutfitRecommendation> recommendations,
    List<WardrobeItemModel> wardrobe,
  ) async {
    final updated = <OutfitRecommendation>[];

    for (var rec in recommendations) {
      // Check if try-on already exists
      String? tryOnImageUrl = rec.tryOnImageUrl;

      if (tryOnImageUrl == null || tryOnImageUrl.isEmpty) {
        // Generate try-on for this outfit
        tryOnImageUrl = await _generateTryOnForOutfit(rec, wardrobe);
      }

      updated.add(rec.copyWith(tryOnImageUrl: tryOnImageUrl));
    }

    return updated;
  }

  Future<String?> _generateTryOnForOutfit(
    OutfitRecommendation recommendation,
    List<WardrobeItemModel> wardrobe,
  ) async {
    try {
      // Get latest base image
      final baseImageUrl = await _tryOnMemory.getLatestBaseImage();
      if (baseImageUrl == null) {
        print('No base image available for try-on');
        return null;
      }

      // Get outfit item images
      final outfitItems = wardrobe
          .where((item) => recommendation.outfitItemIds.contains(item.id))
          .toList();

      if (outfitItems.isEmpty) {
        return null;
      }

      // Use first item as representative (or combine multiple)
      final clothingImageUrl = outfitItems.first.processedImageUrl ??
          outfitItems.first.imageUrl;

      // Call try-on service
      // TODO: Integrate with actual try-on service
      // For now, return placeholder
      return null;
    } catch (e) {
      print('Error generating try-on: $e');
      return null;
    }
  }

  List<OutfitRecommendation> _generateFallbackRecommendations({
    required WeatherData? weather,
    required List<CalendarDay> calendarEvents,
    required List<WardrobeItemModel> wardrobe,
    required DateTime targetDate,
  }) {
    // Rule-based fallback when AI is unavailable
    final recommendations = <OutfitRecommendation>[];

    // Group wardrobe by category
    final byCategory = <String, List<WardrobeItemModel>>{};
    for (var item in wardrobe) {
      byCategory.putIfAbsent(item.category, () => []).add(item);
    }

    // Generate 5 recommendations based on rules
    final event = calendarEvents.isNotEmpty ? calendarEvents.first : null;
    final eventType = event?.eventType ?? 'casual';

    // Recommendation 1: Event-appropriate
    if (byCategory.containsKey('Dress') || byCategory.containsKey('Top')) {
      recommendations.add(OutfitRecommendation(
        id: '${targetDate.millisecondsSinceEpoch}_1',
        name: _getEventOutfitName(eventType),
        reasoning: _getEventReasoning(eventType, weather),
        weatherMatch: weather != null ? _getWeatherMatch(weather) : null,
        eventMatch: eventType,
        outfitItemIds: _selectOutfitItems(byCategory, eventType, weather),
        confidence: 0.85,
        recommendedFor: targetDate,
      ));
    }

    // Add 4 more recommendations...
    // (Simplified for brevity - full implementation would generate 5)

    return recommendations.take(5).toList();
  }

  String _getEventOutfitName(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'work':
        return 'Professional Work Outfit';
      case 'casual':
        return 'Casual Day Outfit';
      case 'event':
        return 'Event Outfit';
      case 'formal':
        return 'Formal Outfit';
      default:
        return 'Stylish Outfit';
    }
  }

  String _getEventReasoning(String eventType, WeatherData? weather) {
    final weatherPart = weather != null
        ? 'Perfect for ${weather.temperature.toStringAsFixed(0)}°C weather'
        : 'Great for today';
    return '$weatherPart. Ideal for ${eventType} occasions.';
  }

  String _getWeatherMatch(WeatherData weather) {
    if (weather.isCold) return 'Warm and cozy';
    if (weather.isHot) return 'Light and breathable';
    if (weather.isRaining) return 'Weather-appropriate';
    return 'Comfortable for current conditions';
  }

  List<String> _selectOutfitItems(
    Map<String, List<WardrobeItemModel>> byCategory,
    String eventType,
    WeatherData? weather,
  ) {
    final items = <String>[];

    // Select top
    if (byCategory.containsKey('Top')) {
      items.add(byCategory['Top']!.first.id);
    }

    // Select bottom
    if (byCategory.containsKey('Pants') || byCategory.containsKey('Jeans')) {
      items.add((byCategory['Pants'] ?? byCategory['Jeans'])!.first.id);
    }

    // Add jacket if cold
    if (weather != null && weather.isCold && byCategory.containsKey('Jacket')) {
      items.add(byCategory['Jacket']!.first.id);
    }

    return items;
  }

  Future<List<CalendarDay>> _getCalendarEvents(DateTime date) async {
    try {
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = startDate.add(const Duration(days: 1));

      final events = await _calendarService.getEvents(
        startDate: startDate,
        endDate: endDate,
      );

      // Convert to CalendarDay format
      return events.map((e) {
        return CalendarDay(
          date: e.date,
          eventType: e.eventType,
          eventName: e.eventName,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> _getUserPreferences() async {
    try {
      final response = await _supabase
          .from('user_preferences')
          .select()
          .eq('user_id', _userId)
          .maybeSingle();

      return response as Map<String, dynamic>? ?? {};
    } catch (e) {
      return {};
    }
  }

  Future<List<OutfitRecommendation>?> _getCachedRecommendations(
    DateTime date,
  ) async {
    try {
      final dateKey = DateTime(date.year, date.month, date.day)
          .toIso8601String()
          .split('T')[0];

      final response = await _supabase
          .from('daily_recommendations')
          .select()
          .eq('user_id', _userId)
          .eq('recommended_for', dateKey)
          .maybeSingle();

      if (response == null) return null;

      final recommendations = (response['recommendations'] as List<dynamic>?)
              ?.map((r) => OutfitRecommendation.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [];

      return recommendations.isNotEmpty ? recommendations : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheRecommendations(
    DateTime date,
    List<OutfitRecommendation> recommendations,
  ) async {
    try {
      final dateKey = DateTime(date.year, date.month, date.day)
          .toIso8601String()
          .split('T')[0];

      await _supabase.from('daily_recommendations').upsert({
        'user_id': _userId,
        'recommended_for': dateKey,
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error caching recommendations: $e');
    }
  }
}

extension OutfitRecommendationExtension on OutfitRecommendation {
  OutfitRecommendation copyWith({
    String? id,
    String? name,
    String? reasoning,
    String? weatherMatch,
    String? eventMatch,
    String? tryOnImageUrl,
    List<String>? outfitItemIds,
    double? confidence,
    DateTime? recommendedFor,
    Map<String, dynamic>? metadata,
  }) {
    return OutfitRecommendation(
      id: id ?? this.id,
      name: name ?? this.name,
      reasoning: reasoning ?? this.reasoning,
      weatherMatch: weatherMatch ?? this.weatherMatch,
      eventMatch: eventMatch ?? this.eventMatch,
      tryOnImageUrl: tryOnImageUrl ?? this.tryOnImageUrl,
      outfitItemIds: outfitItemIds ?? this.outfitItemIds,
      confidence: confidence ?? this.confidence,
      recommendedFor: recommendedFor ?? this.recommendedFor,
      metadata: metadata ?? this.metadata,
    );
  }
}

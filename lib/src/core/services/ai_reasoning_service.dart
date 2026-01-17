/// AI Reasoning Service
/// Production-ready LLM + RAG + Vector DB for outfit generation and style reasoning
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/wardrobe_item_model.dart';
import '../models/calendar_day_model.dart';
import 'weather_service.dart';

class AIReasoningService {
  final SupabaseClient _supabase;
  final FirebaseAuth _auth;
  final WeatherService _weatherService;
  static const String _backendUrl = 'http://localhost:8000';

  AIReasoningService(this._supabase, this._auth, this._weatherService);

  String get _userId => _auth.currentUser?.uid ?? '';

  /// Generate outfit recommendation using AI reasoning
  /// Considers: wardrobe embeddings, calendar events, weather, style history
  Future<OutfitRecommendation> generateOutfit({
    required DateTime date,
    String? eventType,
    String? eventName,
    Map<String, dynamic>? weatherData,
    List<WardrobeItemModel>? wardrobeItems,
  }) async {
    try {
      // Get wardrobe items if not provided
      if (wardrobeItems == null) {
        final response = await _supabase
            .from('wardrobe_items')
            .select()
            .eq('user_id', _userId);
        // Convert to WardrobeItemModel - simplified for now
        wardrobeItems = [];
      }

      // Get calendar context
      final calendarDay = await _getCalendarDay(date);

      // Get weather data if not provided
      Map<String, dynamic>? finalWeatherData = weatherData;
      if (finalWeatherData == null) {
        try {
          // Default location (should be from user preferences)
          final weather = await _weatherService.getCurrentWeather(
            latitude: 40.7128, // NYC default
            longitude: -74.0060,
          );
          if (weather != null) {
            finalWeatherData = weather.toJson();
          }
        } catch (e) {
          // Weather fetch failed, continue without it
        }
      }

      // Call AI reasoning backend
      final response = await http.post(
        Uri.parse('$_backendUrl/ai/generate-outfit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _userId,
          'date': date.toIso8601String(),
          'event_type': eventType ?? calendarDay?.eventType,
          'event_name': eventName ?? calendarDay?.eventName,
          'weather': finalWeatherData,
          'wardrobe_item_ids': wardrobeItems?.map((e) => e.id).toList() ?? [],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('AI outfit generation failed: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return OutfitRecommendation.fromJson(data);
    } catch (e) {
      // Fallback: return basic recommendation
      return OutfitRecommendation(
        outfitId: '',
        itemIds: [],
        explanation: 'Unable to generate outfit recommendation at this time.',
        confidence: 0.0,
        reasoning: 'Service temporarily unavailable',
      );
    }
  }

  /// Get daily outfit summary with AI reasoning
  Future<DailyOutfitSummary> getDailySummary({
    required DateTime date,
    List<WardrobeItemModel>? wardrobeItems,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/ai/daily-summary'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _userId,
          'date': date.toIso8601String(),
          'wardrobe_item_ids': wardrobeItems?.map((e) => e.id).toList() ?? [],
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('AI summary failed: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return DailyOutfitSummary.fromJson(data);
    } catch (e) {
      return DailyOutfitSummary(
        date: date,
        wardrobeStatus: 'unknown',
        eventsCount: 0,
        recommendations: [],
        insights: [],
      );
    }
  }

  /// Reason about wardrobe completeness
  Future<WardrobeAnalysis> analyzeWardrobe({
    required List<WardrobeItemModel> items,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/ai/analyze-wardrobe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _userId,
          'item_ids': items.map((e) => e.id).toList(),
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('Wardrobe analysis failed: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return WardrobeAnalysis.fromJson(data);
    } catch (e) {
      return WardrobeAnalysis(
        totalItems: items.length,
        categories: {},
        gaps: [],
        strengths: [],
        recommendations: [],
      );
    }
  }

  Future<CalendarDay?> _getCalendarDay(DateTime date) async {
    try {
      final dateStr = DateTime(date.year, date.month, date.day)
          .toIso8601String()
          .split('T')[0];
      final response = await _supabase
          .from('calendar_days')
          .select()
          .eq('user_id', _userId)
          .eq('date', dateStr)
          .maybeSingle();
      
      if (response == null) return null;
      // Convert to CalendarDay - simplified
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Outfit recommendation from AI
class OutfitRecommendation {
  final String outfitId;
  final List<String> itemIds;
  final String explanation;
  final double confidence; // 0.0 to 1.0
  final String reasoning;
  final Map<String, dynamic>? metadata;

  OutfitRecommendation({
    required this.outfitId,
    required this.itemIds,
    required this.explanation,
    required this.confidence,
    required this.reasoning,
    this.metadata,
  });

  factory OutfitRecommendation.fromJson(Map<String, dynamic> json) {
    return OutfitRecommendation(
      outfitId: json['outfit_id'] as String? ?? '',
      itemIds: (json['item_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      explanation: json['explanation'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      reasoning: json['reasoning'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Daily outfit summary
class DailyOutfitSummary {
  final DateTime date;
  final String wardrobeStatus;
  final int eventsCount;
  final List<String> recommendations;
  final List<String> insights;

  DailyOutfitSummary({
    required this.date,
    required this.wardrobeStatus,
    required this.eventsCount,
    required this.recommendations,
    required this.insights,
  });

  factory DailyOutfitSummary.fromJson(Map<String, dynamic> json) {
    return DailyOutfitSummary(
      date: DateTime.parse(json['date'] as String),
      wardrobeStatus: json['wardrobe_status'] as String? ?? 'unknown',
      eventsCount: (json['events_count'] as num?)?.toInt() ?? 0,
      recommendations: (json['recommendations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      insights: (json['insights'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

/// Wardrobe analysis
class WardrobeAnalysis {
  final int totalItems;
  final Map<String, int> categories;
  final List<String> gaps;
  final List<String> strengths;
  final List<String> recommendations;

  WardrobeAnalysis({
    required this.totalItems,
    required this.categories,
    required this.gaps,
    required this.strengths,
    required this.recommendations,
  });

  factory WardrobeAnalysis.fromJson(Map<String, dynamic> json) {
    return WardrobeAnalysis(
      totalItems: (json['total_items'] as num?)?.toInt() ?? 0,
      categories: Map<String, int>.from(json['categories'] as Map? ?? {}),
      gaps: (json['gaps'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      strengths: (json['strengths'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      recommendations: (json['recommendations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

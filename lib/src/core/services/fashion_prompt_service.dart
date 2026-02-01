import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fashion Prompt Intent Classification
enum FashionIntent {
  occasion, // "What should I wear for a wedding?"
  style, // "Show me modern streetwear"
  mood, // "I want something casual"
  wardrobeOnly, // "Use only my wardrobe"
  tryOn, // "Try this outfit on me"
  general, // General fashion advice
}

/// Fashion Prompt Handler Service
/// Classifies user prompts and routes to appropriate handlers
class FashionPromptService {
  final SupabaseClient _supabase;
  final FirebaseAuth _auth;
  static const String _apiBaseUrl = 'http://localhost:8001';

  FashionPromptService(this._supabase, this._auth);

  String get _userId => _auth.currentUser?.uid ?? '';

  /// Classify user prompt intent
  Future<FashionIntent> classifyIntent(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/fashion/classify-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt.toLowerCase()}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final intentStr = data['intent'] as String;
        return FashionIntent.values.firstWhere(
          (e) => e.name == intentStr,
          orElse: () => FashionIntent.general,
        );
      }
    } catch (e) {
      // Fallback to local classification
    }

    // Local fallback classification
    final lowerPrompt = prompt.toLowerCase();
    if (lowerPrompt.contains('try on') || lowerPrompt.contains('try this')) {
      return FashionIntent.tryOn;
    }
    if (lowerPrompt.contains('wardrobe') ||
        lowerPrompt.contains('my clothes')) {
      return FashionIntent.wardrobeOnly;
    }
    if (lowerPrompt.contains('wedding') ||
        lowerPrompt.contains('party') ||
        lowerPrompt.contains('work') ||
        lowerPrompt.contains('event') ||
        lowerPrompt.contains('occasion')) {
      return FashionIntent.occasion;
    }
    if (lowerPrompt.contains('streetwear') ||
        lowerPrompt.contains('vintage') ||
        lowerPrompt.contains('modern') ||
        lowerPrompt.contains('style')) {
      return FashionIntent.style;
    }
    if (lowerPrompt.contains('casual') ||
        lowerPrompt.contains('formal') ||
        lowerPrompt.contains('mood')) {
      return FashionIntent.mood;
    }
    return FashionIntent.general;
  }

  /// Extract occasion from prompt
  String? extractOccasion(String prompt) {
    final lower = prompt.toLowerCase();
    final occasions = [
      'wedding',
      'party',
      'work',
      'office',
      'date',
      'dinner',
      'casual',
      'formal',
      'beach',
      'gym',
      'sport',
      'event',
      'meeting',
      'interview',
      'graduation',
      'birthday'
    ];
    for (var occasion in occasions) {
      if (lower.contains(occasion)) return occasion;
    }
    return null;
  }

  /// Extract style keywords
  List<String> extractStyleKeywords(String prompt) {
    final lower = prompt.toLowerCase();
    final styles = [
      'streetwear',
      'vintage',
      'modern',
      'classic',
      'bohemian',
      'minimalist',
      'edgy',
      'elegant',
      'sporty',
      'casual',
      'formal',
      'business',
      'chic',
      'trendy'
    ];
    return styles.where((s) => lower.contains(s)).toList();
  }

  /// Get user preferences from Supabase
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final response = await _supabase
          .from('user_preferences')
          .select()
          .eq('user_id', _userId)
          .maybeSingle();

      return response ?? {};
    } catch (e) {
      return {};
    }
  }

  /// Get user wardrobe items
  Future<List<Map<String, dynamic>>> getUserWardrobe() async {
    try {
      final response = await _supabase
          .from('wardrobe_items')
          .select()
          .eq('user_id', _userId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Generate outfit recommendations based on prompt
  Future<Map<String, dynamic>> generateOutfitRecommendations({
    required String prompt,
    required FashionIntent intent,
    String? occasion,
    List<String>? styleKeywords,
    bool wardrobeOnly = false,
  }) async {
    try {
      final preferences = await getUserPreferences();
      final wardrobe = wardrobeOnly ? await getUserWardrobe() : null;

      final requestBody = {
        'prompt': prompt,
        'intent': intent.name,
        'occasion': occasion,
        'style_keywords': styleKeywords,
        'preferences': preferences,
        'wardrobe_items': wardrobe,
        'wardrobe_only': wardrobeOnly,
      };

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/fashion/generate-outfits'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to generate outfits');
    } catch (e) {
      // Fallback: return mock data structure
      return {
        'outfits': [],
        'message': 'Outfit generation temporarily unavailable',
      };
    }
  }

  /// Request try-on for outfit
  Future<String> requestTryOn({
    required String outfitImageUrl,
    String? userPhotoUrl,
  }) async {
    try {
      final requestBody = {
        'user_id': _userId,
        'outfit_image_url': outfitImageUrl,
        'user_photo_url': userPhotoUrl,
      };

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/vton/process'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result_url'] as String;
      }
      throw Exception('Try-on failed');
    } catch (e) {
      throw Exception('Try-on service unavailable: $e');
    }
  }

  /// Save outfit like/dislike
  Future<void> saveOutfitFeedback({
    required String outfitId,
    required bool liked,
    String? reason,
  }) async {
    try {
      await _supabase.from('outfit_feedback').insert({
        'user_id': _userId,
        'outfit_id': outfitId,
        'liked': liked,
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail - feedback is not critical
    }
  }
}

/// Provider for FashionPromptService
final fashionPromptServiceProvider = Provider<FashionPromptService>((ref) {
  final supabase = Supabase.instance.client;
  final auth = FirebaseAuth.instance;
  return FashionPromptService(supabase, auth);
});

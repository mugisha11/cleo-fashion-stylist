import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/questionnaire_service.dart';

/// Settings Service - Manages user settings in Supabase
class SettingsService {
  final SupabaseClient _supabase;
  final FirebaseAuth _auth;
  final QuestionnaireService _questionnaireService;

  SettingsService(this._supabase, this._auth, this._questionnaireService);

  String get _userId => _auth.currentUser?.uid ?? '';

  /// Get all user settings
  Future<Map<String, dynamic>> getSettings() async {
    try {
      if (_userId.isEmpty) throw Exception('User not authenticated');

      // Get user preferences
      final prefs = await _questionnaireService.getUserPreferences();
      
      // Get app settings (stored separately or in preferences)
      final settings = prefs['app_settings'] as Map<String, dynamic>? ?? {};
      
      return {
        'autoRecommendations': settings['autoRecommendations'] ?? true,
        'highQualityRendering': settings['highQualityRendering'] ?? true,
        'backgroundPreservation': settings['backgroundPreservation'] ?? true,
        'pushNotifications': settings['pushNotifications'] ?? true,
        'outfitReminders': settings['outfitReminders'] ?? true,
        'recommendationAlerts': settings['recommendationAlerts'] ?? true,
        'height': prefs['height'],
        'bodyType': prefs['bodyType'],
        'preferredStyles': prefs['preferredStyles'] ?? [],
        'colorPreferences': prefs['colorPreferences'] ?? [],
        'eventPreferences': prefs['eventPreferences'] ?? [],
      };
    } catch (e) {
      throw Exception('Failed to load settings: $e');
    }
  }

  /// Update app settings
  Future<void> updateAppSettings({
    bool? autoRecommendations,
    bool? highQualityRendering,
    bool? backgroundPreservation,
    bool? pushNotifications,
    bool? outfitReminders,
    bool? recommendationAlerts,
  }) async {
    try {
      if (_userId.isEmpty) throw Exception('User not authenticated');

      final prefs = await _questionnaireService.getUserPreferences();
      final currentSettings = prefs['app_settings'] as Map<String, dynamic>? ?? {};
      
      final updatedSettings = {
        ...currentSettings,
        if (autoRecommendations != null) 'autoRecommendations': autoRecommendations,
        if (highQualityRendering != null) 'highQualityRendering': highQualityRendering,
        if (backgroundPreservation != null) 'backgroundPreservation': backgroundPreservation,
        if (pushNotifications != null) 'pushNotifications': pushNotifications,
        if (outfitReminders != null) 'outfitReminders': outfitReminders,
        if (recommendationAlerts != null) 'recommendationAlerts': recommendationAlerts,
      };

      final updatedPrefs = {
        ...prefs,
        'app_settings': updatedSettings,
      };

      await _supabase.from('user_preferences').upsert({
        'user_id': _userId,
        'preferences': updatedPrefs,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      throw Exception('Failed to update settings: $e');
    }
  }

  /// Update fashion preferences
  Future<void> updateFashionPreferences({
    double? height,
    String? bodyType,
    List<String>? preferredStyles,
    List<String>? colorPreferences,
    List<String>? eventPreferences,
  }) async {
    try {
      if (_userId.isEmpty) throw Exception('User not authenticated');

      final prefs = await _questionnaireService.getUserPreferences();
      
      final updatedPrefs = {
        ...prefs,
        if (height != null) 'height': height,
        if (bodyType != null) 'bodyType': bodyType,
        if (preferredStyles != null) 'preferredStyles': preferredStyles,
        if (colorPreferences != null) 'colorPreferences': colorPreferences,
        if (eventPreferences != null) 'eventPreferences': eventPreferences,
      };

      await _supabase.from('user_preferences').upsert({
        'user_id': _userId,
        'preferences': updatedPrefs,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      throw Exception('Failed to update preferences: $e');
    }
  }
}


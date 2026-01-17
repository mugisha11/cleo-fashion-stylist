import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/settings_state.dart';
import '../services/settings_service.dart';
import '../../../core/services/questionnaire_service.dart';

/// Settings Service Provider
final settingsServiceProvider = Provider<SettingsService>((ref) {
  final supabase = Supabase.instance.client;
  final auth = FirebaseAuth.instance;
  final questionnaireService = ref.watch(questionnaireServiceProvider);
  return SettingsService(supabase, auth, questionnaireService);
});

/// Settings State Notifier
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    final service = ref.watch(settingsServiceProvider);
    return SettingsNotifier(service);
  },
);

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsService _service;

  SettingsNotifier(this._service) : super(const SettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final settings = await _service.getSettings();
      state = state.copyWith(
        isLoading: false,
        autoRecommendations: settings['autoRecommendations'] as bool? ?? true,
        highQualityRendering: settings['highQualityRendering'] as bool? ?? true,
        backgroundPreservation: settings['backgroundPreservation'] as bool? ?? true,
        pushNotifications: settings['pushNotifications'] as bool? ?? true,
        outfitReminders: settings['outfitReminders'] as bool? ?? true,
        recommendationAlerts: settings['recommendationAlerts'] as bool? ?? true,
        height: settings['height'] as double?,
        bodyType: settings['bodyType'] as String?,
        preferredStyles: (settings['preferredStyles'] as List?)?.cast<String>() ?? [],
        colorPreferences: (settings['colorPreferences'] as List?)?.cast<String>() ?? [],
        eventPreferences: (settings['eventPreferences'] as List?)?.cast<String>() ?? [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateAutoRecommendations(bool value) async {
    state = state.copyWith(autoRecommendations: value);
    try {
      await _service.updateAppSettings(autoRecommendations: value);
    } catch (e) {
      state = state.copyWith(autoRecommendations: !value, error: e.toString());
    }
  }

  Future<void> updateHighQualityRendering(bool value) async {
    state = state.copyWith(highQualityRendering: value);
    try {
      await _service.updateAppSettings(highQualityRendering: value);
    } catch (e) {
      state = state.copyWith(highQualityRendering: !value, error: e.toString());
    }
  }

  Future<void> updateBackgroundPreservation(bool value) async {
    state = state.copyWith(backgroundPreservation: value);
    try {
      await _service.updateAppSettings(backgroundPreservation: value);
    } catch (e) {
      state = state.copyWith(backgroundPreservation: !value, error: e.toString());
    }
  }

  Future<void> updatePushNotifications(bool value) async {
    state = state.copyWith(pushNotifications: value);
    try {
      await _service.updateAppSettings(pushNotifications: value);
    } catch (e) {
      state = state.copyWith(pushNotifications: !value, error: e.toString());
    }
  }

  Future<void> updateOutfitReminders(bool value) async {
    state = state.copyWith(outfitReminders: value);
    try {
      await _service.updateAppSettings(outfitReminders: value);
    } catch (e) {
      state = state.copyWith(outfitReminders: !value, error: e.toString());
    }
  }

  Future<void> updateRecommendationAlerts(bool value) async {
    state = state.copyWith(recommendationAlerts: value);
    try {
      await _service.updateAppSettings(recommendationAlerts: value);
    } catch (e) {
      state = state.copyWith(recommendationAlerts: !value, error: e.toString());
    }
  }

  Future<void> updateFashionPreferences({
    double? height,
    String? bodyType,
    List<String>? preferredStyles,
    List<String>? colorPreferences,
    List<String>? eventPreferences,
  }) async {
    state = state.copyWith(
      height: height ?? state.height,
      bodyType: bodyType ?? state.bodyType,
      preferredStyles: preferredStyles ?? state.preferredStyles,
      colorPreferences: colorPreferences ?? state.colorPreferences,
      eventPreferences: eventPreferences ?? state.eventPreferences,
    );
    try {
      await _service.updateFashionPreferences(
        height: height,
        bodyType: bodyType,
        preferredStyles: preferredStyles,
        colorPreferences: colorPreferences,
        eventPreferences: eventPreferences,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}


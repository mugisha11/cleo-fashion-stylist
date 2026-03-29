import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/language_service.dart';
import '../localization/translation_service.dart';

/// Language provider - tracks current language code
final currentLanguageProvider =
    StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

/// Language notifier for state management with auto-detection and persistence
class LanguageNotifier extends StateNotifier<String> {
  static const String _languageKey = 'app_language';
  bool _initialized = false;

  LanguageNotifier() : super(LanguageService.defaultLanguage) {
    _initializeLanguage();
  }

  /// Initialize language from SharedPreferences with auto-detection fallback
  Future<void> _initializeLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);

      if (savedLanguage != null &&
          LanguageService.isValidLanguage(savedLanguage)) {
        // Use saved language if available and valid
        state = savedLanguage;
        debugPrint('✅ Language initialized from storage: $savedLanguage');
      } else {
        // Auto-detect device language on first launch
        final detectedLocale = LanguageService.detectDeviceLanguage();
        state = detectedLocale.languageCode;
        await prefs.setString(_languageKey, state);
        debugPrint('✅ Language auto-detected and saved: $state');
      }

      // Load translations
      await TranslationService().loadTranslations(state);
      _initialized = true;
    } catch (e) {
      debugPrint('⚠️ Error initializing language: $e');
      state = LanguageService.defaultLanguage;
      _initialized = true;
    }
  }

  /// Change application language
  Future<void> setLanguage(String languageCode) async {
    if (!LanguageService.isValidLanguage(languageCode)) {
      debugPrint('❌ Invalid language code: $languageCode');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      state = languageCode;

      // Load translations for new language
      await TranslationService().loadTranslations(languageCode);
      debugPrint('✅ Language changed to: $languageCode');
    } catch (e) {
      debugPrint('❌ Error changing language: $e');
    }
  }

  /// Get current language display name
  String getCurrentLanguageName() {
    return LanguageService.getLanguageName(state);
  }

  /// Get current language flag
  String getCurrentLanguageFlag() {
    return LanguageService.getLanguageFlag(state);
  }

  /// Check if RTL
  bool isRTL() {
    return LanguageService.isRTL(state);
  }

  /// Check if initialized
  bool get isInitialized => _initialized;

  /// Get supported languages
  static const List<String> supportedLanguageCodes = ['en', 'fr', 'de', 'ar'];
}

/// Provider to get current locale
final currentLocaleProvider = Provider<Locale>((ref) {
  final languageCode = ref.watch(currentLanguageProvider);
  return Locale(languageCode);
});

/// Provider for getting translations directly
final translationProvider = Provider<String>((ref) {
  ref.watch(currentLanguageProvider); // Rebuild when language changes
  return TranslationService().get('common.appName');
});

/// Extension for easy translation access in widgets
extension TranslationAccess on BuildContext {
  /// Get translation by key
  String tr(String key, {Map<String, String>? params}) {
    return TranslationService().get(key, params: params);
  }

  /// Change language
  Future<void> setLanguage(String languageCode) async {
    final container = ProviderScope.containerOf(this);
    await container
        .read(currentLanguageProvider.notifier)
        .setLanguage(languageCode);
  }

  /// Get current language code
  String getCurrentLanguageCode() {
    final container = ProviderScope.containerOf(this);
    return container.read(currentLanguageProvider);
  }

  /// Get current language name
  String getCurrentLanguageName() {
    final container = ProviderScope.containerOf(this);
    return container
        .read(currentLanguageProvider.notifier)
        .getCurrentLanguageName();
  }

  /// Get RTL direction
  bool isRTL() {
    final container = ProviderScope.containerOf(this);
    return container.read(currentLanguageProvider.notifier).isRTL();
  }
}

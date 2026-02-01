import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Language service for managing locale detection and language operations
class LanguageService {
  static const String defaultLanguage = 'en';
  static const List<String> supportedLanguages = ['en', 'fr', 'de', 'ar'];

  /// Detect device language from system settings
  static Locale detectDeviceLanguage() {
    try {
      final deviceLocale = ui.PlatformDispatcher.instance.locale;
      final languageCode = deviceLocale.languageCode;

      // Check if device language is supported
      if (supportedLanguages.contains(languageCode)) {
        debugPrint(
            '✅ Device language detected: $languageCode (${deviceLocale.countryCode})');
        return Locale(languageCode);
      }

      // Fallback to English if device language not supported
      debugPrint(
          '⚠️ Device language "$languageCode" not supported, using English');
      return const Locale(defaultLanguage);
    } catch (e) {
      debugPrint('❌ Error detecting device language: $e');
      return const Locale(defaultLanguage);
    }
  }

  /// Get language display name
  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      case 'ar':
        return 'العربية';
      default:
        return 'English';
    }
  }

  /// Get language flag emoji
  static String getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇺🇸';
      case 'fr':
        return '🇫🇷';
      case 'de':
        return '🇩🇪';
      case 'ar':
        return '🇸🇦';
      default:
        return '🌐';
    }
  }

  /// Check if language is RTL
  static bool isRTL(String languageCode) {
    return languageCode == 'ar';
  }

  /// Get text direction for language
  static TextDirection getTextDirection(String languageCode) {
    return isRTL(languageCode) ? TextDirection.rtl : TextDirection.ltr;
  }

  /// Validate language code
  static bool isValidLanguage(String languageCode) {
    return supportedLanguages.contains(languageCode);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/language_provider.dart';
import 'language_service.dart';

/// Extension for easy access to localized strings
extension LocalizationExtension on BuildContext {
  /// Get AppLocalizations from context
  /// This assumes the generated AppLocalizations class exists
  String getText(String Function(AppLocalizations) selector) {
    try {
      final l10n = AppLocalizations.of(this);
      if (l10n != null) {
        return selector(l10n);
      }
    } catch (e) {
      debugPrint('⚠️ Error getting localization: $e');
    }
    return '';
  }

  /// Change app language
  Future<void> changeLanguage(String languageCode) async {
    final container = ProviderScope.containerOf(this);
    await container.read(currentLanguageProvider.notifier).setLanguage(languageCode);
  }

  /// Get current language code
  String getLanguageCode() {
    final container = ProviderScope.containerOf(this);
    return container.read(currentLanguageProvider);
  }

  /// Get language name
  String getLanguageName(String languageCode) {
    return LanguageService.getLanguageName(languageCode);
  }

  /// Get language flag
  String getLanguageFlag(String languageCode) {
    return LanguageService.getLanguageFlag(languageCode);
  }
}
// Note: The generated AppLocalizations from l10n/app_localizations.dart
// already provides the localization delegate and implementation.
// This helper just provides convenient extensions for accessing it.

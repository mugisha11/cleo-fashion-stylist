import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();

  late Map<String, dynamic> _translations;

  TranslationService._internal();

  factory TranslationService() {
    return _instance;
  }

  /// Load translations for a specific language.
  /// Falls back to en.json if the requested locale is missing; if that fails, uses empty map so app still runs.
  Future<void> loadTranslations(String languageCode) async {
    try {
      final jsonString = await rootBundle.loadString(
        'lib/src/core/localization/translations/$languageCode.json',
      );
      _translations = jsonDecode(jsonString) as Map<String, dynamic>;
      debugPrint('✅ Translations loaded for: $languageCode');
    } catch (e) {
      debugPrint('❌ Error loading translations: $e');
      try {
        final jsonString = await rootBundle.loadString(
          'lib/src/core/localization/translations/en.json',
        );
        _translations = jsonDecode(jsonString) as Map<String, dynamic>;
        debugPrint('⚠️ Fell back to English translations');
      } catch (fallbackError) {
        debugPrint('⚠️ Fallback en.json failed: $fallbackError. Using empty translations.');
        _translations = <String, dynamic>{};
      }
    }
  }

  /// Get a translation by key with optional parameter substitution
  String get(String key, {Map<String, String>? params}) {
    try {
      final keys = key.split('.');
      dynamic value = _translations;

      for (final k in keys) {
        value = value[k];
        if (value == null) {
          debugPrint('⚠️ Missing translation key: $key');
          return key; // Return key if not found
        }
      }

      String result = value.toString();

      // Replace parameters
      if (params != null) {
        params.forEach((paramKey, paramValue) {
          result = result.replaceAll('{{$paramKey}}', paramValue);
        });
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error getting translation for $key: $e');
      return key;
    }
  }

  /// Get all keys for missing translation detection (QA)
  List<String> getAllKeys() {
    final keys = <String>[];
    void extractKeys(Map<String, dynamic> map, String prefix) {
      map.forEach((key, value) {
        final fullKey = prefix.isEmpty ? key : '$prefix.$key';
        if (value is Map<String, dynamic>) {
          extractKeys(value, fullKey);
        } else {
          keys.add(fullKey);
        }
      });
    }

    extractKeys(_translations, '');
    return keys;
  }
}

/// Extension for easy access in widgets
extension Localizations on BuildContext {
  String tr(String key, {Map<String, String>? params}) {
    return TranslationService().get(key, params: params);
  }
}

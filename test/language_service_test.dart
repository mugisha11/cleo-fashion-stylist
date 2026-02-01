import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_twin/src/core/localization/language_service.dart';
import 'package:flutter/material.dart';

void main() {
  group('LanguageService Tests', () {
    test('detectDeviceLanguage returns Locale', () {
      final locale = LanguageService.detectDeviceLanguage();
      expect(locale, isA<Locale>());
    });

    test('getLanguageName returns correct names', () {
      expect(LanguageService.getLanguageName('en'), equals('English'));
      expect(LanguageService.getLanguageName('fr'), equals('Français'));
      expect(LanguageService.getLanguageName('de'), equals('Deutsch'));
      expect(LanguageService.getLanguageName('ar'), equals('العربية'));
    });

    test('getLanguageFlag returns correct flags', () {
      expect(LanguageService.getLanguageFlag('en'), equals('🇺🇸'));
      expect(LanguageService.getLanguageFlag('fr'), equals('🇫🇷'));
      expect(LanguageService.getLanguageFlag('de'), equals('🇩🇪'));
      expect(LanguageService.getLanguageFlag('ar'), equals('🇸🇦'));
    });

    test('isRTL correctly identifies RTL languages', () {
      expect(LanguageService.isRTL('ar'), isTrue);
      expect(LanguageService.isRTL('en'), isFalse);
      expect(LanguageService.isRTL('fr'), isFalse);
    });

    test('getTextDirection returns correct direction', () {
      expect(
        LanguageService.getTextDirection('ar'),
        equals(TextDirection.rtl),
      );
      expect(
        LanguageService.getTextDirection('en'),
        equals(TextDirection.ltr),
      );
    });

    test('isValidLanguage validates language codes', () {
      expect(LanguageService.isValidLanguage('en'), isTrue);
      expect(LanguageService.isValidLanguage('fr'), isTrue);
      expect(LanguageService.isValidLanguage('invalid'), isFalse);
    });

    test('supportedLanguages contains all supported languages', () {
      expect(LanguageService.supportedLanguages, contains('en'));
      expect(LanguageService.supportedLanguages, contains('fr'));
      expect(LanguageService.supportedLanguages, contains('de'));
      expect(LanguageService.supportedLanguages, contains('ar'));
    });
  });
}

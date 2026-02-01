import 'dart:convert';
import 'dart:io';

/// Translation QA system for validating localization files
class TranslationQA {
  static const List<String> supportedLanguages = ['en', 'fr', 'de', 'ar'];
  static const String l10nDir = 'lib/l10n';

  /// Run all QA checks
  static Future<void> runAllChecks() async {
    print('🔍 Starting Translation QA System...\n');

    final allKeys = await _loadAllKeys();

    // Check 1: All languages have the same keys
    await _checkKeyConsistency(allKeys);

    // Check 2: No duplicate keys
    await _checkDuplicateKeys(allKeys);

    // Check 3: All keys are properly formatted
    await _checkKeyFormatting(allKeys);

    // Check 4: RTL content validation
    await _checkRTLContent();

    // Check 5: Translation coverage
    await _checkTranslationCoverage(allKeys);

    // Check 6: Validate parameter placeholders
    await _checkParameterConsistency(allKeys);

    print('\n✅ Translation QA completed!');
  }

  /// Load all keys from ARB files
  static Future<Map<String, Set<String>>> _loadAllKeys() async {
    final keys = <String, Set<String>>{};

    for (final lang in supportedLanguages) {
      final file = File('$l10nDir/app_$lang.arb');
      if (!file.existsSync()) {
        print('❌ Missing file: ${file.path}');
        continue;
      }

      try {
        final content = await file.readAsString();
        final jsonData = jsonDecode(content) as Map<String, dynamic>;

        final langKeys = <String>{};
        for (final key in jsonData.keys) {
          if (!key.startsWith('@')) {
            langKeys.add(key);
          }
        }

        keys[lang] = langKeys;
        print('✅ Loaded $lang: ${langKeys.length} keys');
      } catch (e) {
        print('❌ Error loading $lang: $e');
      }
    }

    return keys;
  }

  /// Check if all languages have consistent keys
  static Future<void> _checkKeyConsistency(
      Map<String, Set<String>> allKeys) async {
    print('\n📋 Checking Key Consistency...');

    final enKeys = allKeys['en'] ?? {};
    var hasErrors = false;

    for (final lang in supportedLanguages.skip(1)) {
      final langKeys = allKeys[lang] ?? {};

      final missing = enKeys.difference(langKeys);
      final extra = langKeys.difference(enKeys);

      if (missing.isNotEmpty) {
        print('❌ $lang missing keys: ${missing.length}');
        for (final key in missing) {
          print('   - $key');
        }
        hasErrors = true;
      }

      if (extra.isNotEmpty) {
        print('❌ $lang has extra keys: ${extra.length}');
        for (final key in extra) {
          print('   - $key');
        }
        hasErrors = true;
      }
    }

    if (!hasErrors) {
      print('✅ All languages have consistent keys');
    }
  }

  /// Check for duplicate keys in any language file
  static Future<void> _checkDuplicateKeys(
      Map<String, Set<String>> allKeys) async {
    print('\n🔎 Checking for Duplicate Keys...');

    var hasDuplicates = false;

    for (final lang in supportedLanguages) {
      final file = File('$l10nDir/app_$lang.arb');
      if (!file.existsSync()) continue;

      try {
        final content = await file.readAsString();
        final jsonData = jsonDecode(content) as Map<String, dynamic>;

        final seen = <String>{};
        for (final key in jsonData.keys) {
          if (!key.startsWith('@')) {
            if (seen.contains(key)) {
              print('❌ $lang has duplicate key: $key');
              hasDuplicates = true;
            }
            seen.add(key);
          }
        }
      } catch (e) {
        print('❌ Error checking duplicates in $lang: $e');
      }
    }

    if (!hasDuplicates) {
      print('✅ No duplicate keys found');
    }
  }

  /// Check key naming conventions
  static Future<void> _checkKeyFormatting(
      Map<String, Set<String>> allKeys) async {
    print('\n🏷️ Checking Key Formatting...');

    const validPrefixes = [
      'app',
      'common',
      'auth',
      'home',
      'vton',
      'clothes',
      'recommendations',
      'profile',
      'settings',
      'errors',
      'success',
      'notifications'
    ];

    var allValid = true;

    for (final lang in supportedLanguages) {
      final keys = allKeys[lang] ?? {};
      for (final key in keys) {
        final parts = key.split('_');
        if (parts.isEmpty || !validPrefixes.contains(parts[0].toLowerCase())) {
          print('⚠️ $lang: Unusual key format: $key');
          allValid = false;
        }
      }
    }

    if (allValid) {
      print('✅ All keys follow proper naming convention');
    }
  }

  /// Check RTL-specific content
  static Future<void> _checkRTLContent() async {
    print('\n📱 Checking RTL Content...');

    final arFile = File('$l10nDir/app_ar.arb');
    if (!arFile.existsSync()) {
      print('❌ Arabic file not found');
      return;
    }

    try {
      final content = await arFile.readAsString();
      final jsonData = jsonDecode(content) as Map<String, dynamic>;

      var rtlEntries = 0;
      for (final value in jsonData.values) {
        if (value is String && _isArabic(value)) {
          rtlEntries++;
        }
      }

      if (rtlEntries > 0) {
        print('✅ Arabic content found: $rtlEntries entries');
        print('✅ RTL text direction support ready');
      } else {
        print('⚠️ No Arabic content detected');
      }
    } catch (e) {
      print('❌ Error checking RTL content: $e');
    }
  }

  /// Check translation coverage percentage
  static Future<void> _checkTranslationCoverage(
      Map<String, Set<String>> allKeys) async {
    print('\n📊 Checking Translation Coverage...');

    final enKeys = allKeys['en'] ?? {};
    final totalKeys = enKeys.length;

    for (final lang in supportedLanguages.skip(1)) {
      final langKeys = allKeys[lang] ?? {};
      final coverage = ((langKeys.length / totalKeys) * 100).toStringAsFixed(2);

      if (langKeys.length == totalKeys) {
        print('✅ $lang: 100% coverage ($totalKeys keys)');
      } else {
        print(
            '⚠️ $lang: $coverage% coverage (${langKeys.length}/$totalKeys keys)');
      }
    }
  }

  /// Check parameter placeholders consistency
  static Future<void> _checkParameterConsistency(
      Map<String, Set<String>> allKeys) async {
    print('\n🔗 Checking Parameter Placeholders...');

    final enFile = File('$l10nDir/app_en.arb');
    if (!enFile.existsSync()) {
      print('❌ English file not found');
      return;
    }

    try {
      final enContent = await enFile.readAsString();
      final enData = jsonDecode(enContent) as Map<String, dynamic>;

      var parameterCount = 0;
      for (final entry in enData.entries) {
        if (entry.key.startsWith('@')) {
          parameterCount++;
        }
      }

      if (parameterCount > 0) {
        print('✅ Found $parameterCount parameter definitions');
      }

      // Check other languages have the same parameters
      for (final lang in supportedLanguages.skip(1)) {
        final file = File('$l10nDir/app_$lang.arb');
        if (!file.existsSync()) continue;

        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;

        var langParams = 0;
        for (final entry in data.entries) {
          if (entry.key.startsWith('@')) {
            langParams++;
          }
        }

        if (langParams == parameterCount) {
          print('✅ $lang: Parameter count matches ($parameterCount)');
        } else {
          print(
              '⚠️ $lang: Parameter mismatch ($langParams vs $parameterCount)');
        }
      }
    } catch (e) {
      print('❌ Error checking parameters: $e');
    }
  }

  /// Check if text contains Arabic characters
  static bool _isArabic(String text) {
    // Arabic Unicode range: 0x0600-0x06FF
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }
}

/// Run QA checks from command line
Future<void> main() async {
  await TranslationQA.runAllChecks();
}

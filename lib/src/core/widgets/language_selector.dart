import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';
import '../localization/language_service.dart';

/// Language selector widget
class LanguageSelector extends ConsumerWidget {
  final bool isCompact;
  final VoidCallback? onLanguageChanged;

  const LanguageSelector({
    super.key,
    this.isCompact = false,
    this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(currentLanguageProvider);
    const languages = LanguageNotifier.supportedLanguageCodes;

    if (isCompact) {
      return _buildCompactSelector(context, ref, currentLanguage, languages);
    } else {
      return _buildFullSelector(context, ref, currentLanguage, languages);
    }
  }

  Widget _buildCompactSelector(
    BuildContext context,
    WidgetRef ref,
    String currentLanguage,
    List<String> languages,
  ) {
    return PopupMenuButton<String>(
      initialValue: currentLanguage,
      onSelected: (String languageCode) async {
        await ref
            .read(currentLanguageProvider.notifier)
            .setLanguage(languageCode);
        onLanguageChanged?.call();
      },
      itemBuilder: (BuildContext context) => languages
          .map((languageCode) => PopupMenuItem<String>(
                value: languageCode,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(LanguageService.getLanguageFlag(languageCode)),
                    const SizedBox(width: 8),
                    Text(LanguageService.getLanguageName(languageCode)),
                  ],
                ),
              ))
          .toList(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(LanguageService.getLanguageFlag(currentLanguage),
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 4),
            Text(currentLanguage.toUpperCase()),
          ],
        ),
      ),
    );
  }

  Widget _buildFullSelector(
    BuildContext context,
    WidgetRef ref,
    String currentLanguage,
    List<String> languages,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Select Language',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...languages.map((languageCode) {
          final isSelected = languageCode == currentLanguage;
          final isRTL = LanguageService.isRTL(languageCode);
          return ListTile(
            leading: Text(
              LanguageService.getLanguageFlag(languageCode),
              style: const TextStyle(fontSize: 24),
            ),
            title: Text(
              LanguageService.getLanguageName(languageCode),
              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            ),
            subtitle: Text(
              isRTL ? 'لغة بقراءة من اليمين إلى اليسار' : 'LTR language',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  )
                : null,
            selected: isSelected,
            enabled: !isSelected,
            onTap: isSelected
                ? null
                : () async {
                    await ref
                        .read(currentLanguageProvider.notifier)
                        .setLanguage(languageCode);
                    onLanguageChanged?.call();
                  },
          );
        }),
      ],
    );
  }
}

/// Settings screen for language selection
class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Settings'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LanguageSelector(
            onLanguageChanged: () {
              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Language changed successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

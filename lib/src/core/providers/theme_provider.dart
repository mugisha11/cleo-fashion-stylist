/// Theme Provider
/// Manages theme state and persistence
library;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme_mode.dart';
import '../theme/app_theme_data.dart';
import '../theme/neon_fashion_theme.dart';
import '../theme/dark_ai_theme.dart';

/// Theme Mode Provider
/// Manages the current theme mode with persistence
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeMode>(
  (ref) => ThemeModeNotifier(),
);

/// Theme Data Provider
/// Provides the current theme data based on the selected mode
final themeDataProvider = Provider<AppThemeData>((ref) {
  final mode = ref.watch(themeModeProvider);
  return _getThemeData(mode);
});

/// Helper function to get theme data for a mode
AppThemeData _getThemeData(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.neonFashionAI:
      return NeonFashionTheme.theme;
    case AppThemeMode.darkAI:
      return DarkAITheme.theme;
  }
}

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  static const String _prefsKey = 'app_theme_mode';
  
  ThemeModeNotifier() : super(AppThemeMode.darkAI) {
    _loadTheme();
  }
  
  /// Load theme from persistent storage
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_prefsKey);
      if (themeIndex != null && themeIndex < AppThemeMode.values.length) {
        state = AppThemeMode.values[themeIndex];
      }
    } catch (e) {
      // Use default theme on error
      state = AppThemeMode.darkAI;
    }
  }
  
  /// Set theme and persist it
  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey, mode.index);
    } catch (e) {
      // Theme change still applies, just not persisted
    }
  }
}

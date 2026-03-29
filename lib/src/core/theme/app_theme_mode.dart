/// App Theme Mode Enum
/// Defines available themes in the application
enum AppThemeMode {
  giovanni,      // Light Giovanni style (default)
  neonFashionAI,
  darkAI,
}

extension AppThemeModeExtension on AppThemeMode {
  String get displayName {
    switch (this) {
      case AppThemeMode.giovanni:
        return 'Nikonyx';
      case AppThemeMode.neonFashionAI:
        return 'Neon Fashion AI';
      case AppThemeMode.darkAI:
        return 'Dark AI Mode';
    }
  }

  String get description {
    switch (this) {
      case AppThemeMode.giovanni:
        return 'Light, clean style with coral and purple accents';
      case AppThemeMode.neonFashionAI:
        return 'Electric blue with subtle glow effects';
      case AppThemeMode.darkAI:
        return 'Minimal dark theme for focused conversations';
    }
  }
}

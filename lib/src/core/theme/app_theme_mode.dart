/// App Theme Mode Enum
/// Defines available themes in the application
enum AppThemeMode {
  neonFashionAI, // Default: Electric blue, mode
  darkAI,        // dark, mode
}

extension AppThemeModeExtension on AppThemeMode {
  String get displayName {
    switch (this) {
      case AppThemeMode.neonFashionAI:
        return 'Neon Fashion AI';
      case AppThemeMode.darkAI:
        return 'Dark AI Mode';
    }
  }

  String get description {
    switch (this) {
      case AppThemeMode.neonFashionAI:
        return 'Electric blue with subtle glow effects';
      case AppThemeMode.darkAI:
        return 'Minimal dark theme for focused conversations';
    }
  }
}

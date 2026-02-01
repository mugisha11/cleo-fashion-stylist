import 'package:flutter/material.dart';

/// 🎨 DESIGN TOKENS - Centralized design system
/// Inspired by: Apple Design System, Zara, Nike, ChatGPT
class DesignTokens {
  // Colors - Light Mode
  static const Color lightPrimary = Color(0xFF000000);
  static const Color lightSecondary = Color(0xFFFFFFFF);
  static const Color lightAccent = Color(0xFFFF6B9D); // Fashion Pink
  static const Color lightTertiary = Color(0xFF00B4D8); // Vibrant Blue
  static const Color lightNeutral = Color(0xFFF5F5F5); // Off-white
  static const Color lightText = Color(0xFF1A1A1A); // Dark Gray
  static const Color lightTextSecondary = Color(0xFF808080); // Medium Gray
  static const Color lightBorder = Color(0xFFE0E0E0); // Light Gray
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFAFAFA);
  static const Color lightCardSecondary = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightError = Color(0xFFFF3B30);
  static const Color lightSuccess = Color(0xFF34C759);
  static const Color lightWarning = Color(0xFFFF9500);

  // Colors - Dark Mode
  static const Color darkPrimary = Color(0xFFFFFFFF);
  static const Color darkSecondary = Color(0xFF0A0A0A);
  static const Color darkAccent = Color(0xFFFF6B9D); // Fashion Pink (same)
  static const Color darkTertiary = Color(0xFF00D9FF); // Bright Blue
  static const Color darkNeutral = Color(0xFF1A1A1A); // Dark Gray
  static const Color darkText = Color(0xFFF5F5F5); // Light Gray
  static const Color darkTextSecondary = Color(0xFFA0A0A0); // Medium Gray
  static const Color darkBorder = Color(0xFF2A2A2A); // Dark Border
  static const Color darkBackground = Color(0xFF0F0F0F);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkCardSecondary = Color(0xFF252525);
  static const Color darkSurface = Color(0xFF0F0F0F);
  static const Color darkError = Color(0xFFFF453A);
  static const Color darkSuccess = Color(0xFF32D74B);
  static const Color darkWarning = Color(0xFFFF9500);

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0; // For circular items

  // Typography Sizes
  static const double fontDisplay = 32.0; // SpaceGroteskBold
  static const double fontHeading1 = 24.0;
  static const double fontHeading2 = 18.0;
  static const double fontBody = 14.0;
  static const double fontCaption = 12.0;
  static const double fontMono = 12.0;

  // Shadows
  static final BoxShadow shadowSubtle = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );

  static final BoxShadow shadowMedium = BoxShadow(
    color: Colors.black.withOpacity(0.12),
    blurRadius: 16,
    offset: const Offset(0, 4),
  );

  static final BoxShadow shadowDeep = BoxShadow(
    color: Colors.black.withOpacity(0.16),
    blurRadius: 32,
    offset: const Offset(0, 8),
  );

  static BoxShadow shadowGlow(Color color) => BoxShadow(
        color: color.withOpacity(0.2),
        blurRadius: 24,
        spreadRadius: 0,
      );

  // Layout Constants
  static const double topBarHeight = 56.0;
  static const double recommendationCardHeight = 200.0;
  static const double recommendationCardWidth = 160.0;
  static const double wardrobeSidebarWidth = 320.0;
  static const double maxChatWidth = 600.0;

  // Animation Durations
  static const Duration durationMicroShort = Duration(milliseconds: 100);
  static const Duration durationShort = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationLong = Duration(milliseconds: 400);
  static const Duration durationXlong = Duration(milliseconds: 600);

  // Responsive Breakpoints
  static const double mobileMax = 600.0;
  static const double tabletMin = 600.0;
  static const double tabletMax = 1000.0;
  static const double desktopMin = 1000.0;
  static const double wideMin = 1400.0;

  // Z-Index Layers
  static const int zIndex0 = 0;
  static const int zIndex1 = 1;
  static const int zIndex10 = 10;
  static const int zIndex100 = 100;
  static const int zIndex1000 = 1000;
}

/// 🎯 DESIGN SYSTEM TOKENS - For easy access in widgets
class DesignSystem {
  static const colors = _Colors();
  static const spacing = _Spacing();
  static const radius = _Radius();
  static const shadows = _Shadows();
  static const durations = _Durations();
  static const layout = _Layout();
}

class _Colors {
  const _Colors();

  // Light Mode Palette
  Color get lightText => DesignTokens.lightText;
  Color get lightTextSecondary => DesignTokens.lightTextSecondary;
  Color get lightBorder => DesignTokens.lightBorder;
  Color get lightCard => DesignTokens.lightCard;
  Color get lightAccent => DesignTokens.lightAccent;
  Color get lightError => DesignTokens.lightError;
  Color get lightSuccess => DesignTokens.lightSuccess;
  Color get lightWarning => DesignTokens.lightWarning;

  // Dark Mode Palette
  Color get darkText => DesignTokens.darkText;
  Color get darkTextSecondary => DesignTokens.darkTextSecondary;
  Color get darkBorder => DesignTokens.darkBorder;
  Color get darkCard => DesignTokens.darkCard;
  Color get darkAccent => DesignTokens.darkAccent;
  Color get darkError => DesignTokens.darkError;
  Color get darkSuccess => DesignTokens.darkSuccess;
  Color get darkWarning => DesignTokens.darkWarning;
}

class _Spacing {
  const _Spacing();

  double get xs => DesignTokens.spacingXs;
  double get sm => DesignTokens.spacingSm;
  double get md => DesignTokens.spacingMd;
  double get lg => DesignTokens.spacingLg;
  double get xl => DesignTokens.spacingXl;
  double get xxl => DesignTokens.spacingXxl;
}

class _Radius {
  const _Radius();

  double get xs => DesignTokens.radiusXs;
  double get sm => DesignTokens.radiusSm;
  double get md => DesignTokens.radiusMd;
  double get lg => DesignTokens.radiusLg;
  double get xl => DesignTokens.radiusXl;
  double get full => DesignTokens.radiusFull;
}

class _Shadows {
  const _Shadows();

  BoxShadow get subtle => DesignTokens.shadowSubtle;
  BoxShadow get medium => DesignTokens.shadowMedium;
  BoxShadow get deep => DesignTokens.shadowDeep;

  BoxShadow glow(Color color) => DesignTokens.shadowGlow(color);
}

class _Durations {
  const _Durations();

  Duration get microShort => DesignTokens.durationMicroShort;
  Duration get short => DesignTokens.durationShort;
  Duration get medium => DesignTokens.durationMedium;
  Duration get long => DesignTokens.durationLong;
  Duration get xlong => DesignTokens.durationXlong;
}

class _Layout {
  const _Layout();

  double get topBarHeight => DesignTokens.topBarHeight;
  double get wardrobeSidebarWidth => DesignTokens.wardrobeSidebarWidth;
  double get maxChatWidth => DesignTokens.maxChatWidth;
  double get mobileMax => DesignTokens.mobileMax;
  double get desktopMin => DesignTokens.desktopMin;
}

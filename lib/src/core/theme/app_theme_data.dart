/// App Theme Data Model
/// Centralized theme data structure for all themes
import 'package:flutter/material.dart';
import 'app_theme_mode.dart';

class AppThemeData {
  final AppThemeMode mode;
  
  // Primary Colors
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  
  // Background Colors
  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color backgroundTertiary;
  final LinearGradient? backgroundGradient;
  
  // Surface Colors
  final Color surface;
  final Color surfaceElevated;
  
  // Text Colors
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color? textInverse;
  
  // Border Colors
  final Color borderLight;
  final Color borderMedium;
  
  // Chat Colors
  final Color chatUserBubble;
  final Color chatAIBubble;
  final Color chatAIBorder;
  
  // Accent Colors
  final Color accentSuccess;
  final Color accentWarning;
  final Color accentError;
  
  // Effects
  final BoxShadow? primaryGlow;
  final BoxShadow? cardGlow;
  
  // Border Radius
  final double borderRadius;
  final double borderRadiusLarge;
  
  // Spacing (consistent across themes)
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 400);
  
  // Curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve smoothCurve = Curves.easeOutCubic;
  
  const AppThemeData({
    required this.mode,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.backgroundTertiary,
    this.backgroundGradient,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    this.textInverse,
    required this.borderLight,
    required this.borderMedium,
    required this.chatUserBubble,
    required this.chatAIBubble,
    required this.chatAIBorder,
    required this.accentSuccess,
    required this.accentWarning,
    required this.accentError,
    this.primaryGlow,
    this.cardGlow,
    required this.borderRadius,
    required this.borderRadiusLarge,
  });
  
  /// Convert to Flutter ThemeData
  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: false,
      brightness: mode == AppThemeMode.darkAI ? Brightness.dark : Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: primaryLight,
        surface: surface,
        error: accentError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
        background: backgroundPrimary,
      ),
      scaffoldBackgroundColor: backgroundPrimary,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXXL,
            vertical: spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingLG,
          vertical: spacingMD,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
    );
  }
  
  /// Typography helpers
  TextStyle bodyLarge({Color? color, bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 16 : 18,
      fontWeight: FontWeight.w400,
      color: color ?? textPrimary,
      height: 1.5,
      letterSpacing: -0.01,
    );
  }
  
  TextStyle bodyMedium({Color? color, bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 15 : 17,
      fontWeight: FontWeight.w400,
      color: color ?? textPrimary,
      height: 1.5,
      letterSpacing: -0.01,
    );
  }
  
  TextStyle bodySmall({Color? color, bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 14 : 16,
      fontWeight: FontWeight.w400,
      color: color ?? textSecondary,
      height: 1.4,
    );
  }
  
  TextStyle titleLarge({Color? color, bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 20 : 24,
      fontWeight: FontWeight.w600,
      color: color ?? textPrimary,
      height: 1.3,
      letterSpacing: -0.02,
    );
  }
  
  TextStyle titleMedium({Color? color, bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 18 : 22,
      fontWeight: FontWeight.w600,
      color: color ?? textPrimary,
      height: 1.3,
      letterSpacing: -0.02,
    );
  }
  
  TextStyle headlineLarge({Color? color, bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 24 : 32,
      fontWeight: FontWeight.w600,
      color: color ?? textPrimary,
      height: 1.2,
      letterSpacing: -0.03,
    );
  }
}

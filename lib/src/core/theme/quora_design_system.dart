import 'package:flutter/material.dart';

/// Quora Design System
/// Clean, minimal, content-first design matching Quora mobile app
class QuoraDesignSystem {
  // Colors - Quora's clean palette
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF7F7F7);
  static const Color textPrimary = Color(0xFF2E2E2E);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFF999999);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color dividerColor = Color(0xFFE8E8E8);
  
  // Brand color (used sparingly, like Quora's red)
  static const Color brandColor = Color(0xFFB92B27); // Quora red
  
  // Interactive colors
  static const Color linkColor = Color(0xFF2E69FF);
  static const Color errorColor = Color(0xFFD93025);
  static const Color successColor = Color(0xFF34A853);
  
  // Typography Scale (Quora-style)
  static TextStyle headlineLarge({bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 24 : 28,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      height: 1.3,
      letterSpacing: -0.5,
    );
  }
  
  static TextStyle headlineMedium({bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 20 : 24,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      height: 1.3,
      letterSpacing: -0.3,
    );
  }
  
  static TextStyle headlineSmall({bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 18 : 20,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      height: 1.3,
    );
  }
  
  static TextStyle titleLarge({bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 16 : 18,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      height: 1.4,
    );
  }
  
  static TextStyle bodyLarge({bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 16 : 17,
      fontWeight: FontWeight.w400,
      color: textPrimary,
      height: 1.5,
    );
  }
  
  static TextStyle bodyMedium({bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 14 : 15,
      fontWeight: FontWeight.w400,
      color: textPrimary,
      height: 1.5,
    );
  }
  
  static TextStyle bodySmall({bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 12 : 13,
      fontWeight: FontWeight.w400,
      color: textSecondary,
      height: 1.4,
    );
  }
  
  static TextStyle caption({bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 11 : 12,
      fontWeight: FontWeight.w400,
      color: textTertiary,
      height: 1.3,
    );
  }
  
  static TextStyle linkText({bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 14 : 15,
      fontWeight: FontWeight.w400,
      color: linkColor,
      height: 1.5,
    );
  }
  
  // Spacing System (Quora's tight spacing)
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 12.0;
  static const double spacingLG = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;
  
  // Border Radius (minimal, like Quora)
  static const double radiusSM = 4.0;
  static const double radiusMD = 8.0;
  static const double radiusLG = 12.0;
  
  // Shadows (subtle, like Quora)
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
  
  // Animation Durations (fast, subtle)
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 200);
  static const Duration animationSlow = Duration(milliseconds: 300);
  
  // Card Styling (Quora-style)
  static BoxDecoration get cardDecoration => const BoxDecoration(
    color: backgroundWhite,
    border: Border(
      bottom: BorderSide(color: dividerColor, width: 1),
    ),
  );
  
  // Input Field Styling (Quora-style)
  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: backgroundWhite,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMD),
      borderSide: const BorderSide(color: borderColor, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMD),
      borderSide: const BorderSide(color: borderColor, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMD),
      borderSide: const BorderSide(color: brandColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMD),
      borderSide: const BorderSide(color: errorColor, width: 1),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: spacingLG,
      vertical: spacingMD,
    ),
    labelStyle: bodyMedium(),
    hintStyle: bodyMedium().copyWith(color: textTertiary),
  );
  
  // Button Heights
  static const double buttonHeight = 44.0;
  
  // Icon Sizes
  static const double iconSize = 20.0;
  static const double iconSizeSmall = 16.0;
  static const double iconSizeLarge = 24.0;
}

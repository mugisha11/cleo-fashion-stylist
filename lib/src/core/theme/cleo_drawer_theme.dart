import 'package:flutter/material.dart';

/// Premium fashion drawer theme constants
/// Inspired by Pi Network, Canva, and Discord mobile drawers
class CleoDrawerTheme {
  // Colors - Matte luxury palette
  static const Color primaryNavy = Color(0xFF0B132B);
  static const Color secondaryLavender = Color(0xFF8C7AE6);
  static const Color accentTeal = Color(0xFF2DC6A7);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceOffWhite = Color(0xFFF7F7F9);
  static const Color textPrimary = Color(0xFF1E1E2E);
  static const Color textSecondary = Color(0xFF7A7F98);
  static const Color textMuted = Color(0xFFA8ADBD);
  static const Color borderLight = Color(0xFFE3E6EF);
  static const Color dividerColor = Color(0xFFF0F2F7);
  
  // Drawer dimensions
  static const double drawerWidthPercent = 0.75; // 75% of screen width
  static const double headerHeight = 180.0;
  static const double itemHeight = 56.0;
  static const double itemIconSize = 24.0;
  static const double itemPadding = 20.0;
  
  // Border radius
  static const double radiusSM = 12.0;
  static const double radiusMD = 16.0;
  static const double radiusLG = 20.0;
  
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  
  // Shadows
  static List<BoxShadow> get drawerShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 24,
      offset: const Offset(4, 0),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(2, 0),
    ),
  ];
  
  static List<BoxShadow> get itemShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  // Typography
  static const TextStyle headerTitleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
  );
  
  static const TextStyle headerSubtitleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.2,
  );
  
  static const TextStyle itemLabelStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.1,
  );
  
  static const TextStyle itemLabelActiveStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: primaryNavy,
    letterSpacing: 0.1,
  );
  
  // Animation durations
  static const Duration drawerAnimationDuration = Duration(milliseconds: 300);
  static const Duration itemAnimationDuration = Duration(milliseconds: 200);
}


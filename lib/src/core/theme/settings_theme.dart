import 'package:flutter/material.dart';

/// Blue Futuristic Theme for Cleo Fashion
/// Electric Blue / Neon Blue inspired design system
class SettingsTheme {
  // Primary Colors - Electric Blue
  static const Color primaryBlue = Color(0xFF00BFFF); // Electric blue
  static const Color primaryBlueDark = Color(0xFF0099CC); // Darker electric blue
  static const Color primaryBlueLight = Color(0xFF33CCFF); // Light electric blue
  
  // Secondary Colors - Soft Cyan
  static const Color secondaryCyan = Color(0xFF00CED1); // Soft cyan
  static const Color secondaryCyanLight = Color(0xFFB0E0E6); // Light cyan
  
  // Backgrounds
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundLightBlue = Color(0xFFF0F8FF); // Very light blue
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  
  // Borders & Dividers
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFF0F2F7);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  
  // Border Radius
  static const double radiusSM = 12.0;
  static const double radiusMD = 16.0;
  static const double radiusLG = 20.0;
  
  // Shadows - Soft, subtle glow
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: primaryBlue.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> get activeGlow => [
    BoxShadow(
      color: primaryBlue.withOpacity(0.2),
      blurRadius: 12,
      offset: const Offset(0, 0),
      spreadRadius: 2,
    ),
  ];
  
  // Typography
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
  );
  
  static const TextStyle tileTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.1,
  );
  
  static const TextStyle tileSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: 0.2,
  );
  
  static const TextStyle profileName = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );
  
  static const TextStyle profileEmail = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: 0.2,
  );
}


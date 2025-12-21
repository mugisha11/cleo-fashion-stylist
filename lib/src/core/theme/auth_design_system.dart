import 'package:flutter/material.dart';

/// Premium Authentication Design System
/// Inspired by Canva's soft elegance + Discord's bold clarity + High-fashion minimalism
class AuthDesignSystem {
  // Color Palette - Canva + Discord Inspired
  static const Color primaryNavy = Color(0xFF1A1D2E); // Deep navy
  static const Color secondaryIndigo = Color(0xFF4A5568); // Soft indigo
  static const Color accentTeal = Color(0xFF00C9A7); // Canva-like aqua/teal
  static const Color accentLavender = Color(0xFF8B7FA8); // Muted lavender
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1D2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderFocus = Color(0xFF00C9A7);
  static const Color errorRed = Color(0xFFEF4444);
  
  // Glass Effect Colors
  static const Color glassWhite = Color(0xF2FFFFFF); // 95% opacity white
  static const Color glassOverlay = Color(0x0D000000); // Subtle overlay
  
  // Spacing System
  static const double spacingXS = 8.0;
  static const double spacingSM = 12.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 40.0;
  
  // Border Radius
  static const double radiusSM = 12.0;
  static const double radiusMD = 16.0;
  static const double radiusLG = 18.0;
  
  // Shadows - Premium, soft, subtle (Canva-style)
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 32,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: accentTeal.withValues(alpha: 0.25),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  // Typography Styles
  static TextStyle headlineLarge({bool isMobile = false}) {
    return TextStyle(
      fontSize: isMobile ? 28 : 32,
      fontWeight: FontWeight.bold,
      color: textPrimary,
      letterSpacing: -0.8,
      height: 1.2,
    );
  }
  
  static TextStyle headlineMedium({bool isMobile = false}) {
    return TextStyle(
      fontSize: isMobile ? 24 : 28,
      fontWeight: FontWeight.bold,
      color: textPrimary,
      letterSpacing: -0.5,
      height: 1.3,
    );
  }
  
  static TextStyle bodyLarge({bool isMobile = false}) {
    return TextStyle(
      fontSize: isMobile ? 14 : 16,
      fontWeight: FontWeight.normal,
      color: textSecondary,
      letterSpacing: 0,
      height: 1.5,
    );
  }
  
  static TextStyle bodyMedium({bool isMobile = false}) {
    return TextStyle(
      fontSize: isMobile ? 13 : 14,
      fontWeight: FontWeight.normal,
      color: textSecondary,
      letterSpacing: 0,
      height: 1.5,
    );
  }
  
  static TextStyle buttonText({bool isMobile = false}) {
    return TextStyle(
      fontSize: isMobile ? 15 : 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 0.3,
    );
  }
  
  static TextStyle linkText({bool isMobile = false}) {
    return TextStyle(
      fontSize: isMobile ? 13 : 14,
      fontWeight: FontWeight.w600,
      color: accentTeal,
      letterSpacing: 0,
    );
  }
}




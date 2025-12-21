import 'package:flutter/material.dart';

/// Premium Fashion AI Dashboard Design System
/// Inspired by ChatGPT + Pinterest + Vogue + Pi Network
class DashboardDesignSystem {
  // Color Palette - Luxury Fashion Grade
  static const Color primaryNavy = Color(0xFF1B1D2E); // Deep navy
  static const Color secondaryLavender = Color(0xFFA29BFE); // Soft lavender
  static const Color accentTeal = Color(0xFF41D3BD); // Canva-inspired aqua/teal
  static const Color accentBlush = Color(0xFFF6E9E9); // Muted blush
  static const Color surfaceOffWhite = Color(0xFFFAFAFB); // Off-white surface
  static const Color textCharcoal = Color(0xFF111111); // High contrast text
  static const Color textSecondary = Color(0xFF6B7280); // Secondary text
  static const Color borderLight = Color(0xFFE5E7EB); // Light borders
  
  // Sidebar Colors
  static const Color sidebarBackground = Color(0xFFFFFFFF);
  static const Color sidebarHover = Color(0xFFF5F5F7);
  static const Color sidebarActive = Color(0xFFF0F0FF);
  
  // Chat Colors
  static const Color chatUserBubble = Color(0xFF1B1D2E);
  static const Color chatAIBubble = Color(0xFFF5F5F7);
  static const Color chatAIBorder = Color(0xFFA29BFE);
  
  // Spacing System
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Border Radius
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  
  // Shadows - Premium, soft
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> get sidebarShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(2, 0),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> get chatBubbleShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
  
  // Typography Styles
  static TextStyle headlineLarge({bool isMobile = false}) {
    return TextStyle(
      fontSize: isMobile ? 24 : 28,
      fontWeight: FontWeight.bold,
      color: textCharcoal,
      letterSpacing: -0.5,
      height: 1.2,
    );
  }
  
  static TextStyle headlineMedium({bool isMobile = false}) {
    return TextStyle(
      fontSize: isMobile ? 20 : 24,
      fontWeight: FontWeight.bold,
      color: textCharcoal,
      letterSpacing: -0.3,
      height: 1.3,
    );
  }
  
  static TextStyle bodyLarge({bool isMobile = false}) {
    return TextStyle(
      fontSize: isMobile ? 15 : 16,
      fontWeight: FontWeight.normal,
      color: textCharcoal,
      letterSpacing: 0,
      height: 1.5,
    );
  }
  
  static TextStyle bodyMedium({bool isMobile = false}) {
    return TextStyle(
      fontSize: isMobile ? 14 : 15,
      fontWeight: FontWeight.normal,
      color: textSecondary,
      letterSpacing: 0,
      height: 1.5,
    );
  }
  
  static TextStyle caption({bool isMobile = false}) {
    return TextStyle(
      fontSize: isMobile ? 12 : 13,
      fontWeight: FontWeight.w400,
      color: textSecondary,
      letterSpacing: 0,
      height: 1.4,
    );
  }
  
  // Sidebar Width
  static const double sidebarWidth = 240.0;
  static const double sidebarWidthCollapsed = 72.0;
  
  // Panel Widths
  static const double recommendationsPanelWidth = 360.0;
}




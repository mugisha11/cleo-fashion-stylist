import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Grok-Inspired Design System
/// AI-first, minimal, premium, fashion-forward
/// No gradients, no glassmorphism, high contrast, clean typography
class GrokDesignSystem {
  // ============================================
  // COLOR SYSTEM (Grok-Inspired, Fashion-Grade)
  // ============================================
  
  // Primary: Near-black / charcoal
  static const Color primaryCharcoal = Color(0xFF1A1A1A); // Near-black
  static const Color primaryDark = Color(0xFF2A2A2A); // Dark gray
  
  // Secondary: Soft neutral gray
  static const Color secondaryGray = Color(0xFF6B7280); // Soft gray
  static const Color secondaryLightGray = Color(0xFF9CA3AF); // Light gray
  static const Color secondaryVeryLightGray = Color(0xFFE5E7EB); // Very light gray
  
  // Accent: Muted electric blue OR muted purple (used sparingly)
  static const Color accentBlue = Color(0xFF4A90E2); // Muted electric blue
  static const Color accentPurple = Color(0xFF7C3AED); // Muted purple
  static const Color accentBlueLight = Color(0xFFE3F2FD); // Light blue background
  
  // Backgrounds: Solid colors only
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundOffWhite = Color(0xFFFAFAFA);
  static const Color backgroundLightGray = Color(0xFFF5F5F5);
  
  // Text hierarchy
  static const Color textPrimary = Color(0xFF1A1A1A); // Charcoal
  static const Color textSecondary = Color(0xFF6B7280); // Gray
  static const Color textTertiary = Color(0xFF9CA3AF); // Light gray
  static const Color textInverse = Color(0xFFFFFFFF); // White
  
  // Borders
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderMedium = Color(0xFFD1D5DB);
  
  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  
  // Chat colors
  static const Color chatUserBubble = Color(0xFF1A1A1A); // Charcoal
  static const Color chatAIBubble = Color(0xFFF5F5F5); // Light gray
  static const Color chatAIBorder = Color(0xFFE5E7EB); // Border
  
  // ============================================
  // TYPOGRAPHY RULES
  // ============================================
  // One modern sans-serif family
  // Strong hierarchy: AI messages = slightly larger, User messages = lighter weight
  // Generous line spacing
  // No decorative fonts
  
  // AI messages = slightly larger
  static TextStyle aiMessageText({bool isMobile = false}) {
    return GoogleFonts.inter(
      fontSize: isMobile ? 16 : 17,
      fontWeight: FontWeight.w500,
      color: textPrimary,
      height: 1.6, // Generous line spacing
      letterSpacing: -0.2,
    );
  }
  
  // User messages = lighter weight
  static TextStyle userMessageText({bool isMobile = false}) {
    return GoogleFonts.inter(
      fontSize: isMobile ? 15 : 16,
      fontWeight: FontWeight.w400,
      color: textInverse,
      height: 1.6,
      letterSpacing: 0,
    );
  }
  
  // Headlines
  static TextStyle headlineLarge({bool isMobile = false}) {
    return GoogleFonts.inter(
      fontSize: isMobile ? 28 : 32,
      fontWeight: FontWeight.bold,
      color: textPrimary,
      height: 1.2,
      letterSpacing: -0.8,
    );
  }
  
  static TextStyle headlineMedium({bool isMobile = false}) {
    return GoogleFonts.inter(
      fontSize: isMobile ? 22 : 24,
      fontWeight: FontWeight.bold,
      color: textPrimary,
      height: 1.3,
      letterSpacing: -0.5,
    );
  }
  
  static TextStyle headlineSmall({bool isMobile = false}) {
    return GoogleFonts.inter(
      fontSize: isMobile ? 18 : 20,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      height: 1.4,
      letterSpacing: -0.3,
    );
  }
  
  // Body text
  static TextStyle bodyLarge({bool isMobile = false}) {
    return GoogleFonts.inter(
      fontSize: isMobile ? 16 : 17,
      fontWeight: FontWeight.normal,
      color: textPrimary,
      height: 1.6,
      letterSpacing: 0,
    );
  }
  
  static TextStyle bodyMedium({bool isMobile = false}) {
    return GoogleFonts.inter(
      fontSize: isMobile ? 15 : 16,
      fontWeight: FontWeight.normal,
      color: textSecondary,
      height: 1.6,
      letterSpacing: 0,
    );
  }
  
  static TextStyle bodySmall({bool isMobile = false}) {
    return GoogleFonts.inter(
      fontSize: isMobile ? 13 : 14,
      fontWeight: FontWeight.normal,
      color: textSecondary,
      height: 1.5,
      letterSpacing: 0,
    );
  }
  
  // Caption
  static TextStyle caption({bool isMobile = false}) {
    return GoogleFonts.inter(
      fontSize: isMobile ? 12 : 13,
      fontWeight: FontWeight.w400,
      color: textTertiary,
      height: 1.4,
      letterSpacing: 0,
    );
  }
  
  // Button text
  static TextStyle buttonText({bool isMobile = false}) {
    return GoogleFonts.inter(
      fontSize: isMobile ? 15 : 16,
      fontWeight: FontWeight.w600,
      color: textInverse,
      height: 1.2,
      letterSpacing: 0.2,
    );
  }
  
  // Link text
  static TextStyle linkText({bool isMobile = false}) {
    return GoogleFonts.inter(
      fontSize: isMobile ? 14 : 15,
      fontWeight: FontWeight.w600,
      color: accentBlue,
      height: 1.4,
      letterSpacing: 0,
    );
  }
  
  // ============================================
  // SPACING SYSTEM
  // ============================================
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // ============================================
  // BORDER RADIUS
  // ============================================
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  
  // ============================================
  // SHADOWS (Minimal, subtle)
  // ============================================
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> get chatBubbleShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
  ];
  
  // ============================================
  // COMPONENT SIZES
  // ============================================
  static const double headerHeight = 56.0; // Single row, never wraps
  static const double inputHeight = 48.0;
  static const double buttonHeight = 48.0;
  static const double avatarSize = 32.0;
  static const double iconSize = 20.0;
  
  // ============================================
  // ANIMATION DURATIONS
  // ============================================
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 400);
  
  // ============================================
  // EASING CURVES (iOS native feel)
  // ============================================
  static const Curve defaultCurve = Curves.easeOutCubic;
}


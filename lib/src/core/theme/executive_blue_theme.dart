/// Executive Blue Theme
/// Premium, intelligent, ChatGPT-level design system
import 'package:flutter/material.dart';

class ExecutiveBlueTheme {
  // Primary Executive Blue Palette
  static const Color primaryBlue = Color(0xFF2563EB); // Executive blue
  static const Color primaryBlueDark = Color(0xFF1E40AF);
  static const Color primaryBlueLight = Color(0xFF3B82F6);
  
  // Neutral Grays
  static const Color backgroundPrimary = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF9FAFB);
  static const Color backgroundTertiary = Color(0xFFF3F4F6);
  
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  
  // Borders & Dividers
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderMedium = Color(0xFFD1D5DB);
  
  // Chat Colors
  static const Color chatUserBubble = Color(0xFF2563EB);
  static const Color chatAIBubble = Color(0xFFF9FAFB);
  static const Color chatAIBorder = Color(0xFFE5E7EB);
  
  // Accents
  static const Color accentSuccess = Color(0xFF10B981);
  static const Color accentWarning = Color(0xFFF59E0B);
  static const Color accentError = Color(0xFFEF4444);
  
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Typography
  static TextStyle bodyLarge({Color? color}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: color ?? textPrimary,
      height: 1.5,
      letterSpacing: -0.01,
    );
  }
  
  static TextStyle bodyMedium({Color? color}) {
    return TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: color ?? textPrimary,
      height: 1.5,
      letterSpacing: -0.01,
    );
  }
  
  static TextStyle bodySmall({Color? color}) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color ?? textSecondary,
      height: 1.4,
    );
  }
  
  static TextStyle titleLarge({Color? color}) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: color ?? textPrimary,
      height: 1.3,
      letterSpacing: -0.02,
    );
  }
  
  static TextStyle titleMedium({Color? color}) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: color ?? textPrimary,
      height: 1.3,
      letterSpacing: -0.02,
    );
  }
  
  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 300);
  
  // Curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve smoothCurve = Curves.easeOutCubic;
}

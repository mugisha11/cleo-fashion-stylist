/// Giovanni Theme
/// Light theme matching auth screens: coral/purple/green accents, light grey backgrounds
library;

import 'package:flutter/material.dart';
import 'app_theme_data.dart';
import 'app_theme_mode.dart';

class GiovanniTheme {
  // Background (matching homepage light blue-gray)
  static const Color bgTop = Color(0xFFF5F7FB);
  static const Color bgBottom = Color(0xFFF0F2F6);

  // Primary: blue (matching homepage gradient)
  static const Color primary = Color(0xFF1F66D1);
  static const Color primaryLight = Color(0xFF4DA3FF);
  static const Color primaryDark = Color(0xFF123B7A);

  // Secondary / link green
  static const Color linkGreen = Color(0xFF70C55F);
  static const Color signupLinkGreen = Color(0xFF38C793);

  // Surfaces
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFEDEDED);

  // Text
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF555555);
  static const Color textTertiary = Color(0xFF777777);

  // Borders
  static const Color borderLight = Color(0xFFBBBBBB);
  static const Color borderMedium = Color(0xFF999999);

  // Chat (use primary for user, light for AI)
  static const Color chatUserBubble = Color(0xFF4C7DFF);
  static const Color chatAIBubble = Color(0xFFF0F2F5);
  static const Color chatAIBorder = Color(0xFFE0E0E0);

  // Accents
  static const Color accentSuccess = Color(0xFF70C55F);
  static const Color accentWarning = Color(0xFFFF9800);
  static const Color accentError = Color(0xFFD32F2F);

  static AppThemeData get theme => const AppThemeData(
        mode: AppThemeMode.giovanni,
        primary: primary,
        primaryLight: primaryLight,
        primaryDark: primaryDark,
        backgroundPrimary: bgTop,
        backgroundSecondary: surface,
        backgroundTertiary: surfaceElevated,
        backgroundGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgBottom],
        ),
        surface: surface,
        surfaceElevated: surfaceElevated,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textTertiary: textTertiary,
        textInverse: Colors.white,
        borderLight: borderLight,
        borderMedium: borderMedium,
        shadowColor: Color(0x1A000000),
        chatUserBubble: chatUserBubble,
        chatAIBubble: chatAIBubble,
        chatAIBorder: chatAIBorder,
        accentSuccess: accentSuccess,
        accentWarning: accentWarning,
        accentError: accentError,
        primaryGlow: null,
        cardGlow: null,
        borderRadius: 12.0,
        borderRadiusLarge: 16.0,
      );
}

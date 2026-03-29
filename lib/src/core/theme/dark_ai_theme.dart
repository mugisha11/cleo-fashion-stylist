/// Dark AI Theme
/// Dark charcoal with gentle dark purple-blue radial gradient from upper-middle.
/// Professional dark mode: lighter in center, darker at edges.
library;
import 'package:flutter/material.dart';
import 'app_theme_data.dart';
import 'app_theme_mode.dart';

class DarkAITheme {
  // Near-Black / Charcoal Palette
  static const Color _charcoal = Color(0xFF0F0F0F); // Near-black
  static const Color _charcoalElevated = Color(0xFF1A1A1A);
  static const Color _charcoalSurface = Color(0xFF252525);
  
  // Neutral Grays
  static const Color _grayLight = Color(0xFF2D2D2D);
  static const Color _grayMedium = Color(0xFF3A3A3A);
  
  // Muted Blue Accent (reused from default but toned down)
  static const Color _blueMuted = Color(0xFF4A90E2);
  static const Color _blueMutedLight = Color(0xFF5BA0F2);
  static const Color _blueMutedDark = Color(0xFF3A80D2);
  
  // Text Colors (High Contrast for Readability)
  static const Color _textPrimary = Color(0xFFE5E5E5);
  static const Color _textSecondary = Color(0xFFB0B0B0);
  static const Color _textTertiary = Color(0xFF808080);
  
  // Borders (Minimal)
  static const Color _borderSubtle = Color(0xFF2D2D2D);
  static const Color _borderMedium = Color(0xFF3A3A3A);
  
  // Chat Colors
  static const Color _chatUser = Color(0xFF4A90E2);
  static const Color _chatAI = Color(0xFF1A1A1A);
  static const Color _chatAIBorder = Color(0xFF2D2D2D);
  
  // Accents (Muted)
  static const Color _success = Color(0xFF4CAF50);
  static const Color _warning = Color(0xFFFF9800);
  static const Color _error = Color(0xFFF44336);

  /// Radial gradient: dark purple-blue from upper-middle, darker at edges.
  /// Applied app-wide when dark mode is selected.
  static const RadialGradient _darkRadialGradient = RadialGradient(
    center: Alignment(0.0, -0.35),
    radius: 1.15,
    colors: [
      Color(0xFF1E2438), // Slightly lighter, vibrant center (dark blue-grey)
      Color(0xFF141824),
      Color(0xFF0D0E14), // Darker at edges (near-black with blue hint)
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static AppThemeData get theme => const AppThemeData(
    mode: AppThemeMode.darkAI,
    primary: _blueMuted,
    primaryLight: _blueMutedLight,
    primaryDark: _blueMutedDark,
    backgroundPrimary: _charcoal,
    backgroundSecondary: _charcoalElevated,
    backgroundTertiary: _charcoalSurface,
    surface: _charcoalElevated,
    surfaceElevated: _charcoalSurface,
    textPrimary: _textPrimary,
    textSecondary: _textSecondary,
    textTertiary: _textTertiary,
    textInverse: Colors.white,
    borderLight: _borderSubtle,
    borderMedium: _borderMedium,
    shadowColor: Colors.black,
    chatUserBubble: _chatUser,
    chatAIBubble: _chatAI,
    chatAIBorder: _chatAIBorder,
    accentSuccess: _success,
    accentWarning: _warning,
    accentError: _error,
    backgroundGradient: null,
    radialGradientBackground: _darkRadialGradient,
    primaryGlow: null,
    cardGlow: null,
    borderRadius: 12.0,
    borderRadiusLarge: 16.0,
  );
}

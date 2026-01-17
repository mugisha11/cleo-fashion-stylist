/// Neon Fashion AI Theme
/// Default theme: Electric blue, glowing, fashion-tech aesthetic
/// Inspired by futuristic fashion interfaces with subtle neon accents
import 'package:flutter/material.dart';
import 'app_theme_data.dart';
import 'app_theme_mode.dart';

class NeonFashionTheme {
  // Electric Blue / Cyan Palette
  static const Color _electricBlue = Color(0xFF00D4FF); // Neon cyan
  static const Color _electricBlueLight = Color(0xFF33E0FF);
  static const Color _electricBlueDark = Color(0xFF00B8E6);
  
  // Deep Gradient Background
  static const Color _deepBlue = Color(0xFF0A0E27); // Near-black blue
  static const Color _indigo = Color(0xFF1A1F3A);
  static const Color _darkBlue = Color(0xFF0F1629);
  
  // Surface Colors (Glass-like)
  static const Color _surfaceDark = Color(0xFF1A1F3A);
  static const Color _surfaceElevated = Color(0xFF252B45);
  
  // Text Colors (High Contrast)
  static const Color _textWhite = Color(0xFFFFFFFF);
  static const Color _textGray = Color(0xFFB0B8D1);
  static const Color _textMuted = Color(0xFF7A85A6);
  
  // Borders
  static const Color _borderGlow = Color(0xFF00D4FF);
  static const Color _borderSubtle = Color(0xFF2A3455);
  
  // Chat Colors
  static const Color _chatUser = Color(0xFF00D4FF);
  static const Color _chatAI = Color(0xFF1A1F3A);
  static const Color _chatAIBorder = Color(0xFF2A3455);
  
  // Accents
  static const Color _success = Color(0xFF00FF88);
  static const Color _warning = Color(0xFFFFB800);
  static const Color _error = Color(0xFFFF3D57);

  static AppThemeData get theme => AppThemeData(
    mode: AppThemeMode.neonFashionAI,
    primary: _electricBlue,
    primaryLight: _electricBlueLight,
    primaryDark: _electricBlueDark,
    backgroundPrimary: _deepBlue,
    backgroundSecondary: _indigo,
    backgroundTertiary: _darkBlue,
    surface: _surfaceDark,
    surfaceElevated: _surfaceElevated,
    textPrimary: _textWhite,
    textSecondary: _textGray,
    textTertiary: _textMuted,
    borderLight: _borderSubtle,
    borderMedium: _borderGlow,
    chatUserBubble: _chatUser,
    chatAIBubble: _chatAI,
    chatAIBorder: _chatAIBorder,
    accentSuccess: _success,
    accentWarning: _warning,
    accentError: _error,
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_deepBlue, _indigo, _darkBlue],
      stops: [0.0, 0.5, 1.0],
    ),
    primaryGlow: BoxShadow(
      color: _electricBlue.withValues(alpha: 0.3),
      blurRadius: 12,
      spreadRadius: 0,
    ),
    cardGlow: BoxShadow(
      color: _electricBlue.withValues(alpha: 0.15),
      blurRadius: 20,
      spreadRadius: -5,
    ),
    borderRadius: 16.0,
    borderRadiusLarge: 24.0,
  );
}

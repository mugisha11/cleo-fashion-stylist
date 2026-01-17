import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ChatGPT-like Dark Theme
/// Dark-first, minimal, calm, premium, modern, confident
/// No white leaks, fully responsive
class ChatGPTDarkTheme {
  // ============================================
  // COLOR PALETTE (Dark-First)
  // ============================================
  
  // Backgrounds (Near-black to dark gray)
  static const Color background = Color(0xFF0D0D0D); // Near-black
  static const Color surface = Color(0xFF1A1A1A); // Dark surface
  static const Color surfaceElevated = Color(0xFF252525); // Elevated surface
  static const Color surfaceHover = Color(0xFF2A2A2A); // Hover state
  
  // Text (High contrast for readability)
  static const Color textPrimary = Color(0xFFECECEC); // Almost white
  static const Color textSecondary = Color(0xFFB3B3B3); // Medium gray
  static const Color textTertiary = Color(0xFF808080); // Muted gray
  static const Color textInverse = Color(0xFF0D0D0D); // Dark for light surfaces
  
  // Borders (Minimal, subtle)
  static const Color border = Color(0xFF2A2A2A);
  static const Color borderSubtle = Color(0xFF1F1F1F);
  
  // Accents (Muted, sophisticated)
  static const Color accent = Color(0xFF10A37F); // ChatGPT green
  static const Color accentLight = Color(0xFF12B885);
  static const Color accentDark = Color(0xFF0E8F6E);
  
  // Status colors
  static const Color success = Color(0xFF10A37F);
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFEF4444);
  
  // Chat bubbles
  static const Color chatUser = Color(0xFF1A1A1A);
  static const Color chatAI = Color(0xFF252525);
  static const Color chatInputBg = Color(0xFF1F1F1F);
  
  // Interactive elements
  static const Color interactive = accent;
  static const Color interactiveHover = accentLight;
  static const Color interactiveDisabled = Color(0xFF404040);

  // ============================================
  // TYPOGRAPHY
  // ============================================
  static TextTheme get textTheme => TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      height: 1.2,
      letterSpacing: -0.5,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      height: 1.25,
      letterSpacing: -0.4,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      height: 1.3,
      letterSpacing: -0.3,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: textPrimary,
      height: 1.4,
      letterSpacing: -0.2,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: textPrimary,
      height: 1.4,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: textPrimary,
      height: 1.5,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: textPrimary,
      height: 1.6,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: textSecondary,
      height: 1.5,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: textTertiary,
      height: 1.4,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: textPrimary,
      height: 1.4,
    ),
  );

  // ============================================
  // THEME DATA
  // ============================================
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      onPrimary: Colors.white,
      secondary: accentLight,
      onSecondary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      background: background,
      onBackground: textPrimary,
    ),
    scaffoldBackgroundColor: background,
    textTheme: textTheme,
    
    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: textPrimary),
      titleTextStyle: textTheme.titleLarge,
    ),
    
    // Cards
    cardTheme: CardTheme(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: border, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    
    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accent,
        textStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        side: const BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    
    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: textTheme.bodyMedium?.copyWith(color: textTertiary),
    ),
    
    // Dividers
    dividerTheme: const DividerThemeData(
      color: border,
      thickness: 1,
      space: 1,
    ),
    
    // Icons
    iconTheme: const IconThemeData(
      color: textSecondary,
      size: 24,
    ),
    
    // Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
  );
}

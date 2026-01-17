import 'package:flutter/material.dart';

/// Luxury Calendar Theme - Fashion-grade design system
class CalendarTheme {
  // Deep charcoal → soft violet → electric accent gradient
  static const Color deepCharcoal = Color(0xFF1A1A1A);
  static const Color softViolet = Color(0xFF6B5B95);
  static const Color electricAccent = Color(0xFF9B59B6);
  
  // Status colors
  static const Color tryOnGreen = Color(0xFF4ECDC4); // Soft neon green
  static const Color processingAmber = Color(0xFFFFB347); // Animated amber
  static const Color failedCoral = Color(0xFFFF8C94); // Muted coral
  static const Color completedEmerald = Color(0xFF52C9A2); // Calm emerald
  
  // Glassmorphism
  static Color glassBackground = Colors.white.withOpacity(0.15);
  static Color glassBorder = Colors.white.withOpacity(0.2);
  
  // Shadows - Soft, layered, realistic depth
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get deepShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 30,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 15,
      offset: const Offset(0, 4),
    ),
  ];
  
  // Glassmorphic decoration
  static BoxDecoration get glassCard => BoxDecoration(
    color: glassBackground,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: glassBorder, width: 1.5),
    boxShadow: softShadow,
  );
  
  // Gradient backgrounds
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepCharcoal, softViolet, electricAccent],
    stops: [0.0, 0.5, 1.0],
  );
  
  static LinearGradient get subtleGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.white.withOpacity(0.95),
      Colors.white.withOpacity(0.85),
    ],
  );
  
  // Animation curves
  static const Curve springCurve = Curves.easeOutCubic;
  static const Curve elasticCurve = Curves.elasticOut;
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  
  // Text styles
  static TextStyle displayText({Color? color}) => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w300,
    color: color ?? deepCharcoal,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  static TextStyle headlineText({Color? color}) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: color ?? deepCharcoal,
    letterSpacing: -0.3,
    height: 1.3,
  );
  
  static TextStyle bodyText({Color? color}) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: color ?? deepCharcoal,
    height: 1.6,
  );
  
  static TextStyle captionText({Color? color}) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: color ?? Colors.white70,
    height: 1.4,
  );
}

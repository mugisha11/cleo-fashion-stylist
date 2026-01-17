import 'package:flutter/material.dart';

/// Premium Fashion Design System
/// Elegant, female-attractive, fashion-editorial aesthetic
class FashionDesignSystem {
  // Soft Color Palette - Premium Fashion
  static const Color backgroundIvory = Color(0xFFFAF9F6); // Soft ivory/off-white
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF5F3F0);
  
  static const Color textCharcoal = Color(0xFF2C2C2C); // Deep charcoal (not pure black)
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFF9B9B9B);
  
  // Elegant Fashion Accents
  static const Color accentRose = Color(0xFFE8B4B8); // Soft rose
  static const Color accentNude = Color(0xFFD4C4B0); // Nude/beige
  static const Color accentCharcoal = Color(0xFF4A4A4A); // Muted charcoal
  static const Color accentGold = Color(0xFFD4AF37); // Muted gold
  
  // Primary brand color (elegant rose)
  static const Color primaryColor = accentRose;
  
  // Interactive colors
  static const Color linkColor = Color(0xFF8B6F7D); // Muted purple-rose
  static const Color errorColor = Color(0xFFC88A8A);
  static const Color successColor = Color(0xFFA8C5A0);
  
  // Border & Divider
  static const Color borderColor = Color(0xFFE8E6E3);
  static const Color dividerColor = Color(0xFFF0EDE8);
  
  // Typography Scale - Editorial, Fashion-Oriented
  static TextStyle displayLarge({bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 32 : 40,
      fontWeight: FontWeight.w300, // Light, elegant
      color: textCharcoal,
      height: 1.2,
      letterSpacing: -0.5,
    );
  }
  
  static TextStyle headlineLarge({bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 28 : 36,
      fontWeight: FontWeight.w300,
      color: textCharcoal,
      height: 1.3,
      letterSpacing: -0.3,
    );
  }
  
  static TextStyle headlineMedium({bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 24 : 30,
      fontWeight: FontWeight.w400,
      color: textCharcoal,
      height: 1.3,
      letterSpacing: -0.2,
    );
  }
  
  static TextStyle headlineSmall({bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 20 : 24,
      fontWeight: FontWeight.w500,
      color: textCharcoal,
      height: 1.4,
    );
  }
  
  static TextStyle titleLarge({bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 18 : 22,
      fontWeight: FontWeight.w500,
      color: textCharcoal,
      height: 1.4,
    );
  }
  
  static TextStyle titleMedium({bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 16 : 18,
      fontWeight: FontWeight.w500,
      color: textCharcoal,
      height: 1.4,
    );
  }
  
  static TextStyle bodyLarge({bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 16 : 17,
      fontWeight: FontWeight.w400,
      color: textCharcoal,
      height: 1.6, // Comfortable reading
    );
  }
  
  static TextStyle bodyMedium({bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 14 : 15,
      fontWeight: FontWeight.w400,
      color: textCharcoal,
      height: 1.6,
    );
  }
  
  static TextStyle bodySmall({bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 12 : 13,
      fontWeight: FontWeight.w400,
      color: textSecondary,
      height: 1.5,
    );
  }
  
  static TextStyle caption({bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 11 : 12,
      fontWeight: FontWeight.w400,
      color: textTertiary,
      height: 1.4,
    );
  }
  
  static TextStyle linkText({bool isMobile = true}) {
    return TextStyle(
      fontSize: isMobile ? 14 : 15,
      fontWeight: FontWeight.w500,
      color: linkColor,
      height: 1.5,
      decoration: TextDecoration.underline,
      decorationColor: linkColor,
    );
  }
  
  // Editorial Spacing System
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 12.0;
  static const double spacingLG = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;
  static const double spacingHuge = 48.0;
  
  // Border Radius (Soft, elegant)
  static const double radiusSM = 6.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusHero = 24.0; // For hero cards
  
  // Shadows (Subtle, luxury)
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get heroShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  // Animation Durations (Soft, elegant)
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 400);
  
  // Card Styling (Fashion-editorial)
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: backgroundWhite,
    borderRadius: BorderRadius.circular(radiusLG),
    boxShadow: cardShadow,
  );
  
  static BoxDecoration get heroCardDecoration => BoxDecoration(
    color: backgroundWhite,
    borderRadius: BorderRadius.circular(radiusHero),
    boxShadow: heroShadow,
  );
  
  // Input Field Styling (Elegant)
  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: backgroundWhite,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMD),
      borderSide: const BorderSide(color: borderColor, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMD),
      borderSide: const BorderSide(color: borderColor, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMD),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMD),
      borderSide: const BorderSide(color: errorColor, width: 1),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: spacingLG,
      vertical: spacingMD,
    ),
    labelStyle: bodyMedium().copyWith(color: textSecondary),
    hintStyle: bodyMedium().copyWith(color: textTertiary),
  );
  
  // Button Heights
  static const double buttonHeight = 48.0;
  static const double buttonHeightLarge = 56.0;
  
  // Icon Sizes
  static const double iconSize = 22.0;
  static const double iconSizeSmall = 18.0;
  static const double iconSizeLarge = 28.0;
  
  // Avatar Sizes
  static const double avatarSize = 40.0;
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeLarge = 56.0;
}

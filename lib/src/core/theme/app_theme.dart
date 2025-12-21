import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'fashion_design_system.dart';

class AppTheme {
  static ThemeData get lightTheme {
    // Use elegant, fashion-oriented font (Playfair Display for headings, Inter for body)
    final textTheme = GoogleFonts.interTextTheme();
    
    return ThemeData(
      useMaterial3: false,
      colorScheme: ColorScheme.light(
        primary: FashionDesignSystem.primaryColor,
        secondary: FashionDesignSystem.accentNude,
        surface: FashionDesignSystem.backgroundWhite,
        error: FashionDesignSystem.errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: FashionDesignSystem.textCharcoal,
        onError: Colors.white,
        background: FashionDesignSystem.backgroundIvory,
      ),
      scaffoldBackgroundColor: FashionDesignSystem.backgroundIvory,
      textTheme: textTheme.copyWith(
        displayLarge: FashionDesignSystem.displayLarge(),
        displayMedium: FashionDesignSystem.headlineLarge(),
        displaySmall: FashionDesignSystem.headlineMedium(),
        headlineMedium: FashionDesignSystem.headlineMedium(),
        headlineSmall: FashionDesignSystem.headlineSmall(),
        titleLarge: FashionDesignSystem.titleLarge(),
        titleMedium: FashionDesignSystem.titleMedium(),
        bodyLarge: FashionDesignSystem.bodyLarge(),
        bodyMedium: FashionDesignSystem.bodyMedium(),
        bodySmall: FashionDesignSystem.bodySmall(),
        labelLarge: FashionDesignSystem.bodyMedium().copyWith(fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FashionDesignSystem.radiusLG),
        ),
        color: FashionDesignSystem.backgroundWhite,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FashionDesignSystem.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: FashionDesignSystem.spacingXXL,
            vertical: FashionDesignSystem.spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FashionDesignSystem.radiusMD),
          ),
          textStyle: FashionDesignSystem.bodyMedium().copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          minimumSize: const Size(double.infinity, FashionDesignSystem.buttonHeight),
        ),
        ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FashionDesignSystem.linkColor,
          textStyle: FashionDesignSystem.linkText(),
        ),
        ),
      inputDecorationTheme: FashionDesignSystem.inputDecorationTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: FashionDesignSystem.backgroundWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: FashionDesignSystem.headlineSmall(),
        iconTheme: const IconThemeData(
          color: FashionDesignSystem.textCharcoal,
          size: FashionDesignSystem.iconSize,
        ),
        toolbarHeight: 64,
      ),
      dividerTheme: const DividerThemeData(
        color: FashionDesignSystem.dividerColor,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: FashionDesignSystem.backgroundWhite,
        selectedItemColor: FashionDesignSystem.primaryColor,
        unselectedItemColor: FashionDesignSystem.textSecondary,
        selectedLabelStyle: FashionDesignSystem.caption(),
        unselectedLabelStyle: FashionDesignSystem.caption(),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}


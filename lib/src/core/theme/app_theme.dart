import 'package:flutter/material.dart';
import 'fashion_design_system.dart';
import 'giovanni_theme.dart';

class AppTheme {
  /// Giovanni light theme (same colors as auth and main app)
  static ThemeData get giovanniTheme {
    final textTheme = ThemeData.light().textTheme;
    return ThemeData(
      fontFamily: 'system-ui',
      useMaterial3: false,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: GiovanniTheme.primary,
        secondary: GiovanniTheme.primaryLight,
        surface: GiovanniTheme.surface,
        error: GiovanniTheme.accentError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: GiovanniTheme.textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: GiovanniTheme.bgTop,
      textTheme: textTheme.copyWith(
        bodyLarge: const TextStyle(
            color: GiovanniTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w400),
        bodyMedium: const TextStyle(
            color: GiovanniTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w400),
        bodySmall:
            const TextStyle(color: GiovanniTheme.textSecondary, fontSize: 14),
        titleLarge: const TextStyle(
            color: GiovanniTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600),
        titleMedium: const TextStyle(
            color: GiovanniTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600),
        headlineMedium: const TextStyle(
            color: GiovanniTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w600),
        labelLarge: const TextStyle(
            color: GiovanniTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        color: GiovanniTheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GiovanniTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: GiovanniTheme.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GiovanniTheme.surfaceElevated,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: GiovanniTheme.primary, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: GiovanniTheme.bgTop,
        elevation: 0,
        iconTheme: IconThemeData(color: GiovanniTheme.textPrimary, size: 24),
        titleTextStyle: TextStyle(
            color: GiovanniTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(
          color: GiovanniTheme.borderLight, thickness: 1, space: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: GiovanniTheme.surface,
        selectedItemColor: GiovanniTheme.primary,
        unselectedItemColor: GiovanniTheme.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData get lightTheme {
    // Use elegant, fashion-oriented font (Inter-like fallbacks)
    final textTheme = ThemeData.light().textTheme;

    return ThemeData(
      fontFamily: 'system-ui',
      useMaterial3: false,
      colorScheme: const ColorScheme.light(
        primary: FashionDesignSystem.primaryColor,
        secondary: FashionDesignSystem.accentNude,
        surface: FashionDesignSystem.backgroundWhite,
        error: FashionDesignSystem.errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: FashionDesignSystem.textCharcoal,
        onError: Colors.white,
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
        labelLarge: FashionDesignSystem.bodyMedium()
            .copyWith(fontWeight: FontWeight.w500),
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
          minimumSize:
              const Size(double.infinity, FashionDesignSystem.buttonHeight),
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

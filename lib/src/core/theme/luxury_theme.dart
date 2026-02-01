import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'design_tokens.dart';

/// 🎨 LUXURY THEME - Apple + ChatGPT + Fashion fusion
class LuxuryTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,

      // Color Scheme - Light Mode
      colorScheme: const ColorScheme.light(
        primary: DesignTokens.lightAccent, // Pink
        secondary: DesignTokens.lightTertiary, // Blue
        surface: DesignTokens.lightCard,
        error: DesignTokens.lightError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: DesignTokens.lightText,
      ),

      // Scaffold
      scaffoldBackgroundColor: DesignTokens.lightBackground,

      // Text Themes
      textTheme: TextTheme(
        displayLarge: _displayStyle(),
        displayMedium: _headingLargeStyle(),
        displaySmall: _headingSmallStyle(),
        headlineMedium: _headingMediumStyle(),
        headlineSmall: _headingSmallStyle(),
        titleLarge: _titleLargeStyle(),
        titleMedium: _titleMediumStyle(),
        titleSmall: _titleSmallStyle(),
        bodyLarge: _bodyLargeStyle(),
        bodyMedium: _bodyMediumStyle(),
        bodySmall: _bodySmallStyle(),
        labelLarge: _labelLargeStyle(),
        labelMedium: _labelMediumStyle(),
        labelSmall: _labelSmallStyle(),
      ),

      // AppBar - Minimal
      appBarTheme: const AppBarTheme(
        backgroundColor: DesignTokens.lightBackground,
        foregroundColor: DesignTokens.lightText,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(
            color: DesignTokens.lightBorder,
            width: 0.5,
          ),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.lightAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingLg,
            vertical: DesignTokens.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DesignTokens.lightAccent,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMd,
            vertical: DesignTokens.spacingSm,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignTokens.lightText,
          side: const BorderSide(color: DesignTokens.lightBorder),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingLg,
            vertical: DesignTokens.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.lightNeutral,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingMd,
          vertical: DesignTokens.spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: const BorderSide(color: DesignTokens.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: const BorderSide(color: DesignTokens.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: const BorderSide(
            color: DesignTokens.lightAccent,
            width: 2,
          ),
        ),
        hintStyle: _bodyMediumStyle().copyWith(
          color: DesignTokens.lightTextSecondary,
        ),
        labelStyle: _bodyMediumStyle().copyWith(
          color: DesignTokens.lightTextSecondary,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: DesignTokens.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          side: const BorderSide(color: DesignTokens.lightBorder, width: 0.5),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: DesignTokens.lightBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
        elevation: 16,
      ),

      // Checkbox & Radio
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignTokens.lightAccent;
          }
          return DesignTokens.lightBorder;
        }),
        side: const BorderSide(color: DesignTokens.lightBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: DesignTokens.lightBorder,
        thickness: 0.5,
        space: DesignTokens.spacingMd,
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: DesignTokens.lightBackground,
        selectedItemColor: DesignTokens.lightAccent,
        unselectedItemColor: DesignTokens.lightTextSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: DesignTokens.lightAccent,
        foregroundColor: Colors.white,
        elevation: 8,
        highlightElevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
      ),

      // Navigation Rail
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: DesignTokens.lightCard,
        selectedIconTheme: IconThemeData(color: DesignTokens.lightAccent),
        unselectedIconTheme:
            IconThemeData(color: DesignTokens.lightTextSecondary),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: DesignTokens.lightCard,
        disabledColor: DesignTokens.lightNeutral,
        selectedColor: DesignTokens.lightAccent,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingMd,
          vertical: DesignTokens.spacingSm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        side: const BorderSide(color: DesignTokens.lightBorder),
      ),

      // Extensions
      extensions: [LuxuryThemeExtension.light()],
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,

      // Color Scheme - Dark Mode
      colorScheme: const ColorScheme.dark(
        primary: DesignTokens.darkAccent, // Pink
        secondary: DesignTokens.darkTertiary, // Bright Blue
        surface: DesignTokens.darkCard,
        error: DesignTokens.darkError,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: DesignTokens.darkText,
      ),

      // Scaffold
      scaffoldBackgroundColor: DesignTokens.darkBackground,

      // Text Themes (same styles, different colors)
      textTheme: TextTheme(
        displayLarge: _displayStyle().copyWith(color: DesignTokens.darkText),
        displayMedium:
            _headingLargeStyle().copyWith(color: DesignTokens.darkText),
        displaySmall:
            _headingSmallStyle().copyWith(color: DesignTokens.darkText),
        headlineMedium:
            _headingMediumStyle().copyWith(color: DesignTokens.darkText),
        headlineSmall:
            _headingSmallStyle().copyWith(color: DesignTokens.darkText),
        titleLarge: _titleLargeStyle().copyWith(color: DesignTokens.darkText),
        titleMedium: _titleMediumStyle().copyWith(color: DesignTokens.darkText),
        titleSmall: _titleSmallStyle().copyWith(color: DesignTokens.darkText),
        bodyLarge: _bodyLargeStyle().copyWith(color: DesignTokens.darkText),
        bodyMedium: _bodyMediumStyle().copyWith(color: DesignTokens.darkText),
        bodySmall:
            _bodySmallStyle().copyWith(color: DesignTokens.darkTextSecondary),
        labelLarge: _labelLargeStyle().copyWith(color: DesignTokens.darkText),
        labelMedium: _labelMediumStyle().copyWith(color: DesignTokens.darkText),
        labelSmall:
            _labelSmallStyle().copyWith(color: DesignTokens.darkTextSecondary),
      ),

      // AppBar - Minimal
      appBarTheme: const AppBarTheme(
        backgroundColor: DesignTokens.darkBackground,
        foregroundColor: DesignTokens.darkText,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(
            color: DesignTokens.darkBorder,
            width: 0.5,
          ),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.darkAccent,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingLg,
            vertical: DesignTokens.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DesignTokens.darkAccent,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMd,
            vertical: DesignTokens.spacingSm,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignTokens.darkText,
          side: const BorderSide(color: DesignTokens.darkBorder),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingLg,
            vertical: DesignTokens.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.darkCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingMd,
          vertical: DesignTokens.spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: const BorderSide(color: DesignTokens.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: const BorderSide(color: DesignTokens.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: const BorderSide(
            color: DesignTokens.darkAccent,
            width: 2,
          ),
        ),
        hintStyle: _bodyMediumStyle().copyWith(
          color: DesignTokens.darkTextSecondary,
        ),
        labelStyle: _bodyMediumStyle().copyWith(
          color: DesignTokens.darkTextSecondary,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: DesignTokens.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          side: const BorderSide(color: DesignTokens.darkBorder, width: 0.5),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: DesignTokens.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
        elevation: 16,
      ),

      // Checkbox & Radio
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignTokens.darkAccent;
          }
          return DesignTokens.darkBorder;
        }),
        side: const BorderSide(color: DesignTokens.darkBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: DesignTokens.darkBorder,
        thickness: 0.5,
        space: DesignTokens.spacingMd,
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: DesignTokens.darkCard,
        selectedItemColor: DesignTokens.darkAccent,
        unselectedItemColor: DesignTokens.darkTextSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: DesignTokens.darkAccent,
        foregroundColor: Colors.black,
        elevation: 8,
        highlightElevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
      ),

      // Navigation Rail
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: DesignTokens.darkCardSecondary,
        selectedIconTheme: IconThemeData(color: DesignTokens.darkAccent),
        unselectedIconTheme:
            IconThemeData(color: DesignTokens.darkTextSecondary),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: DesignTokens.darkCard,
        disabledColor: DesignTokens.darkNeutral,
        selectedColor: DesignTokens.darkAccent,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingMd,
          vertical: DesignTokens.spacingSm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        side: const BorderSide(color: DesignTokens.darkBorder),
      ),

      // Extensions
      extensions: [LuxuryThemeExtension.dark()],
    );
  }

  // Text Styles
  static TextStyle _displayStyle() => const TextStyle(
        fontSize: DesignTokens.fontDisplay,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle _headingLargeStyle() => const TextStyle(
        fontSize: DesignTokens.fontHeading1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.3,
      );

  static TextStyle _headingMediumStyle() => const TextStyle(
        fontSize: DesignTokens.fontHeading2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.4,
      );

  static TextStyle _headingSmallStyle() => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
      );

  static TextStyle _titleLargeStyle() => const TextStyle(
        fontSize: DesignTokens.fontHeading2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
      );

  static TextStyle _titleMediumStyle() => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.5,
      );

  static TextStyle _titleSmallStyle() => const TextStyle(
        fontSize: DesignTokens.fontBody,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.5,
      );

  static TextStyle _bodyLargeStyle() => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.5,
      );

  static TextStyle _bodyMediumStyle() => const TextStyle(
        fontSize: DesignTokens.fontBody,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.5,
      );

  static TextStyle _bodySmallStyle() => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.5,
      );

  static TextStyle _labelLargeStyle() => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.5,
      );

  static TextStyle _labelMediumStyle() => const TextStyle(
        fontSize: DesignTokens.fontCaption,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.5,
      );

  static TextStyle _labelSmallStyle() => const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.5,
      );
}

/// 🎨 LUXURY THEME EXTENSION - Custom theme data
class LuxuryThemeExtension extends ThemeExtension<LuxuryThemeExtension> {
  final bool isLight;
  final Color chatUserBubble;
  final Color chatAIBubble;
  final Color cardOverlayColor;
  final Color accentGlowColor;

  LuxuryThemeExtension({
    required this.isLight,
    required this.chatUserBubble,
    required this.chatAIBubble,
    required this.cardOverlayColor,
    required this.accentGlowColor,
  });

  factory LuxuryThemeExtension.light() => LuxuryThemeExtension(
        isLight: true,
        chatUserBubble: DesignTokens.lightAccent,
        chatAIBubble: DesignTokens.lightCard,
        cardOverlayColor: Colors.black.withOpacity(0.04),
        accentGlowColor: DesignTokens.lightAccent.withOpacity(0.2),
      );

  factory LuxuryThemeExtension.dark() => LuxuryThemeExtension(
        isLight: false,
        chatUserBubble: DesignTokens.darkAccent,
        chatAIBubble: DesignTokens.darkCard,
        cardOverlayColor: Colors.white.withOpacity(0.04),
        accentGlowColor: DesignTokens.darkAccent.withOpacity(0.2),
      );

  @override
  LuxuryThemeExtension copyWith({
    bool? isLight,
    Color? chatUserBubble,
    Color? chatAIBubble,
    Color? cardOverlayColor,
    Color? accentGlowColor,
  }) {
    return LuxuryThemeExtension(
      isLight: isLight ?? this.isLight,
      chatUserBubble: chatUserBubble ?? this.chatUserBubble,
      chatAIBubble: chatAIBubble ?? this.chatAIBubble,
      cardOverlayColor: cardOverlayColor ?? this.cardOverlayColor,
      accentGlowColor: accentGlowColor ?? this.accentGlowColor,
    );
  }

  @override
  LuxuryThemeExtension lerp(
    ThemeExtension<LuxuryThemeExtension>? other,
    double t,
  ) {
    if (other is! LuxuryThemeExtension) return this;
    return LuxuryThemeExtension(
      isLight: t < 0.5 ? isLight : other.isLight,
      chatUserBubble:
          Color.lerp(chatUserBubble, other.chatUserBubble, t) ?? chatUserBubble,
      chatAIBubble:
          Color.lerp(chatAIBubble, other.chatAIBubble, t) ?? chatAIBubble,
      cardOverlayColor:
          Color.lerp(cardOverlayColor, other.cardOverlayColor, t) ??
              cardOverlayColor,
      accentGlowColor: Color.lerp(accentGlowColor, other.accentGlowColor, t) ??
          accentGlowColor,
    );
  }
}

/// 🎨 EXTENSION - Easy access to luxury theme
extension LuxuryThemeContext on BuildContext {
  LuxuryThemeExtension get luxuryTheme =>
      Theme.of(this).extension<LuxuryThemeExtension>() ??
      LuxuryThemeExtension.light();

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get accentColor => Theme.of(this).colorScheme.primary;

  Color get surfaceColor => Theme.of(this).colorScheme.surface;

  Color get textColor =>
      isDarkMode ? DesignTokens.darkText : DesignTokens.lightText;

  Color get textSecondaryColor => isDarkMode
      ? DesignTokens.darkTextSecondary
      : DesignTokens.lightTextSecondary;
}

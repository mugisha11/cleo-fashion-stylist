/// Theme Wrapper
/// Wraps the app and applies the current theme
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme_data.dart';

class ThemeWrapper extends ConsumerWidget {
  final Widget child;
  
  const ThemeWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final flutterTheme = themeData.toThemeData();
    
    return Theme(
      data: flutterTheme,
      child: _ThemeDataInheritedWidget(
        themeData: themeData,
        child: child,
      ),
    );
  }
}

/// Inherited widget to provide theme data to descendants
class _ThemeDataInheritedWidget extends InheritedWidget {
  final AppThemeData themeData;
  
  const _ThemeDataInheritedWidget({
    required this.themeData,
    required super.child,
  });
  
  @override
  bool updateShouldNotify(_ThemeDataInheritedWidget oldWidget) {
    return themeData.mode != oldWidget.themeData.mode;
  }
  
  static AppThemeData? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ThemeDataInheritedWidget>()?.themeData;
  }
}

/// Extension to easily access theme data
extension ThemeDataExtension on BuildContext {
  AppThemeData get appTheme {
    final theme = _ThemeDataInheritedWidget.of(this);
    if (theme != null) return theme;
    
    // Fallback: try to get from provider (for cases where context doesn't have inherited widget)
    throw StateError('AppThemeData not found in context. Ensure ThemeWrapper is in the widget tree.');
  }
}

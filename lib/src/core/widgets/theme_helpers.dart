/// Theme Helper Utilities
/// Provides theme-aware widgets for dialogs, snackbars, modals, etc.
library;
import 'package:flutter/material.dart';
import 'theme_wrapper.dart';
import '../theme/app_theme_data.dart';

/// Theme-aware SnackBar helper
class ThemedSnackBar {
  static SnackBar success(BuildContext context, String message) {
    final theme = context.appTheme;
    return SnackBar(
      content: Text(
        message,
        style: theme.bodyMedium(color: Colors.white),
      ),
      backgroundColor: theme.accentSuccess,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
      ),
      margin: const EdgeInsets.all(AppThemeData.spacingMD),
    );
  }

  static SnackBar error(BuildContext context, String message) {
    final theme = context.appTheme;
    return SnackBar(
      content: Text(
        message,
        style: theme.bodyMedium(color: Colors.white),
      ),
      backgroundColor: theme.accentError,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
      ),
      margin: const EdgeInsets.all(AppThemeData.spacingMD),
    );
  }

  static SnackBar warning(BuildContext context, String message) {
    final theme = context.appTheme;
    return SnackBar(
      content: Text(
        message,
        style: theme.bodyMedium(color: Colors.white),
      ),
      backgroundColor: theme.accentWarning,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
      ),
      margin: const EdgeInsets.all(AppThemeData.spacingMD),
    );
  }

  static SnackBar info(BuildContext context, String message) {
    final theme = context.appTheme;
    return SnackBar(
      content: Text(
        message,
        style: theme.bodyMedium(color: Colors.white),
      ),
      backgroundColor: theme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
      ),
      margin: const EdgeInsets.all(AppThemeData.spacingMD),
    );
  }
}

/// Theme-aware Dialog helper
class ThemedDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
  }) {
    final theme = context.appTheme;
    
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.borderRadiusLarge),
        ),
        title: Text(
          title,
          style: theme.titleLarge(),
        ),
        content: Text(
          content,
          style: theme.bodyMedium(),
        ),
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: onCancel ?? () => Navigator.of(context).pop(),
              child: Text(
                cancelText,
                style: theme.bodyMedium(color: theme.textSecondary),
              ),
            ),
          if (confirmText != null)
            TextButton(
              onPressed: onConfirm ?? () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: isDestructive ? theme.accentError : theme.primary,
              ),
              child: Text(
                confirmText,
                style: theme.bodyMedium(
                  color: isDestructive ? theme.accentError : theme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Theme-aware Bottom Sheet helper
class ThemedBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isScrollControlled = false,
    bool showDragHandle = true,
  }) {
    final theme = context.appTheme;
    
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(theme.borderRadiusLarge),
        ),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(theme.borderRadiusLarge),
          ),
          boxShadow: theme.cardGlow != null ? [theme.cardGlow!] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDragHandle)
              Container(
                margin: const EdgeInsets.only(top: AppThemeData.spacingSM),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.all(AppThemeData.spacingMD),
                child: Text(
                  title,
                  style: theme.titleLarge(),
                ),
              ),
              Divider(color: theme.borderLight, height: 1),
            ],
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

/// Theme-aware Loading Indicator
class ThemedLoadingIndicator extends StatelessWidget {
  final String? message;
  final double? size;

  const ThemedLoadingIndicator({
    super.key,
    this.message,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? 40,
            height: size ?? 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppThemeData.spacingMD),
            Text(
              message!,
              style: theme.bodyMedium(color: theme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Theme-aware Card widget
class ThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final bool showGlow;

  const ThemedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    
    Widget card = Container(
      margin: margin ?? const EdgeInsets.all(AppThemeData.spacingMD),
      padding: padding ?? const EdgeInsets.all(AppThemeData.spacingMD),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        border: Border.all(
          color: theme.borderLight,
          width: 1,
        ),
        boxShadow: showGlow && theme.cardGlow != null
            ? [theme.cardGlow!]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        child: card,
      );
    }

    return card;
  }
}

/// Theme-aware Button helpers
class ThemedButton {
  static Widget primary({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = true,
  }) {
    final theme = context.appTheme;
    
    Widget button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppThemeData.spacingLG,
          vertical: AppThemeData.spacingMD,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.borderRadius),
        ),
        minimumSize: isFullWidth
            ? const Size(double.infinity, 48)
            : const Size(0, 48),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: AppThemeData.spacingSM),
                ],
                Text(
                  text,
                  style: theme.bodyMedium(color: Colors.white),
                ),
              ],
            ),
    );

    // Wrap with Container for glow effect if available
    if (theme.primaryGlow != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(theme.borderRadius),
          boxShadow: [theme.primaryGlow!],
        ),
        child: button,
      );
    }

    return button;
  }

  static Widget secondary({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    String? imageAsset,
    bool isFullWidth = true,
  }) {
    final theme = context.appTheme;
    
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.primary,
        side: BorderSide(color: theme.primary, width: 1),
        padding: const EdgeInsets.symmetric(
          horizontal: AppThemeData.spacingLG,
          vertical: AppThemeData.spacingMD,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.borderRadius),
        ),
        minimumSize: isFullWidth
            ? const Size(double.infinity, 48)
            : const Size(0, 48),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imageAsset != null) ...[
            Image.asset(
              imageAsset,
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to icon if image fails
                return Icon(icon ?? Icons.login, size: 20);
              },
            ),
            const SizedBox(width: AppThemeData.spacingSM),
          ] else if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: AppThemeData.spacingSM),
          ],
          Text(
            text,
            style: theme.bodyMedium(color: theme.primary),
          ),
        ],
      ),
    );
  }
}

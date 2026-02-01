import 'package:flutter/material.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/widgets/theme_wrapper.dart';

/// Action tile for settings
class SettingsActionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final IconData? leadingIcon;
  final Widget? trailing;
  final bool isDestructive;

  const SettingsActionTile({
    super.key,
    required this.title,
    this.subtitle,
    this.onTap,
    this.leadingIcon,
    this.trailing,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final accentPink = context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppThemeData.spacingMD,
        vertical: AppThemeData.spacingSM,
      ),
      leading: leadingIcon != null
          ? Icon(
              leadingIcon,
              color: isDestructive
                  ? theme.accentError
                  : accentPink,
              size: 24,
            )
          : null,
      title: Text(
        title,
        style: theme.bodyMedium().copyWith(
          color: isDestructive ? theme.accentError : theme.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: AppThemeData.spacingXS),
              child: Text(
                subtitle!,
                style: theme.bodySmall(color: theme.textSecondary),
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right,
                  color: theme.textTertiary,
                )
              : null),
      onTap: onTap,
    );
  }
}


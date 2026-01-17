import 'package:flutter/material.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';

/// Toggle tile with description
class SettingsToggleTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  const SettingsToggleTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppThemeData.spacingMD,
        vertical: AppThemeData.spacingSM,
      ),
      leading: icon != null
          ? Icon(icon, color: theme.primary, size: 24)
          : null,
      title: Text(
        title,
        style: theme.bodyMedium(),
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
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: theme.primary,
      ),
    );
  }
}


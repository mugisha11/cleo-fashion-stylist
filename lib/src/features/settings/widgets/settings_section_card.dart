import 'package:flutter/material.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';

/// Reusable section card for settings
class SettingsSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsets? padding;

  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return Container(
      margin: const EdgeInsets.only(
        left: AppThemeData.spacingMD,
        right: AppThemeData.spacingMD,
        bottom: AppThemeData.spacingLG,
      ),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        border: Border.all(
          color: theme.borderLight,
          width: 1,
        ),
        boxShadow: theme.cardGlow != null ? [theme.cardGlow!] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppThemeData.spacingMD,
              right: AppThemeData.spacingMD,
              top: AppThemeData.spacingMD,
              bottom: AppThemeData.spacingSM,
            ),
            child: Text(
              title,
              style: theme.titleLarge(),
            ),
          ),
          Divider(height: 1, color: theme.borderLight),
          Padding(
            padding: padding ?? EdgeInsets.zero,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'theme_wrapper.dart';
import '../theme/app_theme_data.dart';

/// Premium Fashion Bottom Navigation
/// Elegant, fashion-styled navigation with icons + labels
class QuoraBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const QuoraBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<BottomNavItem> items = [
    BottomNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Feed',
    ),
    BottomNavItem(
      icon: Icons.checkroom_outlined,
      activeIcon: Icons.checkroom,
      label: 'Wardrobe',
    ),
    BottomNavItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      label: 'Try-On',
    ),
    BottomNavItem(
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications,
      label: 'Alerts',
    ),
    BottomNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          top: BorderSide(
            color: theme.borderLight,
            width: 1,
          ),
        ),
        boxShadow: theme.cardGlow != null
            ? [theme.cardGlow!]
            : [
                BoxShadow(
                  color: theme.backgroundPrimary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isActive = currentIndex == index;

            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppThemeData.spacingSM,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          size: 20,
                          color: isActive
                              ? theme.primary
                              : theme.textSecondary,
                        ),
                        const SizedBox(height: AppThemeData.spacingXS),
                        Text(
                          item.label,
                          style: theme.bodySmall().copyWith(
                            color: isActive
                                ? theme.primary
                                : theme.textSecondary,
                            fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

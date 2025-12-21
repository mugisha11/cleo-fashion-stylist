import 'package:flutter/material.dart';
import '../theme/fashion_design_system.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: FashionDesignSystem.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                      vertical: FashionDesignSystem.spacingSM,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          size: FashionDesignSystem.iconSize,
                          color: isActive
                              ? FashionDesignSystem.primaryColor
                              : FashionDesignSystem.textSecondary,
                        ),
                        SizedBox(height: FashionDesignSystem.spacingXS),
                        Text(
                          item.label,
                          style: FashionDesignSystem.caption().copyWith(
                            color: isActive
                                ? FashionDesignSystem.primaryColor
                                : FashionDesignSystem.textSecondary,
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

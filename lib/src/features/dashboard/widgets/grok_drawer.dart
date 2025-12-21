import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/grok_design_system.dart';
import '../../../core/models/user_model.dart';

/// Grok-Inspired Minimal Drawer
/// Pi Network style: Slide from left, minimal, icon + label, calm animations
class GrokDrawer extends StatelessWidget {
  final String activeRoute;
  final ValueChanged<String> onNavigate;
  final VoidCallback onClose;
  final UserModel? currentUser;
  
  const GrokDrawer({
    super.key,
    required this.activeRoute,
    required this.onNavigate,
    required this.onClose,
    this.currentUser,
  });

  static const List<DrawerItem> items = [
    DrawerItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      route: '/dashboard',
    ),
    DrawerItem(
      label: 'Try-On',
      icon: Icons.checkroom_outlined,
      route: '/tryon',
    ),
    DrawerItem(
      label: 'Wardrobe',
      icon: Icons.inventory_2_outlined,
      route: '/wardrobe',
    ),
    DrawerItem(
      label: 'Calendar',
      icon: Icons.calendar_today_outlined,
      route: '/calendar',
    ),
    DrawerItem(
      label: 'Collections',
      icon: Icons.collections_outlined,
      route: '/collections',
    ),
    DrawerItem(
      label: 'Profile',
      icon: Icons.person_outline,
      route: '/profile',
    ),
    DrawerItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      route: '/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth * 0.75; // 75% of screen width

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {}, // Prevent closing when tapping drawer
              child: Container(
                width: drawerWidth,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: GrokDesignSystem.backgroundWhite,
                  boxShadow: GrokDesignSystem.cardShadow,
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      _DrawerHeader(user: currentUser),
                      const Divider(height: 1, color: GrokDesignSystem.borderLight),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            vertical: GrokDesignSystem.spacingSM,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isActive = activeRoute == item.route;
                            return _DrawerItemTile(
                              item: item,
                              isActive: isActive,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                onNavigate(item.route);
                                onClose();
                              },
                            ).animate(delay: (index * 30).ms)
                             .fadeIn(duration: GrokDesignSystem.animationFast)
                             .slideX(begin: -0.1, duration: GrokDesignSystem.animationFast);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: onClose,
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Drawer item model
class DrawerItem {
  final String label;
  final IconData icon;
  final String route;

  const DrawerItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

/// Minimal user profile header
class _DrawerHeader extends StatelessWidget {
  final UserModel? user;

  const _DrawerHeader({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GrokDesignSystem.spacingLG),
      decoration: const BoxDecoration(
        color: GrokDesignSystem.backgroundOffWhite,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GrokDesignSystem.backgroundLightGray,
              border: Border.all(
                color: GrokDesignSystem.borderLight,
                width: 1,
              ),
            ),
            child: user?.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      user!.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                    ),
                  )
                : _buildDefaultAvatar(),
          ),
          const SizedBox(width: GrokDesignSystem.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'User',
                  style: GrokDesignSystem.headlineSmall(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'user@styleapp.com',
                  style: GrokDesignSystem.bodySmall(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: GrokDesignSystem.animationMedium);
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: GrokDesignSystem.primaryCharcoal,
      ),
      child: const Icon(
        Icons.person,
        color: GrokDesignSystem.textInverse,
        size: 24,
      ),
    );
  }
}

/// Minimal drawer navigation item tile
class _DrawerItemTile extends StatelessWidget {
  final DrawerItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerItemTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isActive
        ? GrokDesignSystem.primaryCharcoal
        : GrokDesignSystem.textSecondary;
    final textColor = isActive
        ? GrokDesignSystem.textPrimary
        : GrokDesignSystem.textSecondary;
    final bgColor = isActive
        ? GrokDesignSystem.backgroundLightGray
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GrokDesignSystem.spacingMD,
        vertical: GrokDesignSystem.spacingXS,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GrokDesignSystem.radiusMD),
          child: AnimatedContainer(
            duration: GrokDesignSystem.animationFast,
            curve: GrokDesignSystem.defaultCurve,
            padding: const EdgeInsets.symmetric(
              horizontal: GrokDesignSystem.spacingMD,
              vertical: GrokDesignSystem.spacingMD,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(GrokDesignSystem.radiusMD),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: GrokDesignSystem.iconSize,
                  color: iconColor,
                ),
                const SizedBox(width: GrokDesignSystem.spacingMD),
                Expanded(
                  child: Text(
                    item.label,
                    style: GrokDesignSystem.bodyMedium().copyWith(
                      color: textColor,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


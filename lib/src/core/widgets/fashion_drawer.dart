import 'package:flutter/material.dart';
import 'theme_wrapper.dart';
import '../theme/app_theme_data.dart';
import '../../routes.dart';

/// Global Fashion Drawer/Sidebar
/// Elegant navigation drawer with fashion-style design
class FashionDrawer extends StatelessWidget {
  final String? userName;
  final String? userEmail;
  final String? profileImageUrl;
  final String? currentRoute;
  final Function(String route)? onNavigate;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogout;

  const FashionDrawer({
    super.key,
    this.userName,
    this.userEmail,
    this.profileImageUrl,
    this.currentRoute,
    this.onNavigate,
    this.onProfileTap,
    this.onLogout,
  });

  static final List<DrawerItem> items = [
    DrawerItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Dashboard',
      route: Routes.dashboard,
    ),
    DrawerItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      label: 'Virtual Try-On',
      route: Routes.tryon,
    ),
    DrawerItem(
      icon: Icons.checkroom_outlined,
      activeIcon: Icons.checkroom,
      label: 'Digital Wardrobe',
      route: Routes.wardrobe,
    ),
    DrawerItem(
      icon: Icons.star_outline,
      activeIcon: Icons.star,
      label: 'AI Recommendations',
      route: Routes.recommendations,
    ),
    DrawerItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Calendar',
      route: Routes.calendar,
    ),
    DrawerItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
      route: Routes.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return Drawer(
      backgroundColor: theme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // User Profile Header
            _buildUserHeader(context, theme),
            
            Divider(
              color: theme.borderLight,
              height: 1,
            ),
            
            // Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: items.map((item) {
                  final isActive = currentRoute == item.route;
                  return _buildDrawerItem(
                    context,
                    item: item,
                    isActive: isActive,
                    theme: theme,
                  );
                }).toList(),
              ),
            ),
            
            // Logout Button
            if (onLogout != null) ...[
              Divider(
                color: theme.borderLight,
                height: 1,
              ),
              Padding(
                padding: const EdgeInsets.all(AppThemeData.spacingLG),
                child: TextButton.icon(
                  onPressed: onLogout,
                  icon: Icon(
                    Icons.logout,
                    size: 20,
                    color: theme.accentError,
                  ),
                  label: Text(
                    'Logout',
                    style: theme.bodyMedium(color: theme.accentError),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppThemeData.spacingLG,
                      vertical: AppThemeData.spacingMD,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppThemeData.spacingXXL),
      child: GestureDetector(
        onTap: onProfileTap,
        child: Row(
          children: [
            // Profile Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.borderLight,
                  width: 2,
                ),
                image: profileImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(profileImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: profileImageUrl == null
                  ? Icon(
                      Icons.person,
                      size: 24,
                      color: theme.textSecondary,
                    )
                  : null,
            ),
            
            const SizedBox(width: AppThemeData.spacingLG),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName ?? 'Fashion Enthusiast',
                    style: theme.titleLarge(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (userEmail != null) ...[
                    const SizedBox(height: AppThemeData.spacingXS),
                    Text(
                      userEmail!,
                      style: theme.bodySmall(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required DrawerItem item,
    required bool isActive,
    required AppThemeData theme,
  }) {
    return ListTile(
      leading: Icon(
        isActive ? item.activeIcon : item.icon,
        size: 20,
        color: isActive
            ? theme.primary
            : theme.textSecondary,
      ),
      title: Text(
        item.label,
        style: theme.bodyMedium().copyWith(
          color: isActive
              ? theme.primary
              : theme.textPrimary,
          fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
      selected: isActive,
      selectedTileColor: theme.primary.withValues(alpha: 0.1),
      onTap: () {
        Navigator.of(context).pop(); // Close drawer
        if (onNavigate != null) {
          onNavigate!(item.route);
        }
      },
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppThemeData.spacingXXL,
        vertical: AppThemeData.spacingSM,
      ),
    );
  }
}

class DrawerItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const DrawerItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

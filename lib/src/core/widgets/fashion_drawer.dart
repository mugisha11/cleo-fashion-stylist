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
    const DrawerItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
      route: Routes.dashboard,
    ),
    const DrawerItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      label: 'Try On',
      route: Routes.tryon,
    ),
    const DrawerItem(
      icon: Icons.checkroom_outlined,
      activeIcon: Icons.checkroom,
      label: 'My Closet',
      route: Routes.wardrobe,
    ),
    const DrawerItem(
      icon: Icons.star_outline,
      activeIcon: Icons.star,
      label: 'Picks for You',
      route: Routes.recommendations,
    ),
    const DrawerItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Calendar',
      route: Routes.calendar,
    ),
    const DrawerItem(
      icon: Icons.grid_view_rounded,
      activeIcon: Icons.grid_view_rounded,
      label: 'Style Feed',
      route: Routes.styleFeed,
    ),
    const DrawerItem(
      icon: Icons.photo_library_outlined,
      activeIcon: Icons.photo_library,
      label: 'My Outfits',
      route: Routes.generatedOutfits,
    ),
    const DrawerItem(
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
            // Cleo Fashion header (same as all sidebars)
            _buildCleoHeader(context, theme),
            Divider(
              color: theme.borderLight,
              height: 1,
            ),
            // User Profile
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
                    'Sign out',
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

  Widget _buildCleoHeader(BuildContext context, AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cleo Fashion',
            style: theme.titleLarge().copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your style companion',
            style: theme.bodySmall(),
          ),
        ],
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
            // Profile Avatar (with fallback for failed URLs e.g. expired ReadyPlayerMe)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.borderLight,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: profileImageUrl != null
                  ? Image.network(
                      profileImageUrl!,
                      fit: BoxFit.cover,
                      width: 56,
                      height: 56,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: 24,
                        color: theme.textSecondary,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 24,
                      color: theme.textSecondary,
                    ),
            ),
            
            const SizedBox(width: AppThemeData.spacingLG),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName ?? 'Style Lover',
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

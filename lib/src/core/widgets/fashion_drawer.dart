import 'package:flutter/material.dart';
import '../theme/fashion_design_system.dart';

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

  static const List<DrawerItem> items = [
    DrawerItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    DrawerItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      label: 'Virtual Try-On',
      route: '/tryon',
    ),
    DrawerItem(
      icon: Icons.checkroom_outlined,
      activeIcon: Icons.checkroom,
      label: 'Digital Wardrobe',
      route: '/wardrobe',
    ),
    DrawerItem(
      icon: Icons.star_outline,
      activeIcon: Icons.star,
      label: 'AI Recommendations',
      route: '/recommendations',
    ),
    DrawerItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Calendar',
      route: '/calendar',
    ),
    DrawerItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
      route: '/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: FashionDesignSystem.backgroundWhite,
      child: SafeArea(
        child: Column(
          children: [
            // User Profile Header
            _buildUserHeader(context),
            
            Divider(
              color: FashionDesignSystem.dividerColor,
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
                  );
                }).toList(),
              ),
            ),
            
            // Logout Button
            if (onLogout != null) ...[
              Divider(
                color: FashionDesignSystem.dividerColor,
                height: 1,
              ),
              Padding(
                padding: EdgeInsets.all(FashionDesignSystem.spacingLG),
                child: TextButton.icon(
                  onPressed: onLogout,
                  icon: Icon(
                    Icons.logout,
                    size: FashionDesignSystem.iconSize,
                    color: FashionDesignSystem.errorColor,
                  ),
                  label: Text(
                    'Logout',
                    style: FashionDesignSystem.bodyMedium().copyWith(
                      color: FashionDesignSystem.errorColor,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: FashionDesignSystem.spacingLG,
                      vertical: FashionDesignSystem.spacingMD,
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

  Widget _buildUserHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(FashionDesignSystem.spacingXXL),
      child: GestureDetector(
        onTap: onProfileTap,
        child: Row(
          children: [
            // Profile Avatar
            Container(
              width: FashionDesignSystem.avatarSizeLarge,
              height: FashionDesignSystem.avatarSizeLarge,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: FashionDesignSystem.borderColor,
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
                      size: FashionDesignSystem.iconSizeLarge,
                      color: FashionDesignSystem.textSecondary,
                    )
                  : null,
            ),
            
            SizedBox(width: FashionDesignSystem.spacingLG),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName ?? 'Fashion Enthusiast',
                    style: FashionDesignSystem.titleLarge(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (userEmail != null) ...[
                    SizedBox(height: FashionDesignSystem.spacingXS),
                    Text(
                      userEmail!,
                      style: FashionDesignSystem.bodySmall(),
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
  }) {
    return ListTile(
      leading: Icon(
        isActive ? item.activeIcon : item.icon,
        size: FashionDesignSystem.iconSize,
        color: isActive
            ? FashionDesignSystem.primaryColor
            : FashionDesignSystem.textSecondary,
      ),
      title: Text(
        item.label,
        style: FashionDesignSystem.bodyMedium().copyWith(
          color: isActive
              ? FashionDesignSystem.primaryColor
              : FashionDesignSystem.textCharcoal,
          fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
      selected: isActive,
      selectedTileColor: FashionDesignSystem.primaryColor.withOpacity(0.1),
      onTap: () {
        Navigator.of(context).pop(); // Close drawer
        if (onNavigate != null) {
          onNavigate!(item.route);
        }
      },
      contentPadding: EdgeInsets.symmetric(
        horizontal: FashionDesignSystem.spacingXXL,
        vertical: FashionDesignSystem.spacingSM,
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

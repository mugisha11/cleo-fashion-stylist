import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/cleo_drawer_theme.dart';
import '../../../core/models/user_model.dart';

/// Premium mobile drawer navigation for Cleo Fashion App
/// Inspired by Pi Network, Canva, and Discord mobile drawers
class CleoMobileDrawer extends StatelessWidget {
  final String activeRoute;
  final ValueChanged<String> onNavigate;
  final VoidCallback onClose;
  final UserModel? currentUser;
  
  const CleoMobileDrawer({
    super.key,
    required this.activeRoute,
    required this.onNavigate,
    required this.onClose,
    this.currentUser,
  });

  static const List<DrawerItem> items = [
    DrawerItem(
      label: 'Dashboard',
      icon: Icons.dashboard_rounded,
      route: '/dashboard',
    ),
    DrawerItem(
      label: 'AI Stylist Chat',
      icon: Icons.chat_bubble_rounded,
      route: '/ai-chat',
    ),
    DrawerItem(
      label: 'My Outfits',
      icon: Icons.collections_bookmark_rounded,
      route: '/outfits',
    ),
    DrawerItem(
      label: 'Digital Wardrobe',
      icon: Icons.checkroom_rounded,
      route: '/wardrobe',
    ),
    DrawerItem(
      label: 'Daily Recommendations',
      icon: Icons.star_rounded,
      route: '/recommendations',
    ),
    DrawerItem(
      label: 'Calendar Planner',
      icon: Icons.calendar_month_rounded,
      route: '/planner',
    ),
    DrawerItem(
      label: 'Event Look Planner',
      icon: Icons.event_available_rounded,
      route: '/events',
    ),
    DrawerItem(
      label: 'Settings',
      icon: Icons.settings_rounded,
      route: '/settings',
    ),
    DrawerItem(
      label: 'Logout',
      icon: Icons.logout_rounded,
      route: '/logout',
      isDestructive: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth * CleoDrawerTheme.drawerWidthPercent;

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {}, // Prevent closing when tapping drawer
              child: Container(
                width: drawerWidth,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: CleoDrawerTheme.surfaceWhite,
                  boxShadow: CleoDrawerTheme.drawerShadow,
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      _DrawerHeader(user: currentUser),
                      const Divider(height: 1, color: CleoDrawerTheme.dividerColor),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            vertical: CleoDrawerTheme.spacingSM,
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
                             .fadeIn(duration: 200.ms)
                             .slideX(begin: -0.1, duration: 200.ms);
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
  final bool isDestructive;

  const DrawerItem({
    required this.label,
    required this.icon,
    required this.route,
    this.isDestructive = false,
  });
}

/// Premium user profile header
class _DrawerHeader extends StatelessWidget {
  final UserModel? user;

  const _DrawerHeader({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: CleoDrawerTheme.headerHeight,
      padding: const EdgeInsets.all(CleoDrawerTheme.spacingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CleoDrawerTheme.primaryNavy,
            CleoDrawerTheme.primaryNavy.withOpacity(0.85),
            CleoDrawerTheme.secondaryLavender.withOpacity(0.3),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CleoDrawerTheme.surfaceWhite.withOpacity(0.2),
                  border: Border.all(
                    color: CleoDrawerTheme.surfaceWhite.withOpacity(0.3),
                    width: 2,
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
              const SizedBox(width: CleoDrawerTheme.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Fashion Enthusiast',
                      style: CleoDrawerTheme.headerTitleStyle.copyWith(
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'user@cleofashion.com',
                      style: CleoDrawerTheme.headerSubtitleStyle.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: CleoDrawerTheme.spacingMD,
              vertical: CleoDrawerTheme.spacingSM,
            ),
            decoration: BoxDecoration(
              color: CleoDrawerTheme.accentTeal.withOpacity(0.2),
              borderRadius: BorderRadius.circular(CleoDrawerTheme.radiusSM),
              border: Border.all(
                color: CleoDrawerTheme.accentTeal.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: CleoDrawerTheme.accentTeal,
                ),
                const SizedBox(width: 6),
                Text(
                  'Premium Member',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CleoDrawerTheme.accentTeal,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, duration: 300.ms);
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CleoDrawerTheme.secondaryLavender,
            CleoDrawerTheme.accentTeal,
          ],
        ),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 32,
      ),
    );
  }
}

/// Premium drawer navigation item tile
class _DrawerItemTile extends StatefulWidget {
  final DrawerItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerItemTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_DrawerItemTile> createState() => _DrawerItemTileState();
}

class _DrawerItemTileState extends State<_DrawerItemTile> {
  @override
  Widget build(BuildContext context) {
    final isDestructive = widget.item.isDestructive;
    final iconColor = widget.isActive
        ? (isDestructive ? Colors.red.shade600 : CleoDrawerTheme.primaryNavy)
        : (isDestructive ? Colors.red.shade400 : CleoDrawerTheme.textSecondary);
    final textColor = widget.isActive
        ? (isDestructive ? Colors.red.shade600 : CleoDrawerTheme.textPrimary)
        : (isDestructive ? Colors.red.shade400 : CleoDrawerTheme.textPrimary);
    final bgColor = widget.isActive
        ? (isDestructive
            ? Colors.red.shade50
            : CleoDrawerTheme.primaryNavy.withOpacity(0.08))
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CleoDrawerTheme.spacingMD,
        vertical: CleoDrawerTheme.spacingXS,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(CleoDrawerTheme.radiusMD),
          child: AnimatedContainer(
            duration: CleoDrawerTheme.itemAnimationDuration,
            curve: Curves.easeOut,
            height: CleoDrawerTheme.itemHeight,
            padding: const EdgeInsets.symmetric(
              horizontal: CleoDrawerTheme.itemPadding,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(CleoDrawerTheme.radiusMD),
              border: widget.isActive
                  ? Border.all(
                      color: isDestructive
                          ? Colors.red.shade200
                          : CleoDrawerTheme.primaryNavy.withOpacity(0.2),
                      width: 1.5,
                    )
                  : null,
              boxShadow: widget.isActive ? CleoDrawerTheme.itemShadow : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? (isDestructive
                            ? Colors.red.shade50
                            : CleoDrawerTheme.primaryNavy.withOpacity(0.1))
                        : CleoDrawerTheme.surfaceOffWhite,
                    borderRadius: BorderRadius.circular(CleoDrawerTheme.radiusSM),
                  ),
                  child: Icon(
                    widget.item.icon,
                    size: CleoDrawerTheme.itemIconSize,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: CleoDrawerTheme.spacingMD),
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: widget.isActive
                        ? CleoDrawerTheme.itemLabelActiveStyle.copyWith(
                            color: textColor,
                          )
                        : CleoDrawerTheme.itemLabelStyle.copyWith(
                            color: textColor,
                          ),
                  ),
                ),
                if (widget.isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isDestructive
                          ? Colors.red.shade600
                          : CleoDrawerTheme.accentTeal,
                      shape: BoxShape.circle,
                    ),
                  ).animate().scale(duration: 200.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


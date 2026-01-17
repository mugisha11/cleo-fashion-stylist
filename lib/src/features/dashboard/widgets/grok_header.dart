import 'package:flutter/material.dart';
import '../../../core/theme/grok_design_system.dart';
import '../../../core/widgets/cleo_logo.dart';
import '../../../routes.dart';
import 'animated_notification_icon.dart';

/// Grok-Inspired Professional Header
/// Single row, never wraps, mobile-optimized
/// App name/logo (left) | Notification | Settings | Profile avatar (right)
class GrokHeader extends StatelessWidget {
  final String? appName;
  final String? userAvatarUrl;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onMenuTap;

  const GrokHeader({
    super.key,
    this.appName,
    this.userAvatarUrl,
    this.onProfileTap,
    this.onNotificationsTap,
    this.onSettingsTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      height: GrokDesignSystem.headerHeight,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? GrokDesignSystem.spacingMD : GrokDesignSystem.spacingLG,
      ),
      decoration: const BoxDecoration(
        color: GrokDesignSystem.backgroundWhite,
        border: Border(
          bottom: BorderSide(
            color: GrokDesignSystem.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Menu button (mobile only)
          if (isMobile && onMenuTap != null) ...[
            _buildIconButton(
              icon: Icons.menu,
              onTap: onMenuTap!,
            ),
            SizedBox(width: GrokDesignSystem.spacingSM),
          ],
          
          // App name/logo (left)
          Expanded(
            child: Row(
              children: [
                const CleoLogo.small(
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
                if (appName != null) ...[
                  SizedBox(width: GrokDesignSystem.spacingSM),
                  Text(
                    appName!,
                    style: GrokDesignSystem.headlineSmall(isMobile: isMobile),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // Notification icon (animated, with real-time badge)
          AnimatedNotificationIcon(
            onTap: onNotificationsTap ?? () {},
          ),
          
          SizedBox(width: GrokDesignSystem.spacingSM),
          
          // Settings icon
          _buildIconButton(
            icon: Icons.settings_outlined,
            onTap: onSettingsTap ?? () {
              Navigator.of(context).pushNamed(Routes.settings);
            },
          ),
          
          SizedBox(width: GrokDesignSystem.spacingSM),
          
          // Circular profile avatar (right)
          _buildProfileAvatar(),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    int? badge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GrokDesignSystem.radiusSM),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: GrokDesignSystem.backgroundLightGray,
            borderRadius: BorderRadius.circular(GrokDesignSystem.radiusSM),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  icon,
                  size: GrokDesignSystem.iconSize,
                  color: GrokDesignSystem.textPrimary,
                ),
              ),
              if (badge != null && badge > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: GrokDesignSystem.accentBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onProfileTap ?? () {
          Navigator.of(context).pushNamed(Routes.settings);
        },
        borderRadius: BorderRadius.circular(GrokDesignSystem.radiusLG),
        child: Container(
          width: GrokDesignSystem.avatarSize,
          height: GrokDesignSystem.avatarSize,
          decoration: BoxDecoration(
            color: GrokDesignSystem.backgroundLightGray,
            shape: BoxShape.circle,
            border: Border.all(
              color: GrokDesignSystem.borderLight,
              width: 1,
            ),
          ),
          child: userAvatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    userAvatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                  ),
                )
              : _buildDefaultAvatar(),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        color: GrokDesignSystem.primaryCharcoal,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        color: GrokDesignSystem.textInverse,
        size: 18,
      ),
    );
  }
}


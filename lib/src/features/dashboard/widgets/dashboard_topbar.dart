import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/dashboard_design_system.dart';
import '../../../routes.dart';

/// Dashboard Top Bar with Profile and Quick Actions
class DashboardTopBar extends StatelessWidget {
  final String? userName;
  final String? userAvatarUrl;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSettingsTap;

  const DashboardTopBar({
    super.key,
    this.userName,
    this.userAvatarUrl,
    this.onProfileTap,
    this.onNotificationsTap,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? DashboardDesignSystem.spacingMD
            : DashboardDesignSystem.spacingLG,
      ),
      decoration: BoxDecoration(
        color: DashboardDesignSystem.sidebarBackground,
        border: Border(
          bottom: BorderSide(
            color: DashboardDesignSystem.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Search Bar (Desktop only)
          if (!isMobile) ...[
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(
                  horizontal: DashboardDesignSystem.spacingMD,
                ),
                decoration: BoxDecoration(
                  color: DashboardDesignSystem.surfaceOffWhite,
                  borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusMD),
                  border: Border.all(
                    color: DashboardDesignSystem.borderLight,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 20,
                      color: DashboardDesignSystem.textSecondary,
                    ),
                    const SizedBox(width: DashboardDesignSystem.spacingSM),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search outfits, styles, wardrobe...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: DashboardDesignSystem.textSecondary,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: DashboardDesignSystem.textCharcoal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: DashboardDesignSystem.spacingLG),
          ],
          
          // Quick Actions
          _buildActionButton(
            icon: Icons.notifications_outlined,
            onTap: onNotificationsTap ?? () {},
            badge: 3,
          ),
          const SizedBox(width: DashboardDesignSystem.spacingSM),
          _buildActionButton(
            icon: Icons.settings_outlined,
            onTap: onSettingsTap ?? () {
              Navigator.of(context).pushNamed(Routes.settings);
            },
          ),
          const SizedBox(width: DashboardDesignSystem.spacingMD),
          
          // Profile
          _buildProfileSection(isMobile),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    int? badge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusMD),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: DashboardDesignSystem.surfaceOffWhite,
            borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusMD),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  icon,
                  size: 20,
                  color: DashboardDesignSystem.textSecondary,
                ),
              ),
              if (badge != null && badge > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: DashboardDesignSystem.accentTeal,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DashboardDesignSystem.sidebarBackground,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(bool isMobile) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onProfileTap ?? () {
          Navigator.of(context).pushNamed(Routes.settings);
        },
        borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusMD),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DashboardDesignSystem.spacingSM,
            vertical: DashboardDesignSystem.spacingXS,
          ),
          decoration: BoxDecoration(
            color: DashboardDesignSystem.surfaceOffWhite,
            borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusMD),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: DashboardDesignSystem.secondaryLavender,
                backgroundImage: userAvatarUrl != null
                    ? NetworkImage(userAvatarUrl!)
                    : null,
                child: userAvatarUrl == null
                    ? Icon(
                        Icons.person,
                        size: 18,
                        color: Colors.white,
                      )
                    : null,
              ),
              if (!isMobile) ...[
                const SizedBox(width: DashboardDesignSystem.spacingSM),
                Text(
                  userName ?? 'User',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DashboardDesignSystem.textCharcoal,
                  ),
                ),
                const SizedBox(width: DashboardDesignSystem.spacingXS),
                Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: DashboardDesignSystem.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}



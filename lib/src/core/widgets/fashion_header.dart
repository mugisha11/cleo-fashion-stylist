import 'package:flutter/material.dart';
import 'theme_wrapper.dart';
import 'nikonyx_logo.dart';
import '../theme/app_theme_data.dart';
import '../../routes.dart';

/// Global Fashion Header
/// Consistent header across ALL pages with title, notifications, and profile
class FashionHeader extends StatelessWidget {
  final String? title;
  final String? greeting;
  final int? notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final String? profileImageUrl;
  final bool showMenuIcon;
  final VoidCallback? onMenuTap;

  const FashionHeader({
    super.key,
    this.title,
    this.greeting,
    this.notificationCount,
    this.onNotificationTap,
    this.onProfileTap,
    this.profileImageUrl,
    this.showMenuIcon = false,
    this.onMenuTap,
  });

  String _getDefaultGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final displayText = title ?? greeting ?? _getDefaultGreeting();
    
    return Container(
      height: 64, // Fixed height - never changes
      padding: const EdgeInsets.symmetric(
        horizontal: AppThemeData.spacingLG,
        vertical: AppThemeData.spacingMD,
      ),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Menu icon (optional, for drawer)
          if (showMenuIcon)
            IconButton(
              icon: Icon(
                Icons.menu,
                size: 20,
                color: theme.textPrimary,
              ),
              onPressed: onMenuTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (showMenuIcon) const SizedBox(width: AppThemeData.spacingMD),
          
          // Logo
          const NikonyxLogo.small(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(width: AppThemeData.spacingSM),
          
          // Title/Greeting (flexible, can be empty)
          if (displayText.isNotEmpty) ...[
            Expanded(
              child: Text(
                displayText,
                style: theme.titleLarge(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            const Spacer(),
          ],
          
          // Spacer
          const SizedBox(width: AppThemeData.spacingMD),
          
          // Notification icon with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: theme.textPrimary,
                ),
                onPressed: onNotificationTap ?? () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              if (notificationCount != null && notificationCount! > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      shape: BoxShape.circle,
                      boxShadow: theme.primaryGlow != null ? [theme.primaryGlow!] : null,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      notificationCount! > 9 ? '9+' : '${notificationCount!}',
                      style: theme.bodySmall(color: Colors.white).copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(width: AppThemeData.spacingMD),
          
          // Profile avatar
          GestureDetector(
            onTap: onProfileTap ?? () {
              Navigator.of(context).pushNamed(Routes.settings);
            },
            child: Container(
              width: 40,
              height: 40,
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
                      width: 40,
                      height: 40,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: 20,
                        color: theme.textSecondary,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 20,
                      color: theme.textSecondary,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

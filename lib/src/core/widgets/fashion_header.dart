import 'package:flutter/material.dart';
import '../theme/fashion_design_system.dart';

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
    final displayText = title ?? greeting ?? _getDefaultGreeting();
    
    return Container(
      height: 64, // Fixed height - never changes
      padding: EdgeInsets.symmetric(
        horizontal: FashionDesignSystem.spacingLG,
        vertical: FashionDesignSystem.spacingMD,
      ),
      decoration: BoxDecoration(
        color: FashionDesignSystem.backgroundWhite,
        border: Border(
          bottom: BorderSide(
            color: FashionDesignSystem.dividerColor,
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
                size: FashionDesignSystem.iconSize,
                color: FashionDesignSystem.textCharcoal,
              ),
              onPressed: onMenuTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (showMenuIcon) SizedBox(width: FashionDesignSystem.spacingMD),
          
          // Title/Greeting (flexible, can be empty)
          if (displayText.isNotEmpty) ...[
            Expanded(
              child: Text(
                displayText,
                style: FashionDesignSystem.headlineSmall(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            const Spacer(),
          ],
          
          // Spacer
          SizedBox(width: FashionDesignSystem.spacingMD),
          
          // Notification icon with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  size: FashionDesignSystem.iconSize,
                  color: FashionDesignSystem.textCharcoal,
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
                      color: FashionDesignSystem.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      notificationCount! > 9 ? '9+' : '${notificationCount!}',
                      style: FashionDesignSystem.caption().copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(width: FashionDesignSystem.spacingMD),
          
          // Profile avatar
          GestureDetector(
            onTap: onProfileTap ?? () {},
            child: Container(
              width: FashionDesignSystem.avatarSize,
              height: FashionDesignSystem.avatarSize,
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
                      size: FashionDesignSystem.iconSize,
                      color: FashionDesignSystem.textSecondary,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

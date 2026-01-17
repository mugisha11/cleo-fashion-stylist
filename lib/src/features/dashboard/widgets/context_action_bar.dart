/// Context Action Bar
/// Top-right status, notifications, profile
import 'package:flutter/material.dart';
import '../../../core/theme/executive_blue_theme.dart';

class ContextActionBar extends StatelessWidget {
  final int? notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final String? profileImageUrl;
  final bool isAIReady;

  const ContextActionBar({
    super.key,
    this.notificationCount,
    this.onNotificationTap,
    this.onProfileTap,
    this.profileImageUrl,
    this.isAIReady = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ExecutiveBlueTheme.spacingLG,
        vertical: ExecutiveBlueTheme.spacingMD,
      ),
      decoration: BoxDecoration(
        color: ExecutiveBlueTheme.backgroundPrimary,
        border: Border(
          bottom: BorderSide(
            color: ExecutiveBlueTheme.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // AI Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ExecutiveBlueTheme.spacingMD,
              vertical: ExecutiveBlueTheme.spacingSM,
            ),
            decoration: BoxDecoration(
              color: isAIReady
                  ? ExecutiveBlueTheme.accentSuccess.withValues(alpha: 0.1)
                  : ExecutiveBlueTheme.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isAIReady
                        ? ExecutiveBlueTheme.accentSuccess
                        : ExecutiveBlueTheme.accentWarning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: ExecutiveBlueTheme.spacingSM),
                Text(
                  isAIReady ? 'AI Ready' : 'Processing',
                  style: ExecutiveBlueTheme.bodySmall(
                    color: isAIReady
                        ? ExecutiveBlueTheme.accentSuccess
                        : ExecutiveBlueTheme.accentWarning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: ExecutiveBlueTheme.spacingMD),
          
          // Notifications
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onNotificationTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(ExecutiveBlueTheme.spacingSM),
                child: Stack(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 24,
                      color: ExecutiveBlueTheme.textSecondary,
                    ),
                    if (notificationCount != null && notificationCount! > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: ExecutiveBlueTheme.accentError,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: ExecutiveBlueTheme.spacingSM),
          
          // Profile
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ExecutiveBlueTheme.borderLight,
                    width: 1,
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
                        size: 20,
                        color: ExecutiveBlueTheme.textSecondary,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

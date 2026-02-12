/// Card for a single Firestore social notification (friend_request, new_message, post_liked, etc.)
library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../models/social_notification_model.dart';
import 'package:intl/intl.dart';

class SocialNotificationCard extends StatelessWidget {
  final SocialNotificationModel notification;
  final VoidCallback? onTap;

  const SocialNotificationCard({
    super.key,
    required this.notification,
    this.onTap,
  });

  String get _title {
    final name = notification.fromUserName ?? 'Someone';
    switch (notification.type) {
      case 'friend_request':
        return '$name sent you a friend request';
      case 'request_accepted':
        return '$name accepted your friend request';
      case 'new_message':
        return name;
      case 'post_liked':
        return '$name liked your look';
      case 'post_comment':
        return '$name commented on your look';
      case 'tryon_shared':
        return '$name shared a try-on with you';
      case 'tryon_completed':
        return 'Try-on complete';
      default:
        return name;
    }
  }

  String get _message {
    switch (notification.type) {
      case 'friend_request':
        return 'Tap to accept or decline';
      case 'request_accepted':
        return 'You are now friends';
      case 'new_message':
        return notification.messagePreview ?? 'New message';
      case 'post_liked':
        return 'Tap to view';
      case 'post_comment':
        return notification.messagePreview ?? 'New comment';
      case 'tryon_shared':
        return notification.messagePreview ?? 'Try-on shared';
      case 'tryon_completed':
        return notification.messagePreview ?? 'Your try-on is ready!';
      default:
        return notification.messagePreview ?? '';
    }
  }

  IconData get _icon {
    switch (notification.type) {
      case 'friend_request':
        return Icons.person_add_rounded;
      case 'request_accepted':
        return Icons.check_circle_rounded;
      case 'new_message':
        return Icons.chat_bubble_rounded;
      case 'post_liked':
        return Icons.favorite_rounded;
      case 'post_comment':
        return Icons.comment_rounded;
      case 'tryon_shared':
        return Icons.photo_camera_rounded;
      case 'tryon_completed':
        return Icons.check_circle_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final accent = isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    final surface = isDark ? DesignTokens.darkSurface : DesignTokens.lightSurface;
    final textColor = isDark ? DesignTokens.darkText : DesignTokens.lightText;
    final textSecondary = isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary;
    final isUnread = !notification.read;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUnread ? accent.withValues(alpha: isDark ? 0.12 : 0.08) : surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnread ? accent.withValues(alpha: 0.4) : (isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.25 : 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    if (_message.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(notification.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: textSecondary),
                    ),
                  ],
                ),
              ),
              if (notification.imageUrl != null && notification.imageUrl!.startsWith('http')) ...[
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: notification.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: surface, width: 48, height: 48),
                    errorWidget: (_, __, ___) => Container(color: surface, width: 48, height: 48),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dateTime);
  }
}

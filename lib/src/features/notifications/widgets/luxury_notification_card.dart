/// Luxury Notification Card
/// Glassmorphic notification card with smooth animations
library;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../theme/calendar_theme.dart';
import 'package:intl/intl.dart';

class LuxuryNotificationCard extends StatefulWidget {
  final FashionNotification notification;
  final VoidCallback? onTap;

  const LuxuryNotificationCard({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  State<LuxuryNotificationCard> createState() => _LuxuryNotificationCardState();
}

class _LuxuryNotificationCardState extends State<LuxuryNotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CalendarTheme.fastAnimation,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getAccentColor() {
    final hex = widget.notification.accentColor ?? '#6B7280';
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor();
    final isUnread = widget.notification.state == NotificationState.unread;

    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: CalendarTheme.glassCard.copyWith(
            color: isUnread
                ? accentColor.withOpacity(0.05)
                : CalendarTheme.glassBackground,
            border: Border.all(
              color: isUnread
                  ? accentColor.withOpacity(0.3)
                  : CalendarTheme.glassBorder,
              width: isUnread ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor,
                      accentColor.withOpacity(0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.notification.iconEmoji ?? '🔔',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.notification.title,
                              style: CalendarTheme.headlineText().copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.notification.message,
                        style: CalendarTheme.bodyText().copyWith(
                          fontSize: 14,
                          color: FashionDesignSystem.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(widget.notification.createdAt),
                        style: CalendarTheme.captionText(
                          color: FashionDesignSystem.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Image preview (if available)
              if (widget.notification.imageUrl != null)
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: CalendarTheme.softShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: widget.notification.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: FashionDesignSystem.backgroundLight,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: FashionDesignSystem.backgroundLight,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}

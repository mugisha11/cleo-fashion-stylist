/// Premium Notification Card Widget
/// Fashion-styled card with smooth animations
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/theme/grok_design_system.dart';

class NotificationCard extends StatefulWidget {
  final FashionNotification notification;
  final int index; // For stagger animation
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final VoidCallback? onSave;

  const NotificationCard({
    super.key,
    required this.notification,
    this.index = 0,
    this.onTap,
    this.onDismiss,
    this.onSave,
  });

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _expandController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    setState(() => _isExpanded = true);
    _expandController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        widget.onTap?.call();
      });
    });
  }

  Color _getAccentColor() {
    final hex = widget.notification.accentColor ?? widget.notification.type.accentColorHex;
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  bool get _isUnread => widget.notification.state == NotificationState.unread;

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor();
    final isMobile = MediaQuery.of(context).size.width < 768;

    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: EdgeInsets.only(
            bottom: GrokDesignSystem.spacingSM,
            left: GrokDesignSystem.spacingMD,
            right: GrokDesignSystem.spacingMD,
          ),
          decoration: BoxDecoration(
            color: _isUnread
                ? GrokDesignSystem.backgroundWhite
                : GrokDesignSystem.backgroundOffWhite,
            borderRadius: BorderRadius.circular(GrokDesignSystem.radiusMD),
            border: Border.all(
              color: _isUnread
                  ? accentColor.withValues(alpha: 0.2)
                  : GrokDesignSystem.borderLight,
              width: _isUnread ? 1.5 : 1,
            ),
            boxShadow: _isUnread
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : GrokDesignSystem.cardShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleTap,
              borderRadius: BorderRadius.circular(GrokDesignSystem.radiusMD),
              child: Padding(
                padding: EdgeInsets.all(GrokDesignSystem.spacingMD),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Avatar/Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.notification.iconEmoji ??
                              widget.notification.type.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    SizedBox(width: GrokDesignSystem.spacingMD),

                    // Center: Title + Message
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            widget.notification.title,
                            style: GrokDesignSystem.bodyLarge(isMobile: isMobile)
                                .copyWith(
                              fontWeight: _isUnread
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: GrokDesignSystem.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: GrokDesignSystem.spacingXS),

                          // Message
                          Text(
                            widget.notification.message,
                            style: GrokDesignSystem.bodyMedium(isMobile: isMobile)
                                .copyWith(
                              color: GrokDesignSystem.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: GrokDesignSystem.spacingXS),

                          // Time
                          Text(
                            _formatTime(widget.notification.createdAt),
                            style: GrokDesignSystem.caption(isMobile: isMobile)
                                .copyWith(
                              color: GrokDesignSystem.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: GrokDesignSystem.spacingSM),

                    // Right: Action dot (if unread)
                    if (_isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 300.ms, curve: Curves.easeOut)
          .slideY(
            begin: 0.1,
            end: 0,
            duration: 300.ms,
            curve: Curves.easeOutCubic,
            delay: (widget.index * 40).ms, // Stagger animation
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
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}


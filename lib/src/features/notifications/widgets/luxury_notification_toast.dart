/// Luxury Notification Toast
/// In-app notification widget with glassmorphic design
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../theme/calendar_theme.dart';

class LuxuryNotificationToast extends StatefulWidget {
  final FashionNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final Duration displayDuration;

  const LuxuryNotificationToast({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
    this.displayDuration = const Duration(seconds: 4),
  });

  @override
  State<LuxuryNotificationToast> createState() => _LuxuryNotificationToastState();
}

class _LuxuryNotificationToastState extends State<LuxuryNotificationToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: CalendarTheme.mediumAnimation,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: CalendarTheme.springCurve,
      ),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    
    _controller.forward();
    
    // Auto dismiss
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _dismiss();
      }
    });
    
    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            
            // Handle deep link if available
            if (widget.notification.actionUrl != null) {
              final deepLink = DeepLinkService(context);
              deepLink.handleDeepLink(widget.notification.actionUrl);
            }
            
            widget.onTap?.call();
            _dismiss();
          },
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! > 0) {
              _dismiss();
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: CalendarTheme.glassCard,
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(int.parse(
                          widget.notification.accentColor?.replaceAll('#', '0xFF') ?? '0xFF6B7280',
                        )),
                        Color(int.parse(
                          widget.notification.accentColor?.replaceAll('#', '0xFF') ?? '0xFF6B7280',
                        )).withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.notification.iconEmoji ?? '🔔',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.notification.title,
                          style: CalendarTheme.headlineText().copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                      ],
                    ),
                  ),
                ),
                
                // Dismiss button
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _dismiss,
                  color: FashionDesignSystem.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

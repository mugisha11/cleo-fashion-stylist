/// Premium Notification Panel
/// Bottom sheet with glassmorphism, smooth animations, swipe gestures
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/grok_design_system.dart';
import '../../../core/models/notification_model.dart';
import '../providers/notification_provider.dart';
import 'notification_card.dart';

class NotificationPanel extends ConsumerStatefulWidget {
  const NotificationPanel({super.key});

  @override
  ConsumerState<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends ConsumerState<NotificationPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutExpo,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // Start animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    HapticFeedback.lightImpact();
    _controller.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _handleNotificationTap(FashionNotification notification) {
    final actions = ref.read(notificationActionsProvider);
    
    // Mark as read
    if (notification.state == NotificationState.unread) {
      actions.markAsRead(notification.id);
    }

    // Navigate if action URL exists
    if (notification.actionUrl != null) {
      // TODO: Navigate to action URL
      // Navigator.of(context).pushNamed(notification.actionUrl!);
    }

    _close();
  }

  void _handleDismiss(FashionNotification notification) {
    HapticFeedback.mediumImpact();
    final actions = ref.read(notificationActionsProvider);
    actions.dismiss(notification.id);
  }

  void _handleSave(FashionNotification notification) {
    HapticFeedback.selectionClick();
    final actions = ref.read(notificationActionsProvider);
    actions.markAsSaved(notification.id);
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCountAsync = ref.watch(unreadCountProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final panelHeight = screenHeight * 0.75; // 75% of screen height
    final isMobile = MediaQuery.of(context).size.width < 768;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: _close,
          child: Container(
            color: Colors.black.withValues(
              alpha: _fadeAnimation.value * 0.4, // Dim background
            ),
            child: GestureDetector(
              onTap: () {}, // Prevent tap from closing when tapping panel
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(_slideAnimation),
                child: Container(
                  height: panelHeight,
                  decoration: BoxDecoration(
                    color: GrokDesignSystem.backgroundWhite,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child: Column(
                      children: [
                        // Handle bar
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: GrokDesignSystem.borderMedium,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // Header
                        Padding(
                          padding: EdgeInsets.all(GrokDesignSystem.spacingMD),
                          child: Row(
                            children: [
                              Text(
                                'Notifications',
                                style: GrokDesignSystem.headlineSmall(
                                  isMobile: isMobile,
                                ),
                              ),
                              const Spacer(),
                              // Unread count badge
                              unreadCountAsync.when(
                                data: (count) {
                                  if (count > 0) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: GrokDesignSystem.accentBlue,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        count.toString(),
                                        style: GrokDesignSystem.caption(
                                          isMobile: isMobile,
                                        ).copyWith(
                                          color: GrokDesignSystem.textInverse,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                              SizedBox(width: GrokDesignSystem.spacingMD),
                              // Mark all as read button
                              TextButton(
                                onPressed: () {
                                  final actions =
                                      ref.read(notificationActionsProvider);
                                  actions.markAllAsRead();
                                },
                                child: Text(
                                  'Mark all read',
                                  style: GrokDesignSystem.linkText(
                                    isMobile: isMobile,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Divider
                        Divider(
                          height: 1,
                          color: GrokDesignSystem.borderLight,
                        ),

                        // Notifications list
                        Expanded(
                          child: notificationsAsync.when(
                            data: (notifications) {
                              if (notifications.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.notifications_none,
                                        size: 64,
                                        color: GrokDesignSystem.textTertiary,
                                      ),
                                      SizedBox(
                                        height: GrokDesignSystem.spacingMD,
                                      ),
                                      Text(
                                        'No notifications',
                                        style: GrokDesignSystem.bodyMedium(
                                          isMobile: isMobile,
                                        ).copyWith(
                                          color: GrokDesignSystem.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                padding: EdgeInsets.only(
                                  top: GrokDesignSystem.spacingSM,
                                  bottom: GrokDesignSystem.spacingXL,
                                ),
                                itemCount: notifications.length,
                                itemBuilder: (context, index) {
                                  final notification = notifications[index];
                                  return Dismissible(
                                    key: Key(notification.id),
                                    direction: DismissDirection.horizontal,
                                    background: Container(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: GrokDesignSystem.spacingMD,
                                      ),
                                      decoration: BoxDecoration(
                                        color: GrokDesignSystem.error,
                                        borderRadius: BorderRadius.circular(
                                          GrokDesignSystem.radiusMD,
                                        ),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      padding: EdgeInsets.only(
                                        left: GrokDesignSystem.spacingMD,
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.white,
                                      ),
                                    ),
                                    secondaryBackground: Container(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: GrokDesignSystem.spacingMD,
                                      ),
                                      decoration: BoxDecoration(
                                        color: GrokDesignSystem.success,
                                        borderRadius: BorderRadius.circular(
                                          GrokDesignSystem.radiusMD,
                                        ),
                                      ),
                                      alignment: Alignment.centerRight,
                                      padding: EdgeInsets.only(
                                        right: GrokDesignSystem.spacingMD,
                                      ),
                                      child: const Icon(
                                        Icons.bookmark_outline,
                                        color: Colors.white,
                                      ),
                                    ),
                                    onDismissed: (direction) {
                                      if (direction ==
                                          DismissDirection.startToEnd) {
                                        _handleDismiss(notification);
                                      } else {
                                        _handleSave(notification);
                                      }
                                    },
                                    child: NotificationCard(
                                      notification: notification,
                                      index: index,
                                      onTap: () =>
                                          _handleNotificationTap(notification),
                                      onDismiss: () =>
                                          _handleDismiss(notification),
                                      onSave: () => _handleSave(notification),
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => Center(
                              child: CircularProgressIndicator(
                                color: GrokDesignSystem.accentBlue,
                              ),
                            ),
                            error: (error, stack) => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: GrokDesignSystem.error,
                                  ),
                                  SizedBox(
                                    height: GrokDesignSystem.spacingMD,
                                  ),
                                  Text(
                                    'Failed to load notifications',
                                    style: GrokDesignSystem.bodyMedium(
                                      isMobile: isMobile,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


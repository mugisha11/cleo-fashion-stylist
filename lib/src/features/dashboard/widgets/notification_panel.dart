/// Premium Notification Panel
/// Bottom sheet with glassmorphism, smooth animations. Uses Firestore social notifications.
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/grok_design_system.dart';
import '../../../core/services/sound_service.dart';
import '../../../routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/models/social_notification_model.dart';
import '../../social/providers/social_provider.dart';
import '../../social/widgets/social_notification_card.dart';

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

  void _handleNotificationTap(SocialNotificationModel n) {
    SoundService.play(AppSound.tap);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null && !n.read) {
      ref.read(socialServiceProvider).markNotificationRead(n.id);
      ref.invalidate(socialNotificationsProvider);
      ref.invalidate(socialUnreadCountProvider);
    }

    switch (n.type) {
      case 'friend_request':
      case 'request_accepted':
        Navigator.of(context).pushNamed(Routes.friendRequests);
        break;
      case 'new_message':
        if (n.chatId != null) {
          Navigator.of(context).pushNamed(
            Routes.chat,
            arguments: <String, dynamic>{
              'chatId': n.chatId,
              'otherUserId': n.fromUserId,
              'otherUserName': n.fromUserName ?? 'User',
              'otherUserAvatar': null,
            },
          );
        } else {
          Navigator.of(context).pushNamed(
            Routes.chat,
            arguments: <String, dynamic>{
              'otherUserId': n.fromUserId,
              'otherUserName': n.fromUserName ?? 'User',
            },
          );
        }
        break;
      case 'post_liked':
      case 'post_comment':
        Navigator.of(context).pushNamed(Routes.styleFeed);
        break;
      case 'tryon_completed':
        Navigator.of(context).pushNamed(Routes.tryon);
        break;
      default:
        break;
    }
    _close();
  }

  Future<void> _markAllAsRead() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    await ref.read(socialServiceProvider).markAllNotificationsRead(user.uid);
    ref.invalidate(socialNotificationsProvider);
    ref.invalidate(socialUnreadCountProvider);
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(socialNotificationsProvider);
    final unreadCount = ref.watch(socialUnreadCountProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final panelHeight = screenHeight * 0.75;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: _close,
          child: Container(
            color: Colors.black.withValues(
              alpha: _fadeAnimation.value * 0.4,
            ),
            child: GestureDetector(
              onTap: () {},
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
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: GrokDesignSystem.borderMedium,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(GrokDesignSystem.spacingMD),
                          child: Row(
                            children: [
                              Text(
                                'Notifications',
                                style: GrokDesignSystem.headlineSmall(
                                  isMobile: isMobile,
                                ),
                              ),
                              const Spacer(),
                              if (unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: GrokDesignSystem.accentBlue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    unreadCount.toString(),
                                    style: GrokDesignSystem.caption(
                                      isMobile: isMobile,
                                    ).copyWith(
                                      color: GrokDesignSystem.textInverse,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: GrokDesignSystem.spacingMD),
                              TextButton(
                                onPressed: unreadCount > 0 ? _markAllAsRead : null,
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
                        const Divider(
                          height: 1,
                          color: GrokDesignSystem.borderLight,
                        ),
                        Expanded(
                          child: notificationsAsync.when(
                            data: (notifications) {
                              if (notifications.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.notifications_none,
                                        size: 64,
                                        color: GrokDesignSystem.textTertiary,
                                      ),
                                      const SizedBox(
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
                                padding: const EdgeInsets.only(
                                  top: GrokDesignSystem.spacingSM,
                                  bottom: GrokDesignSystem.spacingXL,
                                ),
                                itemCount: notifications.length,
                                itemBuilder: (context, index) {
                                  final n = notifications[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: GrokDesignSystem.spacingMD,
                                      vertical: 6,
                                    ),
                                    child: SocialNotificationCard(
                                      notification: n,
                                      onTap: () => _handleNotificationTap(n),
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                color: GrokDesignSystem.accentBlue,
                              ),
                            ),
                            error: (_, __) => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: GrokDesignSystem.error,
                                  ),
                                  const SizedBox(
                                    height: GrokDesignSystem.spacingMD,
                                  ),
                                  Text(
                                    'Couldn\'t load notifications',
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

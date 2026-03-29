/// Notification Center — All app notifications when logged in (Firestore)
/// Design cloned from reference: header with back/menu, Today/Yesterday, card list.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/models/social_notification_model.dart';
import '../../social/providers/social_provider.dart';

// Design colors matching the Notification reference image
class _NotificationPageColors {
  static const Color backgroundTop = Color(0xFFF5F5F5);
  static const Color backgroundBottom = Color(0xFFEAE6EB);
  static const Color headerButtonBg = Color(0xFFEFEFF0);
  static const Color title = Color(0xFF1F1F1F);
  static const Color sectionTitle = Color(0xFF1F1F1F);
  static const Color cardBg = Color(0xFFE4E4E6);
  static const Color cardName = Color(0xFF1F1F1F);
  static const Color cardAction = Color(0xFF1F1F1F);
  static const Color cardTime = Color(0xFF888888);
}

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final notificationsAsync = ref.watch(socialNotificationsProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: _NotificationPageColors.backgroundTop,
        appBar: _buildAppBar(context, ref, null),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none_rounded, size: 64, color: _NotificationPageColors.cardTime),
              SizedBox(height: 16),
              Text(
                'Sign in to see notifications',
                style: TextStyle(fontFamily: 'system-ui', 
                  fontSize: 16,
                  color: _NotificationPageColors.cardTime,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _NotificationPageColors.backgroundTop,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _NotificationPageColors.backgroundTop,
              _NotificationPageColors.backgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, ref, user.uid),
              Expanded(
                child: notificationsAsync.when(
                  data: (notifications) {
                    if (notifications.isEmpty) return _buildEmptyState(context);
                    final grouped = _groupByDate(notifications);
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final entry = grouped.entries.elementAt(index);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: 12, top: index == 0 ? 0 : 20),
                              child: Text(
                                _formatDateHeader(entry.key),
                                style: const TextStyle(fontFamily: 'system-ui', 
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _NotificationPageColors.sectionTitle,
                                ),
                              ),
                            ),
                            ...entry.value.map((n) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _NotificationCard(
                                    notification: n,
                                    onTap: () => _handleTap(context, ref, n),
                                  ),
                                )),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (e, _) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 56, color: DesignTokens.darkAccent),
                        SizedBox(height: 16),
                        Text(
                          'Unable to load notifications',
                          style: TextStyle(fontFamily: 'system-ui', 
                            fontSize: 16,
                            color: _NotificationPageColors.cardTime,
                          ),
                          textAlign: TextAlign.center,
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
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref, String? userId) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Material(
          color: _NotificationPageColors.headerButtonBg,
          shape: const CircleBorder(),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _NotificationPageColors.title),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      title: const Text(
        'Notification',
        style: TextStyle(fontFamily: 'system-ui', 
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _NotificationPageColors.title,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Material(
            color: _NotificationPageColors.headerButtonBg,
            shape: const CircleBorder(),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.menu, size: 22, color: _NotificationPageColors.title),
              onSelected: (value) async {
                if (value == 'mark_all_read' && userId != null) {
                  await ref.read(socialServiceProvider).markAllNotificationsRead(userId);
                  ref.invalidate(socialNotificationsProvider);
                  ref.invalidate(socialUnreadCountProvider);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'mark_all_read', child: Text('Mark all as read')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<DateTime, List<SocialNotificationModel>> _groupByDate(List<SocialNotificationModel> list) {
    final grouped = <DateTime, List<SocialNotificationModel>>{};
    for (final n in list) {
      final date = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      grouped.putIfAbsent(date, () => []).add(n);
    }
    return grouped;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(date);
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: _NotificationPageColors.cardTime,
          ),
          SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(fontFamily: 'system-ui', 
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _NotificationPageColors.title,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "You're all caught up!",
            style: TextStyle(fontFamily: 'system-ui', 
              fontSize: 15,
              color: _NotificationPageColors.cardTime,
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref, SocialNotificationModel n) {
    ref.read(socialServiceProvider).markNotificationRead(n.id);
    ref.invalidate(socialNotificationsProvider);
    ref.invalidate(socialUnreadCountProvider);

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
  }
}

class _NotificationCard extends StatelessWidget {
  final SocialNotificationModel notification;
  final VoidCallback? onTap;

  const _NotificationCard({
    required this.notification,
    this.onTap,
  });

  String get _actionText {
    final name = notification.fromUserName ?? 'Someone';
    switch (notification.type) {
      case 'friend_request':
        return 'Sent you a friend request';
      case 'request_accepted':
        return 'Accepted your friend request';
      case 'new_message':
        return 'Sent you a message';
      case 'post_liked':
        return 'Liked your outfit';
      case 'post_comment':
        return 'Commented on your look';
      case 'tryon_shared':
        return 'Shared your outfit';
      case 'tryon_completed':
        return 'Try-on complete';
      default:
        return 'Notification';
    }
  }

  bool get _showThumbsUp {
    switch (notification.type) {
      case 'post_liked':
      case 'request_accepted':
        return true;
      default:
        return false;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMM d').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final name = notification.fromUserName ?? 'Someone';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: _NotificationPageColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: _NotificationPageColors.backgroundTop,
                backgroundImage: notification.imageUrl != null && notification.imageUrl!.startsWith('http')
                    ? NetworkImage(notification.imageUrl!)
                    : null,
                child: notification.imageUrl == null || !notification.imageUrl!.startsWith('http')
                    ? Text(
                        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                        style: const TextStyle(fontFamily: 'system-ui', 
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _NotificationPageColors.cardName,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontFamily: 'system-ui', 
                          fontSize: 15,
                          color: _NotificationPageColors.cardName,
                          height: 1.35,
                        ),
                        children: [
                          TextSpan(
                            text: '$name ',
                            style: const TextStyle(fontFamily: 'system-ui', 
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _NotificationPageColors.cardName,
                            ),
                          ),
                          TextSpan(
                            text: _actionText,
                            style: const TextStyle(fontFamily: 'system-ui', 
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: _NotificationPageColors.cardAction,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(notification.createdAt),
                      style: const TextStyle(fontFamily: 'system-ui', 
                        fontSize: 13,
                        color: _NotificationPageColors.cardTime,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showThumbsUp)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text('👍', style: TextStyle(fontSize: 22)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

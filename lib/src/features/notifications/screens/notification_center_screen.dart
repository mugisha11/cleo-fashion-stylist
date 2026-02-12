/// Notification Center — All app notifications when logged in (Firestore)
/// Friend requests, messages, post likes, comments, etc.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/models/social_notification_model.dart';
import '../../social/providers/social_provider.dart';
import '../../social/widgets/social_notification_card.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final notificationsAsync = ref.watch(socialNotificationsProvider);
    final unreadCount = ref.watch(socialUnreadCountProvider);
    final isDark = context.isDarkMode;
    final surface = isDark ? DesignTokens.darkSurface : DesignTokens.lightSurface;
    final textSecondary = isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary;

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? DesignTokens.darkBackground : DesignTokens.lightBackground,
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: surface,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none_rounded, size: 64, color: textSecondary),
              const SizedBox(height: 16),
              Text(
                'Sign in to see notifications',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? DesignTokens.darkBackground : DesignTokens.lightBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all, size: 20),
              label: Text('Mark all read ($unreadCount)'),
              onPressed: () => _markAllAsRead(ref, user.uid),
            ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) return _buildEmptyState(context, isDark, textSecondary);
          final grouped = _groupByDate(notifications);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final entry = grouped.entries.elementAt(index);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _formatDateHeader(entry.key),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  ...entry.value.map((n) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SocialNotificationCard(
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
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 56, color: DesignTokens.darkAccent),
              const SizedBox(height: 16),
              Text(
                'Unable to load notifications',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildEmptyState(BuildContext context, bool isDark, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? DesignTokens.darkText : DesignTokens.lightText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllAsRead(WidgetRef ref, String userId) async {
    await ref.read(socialServiceProvider).markAllNotificationsRead(userId);
    ref.invalidate(socialNotificationsProvider);
    ref.invalidate(socialUnreadCountProvider);
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

/// Luxury Notification Center
/// Beautiful, organized notification hub
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../../dashboard/providers/notification_provider.dart';
import '../theme/calendar_theme.dart';
import '../widgets/luxury_notification_card.dart';
import 'package:intl/intl.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen> {
  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCountAsync = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: FashionDesignSystem.backgroundIvory,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: FashionDesignSystem.backgroundWhite,
        elevation: 0,
        actions: [
          unreadCountAsync.when(
            data: (count) => count > 0
                ? TextButton.icon(
                    icon: const Icon(Icons.done_all, size: 20),
                    label: Text('Mark all read ($count)'),
                    onPressed: () => _markAllAsRead(),
                  )
                : const SizedBox(),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            color: CalendarTheme.electricAccent,
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: CalendarTheme.failedCoral,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load notifications',
                style: CalendarTheme.headlineText(),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your connection',
                style: CalendarTheme.bodyText(
                  color: FashionDesignSystem.textSecondary,
                ),
              ),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }
          
          // Group by date
          final grouped = _groupByDate(notifications);
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final entry = grouped.entries.elementAt(index);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _formatDateHeader(entry.key),
                      style: CalendarTheme.captionText(
                        color: FashionDesignSystem.textSecondary,
                      ).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  
                  // Notifications for this date
                  ...entry.value.map((notification) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LuxuryNotificationCard(
                      notification: notification,
                      onTap: () => _handleNotificationTap(notification),
                    ),
                  )),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Map<DateTime, List<FashionNotification>> _groupByDate(
    List<FashionNotification> notifications,
  ) {
    final grouped = <DateTime, List<FashionNotification>>{};
    
    for (final notification in notifications) {
      final date = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );
      
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(notification);
    }
    
    return grouped;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 64,
            color: FashionDesignSystem.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: CalendarTheme.headlineText(),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: CalendarTheme.bodyText(
              color: FashionDesignSystem.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    final service = ref.read(notificationServiceProvider);
    await service.markAllAsRead();
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
  }

  void _handleNotificationTap(FashionNotification notification) {
    // Mark as read
    ref.read(notificationServiceProvider).markAsRead(notification.id);
    
    // Handle deep link
    if (notification.actionUrl != null) {
      final deepLink = DeepLinkService(context);
      deepLink.handleDeepLink(notification.actionUrl);
    }
    
    // Refresh
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
  }
}

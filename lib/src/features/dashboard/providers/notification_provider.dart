/// Notification Provider (Riverpod)
/// Manages notification state and real-time updates
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/models/notification_model.dart';

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  try {
    final supabase = Supabase.instance.client;
    final auth = FirebaseAuth.instance;
    return NotificationService(supabase, auth);
  } catch (e) {
    // Return a service that will fail gracefully
    throw Exception('NotificationService not available: $e');
  }
});

/// Notifications list provider
final notificationsProvider = FutureProvider<List<FashionNotification>>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return await service.getNotifications();
});

/// Unread count provider
final unreadCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return await service.getUnreadCount();
});

/// Notification actions provider
final notificationActionsProvider = Provider<NotificationActions>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return NotificationActions(service, ref);
});

class NotificationActions {
  final NotificationService _service;
  final Ref _ref;

  NotificationActions(this._service, this._ref);

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadCountProvider);
  }

  /// Dismiss notification
  Future<void> dismiss(String notificationId) async {
    await _service.dismiss(notificationId);
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadCountProvider);
  }

  /// Mark as saved (important)
  Future<void> markAsSaved(String notificationId) async {
    await _service.markAsSaved(notificationId);
    _ref.invalidate(notificationsProvider);
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    await _service.markAllAsRead();
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadCountProvider);
  }
}


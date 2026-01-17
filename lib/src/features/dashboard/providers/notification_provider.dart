/// Notification Provider (Riverpod)
/// Manages notification state and real-time updates
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/models/notification_model.dart';

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService?>((ref) {
  try {
    // Check if Supabase is initialized
    final supabase = Supabase.instance.client;
    final auth = FirebaseAuth.instance;
    return NotificationService(supabase, auth);
  } catch (e) {
    // Return null if services not ready - don't throw, prevents blocking
    debugPrint('⚠️ NotificationService not available yet: $e');
    return null;
  }
});

/// Notifications list provider
final notificationsProvider = FutureProvider<List<FashionNotification>>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  if (service == null) {
    // Service not ready yet - return empty list, don't block
    return [];
  }
  try {
    return await service.getNotificationsAsModels();
  } catch (e) {
    debugPrint('⚠️ Failed to get notifications: $e');
    return [];
  }
});

/// Unread count provider
final unreadCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  if (service == null) {
    // Service not ready yet - return 0, don't block
    return 0;
  }
  try {
    return await service.getUnreadCount();
  } catch (e) {
    debugPrint('⚠️ Failed to get unread count: $e');
    return 0;
  }
});

/// Notification actions provider
final notificationActionsProvider = Provider<NotificationActions?>((ref) {
  final service = ref.watch(notificationServiceProvider);
  if (service == null) return null;
  return NotificationActions(service, ref);
});

class NotificationActions {
  final NotificationService? _service;
  final Ref _ref;

  NotificationActions(this._service, this._ref);
  
  bool get isAvailable => _service != null;

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final service = _service;
    if (service == null) return;
    await service.markAsRead(notificationId);
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadCountProvider);
  }

  /// Dismiss notification
  Future<void> dismiss(String notificationId) async {
    final service = _service;
    if (service == null) return;
    await service.dismiss(notificationId);
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadCountProvider);
  }

  /// Mark as saved (important)
  Future<void> markAsSaved(String notificationId) async {
    final service = _service;
    if (service == null) return;
    await service.markAsSaved(notificationId);
    _ref.invalidate(notificationsProvider);
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    final service = _service;
    if (service == null) return;
    await service.markAllAsRead();
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadCountProvider);
  }
}


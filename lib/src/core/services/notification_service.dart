/// Notification Service
/// Handles fetching, caching, and managing notifications from Supabase
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _supabase;
  final FirebaseAuth _auth;

  NotificationService(this._supabase, this._auth);

  String get _userId => _auth.currentUser?.uid ?? '';

  /// Fetch all notifications for current user
  Future<List<FashionNotification>> getNotifications({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    try {
      if (_userId.isEmpty) return [];

      var query = _supabase
          .from('notifications')
          .select()
          .eq('user_id', _userId);

      if (unreadOnly) {
        query = query.eq('state', 'unread');
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) {
            // Convert Supabase format to our model format
            final converted = Map<String, dynamic>.from(json);
            if (converted['created_at'] is String) {
              converted['created_at'] = converted['created_at'];
            }
            return FashionNotification.fromJson(converted);
          })
          .toList();
    } catch (e) {
      // Return empty list on error (offline mode)
      return [];
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      if (_userId.isEmpty) return 0;

      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', _userId)
          .eq('state', 'unread');

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      if (_userId.isEmpty) return;

      await _supabase
          .from('notifications')
          .update({'state': 'read'})
          .eq('id', notificationId)
          .eq('user_id', _userId);
    } catch (e) {
      // Silently fail - offline mode
    }
  }

  /// Mark notification as dismissed
  Future<void> dismiss(String notificationId) async {
    try {
      if (_userId.isEmpty) return;

      await _supabase
          .from('notifications')
          .update({'state': 'dismissed'})
          .eq('id', notificationId)
          .eq('user_id', _userId);
    } catch (e) {
      // Silently fail - offline mode
    }
  }

  /// Mark notification as saved (important)
  Future<void> markAsSaved(String notificationId) async {
    try {
      if (_userId.isEmpty) return;

      await _supabase
          .from('notifications')
          .update({'state': 'saved'})
          .eq('id', notificationId)
          .eq('user_id', _userId);
    } catch (e) {
      // Silently fail - offline mode
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    try {
      if (_userId.isEmpty) return;

      await _supabase
          .from('notifications')
          .update({'state': 'read'})
          .eq('user_id', _userId)
          .eq('state', 'unread');
    } catch (e) {
      // Silently fail - offline mode
    }
  }

  /// Create a notification (for testing or system notifications)
  Future<FashionNotification> createNotification({
    required NotificationType type,
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final notification = FashionNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        state: NotificationState.unread,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        metadata: metadata,
        iconEmoji: type.emoji,
        accentColor: type.accentColorHex,
      );

      // Convert to Supabase format
      final json = notification.toJson();
      json['user_id'] = _userId;
      json['created_at'] = notification.createdAt.toIso8601String();
      
      await _supabase.from('notifications').insert(json);

      return notification;
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Subscribe to real-time notifications
  RealtimeChannel subscribeToNotifications({
    required Function(FashionNotification) onNewNotification,
  }) {
    try {
      final channel = _supabase
          .channel('notifications_$_userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: _userId,
            ),
            callback: (payload) {
              try {
                final notification = FashionNotification.fromJson(
                  payload.newRecord as Map<String, dynamic>,
                );
                onNewNotification(notification);
              } catch (e) {
                // Ignore parse errors
              }
            },
          )
          .subscribe();

      return channel;
    } catch (e) {
      // Return a dummy channel if subscription fails
      return _supabase.channel('notifications_fallback_$_userId');
    }
  }
}


import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

/// Smart Notification Service
/// Handles FCM notifications with deep linking and fashion-aware logic
class NotificationService {
  final SupabaseClient _supabase;
  final FirebaseAuth _auth;
  final FirebaseMessaging _messaging;
  
  NotificationService(this._supabase, this._auth) : _messaging = FirebaseMessaging.instance;
  
  String? get userId => _auth.currentUser?.uid;
  
  /// Initialize notification service
  Future<void> initialize() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    } else {
      debugPrint('User declined notification permission');
      return;
    }
    
    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null && userId != null) {
      await saveFCMToken(token);
    }
    
    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      if (userId != null) {
        saveFCMToken(newToken);
      }
    });
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages (when app is terminated)
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    
    // Handle notification taps (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // Check if app was opened from notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }
  
  /// Save FCM token to Firestore
  Future<void> saveFCMToken(String token) async {
    try {
      if (userId == null) return;
      
      // Save to Firestore (for Firebase Functions)
      await _auth.currentUser?.getIdToken();
      // Note: Firestore update would go here if using Firestore
      // For now, we'll store in Supabase user_preferences
      
      await _supabase
          .from('user_notification_preferences')
          .upsert({
            'user_id': userId,
            'fcm_token': token,
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      debugPrint('FCM token saved for user $userId');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }
  
  /// Handle foreground notification
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground notification received: ${message.notification?.title}');
    
    // Show local notification or in-app banner
    // You can use flutter_local_notifications for this
    _processNotification(message);
  }
  
  /// Handle background notification (must be top-level function)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Background notification received: ${message.notification?.title}');
    // Process notification in background
  }
  
  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    
    final deepLink = message.data['deepLink'];
    final screen = message.data['screen'];
    final notificationId = message.data['notificationId'];
    
    // Mark notification as read
    if (notificationId != null && userId != null) {
      markNotificationAsRead(notificationId);
    }
    
    // Navigate based on deep link
    _navigateFromDeepLink(deepLink, screen, message.data);
  }
  
  /// Process notification and update local state
  void _processNotification(RemoteMessage message) {
    final type = message.data['type'];
    final notificationId = message.data['notificationId'];
    
    if (notificationId != null && userId != null) {
      // Save notification to local state
      _saveNotificationLocally({
        'id': notificationId,
        'type': type,
        'title': message.notification?.title ?? '',
        'body': message.notification?.body ?? '',
        'payload': message.data,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }
  
  /// Save notification locally (for in-app notification center)
  void _saveNotificationLocally(Map<String, dynamic> notification) {
    // This would integrate with your state management (Riverpod/Provider)
    // For now, we'll just log it
    debugPrint('Notification saved locally: $notification');
  }
  
  /// Navigate based on deep link
  void _navigateFromDeepLink(String? deepLink, String? screen, Map<String, dynamic> data) {
    // This would integrate with your navigation system
    // Example implementation:
    switch (deepLink) {
      case 'dashboard':
        if (screen == 'daily_recommendations') {
          // Navigate to dashboard with daily recommendations tab
          debugPrint('Navigate to dashboard > daily recommendations');
        }
        break;
      case 'calendar':
        if (screen == 'event_detail') {
          final eventId = data['eventId'];
          // Navigate to calendar event detail
          debugPrint('Navigate to calendar event: $eventId');
        }
        break;
      case 'tryon':
        // Navigate to try-on page
        debugPrint('Navigate to try-on page');
        break;
      case 'wardrobe':
        // Navigate to wardrobe page
        debugPrint('Navigate to wardrobe page');
        break;
      default:
        debugPrint('Unknown deep link: $deepLink');
    }
  }
  
  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final currentUserId = userId;
      if (currentUserId == null) return;
      
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('user_id', currentUserId);
      
      debugPrint('Notification $notificationId marked as read');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
  
  /// Mark notification as read (alias for compatibility)
  Future<void> markAsRead(String notificationId) async {
    return markNotificationAsRead(notificationId);
  }
  
  /// Dismiss notification (delete it)
  Future<void> dismiss(String notificationId) async {
    try {
      final currentUserId = userId;
      if (currentUserId == null) return;
      
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', currentUserId);
      
      debugPrint('Notification $notificationId dismissed');
    } catch (e) {
      debugPrint('Error dismissing notification: $e');
    }
  }
  
  /// Mark notification as saved (important)
  Future<void> markAsSaved(String notificationId) async {
    try {
      final currentUserId = userId;
      if (currentUserId == null) return;
      
      // Store in payload that it's saved
      final response = await _supabase
          .from('notifications')
          .select('payload')
          .eq('id', notificationId)
          .eq('user_id', currentUserId)
          .single();
      
      final responseMap = response;
      final payload = Map<String, dynamic>.from(responseMap['payload'] ?? {});
      payload['is_saved'] = true;
      
      await _supabase
          .from('notifications')
          .update({'payload': payload})
          .eq('id', notificationId)
          .eq('user_id', currentUserId);
      
      debugPrint('Notification $notificationId marked as saved');
    } catch (e) {
      debugPrint('Error marking notification as saved: $e');
    }
  }
  
  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final currentUserId = userId;
      if (currentUserId == null) return;
      
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', currentUserId)
          .eq('is_read', false);
      
      debugPrint('All notifications marked as read');
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
  
  /// Get user notification preferences
  Future<Map<String, dynamic>?> getUserPreferences() async {
    try {
      final currentUserId = userId;
      if (currentUserId == null) return null;
      
      final response = await _supabase
          .from('user_notification_preferences')
          .select()
          .eq('user_id', currentUserId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      debugPrint('Error fetching notification preferences: $e');
      return null;
    }
  }
  
  /// Update user notification preferences
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final currentUserId = userId;
      if (currentUserId == null) return;
      
      await _supabase
          .from('user_notification_preferences')
          .upsert({
            'user_id': currentUserId,
            ...preferences,
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      debugPrint('Notification preferences updated');
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
    }
  }
  
  /// Get unread notifications count
  Future<int> getUnreadCount() async {
    try {
      final currentUserId = userId;
      if (currentUserId == null) return 0;
      
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', currentUserId)
          .eq('is_read', false);
      
      // Count the results
      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }
  
  /// Get all notifications for user
  Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    try {
      final currentUserId = userId;
      if (currentUserId == null) return [];
      
      var query = _supabase
          .from('notifications')
          .select()
          .eq('user_id', currentUserId);
      
      if (unreadOnly) {
        query = query.eq('is_read', false);
      }
      
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }
  
  /// Get all notifications as FashionNotification objects
  Future<List<FashionNotification>> getNotificationsAsModels({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    try {
      final notifications = await getNotifications(limit: limit, unreadOnly: unreadOnly);
      return notifications.map((json) => _mapToFashionNotification(json)).toList();
    } catch (e) {
      debugPrint('Error fetching notifications as models: $e');
      return [];
    }
  }
  
  /// Map database JSON to FashionNotification model
  FashionNotification _mapToFashionNotification(Map<String, dynamic> json) {
    // Map database type to NotificationType enum
    NotificationType type;
    final dbType = json['type'] as String? ?? 'system';
    switch (dbType) {
      case 'daily_outfit':
        type = NotificationType.outfitReady;
        break;
      case 'event_outfit':
        type = NotificationType.eventReminder;
        break;
      case 'weather_alert':
        type = NotificationType.system;
        break;
      case 'wardrobe_intelligence':
        type = NotificationType.wardrobeMatch;
        break;
      default:
        type = NotificationType.system;
    }
    
    // Map state
    NotificationState state;
    if (json['is_read'] == true) {
      state = NotificationState.read;
    } else {
      final payload = json['payload'] as Map<String, dynamic>? ?? {};
      if (payload['is_saved'] == true) {
        state = NotificationState.saved;
      } else {
        state = NotificationState.unread;
      }
    }
    
    return FashionNotification(
      id: json['id'] as String,
      type: type,
      title: json['title'] as String? ?? '',
      message: json['body'] as String? ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      state: state,
      actionUrl: json['payload']?['deepLink'] as String?,
      metadata: json['payload'] as Map<String, dynamic>?,
    );
  }
}

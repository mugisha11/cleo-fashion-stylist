/// Notification Intelligence Engine
/// AI-driven rules for WHEN and HOW to notify users
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationContext {
  foreground,
  background,
  terminated,
}

class NotificationIntelligence {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Determine if notification should be sent based on AI rules
  Future<bool> shouldNotify(
    Map<String, dynamic> notificationData,
    NotificationContext context,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;
      
      // Get user preferences
      final prefs = await _getUserPreferences(userId);
      
      // Check if user has disabled this notification type
      final type = notificationData['type'] as String?;
      if (type != null && !_isTypeEnabled(type, prefs)) {
        return false;
      }
      
      // Check quiet hours
      if (_isQuietHours(prefs)) {
        // Only allow critical notifications during quiet hours
        if (!_isCritical(notificationData)) {
          return false;
        }
      }
      
      // Check user activity level
      final activityLevel = await _getUserActivityLevel(userId);
      if (activityLevel == UserActivityLevel.inactive) {
        // Reduce notification frequency for inactive users
        if (!_shouldNotifyInactiveUser(notificationData)) {
          return false;
        }
      }
      
      // Context-specific rules
      switch (context) {
        case NotificationContext.foreground:
          // In foreground, be more selective
          return _shouldNotifyInForeground(notificationData, prefs);
        case NotificationContext.background:
          // In background, notify for important events
          return _shouldNotifyInBackground(notificationData);
        case NotificationContext.terminated:
          // App is closed, notify for all important events
          return true;
      }
    } catch (e) {
      // On error, default to showing notification (fail open)
      return true;
    }
  }
  
  /// Get user notification preferences
  Future<Map<String, dynamic>> _getUserPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notifications')
          .get();
      
      if (doc.exists) {
        return doc.data() ?? {};
      }
      
      // Return default preferences
      return {
        'tryon_completed': true,
        'tryon_processing': false, // Silent background update
        'tryon_failed': true,
        'calendar_reminders': true,
        'system_updates': true,
        'quiet_hours_enabled': false,
        'quiet_hours_start': '22:00',
        'quiet_hours_end': '08:00',
        'inactive_user_reduction': true,
      };
    } catch (_) {
      return {};
    }
  }
  
  /// Check if notification type is enabled
  bool _isTypeEnabled(String type, Map<String, dynamic> prefs) {
    switch (type) {
      case 'tryon_completed':
        return prefs['tryon_completed'] as bool? ?? true;
      case 'tryon_processing':
        return prefs['tryon_processing'] as bool? ?? false;
      case 'tryon_failed':
        return prefs['tryon_failed'] as bool? ?? true;
      case 'event_reminder':
        return prefs['calendar_reminders'] as bool? ?? true;
      case 'system':
        return prefs['system_updates'] as bool? ?? true;
      default:
        return true;
    }
  }
  
  /// Check if currently in quiet hours
  bool _isQuietHours(Map<String, dynamic> prefs) {
    final enabled = prefs['quiet_hours_enabled'] as bool? ?? false;
    if (!enabled) return false;
    
    final now = DateTime.now();
    final hour = now.hour;
    
    final startStr = prefs['quiet_hours_start'] as String? ?? '22:00';
    final endStr = prefs['quiet_hours_end'] as String? ?? '08:00';
    
    final startHour = int.parse(startStr.split(':')[0]);
    final endHour = int.parse(endStr.split(':')[0]);
    
    if (startHour > endHour) {
      // Overnight quiet hours (e.g., 22:00 - 08:00)
      return hour >= startHour || hour < endHour;
    } else {
      // Same-day quiet hours
      return hour >= startHour && hour < endHour;
    }
  }
  
  /// Check if notification is critical
  bool _isCritical(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final priority = data['priority'] as String?;
    
    // Critical types
    if (type == 'tryon_failed' || type == 'security_alert') {
      return true;
    }
    
    // High priority
    if (priority == 'high' || priority == 'critical') {
      return true;
    }
    
    return false;
  }
  
  /// Get user activity level
  Future<UserActivityLevel> _getUserActivityLevel(String userId) async {
    try {
      // Check last app open time
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final lastActive = userDoc.data()?['last_active'] as Timestamp?;
      
      if (lastActive == null) return UserActivityLevel.inactive;
      
      final daysSinceActive = DateTime.now()
          .difference(lastActive.toDate())
          .inDays;
      
      if (daysSinceActive < 1) {
        return UserActivityLevel.active;
      } else if (daysSinceActive < 7) {
        return UserActivityLevel.moderate;
      } else {
        return UserActivityLevel.inactive;
      }
    } catch (_) {
      return UserActivityLevel.active;
    }
  }
  
  /// Should notify inactive user
  bool _shouldNotifyInactiveUser(Map<String, dynamic> data) {
    // Only notify for important events
    return _isCritical(data) || data['type'] == 'tryon_completed';
  }
  
  /// Should notify in foreground
  bool _shouldNotifyInForeground(
    Map<String, dynamic> data,
    Map<String, dynamic> prefs,
  ) {
    final type = data['type'] as String?;
    
    // Always show failed try-ons
    if (type == 'tryon_failed') return true;
    
    // Don't show processing updates in foreground (silent)
    if (type == 'tryon_processing') {
      return prefs['tryon_processing'] as bool? ?? false;
    }
    
    // Show completed try-ons
    if (type == 'tryon_completed') return true;
    
    // Show calendar reminders
    if (type == 'event_reminder') return true;
    
    return true;
  }
  
  /// Should notify in background
  bool _shouldNotifyInBackground(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    
    // Always notify for important events
    if (_isCritical(data)) return true;
    
    // Notify for completed try-ons
    if (type == 'tryon_completed') return true;
    
    // Notify for calendar reminders
    if (type == 'event_reminder') return true;
    
    // Don't notify for processing updates
    if (type == 'tryon_processing') return false;
    
    return true;
  }
  
  /// Get notification priority based on type and context
  String getNotificationPriority(
    Map<String, dynamic> data,
    NotificationContext context,
  ) {
    if (_isCritical(data)) return 'high';
    
    final type = data['type'] as String?;
    if (type == 'tryon_completed') return 'high';
    if (type == 'event_reminder') return 'default';
    if (type == 'tryon_processing') return 'low';
    
    return 'default';
  }
}

enum UserActivityLevel {
  active,
  moderate,
  inactive,
}

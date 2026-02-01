/// Notification Model
/// Fashion AI-aware notification system
library;
import 'package:equatable/equatable.dart';

/// Notification types with AI-aware visual differentiation
enum NotificationType {
  // AI Try-On Notifications
  tryonCompleted, // 📸 Try-on completed
  tryonProcessing, // ⏳ Try-on processing (silent background)
  tryonFailed, // ❌ Try-on failed with retry
  tryonImproved, // ✨ Improved result available
  
  // Outfit & Style
  outfitReady, // 👗 Outfit recommendation ready
  styleLearned, // 🧠 AI learned your style
  wardrobeMatch, // 🛍 New wardrobe match found
  
  // Calendar & Events
  eventReminder, // 🗓 Event outfit reminder
  outfitScheduled, // 📅 Outfit scheduled for today
  aiRetryReminder, // 🔄 AI retry reminder
  
  // System
  system, // 🔔 General system notification
  securityAlert, // 🔒 Security alert
  appUpdate, // 📱 App update available
  accountChange, // 👤 Account change notification
}

/// Notification read state
enum NotificationState {
  unread,
  read,
  dismissed,
  saved, // Marked as important
}

class FashionNotification extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final NotificationState state;
  
  // Optional metadata
  final String? imageUrl;
  final String? actionUrl; // Deep link or route
  final Map<String, dynamic>? metadata; // Additional data (outfit ID, try-on session, etc.)
  
  // Visual properties
  final String? iconEmoji; // Custom emoji for type
  final String? accentColor; // Hex color for accent

  const FashionNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.state,
    this.imageUrl,
    this.actionUrl,
    this.metadata,
    this.iconEmoji,
    this.accentColor,
  });

  factory FashionNotification.fromJson(Map<String, dynamic> json) {
    return FashionNotification(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'] || e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.system,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      state: NotificationState.values.firstWhere(
        (e) => e.name == json['state'] || e.toString().split('.').last == json['state'],
        orElse: () => NotificationState.unread,
      ),
      imageUrl: json['image_url'] as String?,
      actionUrl: json['action_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      iconEmoji: json['icon_emoji'] as String?,
      accentColor: json['accent_color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'state': state.name,
      'image_url': imageUrl,
      'action_url': actionUrl,
      'metadata': metadata,
      'icon_emoji': iconEmoji,
      'accent_color': accentColor,
    };
  }

  FashionNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    NotificationState? state,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? metadata,
    String? iconEmoji,
    String? accentColor,
  }) {
    return FashionNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      state: state ?? this.state,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      metadata: metadata ?? this.metadata,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      accentColor: accentColor ?? this.accentColor,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        message,
        createdAt,
        state,
        imageUrl,
        actionUrl,
        metadata,
        iconEmoji,
        accentColor,
      ];
}

/// Extension for notification type properties
extension NotificationTypeExtension on NotificationType {
  /// Get emoji icon for notification type
  String get emoji {
    switch (this) {
      // AI Try-On
      case NotificationType.tryonCompleted:
        return '📸';
      case NotificationType.tryonProcessing:
        return '⏳';
      case NotificationType.tryonFailed:
        return '❌';
      case NotificationType.tryonImproved:
        return '✨';
      
      // Outfit & Style
      case NotificationType.outfitReady:
        return '👗';
      case NotificationType.styleLearned:
        return '🧠';
      case NotificationType.wardrobeMatch:
        return '🛍';
      
      // Calendar
      case NotificationType.eventReminder:
        return '🗓';
      case NotificationType.outfitScheduled:
        return '📅';
      case NotificationType.aiRetryReminder:
        return '🔄';
      
      // System
      case NotificationType.system:
        return '🔔';
      case NotificationType.securityAlert:
        return '🔒';
      case NotificationType.appUpdate:
        return '📱';
      case NotificationType.accountChange:
        return '👤';
    }
  }
  
  /// Get accent color hex for notification type
  String get accentColorHex {
    switch (this) {
      // AI Try-On - Soft neon green
      case NotificationType.tryonCompleted:
        return '#4ECDC4'; // Soft neon green
      case NotificationType.tryonProcessing:
        return '#FFB347'; // Animated amber
      case NotificationType.tryonFailed:
        return '#FF8C94'; // Muted coral
      case NotificationType.tryonImproved:
        return '#52C9A2'; // Calm emerald
      
      // Outfit & Style
      case NotificationType.outfitReady:
        return '#4A90E2'; // Muted electric blue
      case NotificationType.styleLearned:
        return '#10B981'; // Success green
      case NotificationType.wardrobeMatch:
        return '#7C3AED'; // Muted purple
      
      // Calendar
      case NotificationType.eventReminder:
        return '#F59E0B'; // Warning orange
      case NotificationType.outfitScheduled:
        return '#4ECDC4'; // Soft neon green
      case NotificationType.aiRetryReminder:
        return '#FFB347'; // Animated amber
      
      // System
      case NotificationType.system:
        return '#6B7280'; // Secondary gray
      case NotificationType.securityAlert:
        return '#EF4444'; // Error red
      case NotificationType.appUpdate:
        return '#4A90E2'; // Muted electric blue
      case NotificationType.accountChange:
        return '#6B7280'; // Secondary gray
    }
  }
  
  /// Get human-readable label
  String get label {
    switch (this) {
      // AI Try-On
      case NotificationType.tryonCompleted:
        return 'Try-On Complete';
      case NotificationType.tryonProcessing:
        return 'Processing';
      case NotificationType.tryonFailed:
        return 'Try-On Failed';
      case NotificationType.tryonImproved:
        return 'Improved Result';
      
      // Outfit & Style
      case NotificationType.outfitReady:
        return 'Outfit Ready';
      case NotificationType.styleLearned:
        return 'Style Learned';
      case NotificationType.wardrobeMatch:
        return 'Wardrobe Match';
      
      // Calendar
      case NotificationType.eventReminder:
        return 'Event Reminder';
      case NotificationType.outfitScheduled:
        return 'Outfit Scheduled';
      case NotificationType.aiRetryReminder:
        return 'Retry Reminder';
      
      // System
      case NotificationType.system:
        return 'System';
      case NotificationType.securityAlert:
        return 'Security Alert';
      case NotificationType.appUpdate:
        return 'App Update';
      case NotificationType.accountChange:
        return 'Account Change';
    }
  }
}


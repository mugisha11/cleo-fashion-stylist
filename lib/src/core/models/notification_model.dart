/// Notification Model
/// Fashion AI-aware notification system
import 'package:equatable/equatable.dart';

/// Notification types with AI-aware visual differentiation
enum NotificationType {
  outfitReady, // 👗 Outfit recommendation ready
  tryonCompleted, // 📸 Try-on completed
  styleLearned, // 🧠 AI learned your style
  eventReminder, // 🗓 Event outfit reminder
  wardrobeMatch, // 🛍 New wardrobe match found
  system, // General system notification
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
      case NotificationType.outfitReady:
        return '👗';
      case NotificationType.tryonCompleted:
        return '📸';
      case NotificationType.styleLearned:
        return '🧠';
      case NotificationType.eventReminder:
        return '🗓';
      case NotificationType.wardrobeMatch:
        return '🛍';
      case NotificationType.system:
        return '🔔';
    }
  }
  
  /// Get accent color hex for notification type
  String get accentColorHex {
    switch (this) {
      case NotificationType.outfitReady:
        return '#4A90E2'; // Muted electric blue
      case NotificationType.tryonCompleted:
        return '#7C3AED'; // Muted purple
      case NotificationType.styleLearned:
        return '#10B981'; // Success green
      case NotificationType.eventReminder:
        return '#F59E0B'; // Warning orange
      case NotificationType.wardrobeMatch:
        return '#EF4444'; // Error red (but used as accent)
      case NotificationType.system:
        return '#6B7280'; // Secondary gray
    }
  }
  
  /// Get human-readable label
  String get label {
    switch (this) {
      case NotificationType.outfitReady:
        return 'Outfit Ready';
      case NotificationType.tryonCompleted:
        return 'Try-On Complete';
      case NotificationType.styleLearned:
        return 'Style Learned';
      case NotificationType.eventReminder:
        return 'Event Reminder';
      case NotificationType.wardrobeMatch:
        return 'Wardrobe Match';
      case NotificationType.system:
        return 'System';
    }
  }
}


import 'package:equatable/equatable.dart';

/// Try-On Event Status
enum TryOnStatus {
  pending,
  processing,
  completed,
  failed,
}

/// Calendar Event with Try-On Integration
class TryOnCalendarEvent extends Equatable {
  final String id;
  final DateTime date;
  final String? eventName;
  final String? eventType;
  final String? outfitId;
  final String? outfitImageUrl;
  final String? tryOnSessionId;
  final TryOnStatus? tryOnStatus;
  final String? tryOnResultUrl;
  final double? progress; // 0.0 to 1.0 for processing
  final String? errorMessage;
  final bool isAIRecognized;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TryOnCalendarEvent({
    required this.id,
    required this.date,
    this.eventName,
    this.eventType,
    this.outfitId,
    this.outfitImageUrl,
    this.tryOnSessionId,
    this.tryOnStatus,
    this.tryOnResultUrl,
    this.progress,
    this.errorMessage,
    this.isAIRecognized = false,
    this.createdAt,
    this.updatedAt,
  });

  bool get hasTryOn => tryOnSessionId != null;
  bool get isProcessing => tryOnStatus == TryOnStatus.processing;
  bool get isCompleted => tryOnStatus == TryOnStatus.completed;
  bool get isFailed => tryOnStatus == TryOnStatus.failed;
  bool get isPending => tryOnStatus == TryOnStatus.pending;

  TryOnCalendarEvent copyWith({
    String? id,
    DateTime? date,
    String? eventName,
    String? eventType,
    String? outfitId,
    String? outfitImageUrl,
    String? tryOnSessionId,
    TryOnStatus? tryOnStatus,
    String? tryOnResultUrl,
    double? progress,
    String? errorMessage,
    bool? isAIRecognized,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TryOnCalendarEvent(
      id: id ?? this.id,
      date: date ?? this.date,
      eventName: eventName ?? this.eventName,
      eventType: eventType ?? this.eventType,
      outfitId: outfitId ?? this.outfitId,
      outfitImageUrl: outfitImageUrl ?? this.outfitImageUrl,
      tryOnSessionId: tryOnSessionId ?? this.tryOnSessionId,
      tryOnStatus: tryOnStatus ?? this.tryOnStatus,
      tryOnResultUrl: tryOnResultUrl ?? this.tryOnResultUrl,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      isAIRecognized: isAIRecognized ?? this.isAIRecognized,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0],
      'event_name': eventName,
      'event_type': eventType,
      'outfit_id': outfitId,
      'outfit_image_url': outfitImageUrl,
      'tryon_session_id': tryOnSessionId,
      'tryon_status': tryOnStatus?.name,
      'tryon_result_url': tryOnResultUrl,
      'progress': progress,
      'error_message': errorMessage,
      'is_ai_recognized': isAIRecognized,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory TryOnCalendarEvent.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String;
    final date = dateStr.contains('T')
        ? DateTime.parse(dateStr)
        : DateTime.parse('${dateStr}T00:00:00');

    TryOnStatus? status;
    if (json['tryon_status'] != null) {
      try {
        status = TryOnStatus.values.firstWhere(
          (e) => e.name == json['tryon_status'],
        );
      } catch (_) {
        status = null;
      }
    }

    return TryOnCalendarEvent(
      id: json['id'] as String,
      date: date,
      eventName: json['event_name'] as String?,
      eventType: json['event_type'] as String?,
      outfitId: json['outfit_id'] as String?,
      outfitImageUrl: json['outfit_image_url'] as String?,
      tryOnSessionId: json['tryon_session_id'] as String?,
      tryOnStatus: status,
      tryOnResultUrl: json['tryon_result_url'] as String?,
      progress: (json['progress'] as num?)?.toDouble(),
      errorMessage: json['error_message'] as String?,
      isAIRecognized: json['is_ai_recognized'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        eventName,
        eventType,
        outfitId,
        outfitImageUrl,
        tryOnSessionId,
        tryOnStatus,
        tryOnResultUrl,
        progress,
        errorMessage,
        isAIRecognized,
      ];
}

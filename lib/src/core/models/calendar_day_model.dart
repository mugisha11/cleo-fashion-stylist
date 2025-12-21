import 'package:equatable/equatable.dart';

/// Calendar Day Model - Represents a single day with outfit planning data
class CalendarDay extends Equatable {
  final DateTime date;
  final String? outfitId;
  final String? outfitName;
  final String? outfitImageUrl;
  final String? eventType; // 'work', 'casual', 'event', 'formal', etc.
  final String? eventName; // Custom event name
  final String source; // 'ai' or 'manual'
  final double? confidenceScore; // AI confidence (0.0 to 1.0)
  final bool isRecommended; // True if AI-recommended

  const CalendarDay({
    required this.date,
    this.outfitId,
    this.outfitName,
    this.outfitImageUrl,
    this.eventType,
    this.eventName,
    this.source = 'manual',
    this.confidenceScore,
    this.isRecommended = false,
  });

  bool get hasOutfit => outfitId != null && outfitImageUrl != null;
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  CalendarDay copyWith({
    DateTime? date,
    String? outfitId,
    String? outfitName,
    String? outfitImageUrl,
    String? eventType,
    String? eventName,
    String? source,
    double? confidenceScore,
    bool? isRecommended,
  }) {
    return CalendarDay(
      date: date ?? this.date,
      outfitId: outfitId ?? this.outfitId,
      outfitName: outfitName ?? this.outfitName,
      outfitImageUrl: outfitImageUrl ?? this.outfitImageUrl,
      eventType: eventType ?? this.eventType,
      eventName: eventName ?? this.eventName,
      source: source ?? this.source,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      isRecommended: isRecommended ?? this.isRecommended,
    );
  }

  Map<String, dynamic> toJson() {
    // Use date-only format (YYYY-MM-DD) for Supabase DATE column
    final dateStr = DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .split('T')[0];
    return {
      'date': dateStr,
      'outfit_id': outfitId,
      'outfit_name': outfitName,
      'outfit_image_url': outfitImageUrl,
      'event_type': eventType,
      'event_name': eventName,
      'source': source,
      'confidence_score': confidenceScore,
      'is_recommended': isRecommended,
    };
  }

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    // Handle both date-only (YYYY-MM-DD) and full ISO8601 formats
    final dateStr = json['date'] as String;
    final date = dateStr.contains('T')
        ? DateTime.parse(dateStr)
        : DateTime.parse('${dateStr}T00:00:00');
    return CalendarDay(
      date: date,
      outfitId: json['outfit_id'] as String?,
      outfitName: json['outfit_name'] as String?,
      outfitImageUrl: json['outfit_image_url'] as String?,
      eventType: json['event_type'] as String?,
      eventName: json['event_name'] as String?,
      source: json['source'] as String? ?? 'manual',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      isRecommended: json['is_recommended'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        date,
        outfitId,
        outfitName,
        outfitImageUrl,
        eventType,
        eventName,
        source,
        confidenceScore,
        isRecommended,
      ];
}

/// Outfit Event - For planning outfits with events
class OutfitEvent extends Equatable {
  final String id;
  final DateTime date;
  final String? eventType;
  final String? eventName;
  final String? description;
  final String? location;
  final DateTime? startTime;
  final DateTime? endTime;

  const OutfitEvent({
    required this.id,
    required this.date,
    this.eventType,
    this.eventName,
    this.description,
    this.location,
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toJson() {
    // Use date-only format (YYYY-MM-DD) for Supabase DATE column
    final dateStr = DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .split('T')[0];
    return {
      'id': id,
      'date': dateStr,
      'event_type': eventType,
      'event_name': eventName,
      'description': description,
      'location': location,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
    };
  }

  factory OutfitEvent.fromJson(Map<String, dynamic> json) {
    // Handle both date-only (YYYY-MM-DD) and full ISO8601 formats
    final dateStr = json['date'] as String;
    final date = dateStr.contains('T')
        ? DateTime.parse(dateStr)
        : DateTime.parse('${dateStr}T00:00:00');
    return OutfitEvent(
      id: json['id'] as String,
      date: date,
      eventType: json['event_type'] as String?,
      eventName: json['event_name'] as String?,
      description: json['description'] as String?,
      location: json['location'] as String?,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        eventType,
        eventName,
        description,
        location,
        startTime,
        endTime,
      ];
}


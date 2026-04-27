import 'package:equatable/equatable.dart';

/// Calendar Day Model - Represents a single day with outfit planning data
class CalendarDay extends Equatable {
  final DateTime date;
  final String? outfitId;
  final String? outfitName;
  final String? outfitImageUrl;
  final String? linkedOutfitId;
  final String? linkedOutfitName;
  final String? linkedOutfitImageUrl;
  final String? linkedTryonImageUrl;
  final String? outfitLinkingMethod;
  final DateTime? outfitLinkedAt;
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
    this.linkedOutfitId,
    this.linkedOutfitName,
    this.linkedOutfitImageUrl,
    this.linkedTryonImageUrl,
    this.outfitLinkingMethod,
    this.outfitLinkedAt,
    this.eventType,
    this.eventName,
    this.source = 'manual',
    this.confidenceScore,
    this.isRecommended = false,
  });

  bool get hasOutfit => outfitId != null ||
      (outfitName != null && outfitName!.trim().isNotEmpty) ||
      (outfitImageUrl != null && outfitImageUrl!.trim().isNotEmpty) ||
      (linkedOutfitId != null) ||
      (linkedOutfitName != null && linkedOutfitName!.trim().isNotEmpty) ||
      (linkedOutfitImageUrl != null && linkedOutfitImageUrl!.trim().isNotEmpty);

  bool get hasEvent => hasOutfit || eventName != null || eventType != null;

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
    String? linkedOutfitId,
    String? linkedOutfitName,
    String? linkedOutfitImageUrl,
    String? linkedTryonImageUrl,
    String? outfitLinkingMethod,
    DateTime? outfitLinkedAt,
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
      linkedOutfitId: linkedOutfitId ?? this.linkedOutfitId,
      linkedOutfitName: linkedOutfitName ?? this.linkedOutfitName,
      linkedOutfitImageUrl: linkedOutfitImageUrl ?? this.linkedOutfitImageUrl,
      linkedTryonImageUrl: linkedTryonImageUrl ?? this.linkedTryonImageUrl,
      outfitLinkingMethod: outfitLinkingMethod ?? this.outfitLinkingMethod,
      outfitLinkedAt: outfitLinkedAt ?? this.outfitLinkedAt,
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
      'linked_outfit_id': linkedOutfitId,
      'linked_outfit_name': linkedOutfitName,
      'linked_outfit_image_url': linkedOutfitImageUrl,
      'linked_tryon_image_url': linkedTryonImageUrl,
      'outfit_linking_method': outfitLinkingMethod,
      'outfit_linked_at': outfitLinkedAt?.toIso8601String(),
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
      linkedOutfitId: json['linked_outfit_id'] as String?,
      linkedOutfitName: json['linked_outfit_name'] as String?,
      linkedOutfitImageUrl: json['linked_outfit_image_url'] as String?,
      linkedTryonImageUrl: json['linked_tryon_image_url'] as String?,
      outfitLinkingMethod: json['outfit_linking_method'] as String?,
      outfitLinkedAt: json['outfit_linked_at'] != null
          ? DateTime.tryParse(json['outfit_linked_at'] as String)
          : null,
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
        linkedOutfitId,
        linkedOutfitName,
        linkedOutfitImageUrl,
        linkedTryonImageUrl,
        outfitLinkingMethod,
        outfitLinkedAt,
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

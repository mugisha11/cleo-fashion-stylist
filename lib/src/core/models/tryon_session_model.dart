import 'package:equatable/equatable.dart';

/// Try-On Session Model - Represents a saved try-on result
class TryOnSession extends Equatable {
  final String id;
  final String userId;
  final String baseImageUrl; // Original user photo
  final String resultImageUrl; // Final try-on result
  final List<String> outfitIds; // Wardrobe items used
  final String? poseSignature; // For pose matching/reuse
  final DateTime createdAt;
  final String? occasion;
  final String? eventType;
  final Map<String, dynamic>? metadata;

  const TryOnSession({
    required this.id,
    required this.userId,
    required this.baseImageUrl,
    required this.resultImageUrl,
    required this.outfitIds,
    this.poseSignature,
    required this.createdAt,
    this.occasion,
    this.eventType,
    this.metadata,
  });

  factory TryOnSession.fromJson(Map<String, dynamic> json) {
    return TryOnSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      baseImageUrl: json['base_image_url'] as String,
      resultImageUrl: json['result_image_url'] as String,
      outfitIds: (json['outfit_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      poseSignature: json['pose_signature'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      occasion: json['occasion'] as String?,
      eventType: json['event_type'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'base_image_url': baseImageUrl,
      'result_image_url': resultImageUrl,
      'outfit_ids': outfitIds,
      'pose_signature': poseSignature,
      'created_at': createdAt.toIso8601String(),
      'occasion': occasion,
      'event_type': eventType,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        baseImageUrl,
        resultImageUrl,
        outfitIds,
        poseSignature,
        createdAt,
        occasion,
        eventType,
        metadata,
      ];
}

/// AI Outfit Recommendation Model
class OutfitRecommendation extends Equatable {
  final String id;
  final String name;
  final String reasoning;
  final String? weatherMatch;
  final String? eventMatch;
  final String? tryOnImageUrl;
  final List<String> outfitItemIds;
  final double confidence;
  final DateTime recommendedFor;
  final Map<String, dynamic>? metadata;

  const OutfitRecommendation({
    required this.id,
    required this.name,
    required this.reasoning,
    this.weatherMatch,
    this.eventMatch,
    this.tryOnImageUrl,
    required this.outfitItemIds,
    required this.confidence,
    required this.recommendedFor,
    this.metadata,
  });

  factory OutfitRecommendation.fromJson(Map<String, dynamic> json) {
    return OutfitRecommendation(
      id: json['id'] as String,
      name: json['name'] as String,
      reasoning: json['reasoning'] as String,
      weatherMatch: json['weather_match'] as String?,
      eventMatch: json['event_match'] as String?,
      tryOnImageUrl: json['tryon_image_url'] as String?,
      outfitItemIds: (json['outfit_item_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      recommendedFor: DateTime.parse(json['recommended_for'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'reasoning': reasoning,
      'weather_match': weatherMatch,
      'event_match': eventMatch,
      'tryon_image_url': tryOnImageUrl,
      'outfit_item_ids': outfitItemIds,
      'confidence': confidence,
      'recommended_for': recommendedFor.toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        reasoning,
        weatherMatch,
        eventMatch,
        tryOnImageUrl,
        outfitItemIds,
        confidence,
        recommendedFor,
        metadata,
      ];
}

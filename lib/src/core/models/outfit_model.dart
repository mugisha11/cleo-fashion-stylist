import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Outfit Model - For saving user outfits to Firestore
class OutfitModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final List<String> itemIds;
  final String? previewImageUrl;
  final bool isRecommended;
  final DateTime createdAt;

  const OutfitModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.itemIds,
    this.previewImageUrl,
    this.isRecommended = false,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'itemIds': itemIds,
      'previewImageUrl': previewImageUrl,
      'isRecommended': isRecommended,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory OutfitModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OutfitModel(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      itemIds: List<String>.from(data['itemIds'] as List? ?? []),
      previewImageUrl: data['previewImageUrl'] as String?,
      isRecommended: data['isRecommended'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  @override
  List<Object?> get props => [id, userId, name, itemIds, previewImageUrl, isRecommended, createdAt];
}

/// Outfit Recommendation Model - For AI-generated outfit suggestions
class OutfitRecommendation extends Equatable {
  final String id;
  final String imageUrl;
  final String title;
  final String? description;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final double? confidence;
  final bool? fromWardrobe;

  const OutfitRecommendation({
    required this.id,
    required this.imageUrl,
    required this.title,
    this.description,
    this.tags = const [],
    this.metadata = const {},
    this.confidence,
    this.fromWardrobe,
  });

  factory OutfitRecommendation.fromJson(Map<String, dynamic> json) {
    return OutfitRecommendation(
      id: json['id'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String? ?? '',
      title: json['title'] as String? ?? 'Outfit',
      description: json['description'] as String?,
      tags: List<String>.from(json['tags'] as List? ?? []),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      confidence: (json['confidence'] as num?)?.toDouble(),
      fromWardrobe: json['from_wardrobe'] as bool? ?? json['fromWardrobe'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'title': title,
      'description': description,
      'tags': tags,
      'metadata': metadata,
      'confidence': confidence,
      'from_wardrobe': fromWardrobe,
    };
  }

  @override
  List<Object?> get props => [id, imageUrl, title, description, tags, metadata, confidence, fromWardrobe];
}

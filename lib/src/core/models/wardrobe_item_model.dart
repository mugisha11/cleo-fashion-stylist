import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class WardrobeItemModel extends Equatable {
  final String id;
  final String userId;
  final String imageUrl;
  final String category;
  final List<String> colorTags;
  final String? brand;
  final String? notes;
  final DateTime createdAt;

  const WardrobeItemModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.category,
    required this.colorTags,
    this.brand,
    this.notes,
    required this.createdAt,
  });

  factory WardrobeItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WardrobeItemModel(
      id: doc.id,
      userId: data['userId'] as String,
      imageUrl: data['imageUrl'] as String,
      category: data['category'] as String,
      colorTags: List<String>.from(data['colorTags'] as List),
      brand: data['brand'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  factory WardrobeItemModel.fromJson(Map<String, dynamic> json) {
    return WardrobeItemModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String? ?? '',
      category: json['category'] as String? ?? 'other',
      colorTags: json['color_tags'] != null
          ? List<String>.from(json['color_tags'] as List)
          : json['colorTags'] != null
              ? List<String>.from(json['colorTags'] as List)
              : [],
      brand: json['brand'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'category': category,
      'colorTags': colorTags,
      'brand': brand,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  WardrobeItemModel copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? category,
    List<String>? colorTags,
    String? brand,
    String? notes,
    DateTime? createdAt,
  }) {
    return WardrobeItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      colorTags: colorTags ?? this.colorTags,
      brand: brand ?? this.brand,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, imageUrl, category, colorTags, brand, notes, createdAt];
}


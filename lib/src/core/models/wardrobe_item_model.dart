import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class WardrobeItemModel extends Equatable {
  final String id;
  final String userId;
  final String imageUrl;
  final String? processedImageUrl; // Background-removed image URL
  final String category;
  final List<String> colorTags;
  final String? brand;
  final String? notes;
  final DateTime createdAt;
  
  // AI-extracted metadata
  final double? aiConfidence; // Confidence score from AI analysis
  final String? pattern; // Pattern type (Plain, Striped, Floral, etc.)
  final Map<String, dynamic>? aiAttributes; // Additional AI attributes
  final List<Map<String, dynamic>>? colorPalette; // Detailed color palette with hex/name/percentage
  
  // Enhanced AI understanding fields
  final String? subcategory; // e.g., "blazer", "hoodie", "maxi dress", "jeans"
  final String? genderStyle; // "feminine", "masculine", "unisex"
  final String? fit; // "slim", "loose", "oversized", "regular"
  final List<String>? season; // ["summer", "winter", "spring", "fall", "all-season"]
  final List<String>? occasion; // ["casual", "formal", "business", "party", "sport"]
  final String? fabric; // "cotton", "denim", "leather", "knit", "silk", "synthetic", "wool"
  final String? bodyRegion; // "upper", "lower", "full"
  final bool? layeringCompatibility; // Can this be layered?
  final double? patternConfidence; // Confidence for pattern detection

  const WardrobeItemModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.processedImageUrl,
    required this.category,
    required this.colorTags,
    this.brand,
    this.notes,
    required this.createdAt,
    this.aiConfidence,
    this.pattern,
    this.aiAttributes,
    this.colorPalette,
    this.subcategory,
    this.genderStyle,
    this.fit,
    this.season,
    this.occasion,
    this.fabric,
    this.bodyRegion,
    this.layeringCompatibility,
    this.patternConfidence,
  });

  factory WardrobeItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WardrobeItemModel(
      id: doc.id,
      userId: data['userId'] as String,
      imageUrl: data['imageUrl'] as String,
      processedImageUrl: data['processedImageUrl'] as String?,
      category: data['category'] as String,
      colorTags: List<String>.from(data['colorTags'] as List),
      brand: data['brand'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      aiConfidence: (data['aiConfidence'] as num?)?.toDouble(),
      pattern: data['pattern'] as String?,
      aiAttributes: data['aiAttributes'] as Map<String, dynamic>?,
      colorPalette: data['colorPalette'] != null
          ? List<Map<String, dynamic>>.from(data['colorPalette'] as List)
          : null,
      subcategory: data['subcategory'] as String?,
      genderStyle: data['genderStyle'] as String?,
      fit: data['fit'] as String?,
      season: data['season'] != null ? List<String>.from(data['season'] as List) : null,
      occasion: data['occasion'] != null ? List<String>.from(data['occasion'] as List) : null,
      fabric: data['fabric'] as String?,
      bodyRegion: data['bodyRegion'] as String?,
      layeringCompatibility: data['layeringCompatibility'] as bool?,
      patternConfidence: (data['patternConfidence'] as num?)?.toDouble(),
    );
  }

  factory WardrobeItemModel.fromJson(Map<String, dynamic> json) {
    return WardrobeItemModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String? ?? '',
      processedImageUrl: json['processed_image_url'] as String? ?? json['processedImageUrl'] as String?,
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
              ? (json['createdAt'] is String
                  ? DateTime.parse(json['createdAt'] as String)
                  : DateTime.now())
              : DateTime.now(),
      aiConfidence: (json['ai_confidence'] as num?)?.toDouble() ?? (json['aiConfidence'] as num?)?.toDouble(),
      pattern: json['pattern'] as String?,
      aiAttributes: json['ai_attributes'] as Map<String, dynamic>? ?? json['aiAttributes'] as Map<String, dynamic>?,
      colorPalette: json['color_palette'] != null
          ? List<Map<String, dynamic>>.from(json['color_palette'] as List)
          : json['colorPalette'] != null
              ? List<Map<String, dynamic>>.from(json['colorPalette'] as List)
              : null,
      subcategory: json['subcategory'] as String?,
      genderStyle: json['genderStyle'] as String? ?? json['gender_style'] as String?,
      fit: json['fit'] as String?,
      season: json['season'] != null ? List<String>.from(json['season'] as List) : null,
      occasion: json['occasion'] != null ? List<String>.from(json['occasion'] as List) : null,
      fabric: json['fabric'] as String?,
      bodyRegion: json['bodyRegion'] as String? ?? json['body_region'] as String?,
      layeringCompatibility: json['layeringCompatibility'] as bool? ?? json['layering_compatibility'] as bool?,
      patternConfidence: (json['patternConfidence'] as num?)?.toDouble() ?? (json['pattern_confidence'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      if (processedImageUrl != null) 'processedImageUrl': processedImageUrl,
      'category': category,
      'colorTags': colorTags,
      'brand': brand,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      if (aiConfidence != null) 'aiConfidence': aiConfidence,
      if (pattern != null) 'pattern': pattern,
      if (aiAttributes != null) 'aiAttributes': aiAttributes,
      if (colorPalette != null) 'colorPalette': colorPalette,
      if (subcategory != null) 'subcategory': subcategory,
      if (genderStyle != null) 'genderStyle': genderStyle,
      if (fit != null) 'fit': fit,
      if (season != null) 'season': season,
      if (occasion != null) 'occasion': occasion,
      if (fabric != null) 'fabric': fabric,
      if (bodyRegion != null) 'bodyRegion': bodyRegion,
      if (layeringCompatibility != null) 'layeringCompatibility': layeringCompatibility,
      if (patternConfidence != null) 'patternConfidence': patternConfidence,
    };
  }

  WardrobeItemModel copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? processedImageUrl,
    String? category,
    List<String>? colorTags,
    String? brand,
    String? notes,
    DateTime? createdAt,
    double? aiConfidence,
    String? pattern,
    Map<String, dynamic>? aiAttributes,
    List<Map<String, dynamic>>? colorPalette,
    String? subcategory,
    String? genderStyle,
    String? fit,
    List<String>? season,
    List<String>? occasion,
    String? fabric,
    String? bodyRegion,
    bool? layeringCompatibility,
    double? patternConfidence,
  }) {
    return WardrobeItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      processedImageUrl: processedImageUrl ?? this.processedImageUrl,
      category: category ?? this.category,
      colorTags: colorTags ?? this.colorTags,
      brand: brand ?? this.brand,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      pattern: pattern ?? this.pattern,
      aiAttributes: aiAttributes ?? this.aiAttributes,
      colorPalette: colorPalette ?? this.colorPalette,
      subcategory: subcategory ?? this.subcategory,
      genderStyle: genderStyle ?? this.genderStyle,
      fit: fit ?? this.fit,
      season: season ?? this.season,
      occasion: occasion ?? this.occasion,
      fabric: fabric ?? this.fabric,
      bodyRegion: bodyRegion ?? this.bodyRegion,
      layeringCompatibility: layeringCompatibility ?? this.layeringCompatibility,
      patternConfidence: patternConfidence ?? this.patternConfidence,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        imageUrl,
        processedImageUrl,
        category,
        colorTags,
        brand,
        notes,
        createdAt,
        aiConfidence,
        pattern,
        aiAttributes,
        colorPalette,
        subcategory,
        genderStyle,
        fit,
        season,
        occasion,
        fabric,
        bodyRegion,
        layeringCompatibility,
        patternConfidence,
      ];
}


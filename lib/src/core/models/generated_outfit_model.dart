import 'package:cloud_firestore/cloud_firestore.dart';

/// A saved generated outfit (e.g. from Try-On) that can be shared in chat.
class GeneratedOutfitModel {
  final String id;
  final String userId;
  final String imageUrl;
  final String? caption;
  final DateTime createdAt;

  const GeneratedOutfitModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.caption,
    required this.createdAt,
  });

  factory GeneratedOutfitModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return GeneratedOutfitModel(
      id: doc.id,
      userId: d['userId'] as String,
      imageUrl: d['imageUrl'] as String,
      caption: d['caption'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'imageUrl': imageUrl,
        if (caption != null) 'caption': caption,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

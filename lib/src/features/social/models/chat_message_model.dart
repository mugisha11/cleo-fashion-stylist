import 'package:cloud_firestore/cloud_firestore.dart';

/// Single message in a chat. type: text | image | tryon
class ChatMessageModel {
  final String id;
  final String senderId;
  final String text;
  final String type; // 'text' | 'image' | 'tryon'
  final String? imageUrl;
  final DateTime createdAt;
  final bool seen;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.type = 'text',
    this.imageUrl,
    required this.createdAt,
    this.seen = false,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      senderId: d['senderId'] as String,
      text: d['text'] as String? ?? '',
      type: d['type'] as String? ?? 'text',
      imageUrl: d['imageUrl'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      seen: d['seen'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'senderId': senderId,
        'text': text,
        'type': type,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'seen': seen,
      };

  bool get isImage => type == 'image';
  bool get isTryon => type == 'tryon';
}

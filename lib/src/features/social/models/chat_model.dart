import 'package:cloud_firestore/cloud_firestore.dart';

/// Chat between two participants
class ChatModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? updatedAt;
  final String? lastSenderId;

  const ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.updatedAt,
    this.lastSenderId,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(d['participants'] as List<dynamic>? ?? []),
      lastMessage: d['lastMessage'] as String?,
      updatedAt: d['updatedAt'] != null ? (d['updatedAt'] as Timestamp).toDate() : null,
      lastSenderId: d['lastSenderId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'participants': participants,
        'lastMessage': lastMessage,
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'lastSenderId': lastSenderId,
      };

  String otherUserId(String myUserId) {
    return participants.firstWhere((p) => p != myUserId, orElse: () => '');
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// All app notification types: friend_request | request_accepted | new_message | post_liked | post_comment | tryon_shared
class SocialNotificationModel {
  final String id;
  final String type;
  final String fromUserId;
  final String toUserId;
  final String? fromUserName;
  final String? requestId;
  final String? chatId;
  final String? messagePreview;
  final String? postId;
  final String? imageUrl;
  final bool read;
  final DateTime createdAt;

  const SocialNotificationModel({
    required this.id,
    required this.type,
    required this.fromUserId,
    required this.toUserId,
    this.fromUserName,
    this.requestId,
    this.chatId,
    this.messagePreview,
    this.postId,
    this.imageUrl,
    this.read = false,
    required this.createdAt,
  });

  factory SocialNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SocialNotificationModel(
      id: doc.id,
      type: d['type'] as String,
      fromUserId: d['fromUserId'] as String,
      toUserId: d['toUserId'] as String,
      fromUserName: d['fromUserName'] as String?,
      requestId: d['requestId'] as String?,
      chatId: d['chatId'] as String?,
      messagePreview: d['messagePreview'] as String?,
      postId: d['postId'] as String?,
      imageUrl: d['imageUrl'] as String?,
      read: d['read'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'type': type,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        if (fromUserName != null) 'fromUserName': fromUserName,
        if (requestId != null) 'requestId': requestId,
        if (chatId != null) 'chatId': chatId,
        if (messagePreview != null) 'messagePreview': messagePreview,
        if (postId != null) 'postId': postId,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'read': read,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

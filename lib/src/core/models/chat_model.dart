import 'package:equatable/equatable.dart';

/// Chat conversation model
class ChatConversation extends Equatable {
  final String id;
  final String userId;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final int messageCount;

  const ChatConversation({
    required this.id,
    required this.userId,
    this.title,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    required this.messageCount,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      messageCount: json['message_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_message_at': lastMessageAt?.toIso8601String(),
      'message_count': messageCount,
    };
  }

  @override
  List<Object?> get props => [id, userId, title, createdAt, updatedAt];
}

/// Chat message model
class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final String userId;
  final String role; // 'user' or 'assistant'
  final String content;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final int sequenceNumber;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.role,
    required this.content,
    this.metadata,
    required this.createdAt,
    required this.sequenceNumber,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      sequenceNumber: json['sequence_number'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'role': role,
      'content': content,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'sequence_number': sequenceNumber,
    };
  }

  @override
  List<Object?> get props => [id, conversationId, role, content, createdAt];
}


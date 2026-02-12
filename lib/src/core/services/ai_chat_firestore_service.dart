import 'package:cloud_firestore/cloud_firestore.dart';

/// Persists dashboard AI chat (Cleo) messages in Firestore so chat is not lost.
/// Path: ai_chats/{userId} (one chat per user), subcollection messages/{messageId}.
class AiChatFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _chats = 'ai_chats';
  static const String _messages = 'messages';

  /// Ensure the chat document exists for the user (required for rules).
  Future<void> _ensureChatDoc(String userId) async {
    final ref = _firestore.collection(_chats).doc(userId);
    await ref.set({
      'userId': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Save one message to the user's AI chat. Call after adding to local _messages.
  Future<void> saveMessage(String userId, AiChatMessageDto msg) async {
    if (userId.isEmpty) return;
    await _ensureChatDoc(userId);
    final ref = _firestore
        .collection(_chats)
        .doc(userId)
        .collection(_messages)
        .doc(msg.id);
    await ref.set(msg.toMap());
  }

  /// Load all messages for the user, ordered by timestamp. Returns list for initial load.
  Future<List<AiChatMessageDto>> getMessages(String userId) async {
    if (userId.isEmpty) return [];
    final snap = await _firestore
        .collection(_chats)
        .doc(userId)
        .collection(_messages)
        .orderBy('timestamp', descending: false)
        .get();
    return snap.docs
        .map((d) => AiChatMessageDto.fromMap(d.id, d.data()))
        .toList();
  }

  /// Stream of messages for real-time updates (optional).
  Stream<List<AiChatMessageDto>> watchMessages(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _firestore
        .collection(_chats)
        .doc(userId)
        .collection(_messages)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AiChatMessageDto.fromMap(d.id, d.data()))
            .toList());
  }
}

/// Serializable DTO for one AI chat message (Firestore). Dashboard converts to/from ChatMessage.
class AiChatMessageDto {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imageUrl;
  final bool isError;
  final String? buyLinkUrl;
  final String? externalImageUrl;
  final String? externalDisplayImageUrl;
  final String? externalProductPageUrl;
  final List<Map<String, String?>>? searchedProducts;

  AiChatMessageDto({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageUrl,
    this.isError = false,
    this.buyLinkUrl,
    this.externalImageUrl,
    this.externalDisplayImageUrl,
    this.externalProductPageUrl,
    this.searchedProducts,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
      if (imageUrl != null) 'imageUrl': imageUrl,
      'isError': isError,
      if (buyLinkUrl != null) 'buyLinkUrl': buyLinkUrl,
      if (externalImageUrl != null) 'externalImageUrl': externalImageUrl,
      if (externalDisplayImageUrl != null) 'externalDisplayImageUrl': externalDisplayImageUrl,
      if (externalProductPageUrl != null) 'externalProductPageUrl': externalProductPageUrl,
      if (searchedProducts != null && searchedProducts!.isNotEmpty)
        'searchedProducts': searchedProducts,
    };
  }

  static AiChatMessageDto fromMap(String id, Map<String, dynamic> data) {
    final ts = data['timestamp'];
    final timestamp = ts is Timestamp
        ? ts.toDate()
        : (ts is DateTime ? ts : DateTime.now());
    final sp = data['searchedProducts'];
    List<Map<String, String?>>? searchedProducts;
    if (sp is List) {
      searchedProducts = sp
          .map((e) => (e is Map ? Map<String, String?>.from(e.map((k, v) => MapEntry(k.toString(), v?.toString()))) : <String, String?>{}))
          .toList();
    }
    return AiChatMessageDto(
      id: data['id'] as String? ?? id,
      text: data['text'] as String? ?? '',
      isUser: data['isUser'] as bool? ?? false,
      timestamp: timestamp,
      imageUrl: data['imageUrl'] as String?,
      isError: data['isError'] as bool? ?? false,
      buyLinkUrl: data['buyLinkUrl'] as String?,
      externalImageUrl: data['externalImageUrl'] as String?,
      externalDisplayImageUrl: data['externalDisplayImageUrl'] as String?,
      externalProductPageUrl: data['externalProductPageUrl'] as String?,
      searchedProducts: searchedProducts,
    );
  }
}

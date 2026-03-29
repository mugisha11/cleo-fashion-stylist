import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/chat_message_model.dart';
import '../models/friend_request_model.dart';
import '../models/social_notification_model.dart';
import '../models/social_user_profile.dart';

/// Firebase-backed social service: friend requests, chats, messages, notifications
class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _users = 'users';
  static const String _friendRequests = 'friend_requests';
  static const String _chats = 'chats';
  static const String _messages = 'messages';
  static const String _notifications = 'notifications';

  // ---------- User profile (friends + bio) ----------
  Future<void> ensureUserSocialProfile(String userId, {String? name, String? avatarUrl, String? bio}) async {
    final ref = _firestore.collection(_users).doc(userId);
    final doc = await ref.get();
    final Map<String, dynamic> data = {};
    if (!doc.exists || doc.data() == null) {
      data['friends'] = <String>[];
      data['createdAt'] = FieldValue.serverTimestamp();
    } else if (doc.data()!['friends'] == null) {
      data['friends'] = <String>[];
    }
    if (name != null) data['displayName'] = name;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (bio != null) data['bio'] = bio;
    if (data.isNotEmpty) await ref.set(data, SetOptions(merge: true));
  }

  Future<SocialUserProfile?> getUserProfile(String userId) async {
    final doc = await _firestore.collection(_users).doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return SocialUserProfile.fromMap(doc.id, doc.data()!);
  }

  Stream<SocialUserProfile?> watchUserProfile(String userId) {
    return _firestore.collection(_users).doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return SocialUserProfile.fromMap(doc.id, doc.data()!);
    });
  }

  /// List users for Discover (all people on platform). Excludes [excludeUserId].
  /// Used for "Everyone" and as base for "Suggested for you" (sort by mutual friends in app).
  Future<List<SocialUserProfile>> getDiscoverUsers({
    int limit = 150,
    String? excludeUserId,
  }) async {
    final snap = await _firestore
        .collection(_users)
        .limit(limit)
        .get();
    final list = <SocialUserProfile>[];
    for (final doc in snap.docs) {
      if (doc.id == excludeUserId) continue;
      final data = doc.data();
      if (data.isEmpty) continue;
      list.add(SocialUserProfile.fromMap(doc.id, data));
    }
    return list;
  }

  // ---------- Friend requests ----------
  Future<void> sendFriendRequest(String fromUserId, String toUserId, {String? fromName, String? fromAvatar}) async {
    final from = fromUserId;
    final to = toUserId;
    if (from == to) return;
    final q = await _firestore
        .collection(_friendRequests)
        .where('from', isEqualTo: from)
        .where('to', isEqualTo: to)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) return; // already sent
    final ref = _firestore.collection(_friendRequests).doc();
    await ref.set({
      'from': from,
      'to': to,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _createNotification(
      type: 'friend_request',
      fromUserId: from,
      toUserId: to,
      requestId: ref.id,
    );
  }

  Future<void> cancelFriendRequest(String requestId) async {
    await _firestore.collection(_friendRequests).doc(requestId).delete();
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final doc = await _firestore.collection(_friendRequests).doc(requestId).get();
    if (!doc.exists) throw Exception('Friend request not found');
    final d = doc.data()!;
    final from = d['from'] as String? ?? '';
    final to = d['to'] as String? ?? '';
    if (from.isEmpty || to.isEmpty) throw Exception('Invalid friend request data');

    final fromRef = _firestore.collection(_users).doc(from);
    final toRef = _firestore.collection(_users).doc(to);
    final fromSnap = await fromRef.get();
    final toSnap = await toRef.get();
    final fromFriends = List<String>.from(fromSnap.data()?['friends'] as List<dynamic>? ?? []);
    final toFriends = List<String>.from(toSnap.data()?['friends'] as List<dynamic>? ?? []);
    if (!fromFriends.contains(to)) fromFriends.add(to);
    if (!toFriends.contains(from)) toFriends.add(from);

    await _firestore.collection(_friendRequests).doc(requestId).update({'status': 'accepted'});
    await toRef.set({'friends': toFriends}, SetOptions(merge: true));
    await fromRef.set({'friends': fromFriends}, SetOptions(merge: true));
    await _createNotification(type: 'request_accepted', fromUserId: from, toUserId: to, requestId: requestId);
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _firestore.collection(_friendRequests).doc(requestId).update({'status': 'rejected'});
  }

  Stream<List<FriendRequestModel>> watchRequestsToMe(String userId) {
    return _firestore
        .collection(_friendRequests)
        .where('to', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => FriendRequestModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<FriendRequestModel>> watchRequestsFromMe(String userId) {
    return _firestore
        .collection(_friendRequests)
        .where('from', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => FriendRequestModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<FriendRequestModel?> getRequestBetween(String from, String to) async {
    final q = await _firestore
        .collection(_friendRequests)
        .where('from', isEqualTo: from)
        .where('to', isEqualTo: to)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return FriendRequestModel.fromFirestore(q.docs.first);
  }

  Future<String?> getRequestIdFromTo(String from, String to) async {
    final r = await getRequestBetween(from, to);
    return r?.id;
  }

  // ---------- Chats ----------
  Future<String> getOrCreateChat(String userId1, String userId2) async {
    final ids = [userId1, userId2]..sort();
    final q = await _firestore
        .collection(_chats)
        .where('participants', isEqualTo: ids)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) return q.docs.first.id;
    final ref = await _firestore.collection(_chats).add({
      'participants': ids,
      'lastMessage': null,
      'lastSenderId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<List<ChatModel>> watchChatsForUser(String userId) {
    return _firestore
        .collection(_chats)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => ChatModel.fromFirestore(d)).toList();
          list.sort((a, b) {
            final at = a.updatedAt ?? DateTime(0);
            final bt = b.updatedAt ?? DateTime(0);
            return bt.compareTo(at);
          });
          return list;
        });
  }

  Stream<List<ChatMessageModel>> watchMessages(String chatId) {
    return _firestore
        .collection(_chats)
        .doc(chatId)
        .collection(_messages)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatMessageModel.fromFirestore(d)).toList());
  }

  Future<void> sendMessage(String chatId, String senderId, String text, {String type = 'text', String? imageUrl, String? senderName}) async {
    final batch = _firestore.batch();
    final msgRef = _firestore.collection(_chats).doc(chatId).collection(_messages).doc();
    batch.set(msgRef, {
      'senderId': senderId,
      'text': text,
      'type': type,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'seen': false,
    });
    final chatRef = _firestore.collection(_chats).doc(chatId);
    batch.update(chatRef, {
      'lastMessage': text,
      'lastSenderId': senderId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    final chatDoc = await chatRef.get();
    if (chatDoc.exists) {
      final participants = List<String>.from(chatDoc.data()!['participants'] as List<dynamic>? ?? []);
      final other = participants.where((id) => id != senderId).toList();
      final otherUserId = other.isEmpty ? null : other.first;
      if (otherUserId != null) {
        await _createNotification(
          type: 'new_message',
          fromUserId: senderId,
          toUserId: otherUserId,
          chatId: chatId,
          messagePreview: text.length > 80 ? '${text.substring(0, 80)}…' : text,
          fromUserName: senderName,
        );
      }
    }
  }

  Future<void> markMessagesSeen(String chatId, String byUserId) async {
    final snap = await _firestore
        .collection(_chats)
        .doc(chatId)
        .collection(_messages)
        .where('senderId', isNotEqualTo: byUserId)
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'seen': true});
    }
    if (snap.docs.isNotEmpty) await batch.commit();
  }

  // ---------- Notifications ----------
  Future<void> _createNotification({
    required String type,
    required String fromUserId,
    required String toUserId,
    String? fromUserName,
    String? requestId,
    String? chatId,
    String? messagePreview,
    String? postId,
    String? imageUrl,
  }) async {
    await _firestore.collection(_notifications).add({
      'type': type,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      if (fromUserName != null) 'fromUserName': fromUserName,
      if (requestId != null) 'requestId': requestId,
      if (chatId != null) 'chatId': chatId,
      if (messagePreview != null) 'messagePreview': messagePreview,
      if (postId != null) 'postId': postId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createNewMessageNotification(String fromUserId, String toUserId, String chatId, String messagePreview, {String? fromUserName}) async {
    await _createNotification(
      type: 'new_message',
      fromUserId: fromUserId,
      toUserId: toUserId,
      chatId: chatId,
      messagePreview: messagePreview,
      fromUserName: fromUserName,
    );
  }

  Future<void> createPostLikedNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
    required String postId,
    String? postImageUrl,
  }) async {
    if (toUserId == fromUserId) return;
    await _createNotification(
      type: 'post_liked',
      fromUserId: fromUserId,
      toUserId: toUserId,
      fromUserName: fromUserName,
      postId: postId,
      imageUrl: postImageUrl,
    );
  }

  Future<void> createPostCommentNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
    required String postId,
    required String commentPreview,
    String? postImageUrl,
  }) async {
    if (toUserId == fromUserId) return;
    await _createNotification(
      type: 'post_comment',
      fromUserId: fromUserId,
      toUserId: toUserId,
      fromUserName: fromUserName,
      postId: postId,
      messagePreview: commentPreview,
      imageUrl: postImageUrl,
    );
  }

  /// Create a notification when the user's virtual try-on completes (self-notification).
  Future<void> createTryOnCompletedNotification({
    required String userId,
    String? messagePreview,
    String? imageUrl,
  }) async {
    await _createNotification(
      type: 'tryon_completed',
      fromUserId: userId,
      toUserId: userId,
      fromUserName: 'Nikonyx',
      messagePreview: messagePreview ?? 'Your try-on is ready!',
      imageUrl: imageUrl,
    );
  }

  Stream<List<SocialNotificationModel>> watchNotificationsForUser(String userId) {
    return _firestore
        .collection(_notifications)
        .where('toUserId', isEqualTo: userId)
        .limit(100)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => SocialNotificationModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _firestore.collection(_notifications).doc(notificationId).update({'read': true});
  }

  Future<void> markAllNotificationsRead(String userId) async {
    final snap = await _firestore
        .collection(_notifications)
        .where('toUserId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    if (snap.docs.isNotEmpty) await batch.commit();
  }
}

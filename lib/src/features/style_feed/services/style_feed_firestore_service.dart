import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../models/look_post_model.dart';

/// Style feed: post images → Supabase Storage; post metadata (feed, likes, comments) → Firestore.
/// Console "undefined" / WebChannel warnings come from Firestore when the network drops, not from Supabase.
class StyleFeedFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _posts = 'style_feed_posts';
  static const String _styleFeedBucket = 'style_feed';

  /// Upload post image to Supabase Storage and return public URL.
  /// On 400: bucket may be missing — create "style_feed" in Supabase Dashboard → Storage and add INSERT policy for anon.
  Future<String> uploadPostImage({
    required String userId,
    required String postId,
    required Uint8List bytes,
  }) async {
    try {
      final client = Supabase.instance.client;
      final storage = SupabaseStorageService(client);
      final path = '$userId/$postId.jpg';
      return await storage.uploadFile(
        bucket: _styleFeedBucket,
        path: path,
        file: bytes,
        contentType: 'image/jpeg',
      );
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('400') || msg.contains('Bad Request') || msg.contains('Bucket not found')) {
        throw Exception(
          'Post image upload failed. Create the "style_feed" bucket in Supabase Dashboard → Storage (New bucket), '
          'then add an INSERT policy for the anon role. See docs/setup/SUPABASE_STORAGE_STYLE_FEED.md',
        );
      }
      rethrow;
    }
  }

  /// Add a new post. If [imageBytes] is provided, upload to Storage and use URL; else [imageUrl] must be set (e.g. data URL for web).
  Future<LookPost> addPost({
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required String caption,
    required List<String> tags,
    required bool isPublic,
    Uint8List? imageBytes,
    String? imageUrl,
  }) async {
    final postId = _firestore.collection(_posts).doc().id;
    String finalImageUrl = imageUrl ?? '';

    if (imageBytes != null && imageBytes.isNotEmpty) {
      finalImageUrl = await uploadPostImage(userId: userId, postId: postId, bytes: imageBytes);
    }
    if (finalImageUrl.isEmpty) throw ArgumentError('Need imageBytes or imageUrl');

    final post = LookPost(
      id: postId,
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      imagePath: finalImageUrl,
      caption: caption,
      tags: tags,
      isPublic: isPublic,
      likeCount: 0,
      commentCount: 0,
      shareCount: 0,
      viewCount: 0,
      likedByUserIds: const [],
      savedByUserIds: const [],
      comments: const [],
      createdAt: DateTime.now(),
    );

    await _firestore.collection(_posts).doc(postId).set(post.toFirestore());
    return post;
  }

  /// Stream all posts ordered by createdAt descending.
  /// Skips any document that fails to parse so one bad doc doesn't break the feed.
  Stream<List<LookPost>> watchPosts() {
    return _firestore
        .collection(_posts)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      final list = <LookPost>[];
      for (final d in snap.docs) {
        try {
          list.add(LookPost.fromFirestore(d.id, d.data()));
        } catch (_) {
          // Skip malformed documents
        }
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Toggle like: add/remove current user from likedByUserIds and update likeCount.
  Future<void> toggleLike(String postId, String userId) async {
    final ref = _firestore.collection(_posts).doc(postId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      final liked = List<String>.from(data['likedByUserIds'] as List<dynamic>? ?? []);
      final count = data['likeCount'] as int? ?? 0;
      final isLiked = liked.contains(userId);
      if (isLiked) {
        liked.remove(userId);
        tx.update(ref, {'likedByUserIds': liked, 'likeCount': count - 1});
      } else {
        liked.add(userId);
        tx.update(ref, {'likedByUserIds': liked, 'likeCount': count + 1});
      }
    });
  }

  /// Toggle save: add/remove current user from savedByUserIds.
  Future<void> toggleSave(String postId, String userId) async {
    final ref = _firestore.collection(_posts).doc(postId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final saved = List<String>.from(data['savedByUserIds'] as List<dynamic>? ?? []);
    if (saved.contains(userId)) {
      saved.remove(userId);
    } else {
      saved.add(userId);
    }
    await ref.update({'savedByUserIds': saved});
  }

  /// Add a comment and update commentCount.
  Future<void> addComment(String postId, LookPostComment comment) async {
    final ref = _firestore.collection(_posts).doc(postId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final comments = List<Map<String, dynamic>>.from(
      (data['comments'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
    );
    comments.add(comment.toFirestore());
    final count = comments.length;
    await ref.update({'comments': comments, 'commentCount': count});
  }

  /// Increment view count.
  Future<void> incrementViewCount(String postId) async {
    final ref = _firestore.collection(_posts).doc(postId);
    await ref.update({'viewCount': FieldValue.increment(1)});
  }

  /// Increment share count.
  Future<void> incrementShareCount(String postId) async {
    final ref = _firestore.collection(_posts).doc(postId);
    await ref.update({'shareCount': FieldValue.increment(1)});
  }
}

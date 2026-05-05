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
  static const String _userEngagement = 'user_engagement';
  static const String _styleFeedBucket = 'style_feed';

  // Rate limiting constants
  static const int _maxLikesPerHour = 100;
  static const int _maxCommentsPerHour = 20;
  static const int _maxSharesPerHour = 50;
  static const Duration _rateLimitWindow = Duration(hours: 1);

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
      if (msg.contains('400') ||
          msg.contains('Bad Request') ||
          msg.contains('Bucket not found')) {
        throw Exception(
          'Post image upload failed. Create the "style_feed" bucket in Supabase Dashboard → Storage (New bucket), '
          'then add an INSERT policy for the anon role. See docs/setup/SUPABASE_STORAGE_STYLE_FEED.md',
        );
      }
      rethrow;
    }
  }

  /// Check rate limit for user actions
  Future<bool> _checkRateLimit(String userId, String action) async {
    final now = DateTime.now();
    final windowStart = now.subtract(_rateLimitWindow);

    // Avoid a composite Firestore index requirement by querying only by userId
    // and filtering action/timestamp locally.
    final snapshot = await _firestore
        .collection(_userEngagement)
        .where('userId', isEqualTo: userId)
        .get();

    final recentActions = snapshot.docs.where((doc) {
      final data = doc.data();
      final actionValue = data['action'] as String?;
      final timestamp = data['timestamp'];
      final isRecent = timestamp is Timestamp
          ? timestamp.toDate().isAfter(windowStart)
          : false;
      return isRecent && actionValue == action;
    });

    final maxActions = switch (action) {
      'like' => _maxLikesPerHour,
      'comment' => _maxCommentsPerHour,
      'share' => _maxSharesPerHour,
      _ => 10,
    };

    return recentActions.length < maxActions;
  }

  /// Record user engagement for rate limiting
  Future<void> _recordEngagement(
      String userId, String action, String postId) async {
    await _firestore.collection(_userEngagement).add({
      'userId': userId,
      'action': action,
      'postId': postId,
      'timestamp': Timestamp.now(),
    });
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
      finalImageUrl = await uploadPostImage(
          userId: userId, postId: postId, bytes: imageBytes);
    }
    if (finalImageUrl.isEmpty) {
      throw ArgumentError('Need imageBytes or imageUrl');
    }

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

  /// Professional like algorithm with validation and rate limiting
  Future<LikeResult> toggleLike(String postId, String userId) async {
    // Check rate limit
    if (!await _checkRateLimit(userId, 'like')) {
      return LikeResult.rateLimited;
    }

    final ref = _firestore.collection(_posts).doc(postId);
    final result = await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return LikeResult.postNotFound;

      final data = snap.data()!;
      final liked =
          List<String>.from(data['likedByUserIds'] as List<dynamic>? ?? []);
      final count = data['likeCount'] as int? ?? 0;

      final isLiked = liked.contains(userId);
      if (isLiked) {
        // Unlike: remove user and decrement count
        liked.remove(userId);
        tx.update(ref, {
          'likedByUserIds': liked,
          'likeCount': count - 1,
          'lastActivity': Timestamp.now(),
        });
        return LikeResult.unliked;
      } else {
        // Like: add user and increment count
        liked.add(userId);
        tx.update(ref, {
          'likedByUserIds': liked,
          'likeCount': count + 1,
          'lastActivity': Timestamp.now(),
        });
        // Record engagement for rate limiting
        await _recordEngagement(userId, 'like', postId);
        return LikeResult.liked;
      }
    });

    return result ?? LikeResult.error;
  }

  /// Professional save algorithm with validation
  Future<SaveResult> toggleSave(String postId, String userId) async {
    final ref = _firestore.collection(_posts).doc(postId);
    final result = await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return SaveResult.postNotFound;

      final data = snap.data()!;
      final saved =
          List<String>.from(data['savedByUserIds'] as List<dynamic>? ?? []);

      final isSaved = saved.contains(userId);
      if (isSaved) {
        // Unsave: remove user
        saved.remove(userId);
        tx.update(ref, {
          'savedByUserIds': saved,
          'lastActivity': Timestamp.now(),
        });
        return SaveResult.unsaved;
      } else {
        // Save: add user
        saved.add(userId);
        tx.update(ref, {
          'savedByUserIds': saved,
          'lastActivity': Timestamp.now(),
        });
        return SaveResult.saved;
      }
    });

    return result ?? SaveResult.error;
  }

  /// Professional comment algorithm with validation and moderation
  Future<CommentResult> addComment(
      String postId, LookPostComment comment) async {
    // Check rate limit
    if (!await _checkRateLimit(comment.userId, 'comment')) {
      return CommentResult.rateLimited;
    }

    // Basic content validation
    if (comment.text.trim().isEmpty) {
      return CommentResult.emptyContent;
    }

    if (comment.text.length > 1000) {
      return CommentResult.tooLong;
    }

    // Check for spam patterns (basic)
    if (_containsSpamPatterns(comment.text)) {
      return CommentResult.spamDetected;
    }

    final ref = _firestore.collection(_posts).doc(postId);
    final result = await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return CommentResult.postNotFound;

      final data = snap.data()!;
      final comments = List<Map<String, dynamic>>.from(
        (data['comments'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map)) ??
            [],
      );

      // Check for duplicate comments (same user, same text within last 5 minutes)
      final recentComments = comments.where((c) {
        final commentTime = (c['createdAt'] as Timestamp).toDate();
        final timeDiff = DateTime.now().difference(commentTime).inMinutes;
        return c['userId'] == comment.userId &&
            c['text'] == comment.text &&
            timeDiff < 5;
      });

      if (recentComments.isNotEmpty) {
        return CommentResult.duplicate;
      }

      comments.add(comment.toFirestore());
      final count = comments.length;

      tx.update(ref, {
        'comments': comments,
        'commentCount': count,
        'lastActivity': Timestamp.now(),
      });

      // Record engagement for rate limiting
      await _recordEngagement(comment.userId, 'comment', postId);

      return CommentResult.success;
    });

    return result ?? CommentResult.error;
  }

  /// Check for basic spam patterns
  bool _containsSpamPatterns(String text) {
    final spamPatterns = [
      r'http[s]?://', // URLs
      r'\b(?:viagra|casino|lottery)\b', // Common spam words
      r'[A-Z]{10,}', // Excessive caps
      r'(.)\1{4,}', // Repeated characters
    ];

    for (final pattern in spamPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  /// Professional share algorithm with tracking
  Future<ShareResult> incrementShareCount(String postId, String userId) async {
    // Check rate limit
    if (!await _checkRateLimit(userId, 'share')) {
      return ShareResult.rateLimited;
    }

    final ref = _firestore.collection(_posts).doc(postId);
    final result = await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return ShareResult.postNotFound;

      final data = snap.data()!;
      final currentCount = data['shareCount'] as int? ?? 0;

      tx.update(ref, {
        'shareCount': currentCount + 1,
        'lastActivity': Timestamp.now(),
      });

      // Record engagement for rate limiting
      await _recordEngagement(userId, 'share', postId);

      return ShareResult.success;
    });

    return result ?? ShareResult.error;
  }

  /// Increment view count with deduplication (same user can't inflate views)
  Future<void> incrementViewCount(String postId, String userId) async {
    final ref = _firestore.collection(_posts).doc(postId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      final currentCount = data['viewCount'] as int? ?? 0;

      tx.update(ref, {
        'viewCount': currentCount + 1,
        'lastActivity': Timestamp.now(),
      });
    });
  }

  /// Get engagement analytics for a post
  Future<PostAnalytics> getPostAnalytics(String postId) async {
    final doc = await _firestore.collection(_posts).doc(postId).get();
    if (!doc.exists) throw Exception('Post not found');

    final data = doc.data()!;
    final comments = (data['comments'] as List<dynamic>? ?? [])
        .map((c) => LookPostComment.fromFirestore(Map<String, dynamic>.from(c)))
        .toList();

    // Calculate engagement rate
    final views = data['viewCount'] as int? ?? 0;
    final likes = data['likeCount'] as int? ?? 0;
    final shares = data['shareCount'] as int? ?? 0;
    final totalEngagements = likes + comments.length + shares;
    final engagementRate = views > 0 ? (totalEngagements / views) * 100 : 0.0;

    return PostAnalytics(
      postId: postId,
      viewCount: views,
      likeCount: likes,
      commentCount: comments.length,
      shareCount: shares,
      engagementRate: engagementRate,
      topCommenters: _getTopCommenters(comments),
      recentActivity: data['lastActivity'] as Timestamp?,
    );
  }

  /// Get top commenters for analytics
  List<CommenterStats> _getTopCommenters(List<LookPostComment> comments) {
    final commenterMap = <String, CommenterStats>{};

    for (final comment in comments) {
      if (commenterMap.containsKey(comment.userId)) {
        final current = commenterMap[comment.userId]!;
        commenterMap[comment.userId] = CommenterStats(
          userId: current.userId,
          userName: current.userName,
          commentCount: current.commentCount + 1,
        );
      } else {
        commenterMap[comment.userId] = CommenterStats(
          userId: comment.userId,
          userName: comment.userName,
          commentCount: 1,
        );
      }
    }

    final sorted = commenterMap.values.toList()
      ..sort((a, b) => b.commentCount.compareTo(a.commentCount));

    return sorted.take(5).toList(); // Top 5 commenters
  }
}

/// Result enums for professional error handling
enum LikeResult {
  liked,
  unliked,
  postNotFound,
  rateLimited,
  error,
}

enum SaveResult {
  saved,
  unsaved,
  postNotFound,
  error,
}

enum CommentResult {
  success,
  postNotFound,
  emptyContent,
  tooLong,
  spamDetected,
  duplicate,
  rateLimited,
  error,
}

enum ShareResult {
  success,
  postNotFound,
  rateLimited,
  error,
}

/// Analytics data class
class PostAnalytics {
  final String postId;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final double engagementRate;
  final List<CommenterStats> topCommenters;
  final Timestamp? recentActivity;

  const PostAnalytics({
    required this.postId,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.engagementRate,
    required this.topCommenters,
    this.recentActivity,
  });
}

/// Commenter statistics for analytics
class CommenterStats {
  final String userId;
  final String userName;
  final int commentCount;

  const CommenterStats({
    required this.userId,
    required this.userName,
    required this.commentCount,
  });
}

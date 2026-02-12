import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/look_post_model.dart';
import '../services/style_feed_firestore_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../social/providers/social_provider.dart';

class StyleFeedState {
  final List<LookPost> posts;
  final Set<String> likedIds;
  final Set<String> savedIds;
  const StyleFeedState({
    this.posts = const [],
    this.likedIds = const {},
    this.savedIds = const {},
  });
}

final styleFeedFirestoreServiceProvider = Provider<StyleFeedFirestoreService>((ref) {
  return StyleFeedFirestoreService();
});

final styleFeedProvider =
    StateNotifierProvider<StyleFeedNotifier, AsyncValue<StyleFeedState>>((ref) {
  return StyleFeedNotifier(ref);
});

/// Last try-on result image path or data URL — set by Try-On screen, read by Post/ Chat.
final lastTryOnImageForPostProvider = StateProvider<String?>((ref) => null);

/// Last try-on result bytes — set when we have bytes (e.g. from Try-On), used for posting.
final lastTryOnImageBytesProvider = StateProvider<Uint8List?>((ref) => null);

class StyleFeedNotifier extends StateNotifier<AsyncValue<StyleFeedState>> {
  StyleFeedNotifier(this._ref) : super(const AsyncValue.loading()) {
    _subscribe();
  }

  final Ref _ref;
  void Function()? _unsubscribe;

  void _subscribe() {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      state = const AsyncValue.data(StyleFeedState());
      return;
    }
    final service = _ref.read(styleFeedFirestoreServiceProvider);
    final sub = service.watchPosts().listen(
      (posts) {
        final uid = _ref.read(authStateProvider).valueOrNull?.uid ?? '';
        final likedIds = posts.where((p) => p.likedByUserIds.contains(uid)).map((p) => p.id).toSet();
        final savedIds = posts.where((p) => p.savedByUserIds.contains(uid)).map((p) => p.id).toSet();
        state = AsyncValue.data(StyleFeedState(
          posts: posts,
          likedIds: likedIds,
          savedIds: savedIds,
        ));
      },
      onError: (e, st) {
        // Permission-denied or unauthenticated: show empty feed so app stays usable
        if (e is FirebaseException &&
            (e.code == 'permission-denied' || e.code == 'unauthenticated')) {
          if (kDebugMode) debugPrint('Style Feed: ${e.code} — showing empty feed');
          state = const AsyncValue.data(StyleFeedState());
          return;
        }
        if (kDebugMode) debugPrint('Style Feed stream error: $e');
        state = AsyncValue.error(e, st);
      },
    );
    _unsubscribe = sub.cancel;
  }

  String _currentUserId() =>
      _ref.read(authStateProvider).valueOrNull?.uid ?? '';
  String _currentUserName() =>
      _ref.read(authStateProvider).valueOrNull?.displayName ?? _ref.read(currentUserProvider).valueOrNull?.displayName ?? 'You';
  String? _currentUserAvatarUrl() =>
      _ref.read(authStateProvider).valueOrNull?.photoURL ?? _ref.read(currentUserProvider).valueOrNull?.avatarUrl;

  /// Add a new post. Image: [imageBytes] (uploaded to Storage) or [imagePath] as data URL / http URL.
  Future<LookPost?> addPost({
    required String caption,
    required List<String> tags,
    required bool isPublic,
    String? imagePath,
    Uint8List? imageBytes,
  }) async {
    final uid = _currentUserId();
    if (uid.isEmpty) return null;

    String? imageUrl = imagePath;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      // Will upload in service
    } else if (imagePath == null || imagePath.isEmpty) {
      return null;
    } else if (!imagePath.startsWith('http') && !imagePath.startsWith('data:')) {
      // Local file path - caller should pass imageBytes; we can't upload path from web
      return null;
    }

    try {
      final service = _ref.read(styleFeedFirestoreServiceProvider);
      final post = await service.addPost(
        userId: uid,
        userName: _currentUserName(),
        userAvatarUrl: _currentUserAvatarUrl(),
        caption: caption,
        tags: tags,
        isPublic: isPublic,
        imageBytes: imageBytes,
        imageUrl: imageUrl,
      );
      return post;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> toggleLike(String postId) async {
    final uid = _currentUserId();
    if (uid.isEmpty) return;
    final current = state.valueOrNull;
    LookPost? post;
    if (current != null) {
      final list = current.posts.where((p) => p.id == postId).toList();
      post = list.isEmpty ? null : list.first;
    }
    try {
      await _ref.read(styleFeedFirestoreServiceProvider).toggleLike(postId, uid);
      if (post != null && post.userId != uid) {
        await _ref.read(socialServiceProvider).createPostLikedNotification(
          toUserId: post.userId,
          fromUserId: uid,
          fromUserName: _currentUserName(),
          postId: postId,
          postImageUrl: post.imagePath.startsWith('http') ? post.imagePath : null,
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleSavePost(String postId) async {
    final uid = _currentUserId();
    if (uid.isEmpty) return;
    try {
      await _ref.read(styleFeedFirestoreServiceProvider).toggleSave(postId, uid);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> incrementViewCount(String postId) async {
    try {
      await _ref.read(styleFeedFirestoreServiceProvider).incrementViewCount(postId);
    } catch (_) {}
  }

  Future<void> addComment(String postId, String text) async {
    final uid = _currentUserId();
    if (uid.isEmpty) return;
    final name = _currentUserName();
    final current = state.valueOrNull;
    LookPost? post;
    if (current != null) {
      final list = current.posts.where((p) => p.id == postId).toList();
      post = list.isEmpty ? null : list.first;
    }
    final comment = LookPostComment(
      id: const Uuid().v4(),
      userId: uid,
      userName: name,
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    try {
      await _ref.read(styleFeedFirestoreServiceProvider).addComment(postId, comment);
      if (post != null && post.userId != uid) {
        await _ref.read(socialServiceProvider).createPostCommentNotification(
          toUserId: post.userId,
          fromUserId: uid,
          fromUserName: name,
          postId: postId,
          commentPreview: text.trim().length > 80 ? '${text.trim().substring(0, 80)}…' : text.trim(),
          postImageUrl: post.imagePath.startsWith('http') ? post.imagePath : null,
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> incrementShareCount(String postId) async {
    try {
      await _ref.read(styleFeedFirestoreServiceProvider).incrementShareCount(postId);
    } catch (_) {}
  }
}

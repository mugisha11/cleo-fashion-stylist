import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final Map<String, EngagementStatus> engagementStatuses;
  final Map<String, String> errorMessages;

  const StyleFeedState({
    this.posts = const [],
    this.likedIds = const {},
    this.savedIds = const {},
    this.engagementStatuses = const {},
    this.errorMessages = const {},
  });

  StyleFeedState copyWith({
    List<LookPost>? posts,
    Set<String>? likedIds,
    Set<String>? savedIds,
    Map<String, EngagementStatus>? engagementStatuses,
    Map<String, String>? errorMessages,
  }) {
    return StyleFeedState(
      posts: posts ?? this.posts,
      likedIds: likedIds ?? this.likedIds,
      savedIds: savedIds ?? this.savedIds,
      engagementStatuses: engagementStatuses ?? this.engagementStatuses,
      errorMessages: errorMessages ?? this.errorMessages,
    );
  }
}

enum EngagementStatus {
  idle,
  loading,
  success,
  error,
}

final styleFeedFirestoreServiceProvider =
    Provider<StyleFeedFirestoreService>((ref) {
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
    _ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      final previousUid = previous?.valueOrNull?.uid;
      final nextUid = next.valueOrNull?.uid;
      if (previousUid != nextUid) {
        _subscribe();
      }
    });
    _subscribe();
  }

  final Ref _ref;
  void Function()? _unsubscribe;

  void _subscribe() {
    _unsubscribe?.call();

    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      state = const AsyncValue.data(StyleFeedState());
      return;
    }
    final service = _ref.read(styleFeedFirestoreServiceProvider);
    final sub = service.watchPosts().listen(
      (posts) {
        final uid = _ref.read(authStateProvider).valueOrNull?.uid ?? '';
        final likedIds = posts
            .where((p) => p.likedByUserIds.contains(uid))
            .map((p) => p.id)
            .toSet();
        final savedIds = posts
            .where((p) => p.savedByUserIds.contains(uid))
            .map((p) => p.id)
            .toSet();
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
          if (kDebugMode) {
            debugPrint('Style Feed: ${e.code} — showing empty feed');
          }
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
      _ref.read(authStateProvider).valueOrNull?.displayName ??
      _ref.read(currentUserProvider).valueOrNull?.displayName ??
      'You';
  String? _currentUserAvatarUrl() =>
      _ref.read(authStateProvider).valueOrNull?.photoURL ??
      _ref.read(currentUserProvider).valueOrNull?.avatarUrl;

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
    } else if (!imagePath.startsWith('http') &&
        !imagePath.startsWith('data:')) {
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

    final currentState = state.valueOrNull;
    if (currentState == null) return;

    LookPost? post;
    for (final p in currentState.posts) {
      if (p.id == postId) {
        post = p;
        break;
      }
    }
    if (post == null) return;

    final wasLiked = currentState.likedIds.contains(postId);
    final newLikedIds = Set<String>.from(currentState.likedIds);
    final newPosts = currentState.posts.map((p) {
      if (p.id == postId) {
        return p.copyWith(
          likedByUserIds: wasLiked
              ? p.likedByUserIds.where((id) => id != uid).toList()
              : [...p.likedByUserIds, uid],
          likeCount: wasLiked ? p.likeCount - 1 : p.likeCount + 1,
        );
      }
      return p;
    }).toList();

    // Optimistic update and clear any previous like error for this post.
    state = AsyncValue.data(currentState.copyWith(
      posts: newPosts,
      likedIds:
          wasLiked ? (newLikedIds..remove(postId)) : (newLikedIds..add(postId)),
      engagementStatuses: {
        ...currentState.engagementStatuses,
        'like_$postId': EngagementStatus.loading,
      },
      errorMessages: {
        ...currentState.errorMessages,
        'like_$postId': '',
      },
    ));

    try {
      final service = _ref.read(styleFeedFirestoreServiceProvider);
      final result = await service.toggleLike(postId, uid);

      switch (result) {
        case LikeResult.liked:
        case LikeResult.unliked:
          // Success - keep optimistic update
          state = AsyncValue.data(currentState.copyWith(
            posts: newPosts,
            likedIds: wasLiked
                ? (newLikedIds..remove(postId))
                : (newLikedIds..add(postId)),
            engagementStatuses: {
              ...currentState.engagementStatuses,
              'like_$postId': EngagementStatus.success,
            },
            errorMessages: {
              ...currentState.errorMessages,
              'like_$postId': '',
            },
          ));

          // Create notification for likes
          if (result == LikeResult.liked && post.userId != uid) {
            await _ref.read(socialServiceProvider).createPostLikedNotification(
                  toUserId: post.userId,
                  fromUserId: uid,
                  fromUserName: _currentUserName(),
                  postId: postId,
                  postImageUrl:
                      post.imagePath.startsWith('http') ? post.imagePath : null,
                );
          }
          break;

        case LikeResult.rateLimited:
          // Revert optimistic update and show error
          state = AsyncValue.data(currentState.copyWith(
            engagementStatuses: {
              ...currentState.engagementStatuses,
              'like_$postId': EngagementStatus.error,
            },
            errorMessages: {
              ...currentState.errorMessages,
              'like_$postId':
                  'Too many likes. Please wait before trying again.',
            },
          ));
          break;

        case LikeResult.postNotFound:
          state = AsyncValue.data(currentState.copyWith(
            engagementStatuses: {
              ...currentState.engagementStatuses,
              'like_$postId': EngagementStatus.error,
            },
            errorMessages: {
              ...currentState.errorMessages,
              'like_$postId': 'Post not found.',
            },
          ));
          break;

        default:
          // Revert optimistic update for other errors
          state = AsyncValue.data(currentState);
      }
    } catch (e) {
      // Revert optimistic update on error
      state = AsyncValue.data(currentState.copyWith(
        engagementStatuses: {
          ...currentState.engagementStatuses,
          'like_$postId': EngagementStatus.error,
        },
        errorMessages: {
          ...currentState.errorMessages,
          'like_$postId': 'Failed to update like. Please try again.',
        },
      ));
    }
  }

  Future<void> toggleSavePost(String postId) async {
    final uid = _currentUserId();
    if (uid.isEmpty) return;

    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final wasSaved = currentState.savedIds.contains(postId);
    final newSavedIds = Set<String>.from(currentState.savedIds);

    // Optimistic update
    state = AsyncValue.data(currentState.copyWith(
      savedIds:
          wasSaved ? (newSavedIds..remove(postId)) : (newSavedIds..add(postId)),
      engagementStatuses: {
        ...currentState.engagementStatuses,
        'save_$postId': EngagementStatus.loading,
      },
    ));

    try {
      final service = _ref.read(styleFeedFirestoreServiceProvider);
      final result = await service.toggleSave(postId, uid);

      switch (result) {
        case SaveResult.saved:
        case SaveResult.unsaved:
          // Success - keep optimistic update
          state = AsyncValue.data(currentState.copyWith(
            savedIds: wasSaved
                ? (newSavedIds..remove(postId))
                : (newSavedIds..add(postId)),
            engagementStatuses: {
              ...currentState.engagementStatuses,
              'save_$postId': EngagementStatus.success,
            },
            errorMessages: {
              ...currentState.errorMessages,
              'save_$postId': '',
            },
          ));
          break;

        default:
          // Revert optimistic update on error
          state = AsyncValue.data(currentState);
      }
    } catch (e) {
      // Revert optimistic update on error
      state = AsyncValue.data(currentState.copyWith(
        engagementStatuses: {
          ...currentState.engagementStatuses,
          'save_$postId': EngagementStatus.error,
        },
        errorMessages: {
          ...currentState.errorMessages,
          'save_$postId': 'Failed to update save. Please try again.',
        },
      ));
    }
  }

  Future<void> addComment(String postId, String text) async {
    final uid = _currentUserId();
    if (uid.isEmpty) return;

    final currentState = state.valueOrNull;
    if (currentState == null) return;

    LookPost? post;
    for (final p in currentState.posts) {
      if (p.id == postId) {
        post = p;
        break;
      }
    }
    if (post == null) return;

    final name = _currentUserName();
    final comment = LookPostComment(
      id: const Uuid().v4(),
      userId: uid,
      userName: name,
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    // Optimistic update
    final newPosts = currentState.posts.map((p) {
      if (p.id == postId) {
        return p.copyWith(
          comments: [...p.comments, comment],
          commentCount: p.commentCount + 1,
        );
      }
      return p;
    }).toList();

    state = AsyncValue.data(currentState.copyWith(
      posts: newPosts,
      engagementStatuses: {
        ...currentState.engagementStatuses,
        'comment_$postId': EngagementStatus.loading,
      },
    ));

    try {
      final service = _ref.read(styleFeedFirestoreServiceProvider);
      final result = await service.addComment(postId, comment);

      switch (result) {
        case CommentResult.success:
          // Success - keep optimistic update
          state = AsyncValue.data(currentState.copyWith(
            posts: newPosts,
            engagementStatuses: {
              ...currentState.engagementStatuses,
              'comment_$postId': EngagementStatus.success,
            },
            errorMessages: {
              ...currentState.errorMessages,
              'comment_$postId': '',
            },
          ));

          // Create notification for comments
          if (post.userId != uid) {
            await _ref
                .read(socialServiceProvider)
                .createPostCommentNotification(
                  toUserId: post.userId,
                  fromUserId: uid,
                  fromUserName: name,
                  postId: postId,
                  commentPreview: text.trim().length > 80
                      ? '${text.trim().substring(0, 80)}…'
                      : text.trim(),
                  postImageUrl:
                      post.imagePath.startsWith('http') ? post.imagePath : null,
                );
          }
          break;

        case CommentResult.rateLimited:
          // Revert optimistic update and show error
          state = AsyncValue.data(currentState.copyWith(
            engagementStatuses: {
              ...currentState.engagementStatuses,
              'comment_$postId': EngagementStatus.error,
            },
            errorMessages: {
              ...currentState.errorMessages,
              'comment_$postId':
                  'Too many comments. Please wait before trying again.',
            },
          ));
          break;

        case CommentResult.spamDetected:
          state = AsyncValue.data(currentState.copyWith(
            engagementStatuses: {
              ...currentState.engagementStatuses,
              'comment_$postId': EngagementStatus.error,
            },
            errorMessages: {
              ...currentState.errorMessages,
              'comment_$postId': 'Comment contains inappropriate content.',
            },
          ));
          break;

        case CommentResult.duplicate:
          state = AsyncValue.data(currentState.copyWith(
            engagementStatuses: {
              ...currentState.engagementStatuses,
              'comment_$postId': EngagementStatus.error,
            },
            errorMessages: {
              ...currentState.errorMessages,
              'comment_$postId':
                  'Duplicate comment. Please try different content.',
            },
          ));
          break;

        case CommentResult.tooLong:
          state = AsyncValue.data(currentState.copyWith(
            engagementStatuses: {
              ...currentState.engagementStatuses,
              'comment_$postId': EngagementStatus.error,
            },
            errorMessages: {
              ...currentState.errorMessages,
              'comment_$postId':
                  'Comment is too long. Maximum 1000 characters.',
            },
          ));
          break;

        default:
          // Revert optimistic update for other errors
          state = AsyncValue.data(currentState);
      }
    } catch (e) {
      // Revert optimistic update on error
      state = AsyncValue.data(currentState.copyWith(
        engagementStatuses: {
          ...currentState.engagementStatuses,
          'comment_$postId': EngagementStatus.error,
        },
        errorMessages: {
          ...currentState.errorMessages,
          'comment_$postId': 'Failed to add comment. Please try again.',
        },
      ));
    }
  }

  Future<void> incrementShareCount(String postId) async {
    final uid = _currentUserId();
    if (uid.isEmpty) return;

    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // Optimistic update
    final newPosts = currentState.posts.map((p) {
      if (p.id == postId) {
        return p.copyWith(shareCount: p.shareCount + 1);
      }
      return p;
    }).toList();

    state = AsyncValue.data(currentState.copyWith(
      posts: newPosts,
      engagementStatuses: {
        ...currentState.engagementStatuses,
        'share_$postId': EngagementStatus.loading,
      },
    ));

    try {
      final service = _ref.read(styleFeedFirestoreServiceProvider);
      final result = await service.incrementShareCount(postId, uid);

      switch (result) {
        case ShareResult.success:
          // Success - keep optimistic update
          state = AsyncValue.data(currentState.copyWith(
            posts: newPosts,
            engagementStatuses: {
              ...currentState.engagementStatuses,
              'share_$postId': EngagementStatus.success,
            },
            errorMessages: {
              ...currentState.errorMessages,
              'share_$postId': '',
            },
          ));
          break;

        case ShareResult.rateLimited:
          // Revert optimistic update and show error
          state = AsyncValue.data(currentState.copyWith(
            engagementStatuses: {
              ...currentState.engagementStatuses,
              'share_$postId': EngagementStatus.error,
            },
            errorMessages: {
              ...currentState.errorMessages,
              'share_$postId':
                  'Too many shares. Please wait before trying again.',
            },
          ));
          break;

        default:
          // Revert optimistic update on error
          state = AsyncValue.data(currentState);
      }
    } catch (e) {
      // Revert optimistic update on error
      state = AsyncValue.data(currentState.copyWith(
        engagementStatuses: {
          ...currentState.engagementStatuses,
          'share_$postId': EngagementStatus.error,
        },
        errorMessages: {
          ...currentState.errorMessages,
          'share_$postId': 'Failed to share. Please try again.',
        },
      ));
    }
  }

  Future<void> incrementViewCount(String postId) async {
    final uid = _currentUserId();
    if (uid.isEmpty) return;

    try {
      await _ref
          .read(styleFeedFirestoreServiceProvider)
          .incrementViewCount(postId, uid);
    } catch (_) {
      // Silently fail for view counts
    }
  }

  /// Clear error message for specific engagement
  void clearEngagementError(String key) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(
      errorMessages: {
        ...currentState.errorMessages,
        key: '',
      },
    ));
  }

  /// Get analytics for a post
  Future<PostAnalytics?> getPostAnalytics(String postId) async {
    try {
      final service = _ref.read(styleFeedFirestoreServiceProvider);
      return await service.getPostAnalytics(postId);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    super.dispose();
  }
}

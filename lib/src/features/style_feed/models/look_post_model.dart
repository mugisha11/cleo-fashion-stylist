import 'package:cloud_firestore/cloud_firestore.dart';

/// A single comment on a look post.
class LookPostComment {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;

  const LookPostComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LookPostComment.fromJson(Map<String, dynamic> json) =>
      LookPostComment(
        id: json['id'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  static LookPostComment fromFirestore(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    return LookPostComment(
      id: data['id'] as String,
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      text: data['text'] as String,
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.parse(createdAt.toString()),
    );
  }
}

/// A "look" post in the Style Feed (stored in Firestore + optional local).
class LookPost {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  /// Image URL (Firestore) or local path / data URL.
  final String imagePath;
  final String caption;
  final List<String> tags;
  final bool isPublic;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int viewCount;
  final List<String> likedByUserIds;
  final List<String> savedByUserIds;
  final List<LookPostComment> comments;
  final DateTime createdAt;

  const LookPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.imagePath,
    required this.caption,
    this.tags = const [],
    this.isPublic = true,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.viewCount = 0,
    this.likedByUserIds = const [],
    this.savedByUserIds = const [],
    this.comments = const [],
    required this.createdAt,
  });

  LookPost copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? imagePath,
    String? caption,
    List<String>? tags,
    bool? isPublic,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    int? viewCount,
    List<String>? likedByUserIds,
    List<String>? savedByUserIds,
    List<LookPostComment>? comments,
    DateTime? createdAt,
  }) =>
      LookPost(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
        imagePath: imagePath ?? this.imagePath,
        caption: caption ?? this.caption,
        tags: tags ?? this.tags,
        isPublic: isPublic ?? this.isPublic,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
        shareCount: shareCount ?? this.shareCount,
        viewCount: viewCount ?? this.viewCount,
        likedByUserIds: likedByUserIds ?? this.likedByUserIds,
        savedByUserIds: savedByUserIds ?? this.savedByUserIds,
        comments: comments ?? this.comments,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'userAvatarUrl': userAvatarUrl,
        'imagePath': imagePath,
        'caption': caption,
        'tags': tags,
        'isPublic': isPublic,
        'likeCount': likeCount,
        'commentCount': commentCount,
        'shareCount': shareCount,
        'viewCount': viewCount,
        'likedByUserIds': likedByUserIds,
        'savedByUserIds': savedByUserIds,
        'comments': comments.map((c) => c.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory LookPost.fromJson(Map<String, dynamic> json) => LookPost(
        id: json['id'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        userAvatarUrl: json['userAvatarUrl'] as String?,
        imagePath: json['imagePath'] as String,
        caption: json['caption'] as String? ?? '',
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        isPublic: json['isPublic'] as bool? ?? true,
        likeCount: json['likeCount'] as int? ?? 0,
        commentCount: json['commentCount'] as int? ?? 0,
        shareCount: json['shareCount'] as int? ?? 0,
        viewCount: json['viewCount'] as int? ?? 0,
        likedByUserIds: (json['likedByUserIds'] as List<dynamic>?)?.cast<String>() ?? [],
        savedByUserIds: (json['savedByUserIds'] as List<dynamic>?)?.cast<String>() ?? [],
        comments: (json['comments'] as List<dynamic>?)
                ?.map((e) => LookPostComment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  /// Firestore: store imageUrl; model uses imagePath for both URL and local path.
  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'userName': userName,
        'userAvatarUrl': userAvatarUrl,
        'imageUrl': imagePath,
        'caption': caption,
        'tags': tags,
        'isPublic': isPublic,
        'likeCount': likeCount,
        'commentCount': commentCount,
        'shareCount': shareCount,
        'viewCount': viewCount,
        'likedByUserIds': likedByUserIds,
        'savedByUserIds': savedByUserIds,
        'comments': comments.map((c) => c.toFirestore()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  static LookPost fromFirestore(String id, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    final commentsRaw = data['comments'] as List<dynamic>? ?? [];
    return LookPost(
      id: id,
      userId: data['userId'] as String,
      userName: data['userName'] as String? ?? 'User',
      userAvatarUrl: data['userAvatarUrl'] as String?,
      imagePath: data['imageUrl'] as String? ?? data['imagePath'] as String? ?? '',
      caption: data['caption'] as String? ?? '',
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isPublic: data['isPublic'] as bool? ?? true,
      likeCount: data['likeCount'] as int? ?? 0,
      commentCount: data['commentCount'] as int? ?? 0,
      shareCount: data['shareCount'] as int? ?? 0,
      viewCount: data['viewCount'] as int? ?? 0,
      likedByUserIds: (data['likedByUserIds'] as List<dynamic>?)?.cast<String>() ?? [],
      savedByUserIds: (data['savedByUserIds'] as List<dynamic>?)?.cast<String>() ?? [],
      comments: commentsRaw
          .map((e) => LookPostComment.fromFirestore(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : (createdAt != null ? DateTime.tryParse(createdAt.toString()) ?? DateTime.now() : DateTime.now()),
    );
  }
}

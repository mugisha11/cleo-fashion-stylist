import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight profile for social UI (name, avatar, bio, friendIds)
class SocialUserProfile {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final List<String> friends;
  final DateTime? createdAt;

  const SocialUserProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bio,
    this.friends = const [],
    this.createdAt,
  });

  factory SocialUserProfile.fromMap(String id, Map<String, dynamic> data) {
    DateTime? createdAt;
    if (data['createdAt'] != null) {
      final c = data['createdAt'];
      if (c is Timestamp) createdAt = c.toDate();
    }
    return SocialUserProfile(
      id: id,
      name: data['displayName'] as String? ?? data['name'] as String? ?? 'User',
      avatarUrl: data['avatarUrl'] as String?,
      bio: data['bio'] as String?,
      friends: List<String>.from(data['friends'] as List<dynamic>? ?? []),
      createdAt: createdAt,
    );
  }

  bool isFriendWith(String userId) => friends.contains(userId);
}

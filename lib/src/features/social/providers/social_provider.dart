import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/chat_model.dart';
import '../models/chat_message_model.dart';
import '../models/friend_request_model.dart';
import '../models/social_notification_model.dart';
import '../models/social_user_profile.dart';
import '../services/social_service.dart';

final socialServiceProvider = Provider<SocialService>((ref) => SocialService());

/// Current user's social profile (friends list). Ensures profile exists on first load.
final currentUserSocialProfileProvider = StreamProvider<SocialUserProfile?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  final service = ref.watch(socialServiceProvider);
  service.ensureUserSocialProfile(
    user.uid,
    name: user.displayName,
    avatarUrl: user.photoURL,
  );
  return service.watchUserProfile(user.uid);
});

/// Another user's profile (for "Add Friend" button state)
final userSocialProfileProvider = StreamProvider.family<SocialUserProfile?, String>((ref, userId) {
  final service = ref.watch(socialServiceProvider);
  return service.watchUserProfile(userId);
});

/// Friend requests sent TO current user (pending)
final friendRequestsToMeProvider = StreamProvider<List<FriendRequestModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(socialServiceProvider).watchRequestsToMe(user.uid);
});

/// Friend requests sent BY current user
final friendRequestsFromMeProvider = StreamProvider<List<FriendRequestModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(socialServiceProvider).watchRequestsFromMe(user.uid);
});

/// Chats for current user
final chatsListProvider = StreamProvider<List<ChatModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(socialServiceProvider).watchChatsForUser(user.uid);
});

/// Messages for a specific chat
final chatMessagesProvider = StreamProvider.family<List<ChatMessageModel>, String>((ref, chatId) {
  return ref.watch(socialServiceProvider).watchMessages(chatId);
});

/// Notifications for current user (all app notifications when logged in)
final socialNotificationsProvider = StreamProvider<List<SocialNotificationModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(socialServiceProvider).watchNotificationsForUser(user.uid);
});

/// Unread notification count (for badge)
final socialUnreadCountProvider = Provider<int>((ref) {
  final list = ref.watch(socialNotificationsProvider).valueOrNull ?? [];
  return list.where((n) => !n.read).length;
});

/// Discover: all users on platform (excluding current user). Refreshed on read.
final discoverUsersProvider = FutureProvider<List<SocialUserProfile>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];
  return ref.read(socialServiceProvider).getDiscoverUsers(
    limit: 150,
    excludeUserId: user.uid,
  );
});

/// Suggested for you: same style / people you may know (Instagram algorithm).
/// Ranks by mutual friends, then by recent activity; excludes already friends.
final suggestedPeopleProvider = FutureProvider<List<SocialUserProfile>>((ref) async {
  final discover = await ref.watch(discoverUsersProvider.future);
  final myProfile = ref.watch(currentUserSocialProfileProvider).valueOrNull;
  final myFriends = myProfile?.friends ?? [];
  final mySet = myFriends.toSet();
  final notFriends = discover.where((p) => !mySet.contains(p.id)).toList();
  notFriends.sort((a, b) {
    final mutualA = a.friends.toSet().intersection(mySet).length;
    final mutualB = b.friends.toSet().intersection(mySet).length;
    if (mutualB != mutualA) return mutualB.compareTo(mutualA);
    final aTime = a.createdAt ?? DateTime(0);
    final bTime = b.createdAt ?? DateTime(0);
    return bTime.compareTo(aTime);
  });
  return notFriends;
});

/// Friend request status toward a specific user: none | pending_sent | friends
enum FriendStatus { none, pendingSent, friends }

/// Reactive friend status for [otherUserId] (for Add Friend button).
final friendStatusProvider = Provider.family<AsyncValue<FriendStatus>, String>((ref, otherUserId) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null || user.uid == otherUserId) return const AsyncValue.data(FriendStatus.none);
  final profile = ref.watch(currentUserSocialProfileProvider);
  final fromMe = ref.watch(friendRequestsFromMeProvider);
  return profile.when(
    data: (p) {
      if (p?.friends.contains(otherUserId) == true) return const AsyncValue.data(FriendStatus.friends);
      return fromMe.when(
        data: (list) {
          final pending = list.any((r) => r.to == otherUserId && r.isPending);
          return AsyncValue.data(pending ? FriendStatus.pendingSent : FriendStatus.none);
        },
        loading: () => const AsyncValue.data(FriendStatus.none),
        error: (_, __) => const AsyncValue.data(FriendStatus.none),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (_, __) => const AsyncValue.data(FriendStatus.none),
  );
});

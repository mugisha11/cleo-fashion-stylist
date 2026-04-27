// ══════════════════════════════════════════════════════════════════════════════
//  friend_request_banner.dart
//  Banner showing pending friend requests with accept/decline actions
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/friend_request_model.dart';
import '../models/social_user_profile.dart';
import '../providers/social_provider.dart';

class FriendRequestBanner extends ConsumerWidget {
  const FriendRequestBanner({
    super.key,
    required this.requestsAsync,
    required this.onViewAll,
  });

  final AsyncValue<List<FriendRequestModel>> requestsAsync;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return const SizedBox.shrink();
        }

        // Show banner for first request only
        final request = requests.first;
        final fromUserAsync =
            ref.watch(userSocialProfileProvider(request.from));

        return fromUserAsync.when(
          data: (fromUser) {
            if (fromUser == null) {
              return const SizedBox.shrink();
            }

            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1426),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.person_add,
                        color: Color(0xFF6366F1),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Friend Request',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: fromUser.avatarUrl != null
                            ? NetworkImage(fromUser.avatarUrl!)
                            : null,
                        child: fromUser.avatarUrl == null
                            ? Text(fromUser.name.substring(0, 1).toUpperCase())
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fromUser.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'wants to be friends',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _acceptRequest(context, ref, request, fromUser),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _declineRequest(context, ref, request),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                    ],
                  ),
                  if (requests.length > 1) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: onViewAll,
                        child: Text(
                          'View all ${requests.length} requests',
                          style: const TextStyle(
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _acceptRequest(BuildContext context, WidgetRef ref,
      FriendRequestModel request, SocialUserProfile fromUser) async {
    try {
      await ref.read(socialServiceProvider).acceptFriendRequest(request.id);
      ref.invalidate(friendRequestsToMeProvider);
      ref.invalidate(currentUserSocialProfileProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are now friends with ${fromUser.name}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineRequest(
      BuildContext context, WidgetRef ref, FriendRequestModel request) async {
    try {
      await ref.read(socialServiceProvider).rejectFriendRequest(request.id);
      ref.invalidate(friendRequestsToMeProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request declined'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

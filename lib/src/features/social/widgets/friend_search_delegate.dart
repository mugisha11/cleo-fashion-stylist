// ══════════════════════════════════════════════════════════════════════════════
//  friend_search_delegate.dart
//  Search delegate for finding and adding friends by username or phone
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/social_provider.dart';
import '../models/social_user_profile.dart';

class FriendSearchDelegate extends SearchDelegate<String?> {
  @override
  String get searchFieldLabel => 'Search by username or phone';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return _buildEmptyState();
    }

    return Consumer(
      builder: (context, ref, child) {
        final user = ref.watch(authStateProvider).valueOrNull;
        if (user == null) {
          return _buildErrorState('Please log in to search for friends');
        }

        // For now, we'll search through discover users
        // In a real implementation, you'd have a dedicated search API
        final discoverAsync = ref.watch(discoverUsersProvider);

        return discoverAsync.when(
          data: (users) {
            final filteredUsers = users.where((user) {
              final displayName = user.name.toLowerCase();
              final queryLower = query.toLowerCase();

              return displayName.contains(queryLower) ||
                  user.id.toLowerCase().contains(queryLower);
            }).toList();

            if (filteredUsers.isEmpty) {
              return _buildNoResultsState();
            }

            return ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final profile = filteredUsers[index];
                return _UserSearchResult(
                  profile: profile,
                  currentUserId: user.uid,
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => _buildErrorState(error.toString()),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Search for friends',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a username or phone number',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different username or phone number',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _UserSearchResult extends ConsumerWidget {
  const _UserSearchResult({
    required this.profile,
    required this.currentUserId,
  });

  final SocialUserProfile profile;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendStatusAsync = ref.watch(friendStatusProvider(profile.id));

    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
        child: profile.avatarUrl == null
            ? Text(profile.name.substring(0, 1).toUpperCase())
            : null,
      ),
      title: Text(profile.name),
      subtitle: Text('@${profile.id.substring(0, 8)}'),
      trailing: friendStatusAsync.when(
        data: (status) => _buildActionButton(context, ref, status),
        loading: () => const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, __) => const Icon(Icons.error, color: Colors.red),
      ),
      onTap: () {
        // TODO: Navigate to user profile
      },
    );
  }

  Widget _buildActionButton(
      BuildContext context, WidgetRef ref, FriendStatus status) {
    switch (status) {
      case FriendStatus.friends:
        return ElevatedButton(
          onPressed: () {
            // TODO: Navigate to chat or unfriend
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Friends'),
        );

      case FriendStatus.pendingSent:
        return ElevatedButton(
          onPressed: () async {
            // Cancel request
            final requestId = await ref
                .read(socialServiceProvider)
                .getRequestIdFromTo(currentUserId, profile.id);
            if (requestId != null) {
              await ref
                  .read(socialServiceProvider)
                  .cancelFriendRequest(requestId);
              ref.invalidate(friendRequestsFromMeProvider);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
          ),
          child: const Text('Cancel'),
        );

      case FriendStatus.pendingReceived:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                final request = await ref
                    .read(socialServiceProvider)
                    .getRequestBetween(profile.id, currentUserId);
                if (request != null) {
                  await ref
                      .read(socialServiceProvider)
                      .acceptFriendRequest(request.id);
                  ref.invalidate(friendRequestsToMeProvider);
                  ref.invalidate(currentUserSocialProfileProvider);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Accept'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () async {
                final request = await ref
                    .read(socialServiceProvider)
                    .getRequestBetween(profile.id, currentUserId);
                if (request != null) {
                  await ref
                      .read(socialServiceProvider)
                      .rejectFriendRequest(request.id);
                  ref.invalidate(friendRequestsToMeProvider);
                }
              },
              child: const Text('Decline'),
            ),
          ],
        );

      case FriendStatus.none:
      default:
        return ElevatedButton(
          onPressed: () async {
            await ref.read(socialServiceProvider).sendFriendRequest(
                  currentUserId,
                  profile.id,
                  fromName:
                      ref.read(authStateProvider).valueOrNull?.displayName,
                  fromAvatar: ref.read(authStateProvider).valueOrNull?.photoURL,
                );
            ref.invalidate(friendRequestsFromMeProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Friend request sent!')),
            );
          },
          child: const Text('Add Friend'),
        );
    }
  }
}

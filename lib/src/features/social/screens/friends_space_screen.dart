// ══════════════════════════════════════════════════════════════════════════════
//  friends_space_screen.dart
//  Social hub showing friends' outfit posts with search, friend requests, likes/comments
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/social_provider.dart';
import '../../style_feed/models/look_post_model.dart';
import '../../style_feed/widgets/look_post_card.dart';
import '../../style_feed/widgets/style_feed_skeleton.dart';
import '../widgets/friend_search_delegate.dart';
import '../widgets/friend_request_banner.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  FRIENDS SPACE PALETTE - Social Theme
// ══════════════════════════════════════════════════════════════════════════════

// Primary colors - Social purple/blue
const _socialPrimary = Color(0xFF6366F1);
const _socialSecondary = Color(0xFF8B5CF6);

// Background colors
const _backgroundDark = Color(0xFF0F0A1A);
const _backgroundCard = Color(0xFF1A1426);

// Text colors
const _textPrimary = Color(0xFFF8F9FA);
const _textSecondary = Color(0xFFB8B9C5);
const _textMuted = Color(0xFF8B8D98);

// ══════════════════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class FriendsSpaceScreen extends ConsumerStatefulWidget {
  const FriendsSpaceScreen({super.key});

  @override
  ConsumerState<FriendsSpaceScreen> createState() => _FriendsSpaceScreenState();
}

class _FriendsSpaceScreenState extends ConsumerState<FriendsSpaceScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();
  final Set<String> _likedPostIds = {};
  final Set<String> _savedPostIds = {};

  @override
  void initState() {
    super.initState();
    _loadUserInteractions();
  }

  Future<void> _loadUserInteractions() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    // TODO: Load user's liked and saved posts from Firestore
    // For now, we'll track them locally in this session
  }

  void _toggleLike(String postId) {
    setState(() {
      if (_likedPostIds.contains(postId)) {
        _likedPostIds.remove(postId);
      } else {
        _likedPostIds.add(postId);
      }
    });
    // TODO: Persist to Firestore
  }

  void _toggleSave(String postId) {
    setState(() {
      if (_savedPostIds.contains(postId)) {
        _savedPostIds.remove(postId);
      } else {
        _savedPostIds.add(postId);
      }
    });
    // TODO: Persist to Firestore
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchPressed() {
    showSearch(
      context: context,
      delegate: FriendSearchDelegate(),
    );
  }

  void _onAddFriendPressed() {
    Navigator.of(context).pushNamed(Routes.discoverPeople);
  }

  void _onTryThisLook(LookPost post) {
    // Navigate to inspiration screen with friend's outfit
    Navigator.of(context).pushNamed(
      Routes.inspiration,
      arguments: {
        'imageUrl': post.imagePath,
        'title': 'Try ${post.userName}\'s Look',
        'description': post.caption,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendsPostsAsync = ref.watch(friendsPostsProvider);
    final friendRequestsAsync = ref.watch(friendRequestsToMeProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _backgroundDark,
        extendBody: true,
        body: Stack(
          children: [
            // Background
            const Positioned.fill(child: ColoredBox(color: _backgroundDark)),

            // Main content
            CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: _buildHeader(),
                ),

                // Friend requests banner
                SliverToBoxAdapter(
                  child: FriendRequestBanner(
                    requestsAsync: friendRequestsAsync,
                    onViewAll: () =>
                        Navigator.of(context).pushNamed(Routes.friendRequests),
                  ),
                ),

                // Feed content
                friendsPostsAsync.when(
                  data: (posts) => _buildFeed(posts),
                  loading: () => _buildLoading(),
                  error: (error, _) => _buildError(error),
                ),
              ],
            ),

            // Floating action button for search
            Positioned(
              bottom: 100,
              right: 20,
              child: FloatingActionButton(
                onPressed: _onSearchPressed,
                backgroundColor: _socialPrimary,
                child: const Icon(Icons.search, color: Colors.white),
              ),
            ),
          ],
        ),

        // Bottom navigation
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_socialPrimary, _socialSecondary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Friends Space',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover looks from your friends',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _onSearchPressed,
                  icon: const Icon(Icons.search),
                  label: const Text('Find Friends'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _onAddFriendPressed,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Discover'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeed(List<LookPost> posts) {
    if (posts.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final post = posts[index];
          return LookPostCard(
            post: post,
            isLiked: _likedPostIds.contains(post.id),
            isSaved: _savedPostIds.contains(post.id),
            onTryThisLook: () => _onTryThisLook(post),
            onLike: () => _toggleLike(post.id),
            onSave: () => _toggleSave(post.id),
          );
        },
        childCount: posts.length,
      ),
    );
  }

  Widget _buildLoading() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: const StyleFeedSkeleton(itemCount: 3),
      ),
    );
  }

  Widget _buildError(Object error) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: _textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(
                fontSize: 14,
                color: _textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(friendsPostsProvider),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 80,
            color: _textMuted,
          ),
          const SizedBox(height: 24),
          const Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect with friends to see their style posts here',
            style: TextStyle(
              fontSize: 16,
              color: _textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _onAddFriendPressed,
            icon: const Icon(Icons.person_add),
            label: const Text('Find Friends'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _socialPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: _backgroundCard,
        border: Border(top: BorderSide(color: _textMuted.withOpacity(0.2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            isActive: false,
            onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(
              Routes.dashboard,
              (route) => false,
            ),
          ),
          _NavItem(
            icon: Icons.people,
            label: 'Friends',
            isActive: true,
            onTap: () {}, // Already on this screen
          ),
          _NavItem(
            icon: Icons.camera_alt_outlined,
            label: 'Post',
            isActive: false,
            onTap: () => Navigator.of(context).pushNamed(Routes.postLook),
          ),
          _NavItem(
            icon: Icons.chat_bubble_outline,
            label: 'Chat',
            isActive: false,
            onTap: () => Navigator.of(context).pushNamed(Routes.chats),
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            isActive: false,
            onTap: () => Navigator.of(context).pushNamed(Routes.settings),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? _socialPrimary : _textSecondary,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? _socialPrimary : _textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

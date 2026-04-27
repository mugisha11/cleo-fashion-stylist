// ══════════════════════════════════════════════════════════════════════════════
//  nikonyxlook_feed_screen.dart
//  Social feed screen with Nikonyxlook branding and dark luxury theme
//  Dark background, fashion-focused header, vertical feed
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/providers/social_provider.dart';
import '../providers/style_feed_provider.dart';
import '../widgets/look_post_card.dart';
import '../widgets/style_feed_story_strip.dart';
import '../widgets/style_feed_skeleton.dart';

// ─── Route shims ──────────────────────────────────────────────────────────────
const _rChat = Routes.chats;
const _rPostLook = Routes.postLook;
const _rTryon = Routes.tryon;
const _rDiscover = Routes.discoverPeople;
const _rSettings = Routes.settings;

// ══════════════════════════════════════════════════════════════════════════════
//  NIKONYXLOOK PALETTE - Dark Luxury Theme
// ══════════════════════════════════════════════════════════════════════════════

// Primary brand colors - Deep purples and blacks
const _nikonyxDeepPurple = Color(0xFF1A0B2E);
const _nikonyxDarkPurple = Color(0xFF2D1B69);
const _nikonyxRoyalPurple = Color(0xFF4C2A85);
const _nikonyxElectricPurple = Color(0xFF7C3AED);
const _nikonyxGold = Color(0xFFD4AF37);
const _nikonyxLightGold = Color(0xFFF5E6A3);

// Background colors - Dark theme
const _backgroundDark = Color(0xFF0F0A1A);
const _backgroundCard = Color(0xFF1A1426);
const _backgroundLight = Color(0xFF2A2339);

// Text colors - Light on dark
const _textPrimary = Color(0xFFF8F9FA);
const _textSecondary = Color(0xFFB8B9C5);
const _textMuted = Color(0xFF8B8D98);
const _textLink = Color(0xFF7C3AED);

// Border colors
const _borderLight = Color(0xFF3A2E5A);
const _borderMedium = Color(0xFF4C3A6B);
const _borderGold = Color(0xFFD4AF37);

// Action colors
const _likeRed = Color(0xFFEF4444);
const _saveBlue = Color(0xFF3B82F6);

// Header colors
const _headerBackground = _backgroundCard;
const _headerBorder = _borderLight;

// Story ring gradient - Luxury gold to purple
const _storyRingGradient = [
  _nikonyxGold,
  _nikonyxLightGold,
  _nikonyxElectricPurple,
  _nikonyxRoyalPurple,
  _nikonyxDarkPurple,
];

// Navigation colors
const _navBackground = _backgroundCard;
const _navBorder = _borderLight;
const _navActive = _nikonyxGold;
const _navInactive = _textSecondary;

// ══════════════════════════════════════════════════════════════════════════════
//  NIKONYXLOOK LOGO WIDGET
// ══════════════════════════════════════════════════════════════════════════════
class _NikonyxlookLogo extends StatelessWidget {
  const _NikonyxlookLogo({this.size = 100});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.3,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Fashion camera icon with luxury gold gradient
          Container(
            width: size * 0.3,
            height: size * 0.3,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: _storyRingGradient,
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: size * 0.15,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Nikonyxlook',
            style: TextStyle(
              fontFamily: 'Billabong', // Fashion-style script font
              fontSize: size * 0.15,
              color: _nikonyxGold,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  INSTAGRAM HEADER
// ══════════════════════════════════════════════════════════════════════════════
class _InstagramHeader extends StatelessWidget {
  const _InstagramHeader(
      {required this.unreadCount,
      required this.onCameraTap,
      required this.onMessageTap});

  final int unreadCount;
  final VoidCallback onCameraTap;
  final VoidCallback onMessageTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: const BoxDecoration(
        color: _headerBackground,
        border: Border(bottom: BorderSide(color: _headerBorder, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Camera icon
            GestureDetector(
              onTap: onCameraTap,
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 24,
                color: _textPrimary,
              ),
            ),
            const Spacer(),
            // Nikonyxlook logo
            const _NikonyxlookLogo(size: 100),
            const Spacer(),
            // Messages icon with badge
            GestureDetector(
              onTap: onMessageTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.send_outlined,
                    size: 24,
                    color: _textPrimary,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: _likeRed,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  INSTAGRAM BOTTOM NAVIGATION
// ══════════════════════════════════════════════════════════════════════════════
class _InstagramNavBar extends StatelessWidget {
  const _InstagramNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.unreadCount,
  });

  final int currentIndex;
  final Function(int) onTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: _navBackground,
        border: Border(top: BorderSide(color: _navBorder, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: currentIndex == 0 ? Icons.home : Icons.home_outlined,
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: currentIndex == 1 ? Icons.search : Icons.search_outlined,
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.add_box_outlined,
            isActive: false,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: currentIndex == 3 ? Icons.favorite : Icons.favorite_border,
            isActive: currentIndex == 3,
            badge: unreadCount,
            onTap: () => onTap(3),
          ),
          _NavItem(
            icon: currentIndex == 4 ? Icons.person : Icons.person_outline,
            isActive: currentIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 75,
        height: 50,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? _navActive : _navInactive,
            ),
            if (badge > 0)
              Positioned(
                right: -6,
                top: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: _likeRed,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  MAIN SCREEN — Instagram-style feed with white background
// ══════════════════════════════════════════════════════════════════════════════
class InstagramFeedScreen extends ConsumerStatefulWidget {
  const InstagramFeedScreen({super.key});
  @override
  ConsumerState<InstagramFeedScreen> createState() =>
      _InstagramFeedScreenState();
}

class _InstagramFeedScreenState extends ConsumerState<InstagramFeedScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollCtrl = ScrollController();

  int _navIndex = 0; // Home (Instagram feed) active

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ─── Navigation helpers ────────────────────────────────────────────────────
  void _goToPostLook() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushNamed(_rPostLook);
  }

  void _goToTryOn(String? imagePath) {
    if (imagePath == null) return;
    ref.read(lastTryOnImageForPostProvider.notifier).state = imagePath;
    Navigator.of(context).pushNamed(_rTryon);
  }

  void _onNavTap(int index) {
    setState(() => _navIndex = index);
    HapticFeedback.lightImpact();

    switch (index) {
      case 0: // Home - stay here
        break;
      case 1: // Search/Discover
        Navigator.of(context).pushNamed(_rDiscover);
        break;
      case 2: // Add post
        _goToPostLook();
        break;
      case 3: // Activity (chat)
        Navigator.of(context).pushNamed(_rChat);
        break;
      case 4: // Profile
        Navigator.of(context).pushNamed(_rSettings);
        break;
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final unread = ref.watch(socialUnreadCountProvider) ?? 0;
    final user = ref.watch(authStateProvider).valueOrNull;
    final feedAsync = ref.watch(styleFeedProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // Light status bar for dark background
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _backgroundDark,
        extendBody: true,
        body: Stack(children: [
          // Dark background
          const Positioned.fill(child: ColoredBox(color: _backgroundDark)),

          // Main scrollable content — driven by real feed provider
          feedAsync.when(
            data: (state) => _buildFeed(context, state, mq, unread),
            loading: () => _buildLoading(mq, unread),
            error: (e, _) => _buildError(mq, unread, e),
          ),
        ]),
        bottomNavigationBar: _InstagramNavBar(
          currentIndex: _navIndex,
          onTap: _onNavTap,
          unreadCount: unread,
        ),
      ),
    );
  }

  // ─── FEED (loaded) ─────────────────────────────────────────────────────────
  Widget _buildFeed(BuildContext context, StyleFeedState state,
      MediaQueryData mq, int unread) {
    final posts = [...state.posts]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(styleFeedProvider),
      color: _nikonyxGold,
      backgroundColor: _backgroundCard,
      child: CustomScrollView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Instagram header
          SliverToBoxAdapter(
            child: _InstagramHeader(
              unreadCount: unread,
              onCameraTap: _goToPostLook,
              onMessageTap: () => Navigator.of(context).pushNamed(_rChat),
            ),
          ),

          // Stories strip
          SliverToBoxAdapter(
            child: StyleFeedStoryStrip(
              recentPosts: posts.take(10).toList(),
              onAddLook: _goToPostLook,
              onStoryTap: (post) => _goToTryOn(post.imagePath),
              onTryThisLook: (post) => _goToTryOn(post.imagePath),
            ),
          ),

          // Feed posts
          if (posts.isEmpty)
            SliverFillRemaining(child: _emptyFeed())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = posts[index];
                  return LookPostCard(
                    post: post,
                    isLiked: state.likedIds.contains(post.id),
                    isSaved: state.savedIds.contains(post.id),
                    onTryThisLook: () => _goToTryOn(post.imagePath),
                  );
                },
                childCount: posts.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ─── LOADING STATE ─────────────────────────────────────────────────────────
  Widget _buildLoading(MediaQueryData mq, int unread) => Column(children: [
        _InstagramHeader(
          unreadCount: unread,
          onCameraTap: _goToPostLook,
          onMessageTap: () => Navigator.of(context).pushNamed(_rChat),
        ),
        StyleFeedStoryStrip(recentPosts: const [], onAddLook: _goToPostLook),
        const Expanded(child: StyleFeedSkeleton(itemCount: 4)),
      ]);

  // ─── ERROR STATE ───────────────────────────────────────────────────────────
  Widget _buildError(MediaQueryData mq, int unread, Object error) =>
      Column(children: [
        _InstagramHeader(
          unreadCount: unread,
          onCameraTap: _goToPostLook,
          onMessageTap: () => Navigator.of(context).pushNamed(_rChat),
        ),
        Expanded(
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
              const Icon(Icons.error_outline_rounded,
                  size: 52, color: _textSecondary),
              const SizedBox(height: 16),
              const Text(
                "Couldn't load your feed",
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: _textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.invalidate(styleFeedProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _nikonyxGold,
                  foregroundColor: _backgroundDark,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ]))),
      ]);

  // ─── EMPTY FEED ────────────────────────────────────────────────────────────
  Widget _emptyFeed() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: _textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No posts yet',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Be the first to share your style on Nikonyxlook!',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _goToPostLook,
              icon: const Icon(Icons.add),
              label: const Text('Create Post'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _nikonyxGold,
                foregroundColor: _backgroundDark,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
}

// Backward-compat alias for routes.dart
typedef StyleFeedScreen = InstagramFeedScreen;

/// Style Feed — Instagram-style fashion feed
/// Top bar (sticky, blur), story strip, main feed, Try This Look integration
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../routes.dart';
import '../providers/style_feed_provider.dart';
import '../widgets/discover_people_strip.dart';
import '../widgets/look_post_card.dart';
import '../widgets/style_feed_story_strip.dart';
import '../widgets/style_feed_top_bar.dart';
import '../widgets/style_feed_skeleton.dart';

class StyleFeedScreen extends ConsumerStatefulWidget {
  const StyleFeedScreen({super.key});

  @override
  ConsumerState<StyleFeedScreen> createState() => _StyleFeedScreenState();
}

class _StyleFeedScreenState extends ConsumerState<StyleFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  static const double _blurThreshold = 24;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final offset = _scrollController.offset;
    if ((offset - _scrollOffset).abs() > 2) {
      setState(() => _scrollOffset = offset);
    }
  }

  void _goToPostLook() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushNamed(Routes.postLook);
  }

  void _goToTryOn(String? imagePath) {
    if (imagePath == null) return;
    ref.read(lastTryOnImageForPostProvider.notifier).state = imagePath;
    Navigator.of(context).pushNamed(Routes.tryon);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final feedAsync = ref.watch(styleFeedProvider);
    final blurBar = _scrollOffset > _blurThreshold;

    return Scaffold(
      backgroundColor: isDark ? DesignTokens.darkBackground : DesignTokens.lightBackground,
      body: Stack(
        children: [
          // Main scroll: story strip + feed
          feedAsync.when(
            data: (state) {
              final posts = state.posts;
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(styleFeedProvider);
                },
                color: isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Spacer for sticky top bar
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).padding.top + 56,
                      ),
                    ),
                    // Story strip
                    SliverToBoxAdapter(
                      child: StyleFeedStoryStrip(
                        recentPosts: posts.take(10).toList(),
                        onAddLook: _goToPostLook,
                        onTryThisLook: (post) => _goToTryOn(post.imagePath),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    // Discover People strip (Suggested for you + Add Friend)
                    const SliverToBoxAdapter(
                      child: DiscoverPeopleStrip(),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    // Feed list or empty state
                    if (posts.isEmpty)
                      SliverToBoxAdapter(
                        child: _EmptyFeedContent(onPostLook: _goToPostLook),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = posts[index];
                            final isLiked = state.likedIds.contains(post.id);
                            final isSaved = state.savedIds.contains(post.id);
                            return LookPostCard(
                              post: post,
                              isLiked: isLiked,
                              isSaved: isSaved,
                              onTryThisLook: () => _goToTryOn(post.imagePath),
                              onPostSimilar: () {
                                ref.read(lastTryOnImageForPostProvider.notifier).state = post.imagePath;
                                Navigator.of(context).pushNamed(Routes.postLook);
                              },
                            );
                          },
                          childCount: posts.length,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              );
            },
            loading: () => Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 56),
                StyleFeedStoryStrip(
                  recentPosts: const [],
                  onAddLook: _goToPostLook,
                ),
                const Expanded(child: StyleFeedSkeleton(itemCount: 4)),
              ],
            ),
            error: (e, st) => _ErrorState(
              onRetry: () => ref.invalidate(styleFeedProvider),
              isDark: isDark,
            ),
          ),
          // Sticky top bar (Instagram style)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: StyleFeedTopBar(
              enableBlur: blurBar,
              onPostLook: _goToPostLook,
              onProfileTap: () => Navigator.of(context).pushNamed(Routes.settings),
              onDiscover: () {
                Navigator.of(context).pushNamed(Routes.discoverPeople);
              },
              onMessages: () => Navigator.of(context).pushNamed(Routes.chats),
            ),
          ),
          // FAB — Post Look (thumb-friendly)
          Positioned(
            right: 16,
            bottom: 24,
            child: _PostLookFAB(isDark: isDark, onTap: _goToPostLook),
          ),
        ],
      ),
    );
  }
}

class _PostLookFAB extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _PostLookFAB({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent;

    return Material(
      color: Colors.transparent,
      elevation: 6,
      shadowColor: accent.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, accent.withValues(alpha: 0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Post Look',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline empty state for use inside CustomScrollView (below Discover strip).
class _EmptyFeedContent extends StatelessWidget {
  final VoidCallback onPostLook;

  const _EmptyFeedContent({required this.onPostLook});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final accent = isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    final textColor = isDark ? DesignTokens.darkText : DesignTokens.lightText;
    final textSecondary = isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.35,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(Icons.photo_camera_rounded, size: 64, color: accent),
            ),
            const SizedBox(height: 28),
            Text(
              'Share your look.\nInspire others.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: textColor,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Post try-on looks, outfits from your wardrobe, or photos from your gallery.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onPostLook();
              },
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text('Post your first look'),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isDark;

  const _ErrorState({required this.onRetry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    final textColor = isDark ? DesignTokens.darkText : DesignTokens.lightText;

    final topPadding = MediaQuery.of(context).padding.top + 56;
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(32, topPadding + 32, 32, 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: accent.withValues(alpha: 0.8)),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Pull down to refresh or tap Retry.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

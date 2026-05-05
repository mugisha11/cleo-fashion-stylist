import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../routes.dart';
import '../providers/style_feed_provider.dart';
import '../widgets/look_post_card.dart';
import '../widgets/style_feed_story_strip.dart';
import '../../../core/widgets/fashion_drawer.dart';
import '../../../core/widgets/cosmic_footer_widget.dart';

class StyleFeedScreen extends ConsumerWidget {
  const StyleFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(styleFeedProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AppDrawer(currentRoute: Routes.styleFeed),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Style Feed', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined, color: Colors.black),
            tooltip: 'Post new look',
            onPressed: () => _goToPostLook(context),
          ),
        ],
      ),
      body: SafeArea(
        child: feedAsync.when(
          data: (state) => _buildFeed(context, ref, state),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildError(context, ref, error),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? DesignTokens.darkAccent
            : DesignTokens.lightAccent,
        onPressed: () => _goToPostLook(context),
        icon: const Icon(Icons.add),
        label: const Text('New Look'),
      ),
      bottomNavigationBar: CosmicFooter(
        bottomPadding: MediaQuery.of(context).padding.bottom,
        activeIndex: 3, // Friends/Social
        onTryOn: () => Navigator.pushNamed(context, Routes.tryon),
        onWardrobe: () => Navigator.pushNamed(context, Routes.wardrobe),
        onHome: () => Navigator.pushNamed(context, Routes.dashboard),
        onFriends: () => Navigator.pushNamed(context, Routes.styleFeed),
        onOutfits: () => Navigator.pushNamed(context, Routes.outfitPlanner),
      ),
    );
  }

  Widget _buildFeed(BuildContext context, WidgetRef ref, StyleFeedState state) {
    final posts = [...state.posts]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(styleFeedProvider),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildIntro(context)),
          SliverToBoxAdapter(
            child: StyleFeedStoryStrip(
              recentPosts: posts.take(8).toList(),
              onAddLook: () => _goToPostLook(context),
              onStoryTap: (post) => _goToTryOn(context, ref, post.imagePath),
              onTryThisLook: (post) => _goToTryOn(context, ref, post.imagePath),
            ),
          ),
          if (posts.isEmpty)
            SliverFillRemaining(child: _buildEmptyState(context, ref))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = posts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: LookPostCard(
                      post: post,
                      isLiked: state.likedIds.contains(post.id),
                      isSaved: state.savedIds.contains(post.id),
                      onLike: () => ref
                          .read(styleFeedProvider.notifier)
                          .toggleLike(post.id),
                      onSave: () => ref
                          .read(styleFeedProvider.notifier)
                          .toggleSavePost(post.id),
                      onTryThisLook: () =>
                          _goToTryOn(context, ref, post.imagePath),
                    ),
                  );
                },
                childCount: posts.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover fresh looks from the community',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Browse recent style posts, save favorites, and try looks with one tap.',
            style: TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No style posts yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start sharing your looks or refresh to see new community posts.',
              style: TextStyle(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _goToPostLook(context),
              icon: const Icon(Icons.add),
              label: const Text('Create first look'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.invalidate(styleFeedProvider),
              child: const Text('Refresh feed'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Unable to load your style feed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error.toString(),
              style: const TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(styleFeedProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _goToPostLook(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushNamed(Routes.postLook);
  }

  void _goToTryOn(BuildContext context, WidgetRef ref, String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return;
    ref.read(lastTryOnImageForPostProvider.notifier).state = imagePath;
    HapticFeedback.selectionClick();
    Navigator.of(context).pushNamed(Routes.tryon);
  }
}

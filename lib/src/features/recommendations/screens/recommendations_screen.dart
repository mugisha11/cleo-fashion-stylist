import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/fashion_scaffold.dart';
import '../../../core/widgets/dashboard_components.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/services/recommendations_service.dart';
import '../../../core/providers/user_image_provider.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../../settings/screens/fashion_preferences_screen.dart';
import '../providers/recommendations_provider.dart';
import '../../social/providers/social_provider.dart';
import '../../tryon/providers/tryon_provider.dart';
import '../../../routes.dart';
import '../../../core/widgets/theme_wrapper.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final theme = context.appTheme;

    return Scaffold(
      appBar: DashboardTopBar(
        aiStatus: 'AI Recommendations',
        isAITyping: false,
        notificationCount: ref.watch(socialUnreadCountProvider),
        onProfileTap: () {
          Navigator.of(context).pushNamed(Routes.settings);
        },
        onNotificationsTap: () {
          Navigator.of(context).pushNamed(Routes.notificationCenter);
        },
      ),
      drawer: _buildNavigationDrawer(context),
      backgroundColor: theme.backgroundPrimary,
      body: Column(
        children: [
          // Refresh button in header area
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FashionDesignSystem.spacingLG,
              vertical: FashionDesignSystem.spacingMD,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    size: FashionDesignSystem.iconSize,
                    color: FashionDesignSystem.primaryColor,
                  ),
                  onPressed: () {
                    ref.invalidate(recommendationsProvider);
                  },
                ),
              ],
            ),
          ),

          // Recommendations content
          Expanded(
            child: recommendationsAsync.when(
              data: (recommendations) => recommendations.isEmpty
                  ? _buildEmptyState(context)
                  : _buildRecommendationsList(context, recommendations, ref),
              loading: () => _buildLoadingState(),
              error: (error, stack) => Center(
                child: Text('Error loading recommendations: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    final isDark = context.isDarkMode;
    return Drawer(
      child: Container(
        color:
            isDark ? DesignTokens.darkBackground : DesignTokens.lightBackground,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? DesignTokens.darkBorder
                        : DesignTokens.lightBorder,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cleo Fashion',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? DesignTokens.darkAccent
                              : DesignTokens.lightAccent,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your style companion',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _buildNavItem(
              context: context,
              icon: Icons.home_outlined,
              label: 'Home',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.dashboard);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.auto_awesome_outlined,
              label: 'Try On',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.tryon);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.checkroom_outlined,
              label: 'My Closet',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.wardrobe);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.star_outline,
              label: 'Picks for You',
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.calendar_today_outlined,
              label: 'Calendar',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.calendar);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.grid_view_rounded,
              label: 'Style Feed',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.styleFeed);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.photo_library_outlined,
              label: 'My Outfits',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.generatedOutfits);
              },
            ),
            const Divider(),
            _buildNavItem(
              context: context,
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.settings);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDarkMode;
    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent,
      ),
      title: Text(label),
      onTap: onTap,
      hoverColor: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No recommendations yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add more items to your wardrobe to get personalized recommendations',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: SkeletonCard(),
      ),
    );
  }

  Widget _buildRecommendationsList(
    BuildContext context,
    List<RecommendedOutfit> recommendations,
    WidgetRef ref,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = recommendations[index];
        return _buildRecommendationCard(context, recommendation, ref, index);
      },
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    RecommendedOutfit recommendation,
    WidgetRef ref,
    int index,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    recommendation.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(recommendation.confidence * 100).toInt()}% match',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recommendation.reasoning,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              future: ref.read(wardrobeItemsProvider.future),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SkeletonLoader(
                      width: double.infinity, height: 120);
                }
                final items = snapshot.data!;
                final recommendedItems = items
                    .where((item) => recommendation.itemIds.contains(item.id))
                    .toList();
                return SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: recommendedItems.length,
                    itemBuilder: (context, idx) {
                      final item = recommendedItems[idx];
                      return Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const SkeletonLoader(
                              width: 100,
                              height: 120,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _tryOnOutfit(context, recommendation, ref),
                    icon: const Icon(Icons.try_sms_star),
                    label: const Text('Try On'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _saveOutfit(context, recommendation, ref),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 100).ms).slideX(
          duration: 300.ms,
          begin: 0.1,
        );
  }

  Future<void> _tryOnOutfit(
    BuildContext context,
    RecommendedOutfit recommendation,
    WidgetRef ref,
  ) async {
    // Check if user has uploaded photo
    final userImage = ref.read(userImageProvider);
    if (userImage.base64Image == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Upload Your Photo'),
          content: const Text(
            'Upload your full-body photo in Preferences to use Try-On.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FashionPreferencesScreen(),
                  ),
                );
              },
              child: const Text('Go to Preferences'),
            ),
          ],
        ),
      );
      return;
    }

    // Show loading
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating try-on preview...')),
      );
    }

    try {
      // Get user image bytes
      final userImageBytesAsync = ref.read(userImageBytesProvider);
      Uint8List? userImageBytes;

      await userImageBytesAsync.when(
        data: (bytes) {
          userImageBytes = bytes;
        },
        loading: () {},
        error: (error, _) {},
      );

      if (userImageBytes == null) {
        throw Exception('Failed to load user image');
      }

      // Get recommended items
      final wardrobeAsync = ref.read(wardrobeItemsProvider);
      final wardrobe = wardrobeAsync.value;
      if (wardrobe == null) throw Exception('Wardrobe not loaded');

      final selectedItems = wardrobe
          .where((item) => recommendation.itemIds.contains(item.id))
          .toList();
      final imageUrls = selectedItems.map((item) => item.imageUrl).toList();

      if (imageUrls.isEmpty) {
        throw Exception('No items to try on');
      }

      // Convert to Base64
      final base64UserImage = base64Encode(userImageBytes!);
      final userImageBase64 = 'data:image/jpeg;base64,$base64UserImage';

      // Generate try-on
      final tryOnService = ref.read(tryOnServiceProvider);
      final previewUrl = await tryOnService.generateTryOnPreviewFromBase64(
        userImageBase64: userImageBase64,
        clothingImageUrls: imageUrls,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        // Navigate to try-on with result
        Navigator.of(context).pushNamed(Routes.tryon);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _saveOutfit(
    BuildContext context,
    RecommendedOutfit recommendation,
    WidgetRef ref,
  ) async {
    try {
      final tryOnService = ref.read(tryOnServiceProvider);
      await tryOnService.saveOutfit(
        name: recommendation.name,
        itemIds: recommendation.itemIds,
        isRecommended: true,
      );
      ref.invalidate(savedOutfitsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Outfit saved')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save outfit: $e')),
        );
      }
    }
  }
}

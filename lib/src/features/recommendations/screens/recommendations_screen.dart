import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/fashion_scaffold.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../../../core/services/recommendations_service.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../providers/recommendations_provider.dart';
import '../../tryon/providers/tryon_provider.dart';
import '../../../routes.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(recommendationsProvider);

    return FashionScaffold(
      title: 'AI Recommendations',
      currentRoute: Routes.recommendations,
      body: Column(
        children: [
          // Refresh button in header area
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: FashionDesignSystem.spacingLG,
              vertical: FashionDesignSystem.spacingMD,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
          IconButton(
                  icon: Icon(
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                  return const SkeletonLoader(width: double.infinity, height: 120);
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
    // Navigate to try-on screen with pre-selected items
    Navigator.of(context).pushNamed(Routes.tryon);
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


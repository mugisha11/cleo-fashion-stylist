import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/outfit_model.dart';
import '../../../core/theme/grok_design_system.dart';

/// Swipeable Outfit Card Component
/// Displays outfit recommendations with images
class OutfitCard extends StatelessWidget {
  final OutfitRecommendation outfit;
  final VoidCallback? onTryOn;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onAddToWardrobe;

  const OutfitCard({
    super.key,
    required this.outfit,
    this.onTryOn,
    this.onLike,
    this.onDislike,
    this.onAddToWardrobe,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: GrokDesignSystem.spacingMD,
        vertical: GrokDesignSystem.spacingSM,
      ),
      decoration: BoxDecoration(
        color: GrokDesignSystem.backgroundWhite,
        borderRadius: BorderRadius.circular(GrokDesignSystem.radiusLG),
        border: Border.all(
          color: GrokDesignSystem.borderLight,
          width: 1,
        ),
        boxShadow: GrokDesignSystem.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(GrokDesignSystem.radiusLG),
            ),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: CachedNetworkImage(
                imageUrl: outfit.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: GrokDesignSystem.backgroundLightGray,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(GrokDesignSystem.primaryCharcoal),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: GrokDesignSystem.backgroundLightGray,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: GrokDesignSystem.textSecondary,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(GrokDesignSystem.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  outfit.title,
                  style: GrokDesignSystem.headlineSmall(isMobile: isMobile),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (outfit.description != null) ...[
                  const SizedBox(height: GrokDesignSystem.spacingXS),
                  Text(
                    outfit.description!,
                    style: GrokDesignSystem.bodySmall(isMobile: isMobile),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Tags
                if (outfit.tags.isNotEmpty) ...[
                  const SizedBox(height: GrokDesignSystem.spacingSM),
                  Wrap(
                    spacing: GrokDesignSystem.spacingXS,
                    runSpacing: GrokDesignSystem.spacingXS,
                    children: outfit.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: GrokDesignSystem.spacingSM,
                          vertical: GrokDesignSystem.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: GrokDesignSystem.backgroundLightGray,
                          borderRadius: BorderRadius.circular(GrokDesignSystem.radiusSM),
                        ),
                        child: Text(
                          tag,
                          style: GrokDesignSystem.caption(isMobile: isMobile),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Actions
                const SizedBox(height: GrokDesignSystem.spacingMD),
                Row(
                  children: [
                    // Try On button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onTryOn,
                        icon: const Icon(Icons.checkroom, size: 18),
                        label: Text('Try On', style: GrokDesignSystem.bodySmall()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GrokDesignSystem.primaryCharcoal,
                          foregroundColor: GrokDesignSystem.textInverse,
                          padding: const EdgeInsets.symmetric(vertical: GrokDesignSystem.spacingSM),
                        ),
                      ),
                    ),
                    const SizedBox(width: GrokDesignSystem.spacingSM),
                    // Like button
                    IconButton(
                      onPressed: onLike,
                      icon: const Icon(Icons.thumb_up_outlined),
                      color: GrokDesignSystem.textSecondary,
                    ),
                    // Dislike button
                    IconButton(
                      onPressed: onDislike,
                      icon: const Icon(Icons.thumb_down_outlined),
                      color: GrokDesignSystem.textSecondary,
                    ),
                    // Add to wardrobe
                    IconButton(
                      onPressed: onAddToWardrobe,
                      icon: const Icon(Icons.add_circle_outline),
                      color: GrokDesignSystem.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Swipeable Outfit List
class SwipeableOutfitList extends StatelessWidget {
  final List<OutfitRecommendation> outfits;
  final Function(OutfitRecommendation)? onTryOn;
  final Function(OutfitRecommendation)? onLike;
  final Function(OutfitRecommendation)? onDislike;
  final Function(OutfitRecommendation)? onAddToWardrobe;

  const SwipeableOutfitList({
    super.key,
    required this.outfits,
    this.onTryOn,
    this.onLike,
    this.onDislike,
    this.onAddToWardrobe,
  });

  @override
  Widget build(BuildContext context) {
    if (outfits.isEmpty) {
      return Center(
        child: Text(
          'No outfits to display',
          style: GrokDesignSystem.bodyMedium(),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: GrokDesignSystem.spacingMD),
      itemCount: outfits.length,
      itemBuilder: (context, index) {
        final outfit = outfits[index];
        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: OutfitCard(
            outfit: outfit,
            onTryOn: onTryOn != null ? () => onTryOn!(outfit) : null,
            onLike: onLike != null ? () => onLike!(outfit) : null,
            onDislike: onDislike != null ? () => onDislike!(outfit) : null,
            onAddToWardrobe: onAddToWardrobe != null ? () => onAddToWardrobe!(outfit) : null,
          ),
        );
      },
    );
  }
}


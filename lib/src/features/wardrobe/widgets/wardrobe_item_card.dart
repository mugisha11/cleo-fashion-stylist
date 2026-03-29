import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../../../core/models/wardrobe_item_model.dart';

/// Wardrobe Item Card - Pinterest-style image card for masonry grid
class WardrobeItemCard extends StatelessWidget {
  final WardrobeItemModel item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMoreTap;

  const WardrobeItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).brightness == Brightness.dark
        ? DesignTokens.darkAccent
        : DesignTokens.lightAccent;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: FashionDesignSystem.spacingMD),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FashionDesignSystem.radiusLG),
          boxShadow: FashionDesignSystem.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        constraints: const BoxConstraints(
          minHeight: 200,
          maxHeight: 600,
        ),
        child: AspectRatio(
          aspectRatio: 0.75, // Portrait orientation for clothing items
          child: Stack(
            children: [
              // Main Image
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: FashionDesignSystem.backgroundLight,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: accent,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: FashionDesignSystem.backgroundLight,
                    child: const Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: FashionDesignSystem.textTertiary,
                    ),
                  ),
                ),
              ),

              // Gradient Overlay (bottom)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
              ),

              // Content Overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(FashionDesignSystem.spacingMD),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: FashionDesignSystem.spacingMD,
                          vertical: FashionDesignSystem.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                              FashionDesignSystem.radiusSM),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          item.category,
                          style: FashionDesignSystem.caption().copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // Brand (if available)
                      if (item.brand != null) ...[
                        const SizedBox(height: FashionDesignSystem.spacingXS),
                        Text(
                          item.brand!,
                          style: FashionDesignSystem.bodySmall().copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // More Menu Button (top-right)
              Positioned(
                top: FashionDesignSystem.spacingMD,
                right: FashionDesignSystem.spacingMD,
                child: GestureDetector(
                  onTap: onMoreTap,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

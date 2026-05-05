import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/theme_wrapper.dart';

/// Luxury Wardrobe Item Card - Fashion-grade with transparent background
class LuxuryWardrobeItemCard extends StatefulWidget {
  final WardrobeItemModel item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMoreTap;
  final bool isSelected;

  const LuxuryWardrobeItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.onMoreTap,
    this.isSelected = false,
  });

  @override
  State<LuxuryWardrobeItemCard> createState() => _LuxuryWardrobeItemCardState();
}

class _LuxuryWardrobeItemCardState extends State<LuxuryWardrobeItemCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('top') ||
        cat.contains('shirt') ||
        cat.contains('blouse')) {
      return Icons.checkroom;
    } else if (cat.contains('bottom') ||
        cat.contains('pant') ||
        cat.contains('jean') ||
        cat.contains('skirt')) {
      return Icons.style;
    } else if (cat.contains('dress')) {
      return Icons.woman;
    } else if (cat.contains('shoe') ||
        cat.contains('sneaker') ||
        cat.contains('boot')) {
      return Icons.shopping_bag;
    } else if (cat.contains('jacket') ||
        cat.contains('coat') ||
        cat.contains('outer')) {
      return Icons.ac_unit;
    } else {
      return Icons.diamond;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? DesignTokens.darkAccent
        : DesignTokens.lightAccent;
    final isMobile = MediaQuery.of(context).size.width < 768;

    // CRITICAL: Always use processed image (background-removed) if available
    // Never show original image with background in wardrobe UI
    final displayImageUrl =
        widget.item.processedImageUrl ?? widget.item.imageUrl;

    // If no processed image exists, show a placeholder indicating processing needed
    final hasProcessedImage = widget.item.processedImageUrl != null;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: MouseRegion(
        onEnter: (_) {
          if (!isMobile) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _isHovered = true);
              _scaleController.forward();
            });
          }
        },
        onExit: (_) {
          if (!isMobile) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _isHovered = false);
              _scaleController.reverse();
            });
          }
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isHovered ? _scaleAnimation.value : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.08),
                      blurRadius: _isHovered ? 20 : 12,
                      offset: Offset(0, _isHovered ? 8 : 4),
                      spreadRadius: _isHovered ? 2 : -1,
                    ),
                    if (widget.isSelected)
                      BoxShadow(
                        color: accent.withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: 3,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Transparent background container
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.surfaceElevated.withOpacity(0.3),
                              theme.backgroundPrimary.withOpacity(0.2),
                            ],
                          ),
                        ),
                      ),

                      // Clothing image with transparent background
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: displayImageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            color: theme.surfaceElevated.withOpacity(0.1),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(accent),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.surfaceElevated.withOpacity(0.1),
                            child: Icon(
                              Icons.broken_image,
                              color: theme.textTertiary,
                              size: 32,
                            ),
                          ),
                        ),
                      ),

                      // Category icon overlay (top-right)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.surface.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getCategoryIcon(widget.item.category),
                            size: 16,
                            color: accent,
                          ),
                        ),
                      ),

                      // Selection indicator
                      if (widget.isSelected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: accent,
                                width: 2.5,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withOpacity(0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // More menu button (top-left, only on hover/desktop)
                      if (_isHovered || isMobile)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: GestureDetector(
                            onTap: widget.onMoreTap,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.surface.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.more_vert,
                                size: 16,
                                color: theme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    )
        .animate(
          delay: const Duration(milliseconds: 50),
        )
        .fadeIn(
          duration: 300.ms,
          curve: Curves.easeOut,
        )
        .scale(
          begin: const Offset(0.9, 0.9),
          duration: 250.ms,
          curve: Curves.easeOut,
        );
  }
}

/// Production Wardrobe Picker
/// Displays wardrobe items with transparent backgrounds
/// Mobile: Horizontal carousel at bottom
/// Desktop: Vertical list in sidebar
library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../../core/theme/design_tokens.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';

class ProductionWardrobePicker extends ConsumerWidget {
  final List<WardrobeItemModel> selectedGarments;
  final Function(WardrobeItemModel) onGarmentSelected;
  final VoidCallback? onTryOn;
  final ColorScheme colorScheme;
  final bool isVertical;

  const ProductionWardrobePicker({
    super.key,
    required this.selectedGarments,
    required this.onGarmentSelected,
    this.onTryOn,
    required this.colorScheme,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).brightness == Brightness.dark
        ? DesignTokens.darkAccent
        : DesignTokens.lightAccent;
    final wardrobeAsync = ref.watch(wardrobeItemsProvider);

    return wardrobeAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return _buildEmptyState(context, accent);
        }

        if (isVertical) {
          return _buildVerticalList(context, items, accent);
        } else {
          return _buildHorizontalCarousel(context, items, accent);
        }
      },
      loading: () => _buildLoadingState(context, accent),
      error: (_, __) => _buildErrorState(context, accent),
    );
  }

  Widget _buildHorizontalCarousel(BuildContext context, List<WardrobeItemModel> items, Color accent) {
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedGarments.any((g) => g.id == item.id);
                return _buildGarmentCard(context, item, isSelected, index, accent);
              },
            ),
          ),
          if (onTryOn != null && selectedGarments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onTryOn,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: Text(
                    'Try On ${selectedGarments.length} Item${selectedGarments.length > 1 ? 's' : ''}',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerticalList(BuildContext context, List<WardrobeItemModel> items, Color accent) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length + (onTryOn != null && selectedGarments.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          // Try-on button at bottom
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: FilledButton(
              onPressed: onTryOn,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(
                'Try On ${selectedGarments.length} Item${selectedGarments.length > 1 ? 's' : ''}',
              ),
            ),
          );
        }
        final item = items[index];
        final isSelected = selectedGarments.any((g) => g.id == item.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildGarmentCard(context, item, isSelected, index, accent, isVertical: true),
        );
      },
    );
  }

  Widget _buildGarmentCard(
    BuildContext context,
    WardrobeItemModel item,
    bool isSelected,
    int index,
    Color accent, {
    bool isVertical = false,
  }) {
    // Use processed image (transparent background) if available, otherwise regular image
    final imageUrl = item.processedImageUrl ?? item.imageUrl;

    return GestureDetector(
      onTap: () => onGarmentSelected(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: isVertical ? double.infinity : 110,
        height: isVertical ? 110 : 110,
        margin: isVertical ? EdgeInsets.zero : const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? accent
                : colorScheme.outline.withOpacity(0.15),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: accent.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Gradient overlay when not selected
              if (!isSelected)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              
              // Transparent background image
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: colorScheme.surface,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: accent,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: colorScheme.surface,
                  child: Icon(
                    Icons.image_not_supported,
                    color: colorScheme.onSurface.withOpacity(0.3),
                    size: 32,
                  ),
                ),
              ),
              
              // Selection indicator with elegant animation
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check,
                      size: 18,
                      color: colorScheme.onPrimary,
                    ),
                  )
                      .animate()
                      .scale(duration: 200.ms, curve: Curves.elasticOut)
                      .fadeIn(duration: 200.ms),
                ),
              
              // Category tag at bottom
              if (item.category != null && item.category!.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent.withOpacity(0.9)
                          : Colors.black.withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Text(
                      item.category!,
                      style: TextStyle(
                        color: isSelected ? colorScheme.onPrimary : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      )
          .animate(delay: (index * 50).ms)
          .fadeIn(duration: 400.ms, curve: Curves.easeOut)
          .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut)
          .scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.0, 1.0),
            duration: 400.ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color accent) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: 48,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No items in wardrobe',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/wardrobe');
              },
              child: const Text('Add Items'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, Color accent) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(
          color: accent,
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'Failed to load wardrobe',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.error,
          ),
        ),
      ),
    );
  }
}

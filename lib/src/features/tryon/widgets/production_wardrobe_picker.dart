/// Production Wardrobe Picker
/// Displays wardrobe items with transparent backgrounds
/// Mobile: Horizontal carousel at bottom
/// Desktop: Vertical list in sidebar
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/wardrobe_item_model.dart';
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
    final wardrobeAsync = ref.watch(wardrobeItemsProvider);

    return wardrobeAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return _buildEmptyState(context);
        }

        if (isVertical) {
          return _buildVerticalList(context, items);
        } else {
          return _buildHorizontalCarousel(context, items);
        }
      },
      loading: () => _buildLoadingState(context),
      error: (_, __) => _buildErrorState(context),
    );
  }

  Widget _buildHorizontalCarousel(BuildContext context, List<WardrobeItemModel> items) {
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
                return _buildGarmentCard(item, isSelected, index);
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
                    backgroundColor: colorScheme.primary,
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

  Widget _buildVerticalList(BuildContext context, List<WardrobeItemModel> items) {
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
                backgroundColor: colorScheme.primary,
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
          child: _buildGarmentCard(item, isSelected, index, isVertical: true),
        );
      },
    );
  }

  Widget _buildGarmentCard(
    WardrobeItemModel item,
    bool isSelected,
    int index, {
    bool isVertical = false,
  }) {
    // Use processed image (transparent background) if available, otherwise regular image
    final imageUrl = item.processedImageUrl ?? item.imageUrl;

    return GestureDetector(
      onTap: () => onGarmentSelected(item),
      child: Container(
        width: isVertical ? double.infinity : 100,
        height: isVertical ? 100 : 100,
        margin: isVertical ? EdgeInsets.zero : const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Transparent background image
              if (imageUrl != null)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Container(
                    color: colorScheme.surface,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: colorScheme.surface,
                    child: Icon(
                      Icons.image_not_supported,
                      color: colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                )
              else
                Container(
                  color: colorScheme.surface,
                  child: Icon(
                    Icons.image,
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              
              // Selection indicator
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      )
          .animate(delay: (index * 50).ms)
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.1, end: 0, duration: 300.ms),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
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

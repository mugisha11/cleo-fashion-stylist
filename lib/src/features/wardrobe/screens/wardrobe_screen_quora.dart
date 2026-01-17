import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/quora_bottom_navigation.dart';
import '../../../core/theme/quora_design_system.dart';
import '../providers/wardrobe_provider.dart';
import '../../../routes.dart';

/// Quora-Style Wardrobe Screen
/// List-based layout, minimal design, clean cards
class WardrobeScreenQuora extends ConsumerWidget {
  const WardrobeScreenQuora({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wardrobeAsync = ref.watch(wardrobeItemsProvider);
    int _currentBottomNavIndex = 1; // Wardrobe is index 1

    return Scaffold(
      backgroundColor: QuoraDesignSystem.backgroundGray,
      appBar: AppBar(
        title: Text(
          'My Wardrobe',
          style: QuoraDesignSystem.headlineSmall(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_outlined),
            onPressed: () {
              Navigator.of(context).pushNamed(Routes.addItem);
            },
          ),
        ],
      ),
      body: wardrobeAsync.when(
        data: (items) => items.isEmpty
            ? _buildEmptyState(context)
            : _buildWardrobeList(context, items, ref),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(context, error),
      ),
      bottomNavigationBar: QuoraBottomNavigation(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushReplacementNamed(Routes.dashboard);
              break;
            case 1:
              // Already on wardrobe
              break;
            case 2:
              Navigator.of(context).pushReplacementNamed(Routes.tryon);
              break;
            case 3:
              // Show notifications
              break;
            case 4:
              // Show profile
              break;
          }
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(QuoraDesignSystem.spacingXXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: 64,
              color: QuoraDesignSystem.textTertiary,
            ),
            SizedBox(height: QuoraDesignSystem.spacingLG),
            Text(
              'Your wardrobe is empty',
              style: QuoraDesignSystem.headlineMedium(),
            ),
            SizedBox(height: QuoraDesignSystem.spacingSM),
            Text(
              'Start by adding your first clothing item',
              style: QuoraDesignSystem.bodyMedium().copyWith(
                color: QuoraDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: QuoraDesignSystem.spacingXXXL),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(Routes.addItem);
              },
              child: Text(
                'Add Item',
                style: QuoraDesignSystem.bodyMedium().copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        color: QuoraDesignSystem.backgroundWhite,
        padding: EdgeInsets.all(QuoraDesignSystem.spacingLG),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: QuoraDesignSystem.borderColor,
                borderRadius: BorderRadius.circular(QuoraDesignSystem.radiusMD),
              ),
            ),
            SizedBox(width: QuoraDesignSystem.spacingLG),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 150,
                    color: QuoraDesignSystem.borderColor,
                  ),
                  SizedBox(height: QuoraDesignSystem.spacingSM),
                  Container(
                    height: 12,
                    width: 100,
                    color: QuoraDesignSystem.borderColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWardrobeList(
    BuildContext context,
    List<WardrobeItemModel> items,
    WidgetRef ref,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(wardrobeItemsProvider);
      },
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(
          color: QuoraDesignSystem.dividerColor,
          height: 1,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildWardrobeItemCard(context, item, ref);
        },
      ),
    );
  }

  Widget _buildWardrobeItemCard(
    BuildContext context,
    WardrobeItemModel item,
    WidgetRef ref,
  ) {
    return Container(
      color: QuoraDesignSystem.backgroundWhite,
      child: InkWell(
        onTap: () {
          // TODO: Show item details
        },
        child: Padding(
          padding: EdgeInsets.all(QuoraDesignSystem.spacingLG),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(QuoraDesignSystem.radiusMD),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: QuoraDesignSystem.borderColor,
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: QuoraDesignSystem.borderColor,
                    child: Icon(
                      Icons.image_outlined,
                      color: QuoraDesignSystem.textTertiary,
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: QuoraDesignSystem.spacingLG),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category,
                      style: QuoraDesignSystem.titleLarge(),
                    ),
                    if (item.brand != null) ...[
                      SizedBox(height: QuoraDesignSystem.spacingXS),
                      Text(
                        item.brand!,
                        style: QuoraDesignSystem.bodyMedium().copyWith(
                          color: QuoraDesignSystem.textSecondary,
                        ),
                      ),
                    ],
                    if (item.colorTags != null && item.colorTags!.isNotEmpty) ...[
                      SizedBox(height: QuoraDesignSystem.spacingSM),
                      Wrap(
                        spacing: QuoraDesignSystem.spacingXS,
                        children: item.colorTags!.take(3).map((color) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: QuoraDesignSystem.spacingSM,
                              vertical: QuoraDesignSystem.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: QuoraDesignSystem.backgroundGray,
                              borderRadius: BorderRadius.circular(QuoraDesignSystem.radiusSM),
                            ),
                            child: Text(
                              color,
                              style: QuoraDesignSystem.caption(),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Actions
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: QuoraDesignSystem.iconSize,
                  color: QuoraDesignSystem.textSecondary,
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteDialog(context, item, ref);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: QuoraDesignSystem.iconSizeSmall),
                        SizedBox(width: QuoraDesignSystem.spacingSM),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WardrobeItemModel item,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Item',
          style: QuoraDesignSystem.headlineSmall(),
        ),
        content: Text(
          'Are you sure you want to delete this item?',
          style: QuoraDesignSystem.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: QuoraDesignSystem.linkText()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: QuoraDesignSystem.linkText().copyWith(
                color: QuoraDesignSystem.errorColor,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(wardrobeServiceProvider);
        await service.deleteItem(item.id);
        ref.invalidate(wardrobeItemsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Item deleted',
                style: QuoraDesignSystem.bodyMedium(),
              ),
              backgroundColor: QuoraDesignSystem.textPrimary,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to delete: $e',
                style: QuoraDesignSystem.bodyMedium(),
              ),
              backgroundColor: QuoraDesignSystem.errorColor,
            ),
          );
        }
      }
    }
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(QuoraDesignSystem.spacingXXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: QuoraDesignSystem.errorColor,
            ),
            SizedBox(height: QuoraDesignSystem.spacingLG),
            Text(
              'Failed to load wardrobe',
              style: QuoraDesignSystem.headlineMedium(),
            ),
            SizedBox(height: QuoraDesignSystem.spacingSM),
            Text(
              error.toString(),
              style: QuoraDesignSystem.bodyMedium().copyWith(
                color: QuoraDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

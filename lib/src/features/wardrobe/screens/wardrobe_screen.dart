import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../../core/widgets/fashion_scaffold.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../providers/wardrobe_provider.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/wardrobe_masonry_grid.dart';
import '../../../routes.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  String? _selectedCategory;

  List<WardrobeItemModel> _filterItems(List<WardrobeItemModel> items) {
    if (_selectedCategory == null) return items;
    
    // Map category filter to actual category values
    final categoryMap = {
      'Tops': ['Top', 'Tops', 'Shirt', 'Blouse', 'T-Shirt'],
      'Bottoms': ['Bottom', 'Bottoms', 'Pants', 'Jeans', 'Skirt'],
      'Dresses': ['Dress', 'Dresses'],
      'Outerwear': ['Outerwear', 'Jacket', 'Coat', 'Blazer'],
      'Shoes': ['Shoes', 'Shoe', 'Sneakers', 'Boots'],
      'Accessories': ['Accessories', 'Accessory', 'Bag', 'Hat', 'Jewelry'],
    };
    
    final categories = categoryMap[_selectedCategory] ?? [_selectedCategory!];
    return items.where((item) => categories.contains(item.category)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final wardrobeAsync = ref.watch(wardrobeItemsProvider);
    final currentBottomNavIndex = 1; // Wardrobe is index 1

    return FashionScaffold(
      title: 'My Wardrobe',
      currentBottomNavIndex: currentBottomNavIndex,
      currentRoute: Routes.wardrobe,
      body: wardrobeAsync.when(
        data: (items) {
          final filteredItems = _filterItems(items);
          
          return Stack(
            children: [
              Column(
                children: [
                  // Category Filter Bar
                  CategoryFilterBar(
                    selectedCategory: _selectedCategory,
                    onCategorySelected: (category) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
      ),
                  
                  // Wardrobe Grid
                  Expanded(
                    child: filteredItems.isEmpty
                        ? _buildEmptyState(context, items.isEmpty)
                        : RefreshIndicator(
                            onRefresh: () async {
                              ref.invalidate(wardrobeItemsProvider);
                            },
                            child: SingleChildScrollView(
                              padding: EdgeInsets.only(
                                top: FashionDesignSystem.spacingMD,
                                bottom: 100, // Space for FAB
                              ),
                              child: WardrobeMasonryGrid(
                                items: filteredItems,
                                onItemTap: (item) {
                                  // TODO: Show item details
                                },
                                onItemLongPress: (item) {
                                  // TODO: Select for outfit
                                },
                                onItemMoreTap: (item) {
                                  _showItemMenu(context, item);
                                },
        ),
      ),
                          ),
                  ),
                ],
              ),
              
              // Floating Action Button
              Positioned(
                bottom: FashionDesignSystem.spacingXXL,
                right: FashionDesignSystem.spacingLG,
                child: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(Routes.addItem);
        },
                  backgroundColor: FashionDesignSystem.primaryColor,
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: FashionDesignSystem.iconSizeLarge,
                  ),
                ),
      ),
            ],
          );
        },
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isCompletelyEmpty) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(FashionDesignSystem.spacingXXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: FashionDesignSystem.backgroundLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
              Icons.checkroom_outlined,
                size: 64,
                color: FashionDesignSystem.textTertiary,
              ),
            ),
            SizedBox(height: FashionDesignSystem.spacingXXL),
            Text(
              isCompletelyEmpty
                  ? 'Your wardrobe starts here'
                  : 'No items in this category',
              style: FashionDesignSystem.headlineMedium(),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: FashionDesignSystem.spacingMD),
            Text(
              isCompletelyEmpty
                  ? 'Add your favorite pieces and build your digital closet'
                  : 'Try selecting a different category',
              style: FashionDesignSystem.bodyMedium().copyWith(
                color: FashionDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (isCompletelyEmpty) ...[
              SizedBox(height: FashionDesignSystem.spacingXXXL),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(Routes.addItem);
              },
                icon: Icon(
                  Icons.add_circle_outline,
                  size: FashionDesignSystem.iconSize,
                ),
                label: Text('Add your first item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FashionDesignSystem.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: FashionDesignSystem.spacingXXL,
                    vertical: FashionDesignSystem.spacingMD,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FashionDesignSystem.radiusMD),
            ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: FashionDesignSystem.primaryColor,
      ),
    );
  }

  void _showItemMenu(BuildContext context, WardrobeItemModel item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
              decoration: BoxDecoration(
          color: FashionDesignSystem.backgroundWhite,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(FashionDesignSystem.radiusXL),
            ),
          ),
        child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: FashionDesignSystem.textCharcoal,
                ),
                title: Text(
                  'View Details',
                  style: FashionDesignSystem.bodyMedium(),
                    ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show item details
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: FashionDesignSystem.errorColor,
                ),
                title: Text(
                  'Delete',
                  style: FashionDesignSystem.bodyMedium().copyWith(
                    color: FashionDesignSystem.errorColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(context, item);
                },
                      ),
              SizedBox(height: FashionDesignSystem.spacingMD),
                ],
              ),
            ),
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WardrobeItemModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Item',
          style: FashionDesignSystem.headlineSmall(),
        ),
        content: Text(
          'Are you sure you want to delete this item?',
          style: FashionDesignSystem.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: FashionDesignSystem.linkText()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: FashionDesignSystem.linkText().copyWith(
                color: FashionDesignSystem.errorColor,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final service = ref.read(wardrobeServiceProvider);
        await service.deleteItem(item.id);
        ref.invalidate(wardrobeItemsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Item deleted',
                style: FashionDesignSystem.bodyMedium(),
              ),
              backgroundColor: FashionDesignSystem.textCharcoal,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to delete: $e',
                style: FashionDesignSystem.bodyMedium(),
              ),
              backgroundColor: FashionDesignSystem.errorColor,
            ),
          );
        }
      }
    }
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(FashionDesignSystem.spacingXXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: FashionDesignSystem.errorColor,
            ),
            SizedBox(height: FashionDesignSystem.spacingLG),
            Text(
              'Failed to load wardrobe',
              style: FashionDesignSystem.headlineMedium(),
            ),
            SizedBox(height: FashionDesignSystem.spacingSM),
            Text(
              error.toString(),
              style: FashionDesignSystem.bodyMedium().copyWith(
                color: FashionDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


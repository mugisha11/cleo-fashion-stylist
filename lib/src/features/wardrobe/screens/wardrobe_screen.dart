import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../../core/widgets/fashion_scaffold.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../providers/wardrobe_provider.dart';
import '../widgets/luxury_wardrobe_item_card.dart';
import '../screens/wardrobe_item_details_screen.dart';
import '../../calendar/widgets/save_outfit_to_calendar_dialog.dart';
import '../../../routes.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  String? _selectedCategory;
  String? _selectedColor;
  String? _selectedOccasion;
  String? _selectedSeason;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedItems = {}; // For multi-select mode
  bool _isMultiSelectMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WardrobeItemModel> _filterItems(List<WardrobeItemModel> items) {
    var filtered = items;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final query = _searchQuery.toLowerCase();
        return item.category.toLowerCase().contains(query) ||
            (item.brand?.toLowerCase().contains(query) ?? false) ||
            item.colorTags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // Category filter
    if (_selectedCategory != null) {
    final categoryMap = {
      'Tops': ['Top', 'Tops', 'Shirt', 'Blouse', 'T-Shirt'],
      'Bottoms': ['Bottom', 'Bottoms', 'Pants', 'Jeans', 'Skirt'],
      'Dresses': ['Dress', 'Dresses'],
      'Outerwear': ['Outerwear', 'Jacket', 'Coat', 'Blazer'],
      'Shoes': ['Shoes', 'Shoe', 'Sneakers', 'Boots'],
      'Accessories': ['Accessories', 'Accessory', 'Bag', 'Hat', 'Jewelry'],
    };
    final categories = categoryMap[_selectedCategory] ?? [_selectedCategory!];
      filtered = filtered.where((item) => categories.contains(item.category)).toList();
    }

    // Color filter
    if (_selectedColor != null) {
      filtered = filtered.where((item) => item.colorTags.contains(_selectedColor!)).toList();
    }

    return filtered;
  }

  int _getGridColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 2; // Mobile
    if (width < 900) return 3; // Tablet
    if (width < 1200) return 4; // Desktop
    return 5; // Large desktop
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final wardrobeAsync = ref.watch(wardrobeItemsProvider);
    final currentBottomNavIndex = 1;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return FashionScaffold(
      title: 'My Wardrobe',
      currentBottomNavIndex: currentBottomNavIndex,
      currentRoute: Routes.wardrobe,
      backgroundColor: theme.backgroundPrimary,
      body: Container(
        decoration: theme.backgroundGradient != null
            ? BoxDecoration(gradient: theme.backgroundGradient)
            : BoxDecoration(color: theme.backgroundPrimary),
        child: wardrobeAsync.when(
        data: (items) {
          final filteredItems = _filterItems(items);
          
          return Stack(
            children: [
              Column(
                children: [
                    // Search Bar
                    _buildSearchBar(theme, isMobile),
                    
                    // Filter Chips (Horizontal Scrollable)
                    _buildFilterChips(theme, items, isMobile),
                  
                  // Wardrobe Grid
                  Expanded(
                    child: filteredItems.isEmpty
                          ? _buildEmptyState(context, theme, items.isEmpty)
                        : RefreshIndicator(
                            onRefresh: () async {
                              ref.invalidate(wardrobeItemsProvider);
                            },
                              color: theme.primary,
                              child: _buildWardrobeGrid(
                                context,
                                theme,
                                filteredItems,
                                isMobile,
      ),
                          ),
                  ),
                ],
              ),
              
              // Floating Action Button
              Positioned(
                  bottom: isMobile ? 80 : 24,
                  right: 24,
                  child: _buildFloatingActionButton(theme),
                ),
              ],
            );
          },
          loading: () => _buildLoadingState(theme),
          error: (error, stack) => _buildErrorState(context, theme, error),
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppThemeData theme, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.borderLight.withOpacity(0.3),
            width: 1,
                  ),
                ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search your wardrobe...',
          hintStyle: theme.bodyMedium(color: theme.textTertiary),
          prefixIcon: Icon(Icons.search, color: theme.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: theme.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: theme.surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isMobile ? 12 : 16,
          ),
        ),
        style: theme.bodyMedium(color: theme.textPrimary),
      ),
    );
  }

  Widget _buildFilterChips(AppThemeData theme, List<WardrobeItemModel> items, bool isMobile) {
    final categories = ['All', 'Tops', 'Bottoms', 'Dresses', 'Outerwear', 'Shoes', 'Accessories'];
    final colors = items.expand((item) => item.colorTags).toSet().toList()..sort();
    
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Category filters
          ...categories.map((category) {
            final isSelected = _selectedCategory == category || (category == 'All' && _selectedCategory == null);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category == 'All' ? null : category;
                  });
                  HapticFeedback.selectionClick();
                },
                backgroundColor: theme.surfaceElevated,
                selectedColor: theme.primary.withOpacity(0.2),
                checkmarkColor: theme.primary,
                labelStyle: theme.bodySmall(
                  color: isSelected ? theme.primary : theme.textSecondary,
                ).copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide(
                  color: isSelected ? theme.primary : theme.borderLight,
                  width: isSelected ? 1.5 : 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWardrobeGrid(
    BuildContext context,
    AppThemeData theme,
    List<WardrobeItemModel> items,
    bool isMobile,
  ) {
    final columnCount = _getGridColumnCount(context);
    final crossAxisSpacing = isMobile ? 12.0 : 16.0;
    final mainAxisSpacing = isMobile ? 12.0 : 16.0;
    final padding = isMobile ? 12.0 : 16.0;

    return GridView.builder(
      padding: EdgeInsets.all(padding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: 0.75, // Portrait orientation
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return LuxuryWardrobeItemCard(
          item: item,
          isSelected: _selectedItems.contains(item.id),
          onTap: () {
            if (_isMultiSelectMode) {
              setState(() {
                if (_selectedItems.contains(item.id)) {
                  _selectedItems.remove(item.id);
                } else {
                  _selectedItems.add(item.id);
                }
              });
            } else {
              _showItemDetails(context, theme, item);
            }
          },
          onLongPress: () {
            setState(() {
              _isMultiSelectMode = true;
              _selectedItems.add(item.id);
            });
            HapticFeedback.mediumImpact();
          },
          onMoreTap: () => _showItemMenu(context, theme, item),
        );
      },
    );
  }

  Widget _buildFloatingActionButton(AppThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [theme.primary, theme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(Routes.addItem);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 56,
            height: 56,
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildEmptyState(BuildContext context, AppThemeData theme, bool isCompletelyEmpty) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppThemeData.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(
              Icons.checkroom_outlined,
                size: 64,
                color: theme.textTertiary,
              ),
            ),
            SizedBox(height: AppThemeData.spacingXXL),
            Text(
              isCompletelyEmpty
                  ? 'Your wardrobe starts here'
                  : 'No items found',
              style: theme.titleLarge(color: theme.textPrimary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppThemeData.spacingMD),
            Text(
              isCompletelyEmpty
                  ? 'Add your favorite pieces and build your digital closet'
                  : 'Try adjusting your filters or search',
              style: theme.bodyMedium(color: theme.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (isCompletelyEmpty) ...[
              SizedBox(height: AppThemeData.spacingXXL),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(Routes.addItem);
              },
                icon: Icon(Icons.add_circle_outline),
                label: Text('Add your first item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppThemeData.spacingXXL,
                    vertical: AppThemeData.spacingMD,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(theme.borderRadius),
            ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppThemeData theme) {
    return Center(
      child: CircularProgressIndicator(
        color: theme.primary,
      ),
    );
  }

  void _showItemMenu(BuildContext context, AppThemeData theme, WardrobeItemModel item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
              decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(theme.borderRadiusLarge),
            ),
          ),
        child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.borderMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.info_outline, color: theme.textPrimary),
                title: Text(
                  'View Details',
                  style: theme.bodyMedium(color: theme.textPrimary),
                    ),
                onTap: () {
                  Navigator.pop(context);
                  _showItemDetails(context, theme, item);
                },
              ),
              ListTile(
                leading: Icon(Icons.calendar_today, color: theme.primary),
                title: Text(
                  'Save to Calendar',
                  style: theme.bodyMedium(color: theme.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showSaveToCalendarDialog(context, theme, item);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: theme.accentError),
                title: Text(
                  'Delete',
                  style: theme.bodyMedium(color: theme.accentError),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(context, theme, item);
                },
                      ),
              SizedBox(height: AppThemeData.spacingMD),
                ],
              ),
            ),
      ),
    );
  }

  void _showItemDetails(BuildContext context, AppThemeData theme, WardrobeItemModel item) {
    print('📋 Opening item details for: ${item.id} (${item.category})');
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WardrobeItemDetailsScreen(item: item),
        ),
      );
      print('✅ Navigation to details screen successful');
    } catch (e) {
      print('❌ Navigation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open details: ${e.toString()}'),
          backgroundColor: theme.accentError,
        ),
      );
    }
  }

  void _showSaveToCalendarDialog(BuildContext context, AppThemeData theme, WardrobeItemModel item) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => SaveOutfitToCalendarDialog(
        outfitItem: item,
        outfitName: item.category,
        outfitImageUrl: item.processedImageUrl ?? item.imageUrl,
      ),
    ).then((saved) {
      if (saved == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Outfit saved to calendar!',
                    style: theme.bodyMedium(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: theme.accentSuccess,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pushNamed(Routes.calendar);
              },
            ),
          ),
        );
      }
    });
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    AppThemeData theme,
    WardrobeItemModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          'Delete Item',
          style: theme.titleMedium(color: theme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
          style: theme.bodyMedium(color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: theme.bodyMedium(color: theme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: theme.bodyMedium(color: theme.accentError),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: theme.primary),
                SizedBox(height: 16),
                Text(
                  'Deleting item...',
                  style: theme.bodyMedium(color: theme.textPrimary),
                ),
              ],
            ),
          ),
        ),
      );

      try {
        print('🗑️ Starting delete process for item: ${item.id}');
        
        final service = ref.read(wardrobeServiceProvider);
        
        // Delete from backend first
        await service.deleteItem(item.id);
        print('✅ Item deleted from backend');
        
        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // CRITICAL: Force immediate UI update
        // Step 1: Invalidate to clear cache
        ref.invalidate(wardrobeItemsProvider);
        
        // Step 2: Force refresh to trigger new fetch
        print('🔄 Refreshing wardrobe provider for real-time update...');
        try {
          // Refresh the provider - this forces immediate rebuild
          await ref.refresh(wardrobeItemsProvider.future);
          print('✅ Provider refresh completed');
        } catch (refreshError) {
          print('⚠️ Refresh error (non-critical): $refreshError');
          // Even if refresh fails, invalidate ensures next read will fetch fresh
        }
        
        // Step 3: Ensure widget rebuilds by reading the provider
        // This guarantees the UI updates
        if (mounted) {
          ref.read(wardrobeItemsProvider.future);
        }
        
        print('✅ UI update triggered');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Item deleted successfully',
                      style: theme.bodyMedium(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: theme.accentSuccess,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        print('❌ Delete error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Failed to delete: ${e.toString().replaceAll('Exception: ', '')}',
                      style: theme.bodyMedium(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: theme.accentError,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _showDeleteDialog(context, theme, item),
              ),
            ),
          );
        }
      }
    }
  }

  Widget _buildErrorState(BuildContext context, AppThemeData theme, Object error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppThemeData.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.accentError,
            ),
            SizedBox(height: AppThemeData.spacingLG),
            Text(
              'Failed to load wardrobe',
              style: theme.titleMedium(color: theme.textPrimary),
            ),
            SizedBox(height: AppThemeData.spacingSM),
            Text(
              error.toString(),
              style: theme.bodyMedium(color: theme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


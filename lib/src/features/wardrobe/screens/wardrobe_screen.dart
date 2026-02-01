import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../../core/widgets/fashion_scaffold.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/widgets/dashboard_components.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
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
  bool _isGridView = true; // Toggle between grid and list view

  Color get _accentPink => context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent;
  Color get _accentPinkLight => _accentPink.withOpacity(0.85);

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
      filtered =
          filtered.where((item) => categories.contains(item.category)).toList();
    }

    // Color filter
    if (_selectedColor != null) {
      filtered = filtered
          .where((item) => item.colorTags.contains(_selectedColor!))
          .toList();
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
    const currentBottomNavIndex = 1;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: DashboardTopBar(
        aiStatus: 'My Wardrobe',
        isAITyping: false,
        notificationCount: 0,
        onProfileTap: () {
          Navigator.of(context).pushNamed(Routes.settings);
        },
        onNotificationsTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No new notifications')),
          );
        },
      ),
      drawer: _buildNavigationDrawer(context),
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
                    // Modern Header with Search and Controls
                    _buildModernHeader(theme, isMobile),

                    // Category Tabs (Pill-shaped, animated)
                    _buildCategoryTabs(theme, isMobile),

                    // Wardrobe Grid/List with smooth fade-in
                    Expanded(
                      child: filteredItems.isEmpty
                          ? _buildEmptyState(context, theme, items.isEmpty)
                          : RefreshIndicator(
                              onRefresh: () async {
                                ref.invalidate(wardrobeItemsProvider);
                              },
                              color: _accentPink,
                              child: _isGridView
                                  ? _buildWardrobeGrid(
                                      context,
                                      theme,
                                      filteredItems,
                                      isMobile,
                                    )
                                  : _buildWardrobeList(
                                      context,
                                      theme,
                                      filteredItems,
                                    ),
                            ).animate().fadeIn(duration: 300.ms),
                    ),
                  ],
                ),

                // Floating Action Button (modern)
                Positioned(
                  bottom: isMobile ? 80 : 24,
                  right: 24,
                  child: _buildFloatingActionButton(theme),
                ),

                // Multi-select toolbar
                if (_isMultiSelectMode)
                  _buildMultiSelectToolbar(theme, isMobile),
              ],
            );
          },
          loading: () => _buildLoadingState(theme),
          error: (error, stack) => _buildErrorState(context, theme, error),
        ),
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
                    'Your AI Fashion Assistant',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _buildNavItem(
              context: context,
              icon: Icons.home,
              label: 'Dashboard',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.dashboard);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.checkroom,
              label: 'Wardrobe',
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.image_search,
              label: 'Virtual Try-On',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.tryon);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.lightbulb,
              label: 'Recommendations',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.recommendations);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.calendar_today,
              label: 'Calendar & Events',
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
            const Divider(),
            _buildNavItem(
              context: context,
              icon: Icons.settings,
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

  /// Modern Header with Search and View Toggle
  Widget _buildModernHeader(AppThemeData theme, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.borderLight.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Bar with Filter & View Toggle
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.borderLight.withOpacity(0.3),
                      width: 1,
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
                      hintText: 'Search wardrobe...',
                      hintStyle: theme.bodyMedium(color: theme.textTertiary),
                      prefixIcon: Icon(Icons.search,
                          color: theme.textSecondary, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close,
                                  color: theme.textSecondary, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    style: theme.bodyMedium(color: theme.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Filter button
              Container(
                decoration: BoxDecoration(
                  color: theme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.borderLight.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(Icons.tune, color: theme.textSecondary, size: 20),
                  onPressed: () {
                    _showFiltersBottomSheet(theme);
                  },
                  constraints:
                      const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
              ),
              const SizedBox(width: 8),
              // Grid/List toggle button
              Container(
                decoration: BoxDecoration(
                  color: theme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.borderLight.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    _isGridView ? Icons.view_agenda : Icons.grid_view,
                    color: _accentPink,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                    HapticFeedback.selectionClick();
                  },
                  constraints:
                      const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Category Tabs - Pill-shaped with animated underline
  Widget _buildCategoryTabs(AppThemeData theme, bool isMobile) {
    final categories = [
      'All',
      'Tops',
      'Bottoms',
      'Dresses',
      'Shoes',
      'Accessories',
      'Outerwear'
    ];

    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
      color: theme.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category ||
              (category == 'All' && _selectedCategory == null);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category == 'All' ? null : category;
              });
              HapticFeedback.selectionClick();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? _accentPink.withOpacity(0.15)
                    : theme.surfaceElevated.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? _accentPink.withOpacity(0.3)
                      : theme.borderLight.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  category,
                  style: theme
                      .bodySmall(
                        color: isSelected ? _accentPink : theme.textSecondary,
                      )
                      .copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                ),
              ),
            ).animate().fadeIn(duration: 200.ms),
          );
        },
      ),
    );
  }

  /// Wardrobe List View (alternative to grid)
  Widget _buildWardrobeList(
    BuildContext context,
    AppThemeData theme,
    List<WardrobeItemModel> items,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final displayImageUrl = item.processedImageUrl ?? item.imageUrl;

        return GestureDetector(
          onTap: () => _showItemDetails(context, theme, item),
          onLongPress: () {
            setState(() {
              _isMultiSelectMode = true;
              _selectedItems.add(item.id);
            });
            HapticFeedback.mediumImpact();
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.borderLight.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Thumbnail image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: theme.backgroundPrimary,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      displayImageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.checkroom,
                        color: theme.textTertiary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Item info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.category,
                        style: theme
                            .bodyMedium(color: theme.textPrimary)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      if (item.brand != null)
                        Text(
                          item.brand!,
                          style: theme.bodySmall(color: theme.textSecondary),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: item.colorTags.take(2).map((color) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _accentPink.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _accentPink.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              color,
                              style: theme.bodySmall(color: _accentPink),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                // Select checkbox
                if (_isMultiSelectMode)
                  Checkbox(
                    value: _selectedItems.contains(item.id),
                    onChanged: (_) {
                      setState(() {
                        if (_selectedItems.contains(item.id)) {
                          _selectedItems.remove(item.id);
                        } else {
                          _selectedItems.add(item.id);
                        }
                      });
                    },
                    fillColor: MaterialStatePropertyAll<Color>(_accentPink),
                  ),
              ],
            ),
          ).animate().fadeIn(duration: 200.ms + (index * 50).ms),
        );
      },
    );
  }

  /// Multi-select toolbar at bottom
  Widget _buildMultiSelectToolbar(AppThemeData theme, bool isMobile) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: theme.surface,
          border: Border(
            top: BorderSide(
              color: theme.borderLight.withOpacity(0.3),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: 12,
        ),
        child: SafeArea(
          child: Row(
            children: [
              Text(
                '${_selectedItems.length} selected',
                style: theme
                    .bodyMedium(color: theme.textPrimary)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              // Try On button
              ElevatedButton.icon(
                onPressed: () {
                  // Multi try-on action
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Opening try-on for ${_selectedItems.length} items'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.checkroom, size: 18),
                label: const Text('Try On'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentPink,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Delete button
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: theme.accentError, size: 20),
                onPressed: () {
                  _showDeleteSelectedDialog(theme);
                },
                tooltip: 'Delete selected',
              ),
              // Cancel
              IconButton(
                icon: Icon(Icons.close, color: theme.textSecondary, size: 20),
                onPressed: () {
                  setState(() {
                    _isMultiSelectMode = false;
                    _selectedItems.clear();
                  });
                },
                tooltip: 'Cancel',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show filters bottom sheet
  void _showFiltersBottomSheet(AppThemeData theme) {
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filters',
                        style: theme
                            .titleMedium(color: theme.textPrimary)
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Color',
                        style: theme
                            .bodyMedium(color: theme.textPrimary)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      // Color filter chips would go here
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentPink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(double.infinity, 44),
                        ),
                        child: Text(
                          'Apply Filters',
                          style: theme.bodyMedium(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteSelectedDialog(AppThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          'Delete ${_selectedItems.length} items?',
          style: theme.titleMedium(color: theme.textPrimary),
        ),
        content: Text(
          'This action cannot be undone.',
          style: theme.bodyMedium(color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: theme.bodyMedium(color: theme.textPrimary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isMultiSelectMode = false;
                _selectedItems.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Items deleted')),
              );
            },
            child: Text('Delete',
                style: theme.bodyMedium(color: theme.accentError)),
          ),
        ],
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

  Widget _buildFilterChips(
      AppThemeData theme, List<WardrobeItemModel> items, bool isMobile) {
    final categories = [
      'All',
      'Tops',
      'Bottoms',
      'Dresses',
      'Outerwear',
      'Shoes',
      'Accessories'
    ];
    final colors = items.expand((item) => item.colorTags).toSet().toList()
      ..sort();

    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Category filters
          ...categories.map((category) {
            final isSelected = _selectedCategory == category ||
                (category == 'All' && _selectedCategory == null);
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
                selectedColor: _accentPink.withOpacity(0.2),
                checkmarkColor: _accentPink,
                labelStyle: theme
                    .bodySmall(
                      color: isSelected ? _accentPink : theme.textSecondary,
                    )
                    .copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                side: BorderSide(
                  color: isSelected ? _accentPink : theme.borderLight,
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
          colors: [_accentPink, _accentPinkLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _accentPink.withOpacity(0.4),
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
          child: const SizedBox(
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

  Widget _buildEmptyState(
      BuildContext context, AppThemeData theme, bool isCompletelyEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppThemeData.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fashion illustration with gradient
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _accentPink.withOpacity(0.1),
                    _accentPink.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _accentPink.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.checkroom_outlined,
                size: 70,
                color: _accentPink.withOpacity(0.6),
              ),
            ).animate().scale(
                  begin: const Offset(0.8, 0.8),
                  duration: 400.ms,
                  curve: Curves.easeOut,
                ),
            const SizedBox(height: AppThemeData.spacingXXL),
            Text(
              isCompletelyEmpty ? 'Your wardrobe awaits' : 'No matches found',
              style: theme
                  .titleLarge(color: theme.textPrimary)
                  .copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppThemeData.spacingSM),
            SizedBox(
              width: 280,
              child: Text(
                isCompletelyEmpty
                    ? 'Build your digital closet by uploading your favorite pieces. Let AI help you style them.'
                    : 'Try adjusting your search or filters to find what you\'re looking for.',
                style: theme.bodyMedium(color: theme.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
            ),
            if (isCompletelyEmpty) ...[
              const SizedBox(height: AppThemeData.spacingXXL),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(Routes.addItem);
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Your First Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ] else ...[
              const SizedBox(height: AppThemeData.spacingXXL),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _selectedColor = null;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Clear Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accentPink,
                  side: BorderSide(
                      color: _accentPink.withOpacity(0.3), width: 1.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
    return Container(
      decoration: theme.backgroundGradient != null
          ? BoxDecoration(gradient: theme.backgroundGradient)
          : BoxDecoration(color: theme.backgroundPrimary),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.surfaceElevated,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: theme.surfaceElevated.withOpacity(0.5),
                child: const Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            ),
          ).animate().shimmer(
                duration: 1000.ms,
                color: _accentPink.withOpacity(0.1),
              );
        },
      ),
    );
  }

  void _showItemMenu(
      BuildContext context, AppThemeData theme, WardrobeItemModel item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.borderMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header with item preview
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: theme.backgroundPrimary,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.processedImageUrl ?? item.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.checkroom,
                            color: theme.textTertiary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.category,
                            style: theme
                                .bodyMedium(color: theme.textPrimary)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (item.brand != null)
                            Text(
                              item.brand!,
                              style:
                                  theme.bodySmall(color: theme.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Try On button (prominent)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to try-on with this item
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Opening Try-On with ${item.category}...'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    Navigator.of(context).pushNamed(Routes.tryon);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentPink,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.checkroom, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Try On This Item',
                        style: theme
                            .bodyMedium(color: Colors.white)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Other options
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
                leading: Icon(Icons.calendar_today, color: _accentPink),
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
              const SizedBox(height: AppThemeData.spacingMD),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemDetails(
      BuildContext context, AppThemeData theme, WardrobeItemModel item) {
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

  void _showSaveToCalendarDialog(
      BuildContext context, AppThemeData theme, WardrobeItemModel item) {
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
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: _accentPink),
                const SizedBox(height: 16),
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
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
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
                  const Icon(Icons.error_outline,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
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

  Widget _buildErrorState(
      BuildContext context, AppThemeData theme, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppThemeData.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.accentError,
            ),
            const SizedBox(height: AppThemeData.spacingLG),
            Text(
              'Failed to load wardrobe',
              style: theme.titleMedium(color: theme.textPrimary),
            ),
            const SizedBox(height: AppThemeData.spacingSM),
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

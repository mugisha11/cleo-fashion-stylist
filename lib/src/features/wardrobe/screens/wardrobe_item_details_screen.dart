import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../providers/wardrobe_provider.dart';
import '../../../routes.dart';

/// Wardrobe Item Details Screen
/// Shows full metadata for a clothing item
class WardrobeItemDetailsScreen extends ConsumerStatefulWidget {
  final WardrobeItemModel item;

  const WardrobeItemDetailsScreen({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<WardrobeItemDetailsScreen> createState() => _WardrobeItemDetailsScreenState();
}

class _WardrobeItemDetailsScreenState extends ConsumerState<WardrobeItemDetailsScreen> {
  bool _isLoading = false;
  WardrobeItemModel? _loadedItem;

  @override
  void initState() {
    super.initState();
    _loadItemDetails();
  }

  Future<void> _loadItemDetails() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      print('📋 Loading item details for: ${widget.item.id}');
      final service = ref.read(wardrobeServiceProvider);
      final item = await service.getItemById(widget.item.id);
      
      print('📋 Item loaded: ${item != null ? "Found" : "Not found, using passed item"}');
      
      if (mounted) {
        setState(() {
          _loadedItem = item ?? widget.item;
          _isLoading = false;
        });
        print('✅ Details screen updated with item data');
      }
    } catch (e) {
      print('❌ Error loading item details: $e');
      if (mounted) {
        setState(() {
          _loadedItem = widget.item; // Use passed item as fallback
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load details: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: context.appTheme.accentError,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final item = _loadedItem ?? widget.item;
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    // Use processed image if available, otherwise original
    final displayImageUrl = item.processedImageUrl ?? item.imageUrl;

    return Scaffold(
      backgroundColor: theme.backgroundPrimary,
      body: Container(
        decoration: theme.backgroundGradient != null
            ? BoxDecoration(gradient: theme.backgroundGradient)
            : BoxDecoration(color: theme.backgroundPrimary),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(theme),
              
              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState(theme)
                    : SingleChildScrollView(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            _buildImageSection(theme, displayImageUrl, isMobile),
                            
                            SizedBox(height: AppThemeData.spacingLG),
                            
                            // Category & Confidence
                            _buildCategorySection(theme, item),
                            
                            SizedBox(height: AppThemeData.spacingMD),
                            
                            // Colors
                            if (item.colorTags.isNotEmpty || item.colorPalette != null)
                              _buildColorsSection(theme, item),
                            
                            SizedBox(height: AppThemeData.spacingMD),
                            
                            // Pattern
                            if (item.pattern != null)
                              _buildPatternSection(theme, item),
                            
                            SizedBox(height: AppThemeData.spacingMD),
                            
                            // Attributes
                            if (item.aiAttributes != null && item.aiAttributes!.isNotEmpty)
                              _buildAttributesSection(theme, item),
                            
                            SizedBox(height: AppThemeData.spacingMD),
                            
                            // Brand & Notes
                            if (item.brand != null || item.notes != null)
                              _buildMetadataSection(theme, item),
                            
                            SizedBox(height: AppThemeData.spacingMD),
                            
                            // Upload Date
                            _buildDateSection(theme, item),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeData theme) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.borderLight.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: theme.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              'Item Details',
              style: theme.titleMedium(color: theme.textPrimary).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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

  Widget _buildImageSection(AppThemeData theme, String imageUrl, bool isMobile) {
    return Container(
      width: double.infinity,
      height: isMobile ? 400 : 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => Container(
            color: theme.surfaceElevated,
            child: Center(
              child: CircularProgressIndicator(
                color: theme.primary,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: theme.surfaceElevated,
            child: Icon(
              Icons.broken_image,
              color: theme.textTertiary,
              size: 64,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildCategorySection(AppThemeData theme, WardrobeItemModel item) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.checkroom,
              color: theme.primary,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category',
                  style: theme.bodySmall(color: theme.textSecondary),
                ),
                SizedBox(height: 4),
                Text(
                  item.category,
                  style: theme.titleMedium(color: theme.textPrimary).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (item.aiConfidence != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${(item.aiConfidence! * 100).toStringAsFixed(0)}%',
                style: theme.bodySmall(color: theme.primary).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColorsSection(AppThemeData theme, WardrobeItemModel item) {
    final colors = item.colorPalette != null
        ? item.colorPalette!.map((c) => c['name'] as String).toList()
        : item.colorTags;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette, color: theme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Colors',
                style: theme.bodyMedium(color: theme.textPrimary).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((color) {
              final colorData = item.colorPalette?.firstWhere(
                (c) => c['name'] == color,
                orElse: () => {'hex': '#000000', 'name': color, 'percentage': 0},
              );
              final hex = colorData?['hex'] as String? ?? '#000000';
              
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _hexToColor(hex).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _hexToColor(hex),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _hexToColor(hex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.borderLight,
                          width: 1,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      color,
                      style: theme.bodySmall(color: theme.textPrimary).copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternSection(AppThemeData theme, WardrobeItemModel item) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.texture, color: theme.primary, size: 20),
          SizedBox(width: 12),
          Text(
            'Pattern: ',
            style: theme.bodyMedium(color: theme.textSecondary),
          ),
          Text(
            item.pattern!,
            style: theme.bodyMedium(color: theme.textPrimary).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributesSection(AppThemeData theme, WardrobeItemModel item) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: theme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Attributes',
                style: theme.bodyMedium(color: theme.textPrimary).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...item.aiAttributes!.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatAttributeKey(entry.key),
                      style: theme.bodyMedium(color: theme.textSecondary),
                    ),
                  ),
                  Text(
                    entry.value.toString(),
                    style: theme.bodyMedium(color: theme.textPrimary).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(AppThemeData theme, WardrobeItemModel item) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.brand != null) ...[
            Row(
              children: [
                Icon(Icons.store, color: theme.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.brand!,
                    style: theme.bodyMedium(color: theme.textPrimary).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (item.notes != null) SizedBox(height: 12),
          ],
          if (item.notes != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.note_outlined, color: theme.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.notes!,
                    style: theme.bodyMedium(color: theme.textSecondary),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDateSection(AppThemeData theme, WardrobeItemModel item) {
    final dateFormat = '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}';
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: theme.primary, size: 20),
          SizedBox(width: 12),
          Text(
            'Added: $dateFormat',
            style: theme.bodyMedium(color: theme.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatAttributeKey(String key) {
    // Convert camelCase to Title Case
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}

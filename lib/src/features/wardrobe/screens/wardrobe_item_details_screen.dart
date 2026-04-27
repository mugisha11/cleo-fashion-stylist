import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/services/wardrobe_service.dart';
import '../providers/wardrobe_provider.dart';

/// Wardrobe Item Details Screen
/// Shows full metadata for a clothing item
class WardrobeItemDetailsScreen extends ConsumerStatefulWidget {
  final WardrobeItemModel item;

  const WardrobeItemDetailsScreen({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<WardrobeItemDetailsScreen> createState() =>
      _WardrobeItemDetailsScreenState();
}

class _WardrobeItemDetailsScreenState
    extends ConsumerState<WardrobeItemDetailsScreen> {
  bool _isLoading = false;
  WardrobeItemModel? _loadedItem;
  List<WardrobeOutfitSuggestion>? _outfitRecommendations;
  bool _isGeneratingRecommendations = false;
  String? _recommendationsError;

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

      print(
          '📋 Item loaded: ${item != null ? "Found" : "Not found, using passed item"}');

      if (mounted) {
        setState(() {
          _loadedItem = item ?? widget.item;
          _isLoading = false;
        });
        print('✅ Details screen updated with item data');
        _loadRecommendations(_loadedItem!);
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
            content: Text(
                'Failed to load details: ${e.toString().replaceAll('Exception: ', '')}'),
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
    final accentPink =
        context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent;
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
                            _buildImageSection(
                                theme, displayImageUrl, isMobile),

                            const SizedBox(height: AppThemeData.spacingLG),

// Category
                            _buildCategorySection(theme, item),

                            const SizedBox(height: AppThemeData.spacingMD),

                            // Quick facts for friendly display
                            if (_hasFriendlyFacts(item))
                              _buildQuickFactsSection(theme, item),

                            const SizedBox(height: AppThemeData.spacingMD),

                            // Colors
                            if (item.colorTags.isNotEmpty ||
                                item.colorPalette != null)
                              _buildColorsSection(theme, item),

                            const SizedBox(height: AppThemeData.spacingMD),

                            // Pattern
                            if (item.pattern != null)
                              _buildPatternSection(theme, item),

                            const SizedBox(height: AppThemeData.spacingMD),

                            // Brand & Notes
                            if (item.brand != null || item.notes != null)
                              _buildMetadataSection(theme, item),

                            const SizedBox(height: AppThemeData.spacingMD),

                            // Upload Date
                            _buildDateSection(theme, item),

                            const SizedBox(height: AppThemeData.spacingMD),

                            // Outfit Recommendations
                            _buildOutfitRecommendationsSection(theme, item),
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
      padding: const EdgeInsets.all(16),
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
    final accentPink =
        context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    return Center(
      child: CircularProgressIndicator(
        color: accentPink,
      ),
    );
  }

  Widget _buildImageSection(
      AppThemeData theme, String imageUrl, bool isMobile) {
    final accentPink =
        context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent;
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
                color: accentPink,
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
      padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.all(12),
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
              const SizedBox(width: 16),
              Text(
                'Category',
                style: theme.bodySmall(color: theme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.category,
            style: theme.titleMedium(color: theme.textPrimary).copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (item.subcategory != null && item.subcategory!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.subcategory!,
              style: theme.bodyMedium(color: theme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasFriendlyFacts(WardrobeItemModel item) {
    return item.subcategory != null && item.subcategory!.isNotEmpty ||
        item.fit != null && item.fit!.isNotEmpty ||
        item.occasion != null && item.occasion!.isNotEmpty ||
        item.season != null && item.season!.isNotEmpty ||
        item.fabric != null && item.fabric!.isNotEmpty;
  }

  Widget _buildQuickFactsSection(AppThemeData theme, WardrobeItemModel item) {
    final facts = <Map<String, String>>[];
    if (item.subcategory != null && item.subcategory!.isNotEmpty) {
      facts.add({'Type': item.subcategory!});
    }
    if (item.fit != null && item.fit!.isNotEmpty) {
      facts.add({'Fit': item.fit!});
    }
    if (item.fabric != null && item.fabric!.isNotEmpty) {
      facts.add({'Fabric': item.fabric!});
    }
    if (item.occasion != null && item.occasion!.isNotEmpty) {
      facts.add({'Occasion': item.occasion!.join(', ')});
    }
    if (item.season != null && item.season!.isNotEmpty) {
      facts.add({'Season': item.season!.join(', ')});
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            'Quick Details',
            style: theme.bodyMedium(color: theme.textPrimary).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 12),
          ...facts.map((fact) {
            final key = fact.keys.first;
            final value = fact.values.first;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      key,
                      style: theme.bodyMedium(color: theme.textSecondary),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      value,
                      style:
                          theme.bodyMedium(color: theme.textPrimary).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildColorsSection(AppThemeData theme, WardrobeItemModel item) {
    final accentPink =
        context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    final colors = item.colorPalette != null
        ? item.colorPalette!.map((c) => c['name'] as String).toList()
        : item.colorTags;

    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.palette, color: accentPink, size: 20),
              const SizedBox(width: 8),
              Text(
                'Colors',
                style: theme.bodyMedium(color: theme.textPrimary).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((color) {
              final colorData = item.colorPalette?.firstWhere(
                (c) => c['name'] == color,
                orElse: () =>
                    {'hex': '#000000', 'name': color, 'percentage': 0},
              );
              final hex = colorData?['hex'] as String? ?? '#000000';

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    const SizedBox(width: 8),
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
    final accentPink =
        context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    return Container(
      padding: const EdgeInsets.all(16),
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
          Icon(Icons.texture, color: accentPink, size: 20),
          const SizedBox(width: 12),
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
    final accentPink =
        context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.info_outline, color: accentPink, size: 20),
              const SizedBox(width: 8),
              Text(
                'Attributes',
                style: theme.bodyMedium(color: theme.textPrimary).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...item.aiAttributes!.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
          }),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(AppThemeData theme, WardrobeItemModel item) {
    final accentPink =
        context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    return Container(
      padding: const EdgeInsets.all(16),
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
                Icon(Icons.store, color: accentPink, size: 20),
                const SizedBox(width: 12),
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
            if (item.notes != null) const SizedBox(height: 12),
          ],
          if (item.notes != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.note_outlined, color: accentPink, size: 20),
                const SizedBox(width: 12),
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

  Widget _buildOutfitRecommendationsSection(
      AppThemeData theme, WardrobeItemModel item) {
    final accentPink =
        context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.style_outlined, color: accentPink, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Outfit Ideas',
                  style: theme.bodyMedium(color: theme.textPrimary).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recommendationsError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _recommendationsError!,
                style: theme.bodyMedium(color: theme.textTertiary),
              ),
            )
          else if (_outfitRecommendations != null &&
              _outfitRecommendations!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _outfitRecommendations!.map((rec) {
                final isOnline = rec.source == 'online';
                final sourceIcon =
                    isOnline ? Icons.shopping_bag_outlined : Icons.checkroom;
                final sourceLabel =
                    isOnline ? 'Online Option' : 'From Wardrobe';
                final sourceColor = isOnline
                    ? Colors.blue.withOpacity(0.15)
                    : accentPink.withOpacity(0.1);
                final borderColor = isOnline
                    ? Colors.blue.withOpacity(0.45)
                    : Colors.transparent;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.backgroundPrimary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor != Colors.transparent
                            ? borderColor
                            : theme.borderLight.withOpacity(0.2),
                        width: isOnline ? 2 : 1,
                      ),
                      gradient: isOnline
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue.withOpacity(0.05),
                                Colors.transparent,
                              ],
                            )
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                rec.title,
                                style: theme
                                    .bodyMedium(color: theme.textPrimary)
                                    .copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: sourceColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    sourceIcon,
                                    size: 12,
                                    color: isOnline ? Colors.blue : accentPink,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    sourceLabel,
                                    style: theme
                                        .bodySmall(
                                          color: isOnline
                                              ? Colors.blue
                                              : accentPink,
                                        )
                                        .copyWith(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (!isOnline && rec.itemIds.isNotEmpty)
                          FutureBuilder<List<WardrobeItemModel>>(
                            future: _fetchWardrobeItemsByIds(rec.itemIds),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return SizedBox(
                                  height: 88,
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: accentPink,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final wardrobeItems = snapshot.data ?? [];
                              if (wardrobeItems.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'No wardrobe images found for this outfit.',
                                    style: theme.bodySmall(
                                        color: theme.textSecondary),
                                  ),
                                );
                              }

                              return SizedBox(
                                height: 88,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: wardrobeItems.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final item = wardrobeItems[index];
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 84,
                                        height: 84,
                                        color: theme.surface,
                                        child: CachedNetworkImage(
                                          imageUrl: item.imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                            color: theme.surface,
                                            child: Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: accentPink,
                                                ),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            color: theme.surface,
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: theme.textTertiary,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        if (!isOnline || rec.itemIds.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              rec.description,
                              style:
                                  theme.bodySmall(color: theme.textSecondary),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          '✨ ${rec.reason}',
                          style: theme.bodySmall(color: accentPink),
                        ),
                        if (isOnline) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (rec.sourceStore != null) ...[
                                const Icon(Icons.store, size: 14, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  rec.sourceStore!,
                                  style: theme
                                      .bodySmall(color: Colors.blue)
                                      .copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                              if (rec.price != null) ...[
                                const SizedBox(width: 12),
                                const Icon(Icons.local_offer,
                                    size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  '\$${rec.price!.toStringAsFixed(2)}',
                                  style: theme
                                      .bodySmall(color: Colors.green)
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                          if (rec.sourceLink != null) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (rec.sourceLink != null) {
                                    try {
                                      // Use url_launcher to open the link
                                      await launchUrl(
                                        Uri.parse(rec.sourceLink!),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } catch (e) {
                                      print('❌ Error opening link: $e');
                                      // Fallback: show snackbar with link
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Could not open link. URL: ${rec.sourceLink}'),
                                            backgroundColor: theme.accentError,
                                            duration:
                                                const Duration(seconds: 5),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.open_in_new, size: 14),
                                label: const Text('Shop Now'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  textStyle: theme.bodySmall(),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No recommendations available',
                style: theme.bodyMedium(color: theme.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Future<List<WardrobeItemModel>> _fetchWardrobeItemsByIds(
      List<String> itemIds) async {
    if (itemIds.isEmpty) return [];

    try {
      final service = ref.read(wardrobeServiceProvider);
      final items = await service.getUserWardrobe();
      return items.where((item) => itemIds.contains(item.id)).toList();
    } catch (e) {
      print('❌ Error fetching wardrobe items: $e');
      return [];
    }
  }

  Future<void> _loadRecommendations(WardrobeItemModel item) async {
    if (!mounted) return;

    setState(() {
      _isGeneratingRecommendations = true;
      _recommendationsError = null;
    });

    try {
      final service = ref.read(wardrobeServiceProvider);
      final recommendations = await service.generateOutfitRecommendations(item);
      if (mounted) {
        setState(() {
          _outfitRecommendations = recommendations;
        });
      }
    } catch (e) {
      print('❌ Error loading recommendations: $e');
      if (mounted) {
        setState(() {
          _recommendationsError = 'Could not load outfit ideas right now.';
          _outfitRecommendations = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingRecommendations = false;
        });
      }
    }
  }

  Widget _buildDateSection(AppThemeData theme, WardrobeItemModel item) {
    final accentPink =
        context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    final dateFormat =
        '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}';

    return Container(
      padding: const EdgeInsets.all(16),
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
          Icon(Icons.calendar_today, color: accentPink, size: 20),
          const SizedBox(width: 12),
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

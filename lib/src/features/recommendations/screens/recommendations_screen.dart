import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/backend_config_service.dart';
import '../../../core/widgets/cosmic_header_widget.dart';
import '../../../core/widgets/cosmic_footer_widget.dart';
import '../../social/providers/social_provider.dart';
import '../../../routes.dart';
import '../../../core/widgets/fashion_drawer.dart';
import '../../settings/models/settings_state.dart';
import '../../settings/providers/settings_provider.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../../../core/models/wardrobe_item_model.dart';

// ─────────────────────────────────────────────
// CONSTANTS  (mirrors the CSS vars & sizes)
// ─────────────────────────────────────────────
class _C {
  // header chrome
  static const headerBg = Color(0xFF0A1030);
  static const chromeDark = Color(0xFF080F36);
  static const chromeMid = Color(0xFF0D1E58);

  // product page
  static const pageWhite = Color(0xFFFFFFFF);
  static const pageBg = Color(0xFF0C1E48);
  static const textDark = Color(0xFF0C1E48);
  static const textMid = Color(0xFF2A3A6A);
  static const textLight = Color(0xFF6070A0);
  // NX action bar
  static const nxBtnBorder = Color(0x615090FF);

  // buttons
  static const bagGold = Color(0xFFB87D3A);
  static const sizeNavy = Color(0xFF0A4E8F);
  static const sizeNavyDark = Color(0xFF060F2E);

  // misc
  static const accent = Color(0xFF6AA4FF);
}

const List<String> _retailerOptions = [
  'Any store',
  'ASOS',
  'Zara',
  'H&M',
  'Nordstrom',
  'Mango',
  'Revolve',
  'Boohoo',
  'Urban Outfitters',
  'SHEIN',
];

// ─────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────
class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = false;
  final TextEditingController _urlController = TextEditingController();
  bool _initialRecommendationsLoaded = false;

  // Product page state
  String? _toastMsg;
  bool _showToast = false;

  // Shopping state
  final Set<String> _favoriteProducts = {};
  final Set<String> _outfitProducts = {};
  final List<_ProductRecommendation> _recommendations = [];
  String? _recommendationQuery;
  String? _recommendationMessage;
  String _selectedRetailer = _retailerOptions.first;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String _buildRecommendationSearchQuery(
      SettingsState settings, List<WardrobeItemModel> wardrobeItems) {
    final parts = <String>[];

    if (settings.preferredStyles.isNotEmpty) {
      parts.add(settings.preferredStyles.join(' '));
    }
    if (settings.colorPreferences.isNotEmpty) {
      parts.add(settings.colorPreferences.join(' '));
    }
    if (settings.eventPreferences.isNotEmpty) {
      parts.add(settings.eventPreferences.join(' '));
    }
    if (settings.bodyType != null && settings.bodyType!.isNotEmpty) {
      parts.add('${settings.bodyType} friendly');
    }
    if (settings.height != null) {
      parts.add('${settings.height!.round()}cm');
    }

    final wardrobeQuery = _buildWardrobeQuery(wardrobeItems);
    if (wardrobeQuery.isNotEmpty) {
      parts.add(wardrobeQuery);
    }

    final query = parts.isNotEmpty
        ? 'outfit ideas ${parts.join(' ')}'
        : 'outfit ideas based on a modern wardrobe';

    return query.trim();
  }

  String _buildWardrobeQuery(List<WardrobeItemModel> wardrobeItems) {
    if (wardrobeItems.isEmpty) return 'new wardrobe essentials';

    final categories = wardrobeItems
        .map((item) =>
            (item.subcategory?.isNotEmpty == true
                ? item.subcategory
                : item.category) ??
            '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    if (categories.isEmpty) {
      return 'new outfits to complement my wardrobe';
    }

    final topCategories = categories.length > 3
        ? categories.take(3).join(', ')
        : categories.join(', ');
    return 'outfits to complement my $topCategories';
  }

  void _loadInitialRecommendationsIfNeeded(SettingsState settings,
      AsyncValue<List<WardrobeItemModel>> wardrobeAsync) {
    if (_initialRecommendationsLoaded) return;
    if (settings.isLoading || wardrobeAsync.isLoading) return;

    final wardrobeItems = wardrobeAsync.valueOrNull ?? [];
    final query = _buildRecommendationSearchQuery(settings, wardrobeItems);
    _initialRecommendationsLoaded = true;

    setState(() {
      _urlController.text = query;
      _isLoading = true;
      _recommendationQuery = query;
      _recommendationMessage = 'Curating your runway-ready looks…';
    });

    _fetchProductRecommendations(query, _selectedRetailer);
  }

  Future<void> _fetchProductRecommendations(String query,
      [String? retailer]) async {
    setState(() {
      _recommendationMessage = 'Styling your curated edit now…';
    });

    try {
      final baseUrl = await BackendConfigService.getBackendUrl();
      final shoppingQuery = await _rewriteSearchQuery(query, retailer);
      final params = <String, String>{'q': shoppingQuery, 'limit': '50'};
      if (retailer != null && retailer != 'Any store') {
        params['site'] = retailer;
      }
      final uri = Uri.parse('$baseUrl/product-search').replace(
        queryParameters: params,
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200 || resp.body.isEmpty) {
        final responseBody =
            resp.body.isNotEmpty ? resp.body : 'Empty response';
        throw Exception(
            'Failed to load recommendations (${resp.statusCode}): $responseBody');
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>?;
      final list = data?['products'] as List<dynamic>?;
      final backendMessage = data?['message'] as String?;
      if (list == null) {
        if (mounted) {
          setState(() {
            _recommendations.clear();
            _recommendationMessage =
                backendMessage ?? 'No style picks could be found right now.';
          });
        }
        return;
      }
      final items = <_ProductRecommendation>[];
      for (final entry in list) {
        if (entry is! Map<String, dynamic>) continue;
        final title = entry['title'] as String? ?? 'Style pick';
        final imageUrl = entry['image_url'] as String? ?? '';
        final link = entry['link'] as String? ?? '';
        final price = entry['price'] as String?;
        final brand = entry['brand'] as String?;
        final size = entry['size'] as String?;
        final source = entry['source'] as String?;
        final availability = entry['availability'] as String?;
        final description = entry['description'] as String?;
        final rawImages = <String>[];
        final images = entry['images'];
        if (images is List) {
          for (final imageEntry in images) {
            if (imageEntry is String && imageEntry.isNotEmpty) {
              rawImages.add(imageEntry);
            } else if (imageEntry is Map<String, dynamic>) {
              final possibleUrl = imageEntry['url'] as String? ??
                  imageEntry['image'] as String?;
              if (possibleUrl != null && possibleUrl.isNotEmpty) {
                rawImages.add(possibleUrl);
              }
            }
          }
        }
        if (rawImages.isEmpty && imageUrl.isNotEmpty) {
          rawImages.add(imageUrl);
        }
        final previewImageUrls = rawImages
            .where((url) => url is String && url.isNotEmpty)
            .map(
                (url) => '$baseUrl/proxy-image?url=${Uri.encodeComponent(url)}')
            .toList();
        final displayImageUrl =
            previewImageUrls.isNotEmpty ? previewImageUrls.first : null;
        if (title.isEmpty || displayImageUrl == null) continue;
        items.add(_ProductRecommendation(
          title: title,
          imageUrl: imageUrl,
          displayImageUrl: displayImageUrl,
          previewImageUrls: previewImageUrls,
          link: link,
          price: price,
          brand: brand,
          size: size,
          source: source,
          availability: availability,
          description: description,
        ));
      }
      if (!mounted) return;
      setState(() {
        _recommendations.clear();
        _recommendations.addAll(items);
        _recommendationMessage = items.isEmpty
            ? (backendMessage ?? 'Your style lookbook is still being styled.')
            : 'Here are your curated pieces for a polished wardrobe update.';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _recommendationMessage = 'Style search hit a snag. ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _searchRecommendations(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _showToastMsg('Share your style mood and I’ll find the right pieces.');
      return;
    }

    setState(() {
      _urlController.text = trimmed;
      _isLoading = true;
      _recommendationQuery = trimmed;
      _recommendationMessage = 'Searching the fashion edit for your next look…';
    });

    _fetchProductRecommendations(trimmed, _selectedRetailer);
  }

  Future<String> _rewriteSearchQuery(String query, [String? retailer]) async {
    if (query.trim().isEmpty) return query.trim();
    try {
      final baseUrl = await BackendConfigService.getBackendUrl();
      final params = <String, String>{'q': query.trim()};
      if (retailer != null && retailer != 'Any store') {
        params['site'] = retailer;
      }
      final uri = Uri.parse('$baseUrl/product-search/rewrite').replace(
        queryParameters: params,
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200 || resp.body.isEmpty) {
        return query.trim();
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>?;
      final rewritten = data?['query'] as String?;
      if (rewritten == null || rewritten.trim().isEmpty) {
        return query.trim();
      }
      return rewritten.trim();
    } catch (_) {
      return query.trim();
    }
  }

  Widget _buildRecommendationViewport(
      List<WardrobeItemModel> wardrobeItems, SettingsState settings) {
    final gapLabels = _detectWardrobeGaps(wardrobeItems);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (gapLabels.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Wardrobe gap alerts',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _C.pageBg)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: gapLabels
                      .map((label) => ActionChip(
                            label: Text(label,
                                style: const TextStyle(fontSize: 11)),
                            backgroundColor: const Color(0xFFEDF2FF),
                            onPressed: () => _searchRecommendations(
                                _buildGapQuery(label, settings)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        Expanded(child: _buildProductGrid()),
      ],
    );
  }

  String _buildGapQuery(String gap, SettingsState settings) {
    final styleHint = settings.preferredStyles.isNotEmpty
        ? settings.preferredStyles.join(' ')
        : 'modern';
    final colorHint = settings.colorPreferences.isNotEmpty
        ? settings.colorPreferences.join(' ')
        : '';
    final occasionHint = settings.eventPreferences.isNotEmpty
        ? settings.eventPreferences.join(' ')
        : '';

    if (gap == 'Shoes') {
      return 'best $styleHint sneakers $colorHint'.trim();
    }
    if (gap == 'Layering') {
      return 'light jacket $styleHint $colorHint'.trim();
    }
    if (gap == 'Formal') {
      return 'formal outfit $styleHint $colorHint'.trim();
    }
    if (gap == 'Accessories') {
      return 'accessories for $occasionHint $styleHint'.trim();
    }
    if (gap == 'Complete outfit') {
      return '$styleHint complete outfit $colorHint'.trim();
    }
    return '$gap $styleHint $colorHint'.trim();
  }

  List<String> _detectWardrobeGaps(List<WardrobeItemModel> wardrobeItems) {
    final normalized = wardrobeItems
        .map((item) => (item.subcategory ?? item.category).toLowerCase())
        .toSet();

    final hasShoes = normalized.any((value) =>
        value.contains('shoe') ||
        value.contains('boot') ||
        value.contains('sneaker'));
    final hasJacket = normalized.any((value) =>
        value.contains('jacket') ||
        value.contains('coat') ||
        value.contains('blazer') ||
        value.contains('hoodie'));
    final hasFormal = wardrobeItems.any((item) {
      final occasions =
          item.occasion?.map((e) => e.toLowerCase()).toList() ?? [];
      return occasions.any((text) =>
              text.contains('formal') ||
              text.contains('business') ||
              text.contains('evening')) ||
          normalized.any((value) =>
              value.contains('suit') ||
              value.contains('dress') ||
              value.contains('blazer'));
    });
    final hasAccessories = normalized.any((value) =>
        value.contains('bag') ||
        value.contains('belt') ||
        value.contains('scarf') ||
        value.contains('hat') ||
        value.contains('jewelry'));
    final hasTop = normalized.any((value) =>
        value.contains('top') ||
        value.contains('shirt') ||
        value.contains('blouse') ||
        value.contains('tee') ||
        value.contains('sweater'));
    final hasBottom = normalized.any((value) =>
        value.contains('jean') ||
        value.contains('pant') ||
        value.contains('skirt') ||
        value.contains('short') ||
        value.contains('trouser'));

    final gaps = <String>[];
    if (!hasShoes) gaps.add('Shoes');
    if (!hasJacket) gaps.add('Layering');
    if (!hasFormal) gaps.add('Formal');
    if (!hasAccessories) gaps.add('Accessories');
    if (!hasTop || !hasBottom) gaps.add('Complete outfit');

    return gaps.toSet().toList();
  }

  Widget _buildEmptyRecommendationView() {
    return Container(
      color: const Color(0xFFF0F4FF),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_recommendationMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_recommendationMessage!,
                  style: const TextStyle(color: _C.textMid)),
            ),
          const Expanded(
            child: Center(
              child: Text(
                'No items found yet. Enter your style preferences and we’ll bring curated pieces from top retailers into the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _C.textMid),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return Container(
      color: const Color(0xFFF0F4FF),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_recommendationMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_recommendationMessage!,
                  style: const TextStyle(color: _C.textMid, fontSize: 12)),
            ),
          if (_isLoading && _recommendations.isEmpty)
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.72,
                ),
                itemCount: 8,
                itemBuilder: (context, index) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEFF4),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(18)),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: 12),
                            LinearProgressIndicator(minHeight: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.72,
                ),
                itemCount: _recommendations.length,
                itemBuilder: (context, index) {
                  final item = _recommendations[index];
                  return GestureDetector(
                    onTap: () => _openProductLink(item),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE3E7F3)),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 8,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(18)),
                                child: item.displayImageUrl != null
                                    ? Image.network(
                                        item.displayImageUrl!,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Container(
                                            height: 120,
                                            color: const Color(0xFFEFEFF4),
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            height: 120,
                                            color: const Color(0xFFEFEFF4),
                                            child: const Center(
                                              child: Icon(
                                                Icons.broken_image_outlined,
                                                size: 36,
                                                color: _C.textLight,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        height: 120,
                                        color: const Color(0xFFEFEFF4),
                                        child: const Icon(
                                            Icons.shopping_bag_outlined,
                                            size: 42,
                                            color: _C.textLight),
                                      ),
                              ),
                              if (item.isSoldOut)
                                Positioned(
                                  right: 10,
                                  top: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xCCB00020),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text('Sold out',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                if (item.brand != null || item.size != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        if (item.brand != null)
                                          _MetadataChip(
                                              label: item.brand!,
                                              icon: Icons.tag),
                                        if (item.size != null)
                                          _MetadataChip(
                                              label: item.size!,
                                              icon: Icons.straighten),
                                      ],
                                    ),
                                  ),
                                if (item.description != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(item.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: _C.textMid,
                                            height: 1.2)),
                                  ),
                                Text(item.price ?? 'Price unavailable',
                                    style: const TextStyle(
                                        fontSize: 11, color: _C.textMid)),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDF2FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                      item.source ??
                                          shopNameFromLink(item.link),
                                      style: const TextStyle(
                                          fontSize: 9, color: _C.sizeNavy)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openProductLink(_ProductRecommendation item) async {
    if (item.link.isEmpty) {
      _showToastMsg('This piece is missing a link — try another style.');
      return;
    }
    setState(() {
      _recommendationQuery = item.title;
    });
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _ProductDetailPage(
              product: item,
              onSaveToOutfit: () => _addCurrentProductToOutfit(
                  itemId: item.link, title: item.title),
            )));
  }

  void _showToastMsg(String msg) {
    setState(() {
      _toastMsg = msg;
      _showToast = true;
    });
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) setState(() => _showToast = false);
    });
  }

  void _toggleFavorite(String itemId, {String? title}) {
    setState(() {
      if (_favoriteProducts.contains(itemId)) {
        _favoriteProducts.remove(itemId);
        _showToastMsg('${title ?? 'Item'} removed from favorites');
      } else {
        _favoriteProducts.add(itemId);
        _showToastMsg('${title ?? 'Item'} added to favorites ✓');
      }
    });
  }

  void _addCurrentProductToOutfit({String? itemId, String? title}) {
    final effectiveItemId = itemId ?? _currentProductId;
    if (effectiveItemId.isEmpty) {
      _showToastMsg('Select a product first');
      return;
    }
    setState(() {
      _outfitProducts.add(effectiveItemId);
    });
    _showToastMsg('${title ?? _currentProductTitle} added to outfit ✓');
  }

  String get _currentProductId => _recommendationQuery ?? '';

  String get _currentProductTitle => _recommendationQuery?.isNotEmpty == true
      ? _recommendationQuery!
      : 'Style search';

  // ── BUILD ──────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final wardrobeAsync = ref.watch(wardrobeItemsProvider);

    if (!_initialRecommendationsLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialRecommendationsIfNeeded(settings, wardrobeAsync);
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _C.headerBg,
      drawer: const AppDrawer(currentRoute: Routes.recommendations),
      body: Stack(
        children: [
          Column(
            children: [
              // ① Cosmic header
              CosmicHeader(
                topPadding: MediaQuery.of(context).padding.top,
                hasNotification: ref.watch(socialUnreadCountProvider) > 0,
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                onBellTap: () => _showToastMsg('Notifications'),
                onAvatarTap: () => _showToastMsg('Profile'),
              ),

              // ② Search header
              _ShoppingSearchHeader(
                queryController: _urlController,
                isLoading: _isLoading,
                selectedRetailer: _selectedRetailer,
                retailerOptions: _retailerOptions,
                onRetailerChanged: (value) {
                  setState(() {
                    _selectedRetailer = value;
                  });
                  if (_recommendationQuery?.isNotEmpty == true) {
                    _searchRecommendations(_recommendationQuery!);
                  }
                },
                onSearch: _searchRecommendations,
                onRefresh: () => _searchRecommendations(
                    _recommendationQuery ?? _urlController.text),
                onFav: () => _toggleFavorite(_currentProductId,
                    title: _currentProductTitle),
                onOutfit: _addCurrentProductToOutfit,
                onTryOn: () => Navigator.of(context).pushNamed(Routes.tryon),
              ),

              // ③ Viewport
              Expanded(
                child: Container(
                  color: _C.pageWhite,
                  child: _recommendations.isEmpty && !_isLoading
                      ? (_recommendationQuery == null
                          ? _NewTabPage(onSearch: _searchRecommendations)
                          : _buildEmptyRecommendationView())
                      : _buildRecommendationViewport(
                          wardrobeAsync.valueOrNull ?? [],
                          settings,
                        ),
                ),
              ),

              // ④ NX action bar
              _NXActionBar(
                onFav: () => _showToastMsg('Added to My Favourites ♥'),
                onRemove: () => _showToastMsg('Removed from list'),
                onOutfit: () => _showToastMsg('Added to Outfit ✓'),
              ),

              // ⑤ COSMIC FOOTER
              CosmicFooter(
                bottomPadding: MediaQuery.of(context).padding.bottom,
                activeIndex: 2, // Home active for recommendations page
                onTryOn: () => Navigator.of(context).pushNamed(Routes.tryon),
                onWardrobe: () =>
                    Navigator.of(context).pushNamed(Routes.wardrobe),
                onHome: () => Navigator.of(context).pushNamed(Routes.dashboard),
                onFriends: () => _showToastMsg('Friends Space opening…'),
                onProfile: () => _showToastMsg('Profile'),
              ),
            ],
          ),

          // Toast overlay
          if (_showToast && _toastMsg != null)
            Positioned(
              bottom: 90,
              left: 0,
              right: 0,
              child: Center(
                child: _Toast(message: _toastMsg!),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────
class _ProductRecommendation {
  final String title;
  final String imageUrl;
  final String? displayImageUrl;
  final List<String> previewImageUrls;
  final String link;
  final String? price;
  final String? brand;
  final String? size;
  final String? source;
  final String? availability;
  final String? description;

  const _ProductRecommendation({
    required this.title,
    required this.imageUrl,
    required this.link,
    this.displayImageUrl,
    this.previewImageUrls = const [],
    this.price,
    this.brand,
    this.size,
    this.source,
    this.availability,
    this.description,
  });

  bool get isSoldOut {
    final text = availability?.toLowerCase();
    return text != null &&
        (text.contains('sold out') ||
            text.contains('out of stock') ||
            text.contains('unavailable'));
  }
}

String shopNameFromLink(String link) {
  try {
    final uri = Uri.parse(link);
    final host = uri.host.replaceFirst('www.', '');
    if (host.contains('asos')) return 'ASOS';
    if (host.contains('zara')) return 'ZARA';
    if (host.contains('hm') || host.contains('h&m')) return 'H&M';
    if (host.contains('nordstrom')) return 'Nordstrom';
    if (host.contains('mango')) return 'Mango';
    if (host.contains('revolve')) return 'Revolve';
    if (host.contains('boohoo')) return 'Boohoo';
    if (host.contains('urbanoutfitters')) return 'Urban Outfitters';
    if (host.contains('shein')) return 'SHEIN';
    return host.isNotEmpty ? host : 'Shop';
  } catch (_) {
    return 'Shop';
  }
}

// ─────────────────────────────────────────────
// ② SEARCH HEADER
// ─────────────────────────────────────────────
class _ShoppingSearchHeader extends StatelessWidget {
  final TextEditingController queryController;
  final bool isLoading;
  final String selectedRetailer;
  final List<String> retailerOptions;
  final void Function(String) onRetailerChanged;
  final void Function(String) onSearch;
  final VoidCallback onRefresh;
  final VoidCallback onFav;
  final VoidCallback onOutfit;
  final VoidCallback onTryOn;

  const _ShoppingSearchHeader({
    required this.queryController,
    required this.isLoading,
    required this.selectedRetailer,
    required this.retailerOptions,
    required this.onRetailerChanged,
    required this.onSearch,
    required this.onRefresh,
    required this.onFav,
    required this.onOutfit,
    required this.onTryOn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_C.chromeMid, _C.chromeDark],
        ),
        border: Border(bottom: BorderSide(color: Color(0x384096FF), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: queryController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search outfits, styles or shopping ideas…',
                    hintStyle: const TextStyle(color: Color(0x99D2E8FF)),
                    filled: true,
                    fillColor: const Color(0x1AFFFFFF),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: onSearch,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onSearch(queryController.text),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _C.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.search, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRetailer,
                        dropdownColor: _C.chromeMid,
                        iconEnabledColor: Colors.white,
                        isExpanded: true,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                        items: retailerOptions
                            .map(
                              (store) => DropdownMenuItem(
                                value: store,
                                child: Text(store),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            onRetailerChanged(value);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ActionBtn(
                  icon: Icons.refresh, label: 'Reload', onTap: onRefresh),
              const SizedBox(width: 6),
              _ActionBtn(icon: Icons.favorite, label: 'Favorite', onTap: onFav),
              const SizedBox(width: 6),
              _ActionBtn(
                  icon: Icons.checkroom, label: 'Outfit', onTap: onOutfit),
              const SizedBox(width: 6),
              _ActionBtn(
                  icon: Icons.camera_alt, label: 'Try On', onTap: onTryOn),
            ],
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(
                backgroundColor: Color(0x1A6490FF),
                valueColor: AlwaysStoppedAnimation(_C.accent),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: const Color(0x126496FF),
            border: Border.all(color: const Color(0x2E6490FF), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 10, color: const Color(0xBFB4D7FF)),
              const SizedBox(width: 3),
              Flexible(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xBFB4D7FF)),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MetadataChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: const Color(0xFF6070A0)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 9, color: _C.sizeNavy)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NEW TAB PAGE
// ─────────────────────────────────────────────
class _NewTabPage extends StatelessWidget {
  final void Function(String query) onSearch;
  const _NewTabPage({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Container(
      color: const Color(0xFFF0F4FF),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NX Style Search',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: _C.pageBg)),
          const SizedBox(height: 12),
          const Text(
              'Search outfit ideas and styling options tailored to your profile and wardrobe.',
              style: TextStyle(fontSize: 10, color: _C.textLight)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient:
                  const LinearGradient(colors: [_C.sizeNavy, _C.sizeNavyDark]),
              border: Border.all(color: const Color(0x4D6490FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NX Smart Search',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xF2D2E8FF))),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0x146496FF),
                    border: Border.all(color: const Color(0x406490FF)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xCCD2E8FF)),
                          decoration: const InputDecoration(
                            hintText:
                                'Search outfit looks, styles or outfit ideas…',
                            hintStyle: TextStyle(
                                fontSize: 10, color: Color(0x80D2E8FF)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: onSearch,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => onSearch(controller.text),
                        child: const Icon(Icons.search,
                            size: 14, color: Color(0x99A0C8FF)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductDetailPage extends StatefulWidget {
  final _ProductRecommendation product;
  final VoidCallback onSaveToOutfit;

  const _ProductDetailPage(
      {required this.product, required this.onSaveToOutfit});

  @override
  State<_ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<_ProductDetailPage> {
  late final PageController _pageController;
  int _selectedPreviewIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedPreviewIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: _C.headerBg,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.product.previewImageUrls.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 340,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: widget.product.previewImageUrls.length,
                            onPageChanged: (index) =>
                                setState(() => _selectedPreviewIndex = index),
                            itemBuilder: (context, index) {
                              return InteractiveViewer(
                                panEnabled: false,
                                scaleEnabled: true,
                                minScale: 1.0,
                                maxScale: 4.0,
                                child: Image.network(
                                  widget.product.previewImageUrls[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: const Color(0xFFEFEFF4),
                                    child: const Icon(
                                        Icons.broken_image_outlined,
                                        size: 48,
                                        color: _C.textLight),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('View all angles',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _C.textDark)),
                            Text(
                                '${_selectedPreviewIndex + 1}/${widget.product.previewImageUrls.length}',
                                style: const TextStyle(
                                    fontSize: 11, color: _C.textMid)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (widget.product.previewImageUrls.length > 1)
                          SizedBox(
                            height: 86,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.product.previewImageUrls.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final thumbUrl =
                                    widget.product.previewImageUrls[index];
                                return GestureDetector(
                                  onTap: () {
                                    _pageController.animateToPage(
                                      index,
                                      duration:
                                          const Duration(milliseconds: 250),
                                      curve: Curves.easeOut,
                                    );
                                    setState(
                                        () => _selectedPreviewIndex = index);
                                  },
                                  child: Container(
                                    width: 72,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: index == _selectedPreviewIndex
                                            ? _C.accent
                                            : const Color(0xFFE3E7F3),
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        thumbUrl,
                                        fit: BoxFit.cover,
                                        width: 72,
                                        height: 72,
                                        loadingBuilder:
                                            (context, child, progress) {
                                          if (progress == null) return child;
                                          return Container(
                                            color: const Color(0xFFEFEFF4),
                                            child: const Center(
                                              child: SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          color: const Color(0xFFEFEFF4),
                                          child: const Icon(
                                            Icons.broken_image_outlined,
                                            size: 24,
                                            color: _C.textLight,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    )
                  else if (widget.product.displayImageUrl != null)
                    SizedBox(
                      height: 320,
                      child: InteractiveViewer(
                        panEnabled: false,
                        scaleEnabled: true,
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Image.network(
                          widget.product.displayImageUrl!,
                          height: 320,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 320,
                            color: const Color(0xFFEFEFF4),
                            child: const Icon(Icons.broken_image_outlined,
                                size: 48, color: _C.textLight),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 320,
                      color: const Color(0xFFEFEFF4),
                      child: const Center(
                        child: Icon(Icons.shopping_bag_outlined,
                            size: 48, color: _C.textLight),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.product.title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        if (widget.product.description != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8),
                            child: Text(widget.product.description!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: _C.textMid,
                                    height: 1.3)),
                          ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (widget.product.brand != null)
                              _MetadataChip(
                                  label: widget.product.brand!,
                                  icon: Icons.tag),
                            if (widget.product.size != null)
                              _MetadataChip(
                                  label: widget.product.size!,
                                  icon: Icons.straighten),
                            if (widget.product.availability != null)
                              _MetadataChip(
                                  label: widget.product.availability!,
                                  icon: widget.product.isSoldOut
                                      ? Icons.block
                                      : Icons.check_circle_outline),
                            _MetadataChip(
                                label: widget.product.source ??
                                    shopNameFromLink(widget.product.link),
                                icon: Icons.store),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(widget.product.price ?? 'Price unavailable',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _C.sizeNavy)),
                        const SizedBox(height: 14),
                        Text('Official product page',
                            style: const TextStyle(
                                fontSize: 12, color: _C.textLight)),
                        const SizedBox(height: 8),
                        Text(widget.product.link,
                            style: const TextStyle(
                                fontSize: 11, color: _C.textMid)),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: widget.onSaveToOutfit,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: _C.sizeNavy),
                                child: const Text('Save to Outfit'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context)
                                    .pushNamed(Routes.tryon),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: _C.bagGold),
                                child: const Text('Try On'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E7F2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                  'Product details from the original source',
                                  style: TextStyle(
                                      fontSize: 12, color: _C.textLight)),
                              const SizedBox(height: 8),
                              Text(widget.product.link,
                                  style: const TextStyle(
                                      fontSize: 11, color: _C.textMid)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ④ NX ACTION BAR
// ─────────────────────────────────────────────
class _NXActionBar extends StatelessWidget {
  final VoidCallback onFav, onRemove, onOutfit;
  const _NXActionBar(
      {required this.onFav, required this.onRemove, required this.onOutfit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF7081246), Color(0xFC050C32)]),
        border: Border(top: BorderSide(color: Color(0x476490FF), width: 1)),
      ),
      child: Row(
        children: [
          _NXBtn(
              icon: Icons.favorite,
              label: 'Add to\nMy Favourites',
              onTap: onFav),
          const SizedBox(width: 6),
          _NXBtn(
              icon: Icons.delete_outline,
              label: 'Remove\nfrom List',
              onTap: onRemove),
          const SizedBox(width: 6),
          _NXBtn(
              icon: Icons.checkroom, label: 'Add to\nOutfit', onTap: onOutfit),
        ],
      ),
    );
  }
}

class _NXBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NXBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xE60F2680), Color(0xF2081658)]),
            border: Border.all(color: _C.nxBtnBorder, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xCCDCEBFF), size: 16),
              const SizedBox(height: 3),
              Text(label,
                  style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Color(0xE0C8E1FF)),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SIZE MODAL
// ─────────────────────────────────────────────
class _SizeModal extends StatefulWidget {
  final List<String> sizes, soldOut;
  final String? selected;
  final void Function(String) onChanged;
  final VoidCallback onConfirm, onClose;

  const _SizeModal({
    required this.sizes,
    required this.soldOut,
    required this.selected,
    required this.onChanged,
    required this.onConfirm,
    required this.onClose,
  });

  @override
  State<_SizeModal> createState() => _SizeModalState();
}

class _SizeModalState extends State<_SizeModal> {
  String? _sel;

  @override
  void initState() {
    super.initState();
    _sel = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_C.chromeMid, _C.sizeNavyDark]),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        border: Border(top: BorderSide(color: Color(0x4D6490FF))),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select a Size',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xF2D2E8FF))),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x1AFFFFFF),
                        border: Border.all(color: const Color(0x406490FF))),
                    child: const Center(
                        child: Text('×',
                            style: TextStyle(
                                color: Color(0xCCB4D7FF),
                                fontSize: 16,
                                height: 1))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text('Neck / Sleeve — Select your fit',
                    style: TextStyle(fontSize: 8.5, color: Color(0x998CC8FF)))),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
              childAspectRatio: 1.6,
              children: widget.sizes.map((s) {
                final sold = widget.soldOut.contains(s);
                final selected = _sel == s;
                return GestureDetector(
                  onTap: sold
                      ? null
                      : () => setState(() {
                            _sel = s;
                            widget.onChanged(s);
                          }),
                  child: Opacity(
                    opacity: sold ? .3 : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: selected
                            ? const Color(0xD96A58C8)
                            : const Color(0x146496FF),
                        border: Border.all(
                            color: selected
                                ? const Color(0x8C64AAFF)
                                : const Color(0x386490FF)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s,
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? const Color(0xFADCEBFF)
                                      : const Color(0xCCB9D7FF),
                                  decoration: sold
                                      ? TextDecoration.lineThrough
                                      : null)),
                          if (sold)
                            const Text('Sold out',
                                style: TextStyle(
                                    fontSize: 6, color: Color(0x99B9D7FF))),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: widget.onConfirm,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                      colors: [Color(0xE62A58C8), Color(0xF21A3A9A)]),
                  border: Border.all(color: const Color(0x666490FF)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x4D03082A), blurRadius: 10)
                  ],
                ),
                child: const Text('Confirm Size',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xF2D2E8FF))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TOAST
// ─────────────────────────────────────────────
class _Toast extends StatelessWidget {
  final String message;
  const _Toast({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_C.sizeNavy, _C.sizeNavyDark]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x616490FF)),
        boxShadow: const [BoxShadow(color: Color(0x6603082A), blurRadius: 12)],
      ),
      child: Text(message,
          style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Color(0xF2D2E8FF)),
          maxLines: 1),
    );
  }
}

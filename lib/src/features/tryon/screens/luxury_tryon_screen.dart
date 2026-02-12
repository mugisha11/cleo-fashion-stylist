/// Luxury Virtual Try-On Screen
/// Full-screen user image; mobile: small garments + actions floating on the right.
/// UI/UX only - backend logic unchanged (same as ProductionTryOnScreen).
library;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import '../../../core/models/production_vton_state.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/providers/production_vton_provider.dart';
import '../../../core/providers/user_image_provider.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/providers/social_provider.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../widgets/production_wardrobe_picker.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../../../routes.dart';
import '../../style_feed/providers/style_feed_provider.dart';
import '../../style_feed/screens/post_look_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/save_tryon_result_io.dart' if (dart.library.io) '../utils/save_tryon_result_stub.dart' as save_tryon_result;

class LuxuryTryOnScreen extends ConsumerStatefulWidget {
  const LuxuryTryOnScreen({super.key});

  @override
  ConsumerState<LuxuryTryOnScreen> createState() => _LuxuryTryOnScreenState();
}

class _LuxuryTryOnScreenState extends ConsumerState<LuxuryTryOnScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _userImageBytes;
  String? _userImageUrl;
  final List<WardrobeItemModel> _selectedGarments = [];
  bool _showBeforeAfter = false;
  int _beforeAfterMode = 0;

  late AnimationController _resultFadeController;
  late AnimationController _loadingTextController;
  late AnimationController _pageEnterController;

  final List<String> _loadingTexts = [
    'Styling your look...',
    'Almost ready...',
    'Perfecting details...',
  ];
  int _currentLoadingTextIndex = 0;
  bool _preferenceImageLoaded = false;

  @override
  void initState() {
    super.initState();
    _resultFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadingTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pageEnterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pageEnterController.forward();
    // Load preference image first (Settings → Fashion Preferences); fallback to asset only if none set.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreferenceImageFirst());
    _loadingTextController.addListener(() {
      if (_loadingTextController.value >= 1.0) {
        setState(() {
          _currentLoadingTextIndex =
              (_currentLoadingTextIndex + 1) % _loadingTexts.length;
        });
        _loadingTextController.reset();
      }
    });
  }

  @override
  void dispose() {
    _resultFadeController.dispose();
    _loadingTextController.dispose();
    _pageEnterController.dispose();
    super.dispose();
  }

  /// Load preference image first (Settings → Fashion Preferences). Fallback to asset only if none set.
  Future<void> _loadPreferenceImageFirst() async {
    if (_preferenceImageLoaded) return;
    _preferenceImageLoaded = true;
    try {
      final bytes = await ref.read(userImageBytesProvider.future);
      if (mounted) {
        if (bytes != null && bytes.isNotEmpty) {
          setState(() {
            _userImageBytes = bytes;
            _userImageUrl = null;
          });
          return;
        }
        // No preference image: use asset as fallback so the page isn't empty
        final byteData = await rootBundle.load('assets/icons/dftryon.jpg');
        if (mounted) {
          setState(() {
            _userImageBytes = byteData.buffer.asUint8List();
            _userImageUrl = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Try-on: load preference/fallback image: $e');
      if (mounted) {
        try {
          final byteData = await rootBundle.load('assets/icons/dftryon.jpg');
          if (mounted) {
            setState(() {
              _userImageBytes = byteData.buffer.asUint8List();
              _userImageUrl = null;
            });
          }
        } catch (_) {}
      }
    }
  }

  /// Kept for any late refresh of preference image (e.g. after returning from Settings).
  void _loadPreferenceImage(WidgetRef ref) {
    if (_preferenceImageLoaded) return;
    _loadPreferenceImageFirst();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vtonState = ref.watch(productionVTONProvider);
    final screenSize = MediaQuery.of(context).size;
    final isWide = screenSize.width >= 768;

    _loadPreferenceImage(ref);

    ref.listen<ProductionVTONState>(productionVTONProvider, (prev, next) {
      if (next.stage == ProductionVTONStage.success &&
          next.resultImageUrl != null &&
          (prev?.stage != ProductionVTONStage.success)) {
        final uid = ref.read(authStateProvider).valueOrNull?.uid;
        if (uid != null) {
          ref.read(socialServiceProvider).createTryOnCompletedNotification(
                userId: uid,
                messagePreview: 'Your try-on is ready!',
              );
        }
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _pageEnterController,
          child: isWide ? _buildWideLayout(context, vtonState, colorScheme)
              : _buildMobileLayout(context, vtonState, colorScheme),
        ),
      ),
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    ProductionVTONState state,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildFullScreenPreview(context, state, colorScheme),
        ),
        SizedBox(
          width: 320,
          child: _buildRightPanel(context, state, colorScheme),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    ProductionVTONState state,
    ColorScheme colorScheme,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildFullScreenPreview(context, state, colorScheme),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildMinimalTopBar(context, colorScheme),
        ),
        Positioned(
          right: 0,
          top: 56,
          bottom: 0,
          child: SizedBox(
            width: 72,
            child: _buildMobileFloatingRightStrip(context, state, colorScheme),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalTopBar(BuildContext context, ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface),
            ),
            const Spacer(),
            if (_userImageBytes != null || _userImageUrl != null)
              IconButton(
                onPressed: _pickPhoto,
                icon: Icon(Icons.camera_alt_outlined, color: colorScheme.onSurface),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenPreview(
    BuildContext context,
    ProductionVTONState state,
    ColorScheme colorScheme,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildPreviewContent(context, colorScheme, state),
        if (state.isProcessing) _buildMinimalLoadingOverlay(context, colorScheme),
      ],
    );
  }

  Widget _buildPreviewContent(
    BuildContext context,
    ColorScheme colorScheme,
    ProductionVTONState state,
  ) {
    if (_userImageBytes == null && _userImageUrl == null) {
      return _buildDefaultPlaceholder(context, colorScheme);
    }
    if (state.isSuccess && state.resultImageUrl != null) {
      return _buildResultDisplay(context, colorScheme, state.resultImageUrl!);
    }
    if (state.isFailed || state.isRejected) {
      return _buildErrorDisplay(context, colorScheme, state);
    }
    return _buildOriginalDisplay(context, colorScheme, state);
  }

  Widget _buildDefaultPlaceholder(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 64,
            color: colorScheme.primary.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Upload your photo',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalDisplay(
    BuildContext context,
    ColorScheme colorScheme,
    ProductionVTONState state,
  ) {
    return _userImageBytes != null
        ? Image.memory(
            _userImageBytes!,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          )
        : _userImageUrl != null
            ? CachedNetworkImage(
                imageUrl: _userImageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) => Icon(Icons.error_outline, color: colorScheme.error, size: 48),
              )
            : const SizedBox();
  }

  Widget _buildResultDisplay(
    BuildContext context,
    ColorScheme colorScheme,
    String imageUrl,
  ) {
    Widget imageWidget;
    if (imageUrl.startsWith('data:image') && imageUrl.contains(',')) {
      try {
        final bytes = base64Decode(imageUrl.split(',').last);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        );
      } catch (_) {
        imageWidget = Icon(Icons.error_outline, size: 64, color: colorScheme.error);
      }
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
      );
    }

    if (_showBeforeAfter && _beforeAfterMode == 2) {
      return Row(
        children: [
          Expanded(
            child: _userImageBytes != null
                ? Image.memory(_userImageBytes!, fit: BoxFit.cover, filterQuality: FilterQuality.high)
                : _userImageUrl != null
                    ? CachedNetworkImage(imageUrl: _userImageUrl!, fit: BoxFit.cover, filterQuality: FilterQuality.high)
                    : const SizedBox(),
          ),
          Container(width: 2, color: colorScheme.outline.withOpacity(0.2)),
          Expanded(child: imageWidget),
        ],
      );
    }

    return _beforeAfterMode == 0 && _showBeforeAfter
        ? (_userImageBytes != null
            ? Image.memory(_userImageBytes!, fit: BoxFit.cover)
            : _userImageUrl != null
                ? CachedNetworkImage(imageUrl: _userImageUrl!, fit: BoxFit.cover)
                : const SizedBox())
        : imageWidget;
  }

  Widget _buildErrorDisplay(
    BuildContext context,
    ColorScheme colorScheme,
    ProductionVTONState state,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            state.error ?? 'Try-on failed',
            style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalLoadingOverlay(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Container(
      color: Colors.black26,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _loadingTexts[_currentLoadingTextIndex],
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _garmentImageUrl(WardrobeItemModel item) =>
      item.processedImageUrl ?? item.imageUrl;

  Widget _buildMobileFloatingRightStrip(
    BuildContext context,
    ProductionVTONState state,
    ColorScheme colorScheme,
  ) {
    final accent = Theme.of(context).brightness == Brightness.dark
        ? DesignTokens.darkAccent
        : DesignTokens.lightAccent;
    const double garmentSize = 56.0;
    const int visibleGarmentCount = 3;
    const double itemExtent = garmentSize + 8;
    final wardrobeAsync = ref.watch(wardrobeItemsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SafeArea(
        left: false,
        top: false,
        bottom: true,
        right: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: visibleGarmentCount * itemExtent,
                child: wardrobeAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            'Add pieces to your closet',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = _selectedGarments.any((g) => g.id == item.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                final i = _selectedGarments.indexWhere((g) => g.id == item.id);
                                if (i >= 0) _selectedGarments.removeAt(i);
                                else _selectedGarments.add(item);
                              });
                            },
                            child: Container(
                              width: garmentSize,
                              height: garmentSize,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? accent : colorScheme.outline.withOpacity(0.4),
                                  width: isSelected ? 2.5 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _garmentImageUrl(item).isNotEmpty && (_garmentImageUrl(item).startsWith('http://') || _garmentImageUrl(item).startsWith('https://'))
                                  ? CachedNetworkImage(
                                      imageUrl: _garmentImageUrl(item),
                                      fit: BoxFit.contain,
                                      errorWidget: (_, __, ___) => Icon(Icons.checkroom, color: colorScheme.onSurface.withOpacity(0.5), size: 26),
                                    )
                                  : Icon(Icons.checkroom, color: colorScheme.onSurface.withOpacity(0.5), size: 26),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (_, __) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        'Loading your closet',
                        style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.8)),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ),
                ),
              ),
              _buildMobileFloatingActions(context, state, colorScheme, accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFloatingActions(
    BuildContext context,
    ProductionVTONState state,
    ColorScheme colorScheme,
    Color accent,
  ) {
    final hasResult = state.isSuccess && state.resultImageUrl != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _mobileActionIcon(
          context,
          icon: Icons.camera_alt_outlined,
          onTap: _pickPhoto,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        _mobileActionIcon(
          context,
          icon: hasResult ? Icons.download_outlined : Icons.checkroom_outlined,
          onTap: hasResult ? () => _saveResult(state.resultImageUrl!) : (_selectedGarments.isNotEmpty ? _executeTryOn : null),
          colorScheme: colorScheme,
          accent: accent,
        ),
        if (hasResult) ...[
          const SizedBox(height: 12),
          _mobileActionIcon(
            context,
            icon: Icons.grid_view_rounded,
            onTap: () => _openPostLook(state.resultImageUrl!),
            colorScheme: colorScheme,
            accent: accent,
          ),
        ],
        const SizedBox(height: 12),
        _mobileActionIcon(
          context,
          icon: Icons.refresh_outlined,
          onTap: () {
            ref.read(productionVTONProvider.notifier).reset();
            setState(() {
              _selectedGarments.clear();
              _showBeforeAfter = false;
              _beforeAfterMode = 0;
            });
          },
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _mobileActionIcon(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onTap,
    required ColorScheme colorScheme,
    Color? accent,
  }) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 24,
            color: enabled ? (accent ?? colorScheme.onSurface) : colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildRightPanel(
    BuildContext context,
    ProductionVTONState state,
    ColorScheme colorScheme,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isMobile) _buildMinimalTopBar(context, colorScheme),
          if (state.isSuccess && state.resultImageUrl != null)
            _buildBeforeAfterChips(context, colorScheme),
          const SizedBox(height: 12),
          Text(
            'Pick pieces',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 3 * (110 + 12),
            child: ProductionWardrobePicker(
              selectedGarments: _selectedGarments,
              onGarmentSelected: (garment) {
                setState(() {
                  final i = _selectedGarments.indexWhere((g) => g.id == garment.id);
                  if (i >= 0) _selectedGarments.removeAt(i);
                  else _selectedGarments.add(garment);
                });
                HapticFeedback.selectionClick();
              },
              onTryOn: null,
              colorScheme: colorScheme,
              isVertical: true,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButtons(context, state, colorScheme),
        ],
      ),
    );
  }

  Widget _buildBeforeAfterChips(BuildContext context, ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      children: [
        _chip('Before', 0),
        _chip('Split', 2),
        _chip('After', 1),
      ],
    );
  }

  Widget _chip(String label, int mode) {
    final isActive = _beforeAfterMode == mode;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _beforeAfterMode = mode;
          _showBeforeAfter = mode != 0;
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive
                ? DesignTokens.lightAccent
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ProductionVTONState state,
    ColorScheme colorScheme,
  ) {
    final hasResult = state.isSuccess && state.resultImageUrl != null;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? DesignTokens.darkAccent
        : DesignTokens.lightAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                label: const Text('New photo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: hasResult
                    ? () => _saveResult(state.resultImageUrl!)
                    : _selectedGarments.isNotEmpty
                        ? _executeTryOn
                        : null,
                icon: Icon(
                  hasResult ? Icons.download_outlined : Icons.checkroom_outlined,
                  size: 20,
                ),
                label: Text(hasResult ? 'Save' : 'Try it on'),
                style: FilledButton.styleFrom(backgroundColor: accent),
              ),
            ),
          ],
        ),
        if (hasResult) ...[
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _openPostLook(state.resultImageUrl!),
            icon: const Icon(Icons.grid_view_rounded, size: 20),
            label: const Text('Share look'),
            style: FilledButton.styleFrom(backgroundColor: accent),
          ),
        ],
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            ref.read(productionVTONProvider.notifier).reset();
            setState(() {
              _selectedGarments.clear();
              _showBeforeAfter = false;
              _beforeAfterMode = 0;
            });
          },
          icon: const Icon(Icons.refresh_outlined, size: 20),
          label: const Text('Start over'),
        ),
      ],
    );
  }

  Future<void> _pickPhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _userImageBytes = bytes;
          _userImageUrl = null;
        });
        await _uploadPhoto(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _uploadPhoto(Uint8List bytes) async {
    try {
      final supabase = Supabase.instance.client;
      final storageService = SupabaseStorageService(supabase);
      final userId = supabase.auth.currentUser?.id ?? 'temp';
      final url = await storageService.uploadFile(
        bucket: 'uploads',
        path: 'tryon/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg',
        file: bytes,
        contentType: 'image/jpeg',
      );
      setState(() => _userImageUrl = url);
    } catch (e) {
      debugPrint('Failed to upload photo: $e');
    }
  }

  Future<void> _executeTryOn() async {
    if (_userImageUrl == null && _userImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a photo first')),
      );
      return;
    }
    if (_selectedGarments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one garment')),
      );
      return;
    }

    String? userImageBase64;
    if (_userImageBytes != null) {
      userImageBase64 = base64Encode(_userImageBytes!);
    }
    if (_userImageUrl == null && _userImageBytes != null) {
      _uploadPhoto(_userImageBytes!);
    }

    final garmentUrls = _selectedGarments
        .map((g) => g.processedImageUrl ?? g.imageUrl)
        .where((u) => u.isNotEmpty && (u.startsWith('http://') || u.startsWith('https://')))
        .toList();

    if (garmentUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selected garments need valid image URLs. Add wardrobe items with accessible links.',
          ),
        ),
      );
      return;
    }

    List<String>? garmentBase64s;
    try {
      final firstUrl = garmentUrls.first;
      final response = await http.get(Uri.parse(firstUrl)).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Garment image load timed out'),
      );
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        garmentBase64s = [base64Encode(response.bodyBytes)];
      }
    } catch (e) {
      debugPrint('Garment image fetch failed (will send URL): $e');
    }

    final notifier = ref.read(productionVTONProvider.notifier);
    await notifier.executeTryOn(
      userImageUrl: _userImageUrl ?? '',
      garmentImageUrls: garmentUrls,
      userImageBase64: userImageBase64,
      garmentImageBase64s: garmentBase64s,
    );

    final newState = ref.read(productionVTONProvider);
    if (newState.isSuccess) {
      _resultFadeController.forward();
    }
  }

  void _openPostLook(String resultImageUrl) {
    ref.read(lastTryOnImageForPostProvider.notifier).state = resultImageUrl;
    Uint8List? bytes;
    if (resultImageUrl.startsWith('data:image') && resultImageUrl.contains(',')) {
      try {
        bytes = base64Decode(resultImageUrl.split(',').last);
      } catch (_) {}
    }
    if (bytes != null) {
      ref.read(lastTryOnImageBytesProvider.notifier).state = bytes;
    }
    PostLookScreen.navigate(
      context,
      imagePath: resultImageUrl,
      imageBytes: bytes,
      suggestedCaption: 'My try-on look',
    );
  }

  Future<void> _saveResult(String imageUrl) async {
    try {
      Uint8List? imageBytes;
      if (imageUrl.startsWith('data:image') && imageUrl.contains(',')) {
        try {
          imageBytes = base64Decode(imageUrl.split(',').last);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to decode image: $e')),
            );
          }
          return;
        }
      } else {
        try {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            imageBytes = response.bodyBytes;
          } else {
            throw Exception('Failed to fetch image: ${response.statusCode}');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to download image: $e')),
            );
          }
          return;
        }
      }

      if (imageBytes == null || imageBytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image data to save')),
          );
        }
        return;
      }

      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      bool savedToOutfits = false;
      if (uid != null) {
        final service = ref.read(generatedOutfitsServiceProvider);
        await service.saveGeneratedOutfit(
          userId: uid,
          imageBytes: imageBytes,
          caption: 'My try-on look',
        );
        ref.invalidate(generatedOutfitsProvider);
        savedToOutfits = true;
      }

      final devicePath = await save_tryon_result.saveTryOnResultToDevice(imageBytes);
      final savedToDevice = devicePath != null && devicePath.isNotEmpty;

      if (mounted) {
        String msg = savedToOutfits
            ? 'Saved to My Outfits'
            : (savedToDevice ? 'Saved to device' : 'Sign in to save to My Outfits.');
        if (savedToOutfits && savedToDevice) msg = 'Saved to My Outfits and device';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        final friendly = msg.contains('Bucket not found') || msg.contains('does not exist') || msg.contains('Permission denied')
            ? 'Storage not set up. Create the "generated_outfits" bucket in Supabase (see docs).'
            : 'Failed to save: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendly), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  ThemeData get theme => Theme.of(context);
}

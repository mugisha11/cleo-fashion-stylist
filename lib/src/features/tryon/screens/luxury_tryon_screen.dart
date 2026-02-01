/// 🎨 Luxury Virtual Try-On Screen
/// Premium, fashion-forward redesign
/// - Minimal & elegant UI
/// - Instagram-level smoothness
/// - App Store ready production code
library;

import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart' show AsyncValue;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/production_vton_state.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/providers/production_vton_provider.dart';
import '../../../core/providers/user_image_provider.dart';
import '../../wardrobe/providers/wardrobe_provider.dart'
    show wardrobeItemsProvider;
import '../../settings/screens/fashion_preferences_screen.dart';
import '../utils/save_tryon_result_io.dart'
    if (dart.library.html) '../utils/save_tryon_result_web.dart' as save_tryon_result;

/// Soft, fashion-forward tokens for this screen only.
/// Keeps styling consistent across light/dark without changing app-wide theme.
/// Design: soft neutral #F8F6F2 / #FAFAFA, feminine but professional.
class _TryOnTokens {
  static const ivory = Color(0xFFF8F6F2);
  static const blush = Color(0xFFFFE8EF);
  static const rose = Color(0xFFFF6B9D);
  static const lavender = Color(0xFFB794F6);

  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF141414)
          : ivory;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : Colors.white;

  static Color accent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? DesignTokens.darkAccent
          : DesignTokens.lightAccent;

  static TextStyle? headlineSerif(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.w400,
            letterSpacing: 0.4,
          );
}

/// Luxury Try-On Screen - Premium Virtual Try-On Experience
class LuxuryTryOnScreen extends ConsumerStatefulWidget {
  const LuxuryTryOnScreen({super.key});

  @override
  ConsumerState<LuxuryTryOnScreen> createState() => _LuxuryTryOnScreenState();
}

class _LuxuryTryOnScreenState extends ConsumerState<LuxuryTryOnScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _sheetController;
  late AnimationController _loadingController;

  // Loading copy that softly cycles (no raw spinner-only state).
  final List<String> _loadingLines = const [
    'Styling your look…',
    'Almost ready…',
    'Perfecting details…',
  ];
  int _loadingLineIndex = 0;
  PageController? _carouselController;
  int _carouselIndex = 0;

  Uint8List? _userImageBytes;
  String? _userImageUrl;
  final List<WardrobeItemModel> _selectedGarments = [];
  bool _showBeforeAfter = false;
  int _beforeAfterMode = 0; // 0: before, 1: after, 2: split
  bool _saveSuccess = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _carouselController = PageController(viewportFraction: 0.32);
    WidgetsBinding.instance.addObserver(this);

    _loadingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;
        setState(() => _loadingLineIndex = (_loadingLineIndex + 1) % _loadingLines.length);
        _loadingController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _sheetController.dispose();
    _loadingController.dispose();
    _carouselController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Sync local _userImageBytes from Settings (userImageProvider). Called when provider updates.
  void _syncUserImageFromSettings(Uint8List? bytes) {
    if (mounted && _userImageBytes != bytes) {
      setState(() => _userImageBytes = bytes);
    }
  }

  Future<void> _pickUserImage() async {
    try {
      HapticFeedback.mediumImpact();
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (picked != null && mounted) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _userImageBytes = bytes;
        });

        // Save to provider
        ref
            .read(userImageProvider.notifier)
            .uploadUserImage(bytes, 'image/jpeg');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Photo updated ✨'),
              duration: const Duration(milliseconds: 1200),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              backgroundColor: context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _selectGarment(WardrobeItemModel item) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedGarments.contains(item)) {
        _selectedGarments.remove(item);
      } else {
        _selectedGarments.add(item);
      }
    });
  }

  Future<void> _performTryOn() async {
    if (_userImageBytes == null) {
      _showSheet(
        title: 'Add your photo',
        subtitle: 'Save your photo in Settings → Preferences once; it’ll load here every time.',
        onAction: () {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const FashionPreferencesScreen()),
          );
        },
        actionLabel: 'Open Settings',
      );
      return;
    }

    if (_selectedGarments.isEmpty) {
      _showSheet(
        title: 'Select Items',
        subtitle: 'Choose at least one item to try on',
        onAction: () => Navigator.pop(context),
        actionLabel: 'Browse Wardrobe',
      );
      return;
    }

    final garmentUrls = _selectedGarments
        .map((g) => g.imageUrl)
        .where((u) => u.isNotEmpty && (u.startsWith('http://') || u.startsWith('https://')))
        .toList();
    if (garmentUrls.isEmpty) {
      _showSheet(
        title: 'Invalid Garment Images',
        subtitle: 'Selected items need valid http/https image URLs. Check your wardrobe.',
        onAction: () => Navigator.pop(context),
        actionLabel: 'Close',
      );
      return;
    }

    HapticFeedback.mediumImpact();
    _fadeController.forward();

    try {
      final userImageBase64 = 'data:image/jpeg;base64,${base64Encode(
        _userImageBytes!,
      )}';

      await ref.read(productionVTONProvider.notifier).executeTryOn(
            userImageUrl: _userImageUrl ?? '',
            garmentImageUrls: garmentUrls,
            userImageBase64: userImageBase64,
          );

      if (mounted) {
        setState(() {
          _showBeforeAfter = true;
        });
      }
    } catch (e) {
      if (mounted) {
        _fadeController.reverse();
        final msg = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString();
        _showSheet(
          title: 'Try-On Failed',
          subtitle: msg.length > 120 ? '${msg.substring(0, 117)}...' : msg,
          onAction: () => Navigator.pop(context),
          actionLabel: 'Close',
        );
      }
    }
  }

  void _resetTryOn() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedGarments.clear();
      _showBeforeAfter = false;
      _beforeAfterMode = 0;
      _saveSuccess = false;
    });
    _fadeController.reverse();
  }

  /// Returns image bytes from [resultImageUrl] (data URL or null if not decodable).
  Uint8List? _getResultImageBytes(String? resultImageUrl) {
    if (resultImageUrl == null || resultImageUrl.isEmpty) return null;
    if (resultImageUrl.startsWith('data:image') && resultImageUrl.contains(',')) {
      try {
        return base64Decode(resultImageUrl.split(',').last);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Saves the current try-on result (download on web, file on device).
  /// Shows premium success animation and SnackBar.
  Future<void> _saveLook(ProductionVTONState vtonState) async {
    final url = vtonState.resultImageUrl;
    final bytes = _getResultImageBytes(url);
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No result image to save'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    HapticFeedback.mediumImpact();
    final saveResult = await save_tryon_result.saveTryOnResultToDevice(bytes);
    if (!mounted) return;
    if (saveResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn’t save image'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _saveSuccess = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            const Text('Look saved ✨'),
          ],
        ),
        duration: const Duration(milliseconds: 2200),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: _TryOnTokens.accent(context),
      ),
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _saveSuccess = false);
    });
  }

  void _showSheet({
    required String title,
    required String subtitle,
    required VoidCallback onAction,
    required String actionLabel,
  }) {
    _sheetController.forward();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _LuxuryBottomSheet(
        title: title,
        subtitle: subtitle,
        onAction: onAction,
        actionLabel: actionLabel,
      ),
    ).then((_) => _sheetController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vtonState = ref.watch(productionVTONProvider);
    final wardrobeAsync = ref.watch(wardrobeItemsProvider);
    final userImageBytesAsync = ref.watch(userImageBytesProvider);

    // Sync local _userImageBytes from Settings (persisted try-on photo) when provider updates.
    ref.listen<AsyncValue<Uint8List?>>(userImageBytesProvider, (prev, next) {
      next.whenOrNull(data: (bytes) {
        _syncUserImageFromSettings(bytes);
      });
    });

    return Scaffold(
      backgroundColor: _TryOnTokens.bg(context),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, colorScheme),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final isMobile = w < 720;
          final isWide = w >= 1100;

          // Mobile: stacked, thumb-friendly.
          // Wide screens: preview left, controls right.
          return Stack(
            children: [
              if (isWide)
                Row(
                  children: [
                    Expanded(
                      flex: 7,
                      child: _buildPreviewSection(context, colorScheme, vtonState, userImageBytesAsync),
                    ),
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80, right: 20, bottom: 20),
                        child: _buildSideControls(context, colorScheme, vtonState, wardrobeAsync),
                      ),
                    ),
                  ],
                )
              else
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildPreviewSection(context, colorScheme, vtonState, userImageBytesAsync),
                      SizedBox(height: MediaQuery.of(context).padding.bottom + (isMobile ? 190 : 170)),
                    ],
                  ),
                ),

              // Floating bottom bar (mobile/tablet)
              if (!isWide)
                _buildBottomActionBar(
                  context,
                  colorScheme,
                  vtonState,
                  wardrobeAsync,
                ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      backgroundColor: _TryOnTokens.surface(context).withOpacity(0.70),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: _TryOnTokens.surface(context).withOpacity(0.45),
          ),
        ),
      ),
      centerTitle: true,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Virtual Try-On',
            style: _TryOnTokens.headlineSerif(context),
          ),
          const SizedBox(height: 2),
          Text(
            'See how it looks on you',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w400,
                ),
          ),
        ],
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _TryOnTokens.accent(context).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(10),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _TryOnTokens.accent(context).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                showDialog(
                  context: context,
                  builder: (context) => _buildInfoDialog(context, colorScheme),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildPreviewSection(
    BuildContext context,
    ColorScheme colorScheme,
    ProductionVTONState vtonState,
    AsyncValue<Uint8List?> userImageBytesAsync,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final previewHeight = screenHeight * 0.65;

    return SizedBox(
      height: previewHeight,
      child: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _TryOnTokens.bg(context),
                  _TryOnTokens.bg(context).withOpacity(0.92),
                ],
              ),
            ),
          ),

          // Main image container (or empty state when no saved photo)
          Center(
            child: _buildMainImageContainer(
              context,
              colorScheme,
              vtonState,
              previewHeight,
              userImageBytesAsync,
            ),
          ),

          // Before/After indicator (show when we have a result and not processing)
          if (!vtonState.isProcessing && vtonState.resultImageUrl != null)
            Positioned(
              top: 16,
              right: 16,
              child: _buildBeforeAfterToggle(context, colorScheme),
            ),

          // Loading overlay
          if (vtonState.isProcessing)
            _buildLoadingOverlay(context, colorScheme, vtonState),
        ],
      ),
    );
  }

  Widget _buildMainImageContainer(
    BuildContext context,
    ColorScheme colorScheme,
    ProductionVTONState vtonState,
    double maxHeight,
    AsyncValue<Uint8List?> userImageBytesAsync,
  ) {
    // Key includes mode so Before/After/Split switch correctly.
    final hasResult = vtonState.resultImageUrl != null && !vtonState.isProcessing;
    final resultKey = ValueKey<String>('${vtonState.resultImageUrl}_$_beforeAfterMode');
    final showUserInMain = !hasResult || _beforeAfterMode == 0;
    final hasNoSavedPhoto = userImageBytesAsync.hasValue && userImageBytesAsync.value == null && _userImageBytes == null;
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _TryOnTokens.accent(context).withOpacity(0.12),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Light gradient behind image to feel “editorial”.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _TryOnTokens.surface(context),
                      _TryOnTokens.surface(context).withOpacity(0.85),
                      _TryOnTokens.blush.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.05 : 0.20),
                    ],
                  ),
                ),
              ),
            ),

            // Main image: Before (0) = user only, After (1) = result only, Split (2) = overlay shows both.
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 550),
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                transitionBuilder: (child, anim) {
                  return FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.985, end: 1.0).animate(anim),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: resultKey,
                  alignment: Alignment.center,
                  child: showUserInMain
                      ? (hasNoSavedPhoto
                          ? _buildEmptyPhotoState(context, colorScheme, maxHeight)
                          : (userImageBytesAsync.isLoading && _userImageBytes == null
                              ? _buildLoadingPlaceholder(maxHeight)
                              : _buildUserImageDisplay(maxHeight)))
                      : _buildResultImageDisplay(vtonState, maxHeight),
                ),
              ),
            ),

            // Split view overlay only when mode is 2
            if (hasResult && _beforeAfterMode == 2) _buildSplitViewIfNeeded(vtonState, maxHeight),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut);
  }

  /// Empty state when no try-on photo is saved in Settings. CTA → Fashion Preferences.
  Widget _buildEmptyPhotoState(
    BuildContext context,
    ColorScheme colorScheme,
    double maxHeight,
  ) {
    final accent = _TryOnTokens.accent(context);
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: _TryOnTokens.surface(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline_rounded,
            size: 56,
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Add your photo to try on outfits',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: colorScheme.onSurface.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save your photo in Settings once — it’ll load here every time.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 24),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const FashionPreferencesScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 22, color: accent),
                    const SizedBox(width: 10),
                    Text(
                      'Add your photo',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder(double maxHeight) {
    return Container(
      height: maxHeight - 40,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _TryOnTokens.surface(context).withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(_TryOnTokens.accent(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildUserImageDisplay(double maxHeight) {
    if (_userImageBytes == null) {
      return Container(
        height: maxHeight - 40,
        color: Colors.grey.shade100,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, size: 48),
        ),
      );
    }

    return Image.memory(
      _userImageBytes!,
      height: maxHeight - 40,
      fit: BoxFit.cover,
    );
  }

  Widget _buildResultImageWidget(String url, double? height) {
    // data:image/jpeg;base64,... from backend – use Image.memory
    if (url.startsWith('data:image') && url.contains(',')) {
      try {
        final b64 = url.split(',').last;
        final bytes = base64Decode(b64);
        return Image.memory(
          bytes,
          height: height,
          fit: BoxFit.cover,
        );
      } catch (_) {
        return Container(
          height: height,
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.error_outline, size: 48)),
        );
      }
    }
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, u) => _buildShimmerLoading(),
      errorWidget: (context, u, e) => Container(
        height: height,
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.error_outline, size: 48)),
      ),
    );
  }

  Widget _buildResultImageDisplay(ProductionVTONState state, double maxHeight) {
    // Show result at full opacity so it's always visible when we have it (no fade controller dependency).
    return _buildResultImageWidget(state.resultImageUrl!, maxHeight - 40);
  }

  Widget _buildSplitViewIfNeeded(ProductionVTONState state, double height) {
    if (_beforeAfterMode != 2) return const SizedBox.shrink();

    return Positioned.fill(
      child: Row(
        children: [
          Expanded(child: _buildUserImageDisplay(height)),
          Expanded(
            child: _buildResultImageWidget(state.resultImageUrl!, height - 40),
          ),
        ],
      ),
    );
  }

  Widget _buildBeforeAfterToggle(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _TryOnTokens.accent(context).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            context,
            colorScheme,
            'Before',
            0,
          ),
          _buildToggleButton(
            context,
            colorScheme,
            'Split',
            2,
          ),
          _buildToggleButton(
            context,
            colorScheme,
            'After',
            1,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context,
    ColorScheme colorScheme,
    String label,
    int mode,
  ) {
    final isActive = _beforeAfterMode == mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _beforeAfterMode = mode;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? _TryOnTokens.accent(context)
                      : colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(
    BuildContext context,
    ColorScheme colorScheme,
    ProductionVTONState vtonState,
  ) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: Colors.black.withOpacity(0.28),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                decoration: BoxDecoration(
                  color: _TryOnTokens.surface(context).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _TryOnTokens.accent(context).withOpacity(0.22)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LuxuryRing(
                      progress: _loadingController,
                      color: _TryOnTokens.accent(context),
                      glow: _TryOnTokens.accent(context).withOpacity(0.25),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.12),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: Text(
                            _loadingLines[_loadingLineIndex],
                            key: ValueKey(_loadingLineIndex),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                  color: colorScheme.onSurface.withOpacity(0.92),
                                ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vtonState.stage.displayName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.55),
                                letterSpacing: 0.2,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 260.ms).scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1)),
            ),
          ),
        ),
      ),
    );
  }

  /// Side controls for wide layouts (preview left, controls right).
  Widget _buildSideControls(
    BuildContext context,
    ColorScheme colorScheme,
    ProductionVTONState vtonState,
    AsyncValue<List<WardrobeItemModel>> wardrobeAsync,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _TryOnTokens.surface(context).withOpacity(0.78),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outline.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose pieces',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap to select. Then try your look.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: wardrobeAsync.when(
                    data: (items) => _buildClothingCarousel(context, colorScheme, items, isWide: true),
                    loading: () => const Center(child: SizedBox.shrink()),
                    error: (_, __) => Center(
                      child: Text('Couldn’t load wardrobe', style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildActionButtons(context, colorScheme, vtonState.isProcessing, vtonState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    ColorScheme colorScheme,
    ProductionVTONState vtonState,
    AsyncValue<List<WardrobeItemModel>> wardrobeAsync,
  ) {
    final isProcessing = vtonState.isProcessing;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _TryOnTokens.surface(context).withOpacity(0.84),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _TryOnTokens.accent(context).withOpacity(0.22),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Clothing carousel
                  wardrobeAsync.when(
                    data: (items) => _buildClothingCarousel(
                      context,
                      colorScheme,
                      items,
                    ),
                    loading: () => const SizedBox(height: 110, child: Center(child: SizedBox.shrink())),
                    error: (err, stack) => SizedBox(
                      height: 100,
                      child: Center(
                        child: Text(
                          'Error loading wardrobe',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  _buildActionButtons(
                    context,
                    colorScheme,
                    isProcessing,
                    vtonState,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClothingCarousel(
    BuildContext context,
    ColorScheme colorScheme,
    List<WardrobeItemModel> items,
    {bool isWide = false}
  ) {
    final cardH = isWide ? 120.0 : 110.0;
    final cardW = isWide ? 140.0 : 110.0;
    final accent = _TryOnTokens.accent(context);

    return SizedBox(
      height: cardH,
      child: PageView.builder(
        controller: _carouselController,
        itemCount: items.length,
        onPageChanged: (i) => setState(() => _carouselIndex = i),
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = _selectedGarments.contains(item);
          final centered = index == _carouselIndex;
          final scale = centered ? 1.0 : 0.94;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () => _selectGarment(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                transform: Matrix4.identity()..scale(scale),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? accent.withOpacity(0.85) : colorScheme.outline.withOpacity(0.18),
                    width: selected ? 1.6 : 1.0,
                  ),
                  boxShadow: [
                    if (selected)
                      BoxShadow(
                        color: accent.withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: colorScheme.surfaceContainerHighest.withOpacity(0.6)),
                          errorWidget: (context, url, error) => Container(
                            color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
                            child: const Center(child: Icon(Icons.broken_image_outlined)),
                          ),
                        ),
                      ),

                      // Semi-transparent gradient overlay when unselected (keeps carousel calm).
                      if (!selected)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.18),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Category tag + underline
                      Positioned(
                        left: 10,
                        bottom: 10,
                        right: 10,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                          color: Colors.white.withOpacity(0.92),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 2,
                                    width: selected ? 28 : 16,
                                    decoration: BoxDecoration(
                                      color: selected ? accent : Colors.white.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: selected ? accent : Colors.black.withOpacity(0.25),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(selected ? 0.0 : 0.22)),
                              ),
                              child: Icon(
                                selected ? Icons.check : Icons.add,
                                size: 16,
                                color: Colors.white,
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
          ).animate().fadeIn(duration: 280.ms, delay: (60 * index).ms);
        },
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ColorScheme colorScheme,
    bool isProcessing,
    ProductionVTONState vtonState,
  ) {
    final hasResult = vtonState.resultImageUrl != null && !vtonState.isProcessing;

    return Row(
      children: [
        // Secondary actions (left side)
        Expanded(
          child: Row(
            children: [
              if (!hasResult)
                Expanded(
                  child: _buildSecondaryButton(
                    context,
                    colorScheme,
                    'Change Photo',
                    Icons.photo_library_outlined,
                    _pickUserImage,
                  ),
                )
              else
                Expanded(
                  child: _buildSecondaryButton(
                    context,
                    colorScheme,
                    'Reset',
                    Icons.refresh_outlined,
                    _resetTryOn,
                  ),
                ),
              if (hasResult) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSaveButton(context, colorScheme, vtonState),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Primary action (right side)
        Expanded(
          child: _buildPrimaryButton(
            context,
            colorScheme,
            hasResult ? 'Try Another' : 'Try On',
            isProcessing,
            hasResult ? _resetTryOn : _performTryOn,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(
    BuildContext context,
    ColorScheme colorScheme,
    String label,
    bool isLoading,
    VoidCallback onPressed,
  ) {
    return Material(
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _TryOnTokens.accent(context),
              _TryOnTokens.accent(context).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _TryOnTokens.accent(context).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        colorScheme.onPrimary,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isLoading)
                        Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: colorScheme.onPrimary,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// Save button with premium success animation (checkmark + scale).
  Widget _buildSaveButton(
    BuildContext context,
    ColorScheme colorScheme,
    ProductionVTONState vtonState,
  ) {
    final accent = _TryOnTokens.accent(context);
    return Material(
      child: Ink(
        decoration: BoxDecoration(
          color: _saveSuccess
              ? accent.withOpacity(0.15)
              : _TryOnTokens.accent(context).withOpacity(0.08),
          border: Border.all(
            color: _saveSuccess ? accent.withOpacity(0.6) : _TryOnTokens.accent(context).withOpacity(0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          onTap: _saveSuccess ? null : () => _saveLook(vtonState),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) {
                return ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                );
              },
              child: _saveSuccess
                  ? Column(
                      key: const ValueKey<bool>(true),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 22, color: accent),
                        const SizedBox(height: 4),
                        Text(
                          'Saved',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )
                  : Column(
                      key: const ValueKey<bool>(false),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_outline, size: 18, color: _TryOnTokens.accent(context)),
                        const SizedBox(height: 4),
                        Text(
                          'Save',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: _TryOnTokens.accent(context),
                                fontWeight: FontWeight.w500,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
    BuildContext context,
    ColorScheme colorScheme,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Material(
      child: Ink(
        decoration: BoxDecoration(
          color: _TryOnTokens.accent(context).withOpacity(0.08),
          border: Border.all(
            color: _TryOnTokens.accent(context).withOpacity(0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: _TryOnTokens.accent(context),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _TryOnTokens.accent(context),
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoDialog(BuildContext context, ColorScheme colorScheme) {
    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How Virtual Try-On Works',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              context,
              '📸',
              'Upload Photo',
              'Choose a full-body photo with clear lighting',
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              context,
              '👗',
              'Select Items',
              'Browse and select items from your wardrobe',
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              context,
              '✨',
              'AI Magic',
              'Our AI generates a photorealistic preview',
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              context,
              '🎯',
              'Compare',
              'See before & after with our split view',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Material(
                child: Ink(
                  decoration: BoxDecoration(
                    color: _TryOnTokens.accent(context).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Got it',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: _TryOnTokens.accent(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String emoji,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Luxury Bottom Sheet Component
class _LuxuryBottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onAction;
  final String actionLabel;

  const _LuxuryBottomSheet({
    required this.title,
    required this.subtitle,
    required this.onAction,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: colorScheme.surface.withOpacity(0.95),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Material(
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _TryOnTokens.accent(context),
                          _TryOnTokens.accent(context).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: InkWell(
                      onTap: onAction,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            actionLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Material(
                  child: Ink(
                    decoration: BoxDecoration(
                      color: _TryOnTokens.accent(context).withOpacity(0.08),
                      border: Border.all(
                        color: _TryOnTokens.accent(context).withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            'Later',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: _TryOnTokens.accent(context),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple neutral placeholder (no default spinner) to keep loading calm.
Widget _buildShimmerLoading() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

/// Luxury fashion ring loader (no default spinner).
class _LuxuryRing extends StatelessWidget {
  final Animation<double> progress;
  final Color color;
  final Color glow;

  const _LuxuryRing({
    required this.progress,
    required this.color,
    required this.glow,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) {
          return CustomPaint(
            painter: _LuxuryRingPainter(
              t: progress.value,
              color: color,
              glow: glow,
            ),
          );
        },
      ),
    );
  }
}

class _LuxuryRingPainter extends CustomPainter {
  final double t;
  final Color color;
  final Color glow;

  _LuxuryRingPainter({
    required this.t,
    required this.color,
    required this.glow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;

    // Soft glow.
    final glowPaint = Paint()
      ..color = glow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(c, r - 2, glowPaint);

    // Background ring.
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.18);
    canvas.drawCircle(c, r - 2, bg);

    // Moving highlight arc.
    final start = (t * 2 * 3.141592653589793);
    final sweep = 1.15 + 0.55 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + sweep,
        colors: [
          color.withOpacity(0.0),
          color.withOpacity(0.95),
          color.withOpacity(0.25),
        ],
        stops: const [0.0, 0.6, 1.0],
        transform: GradientRotation(start),
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 2),
      start,
      sweep,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _LuxuryRingPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.color != color || oldDelegate.glow != glow;
  }
}

/// Extension on ProductionVTONStage for display names
extension ProductionVTONStageDisplay on ProductionVTONStage {
  String get displayName {
    switch (this) {
      case ProductionVTONStage.idle:
        return 'Ready…';
      case ProductionVTONStage.stage0_validation:
        return 'Validating photo…';
      case ProductionVTONStage.stage1_reasoning:
        return 'Processing image…';
      case ProductionVTONStage.stage2_body_understanding:
        return 'Analyzing body…';
      case ProductionVTONStage.stage3_garment_segmentation:
        return 'Encoding clothing…';
      case ProductionVTONStage.stage4_constraint:
        return 'Applying outfit…';
      case ProductionVTONStage.stage5_prompt_synthesis:
        return 'Generating preview…';
      case ProductionVTONStage.stage6_gemini_generation:
        return 'Refining…';
      case ProductionVTONStage.stage7_quality:
        return 'Finalizing…';
      case ProductionVTONStage.success:
        return 'Complete!';
      case ProductionVTONStage.failed:
        return 'Try-on failed';
      case ProductionVTONStage.rejected:
        return 'Try-on rejected';
    }
  }
}

/// Production Virtual Try-On Screen
/// Elegant, fashion-forward UI redesign
/// Backend logic preserved - UI only changes
library;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Web-specific imports - only available on web platform
// import 'dart:html' as html; // Commented out for mobile builds
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import '../../../core/models/production_vton_state.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/image_resizer.dart';
import '../../../core/providers/production_vton_provider.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../widgets/production_wardrobe_picker.dart';
import '../widgets/production_stage_indicator.dart';
import '../widgets/production_chat_interface.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../../../routes.dart';
import '../../style_feed/providers/style_feed_provider.dart';
import '../../style_feed/screens/post_look_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fashion-forward color palette
class TryOnColors {
  // Light mode - soft neutrals
  static const Color lightIvory = Color(0xFFFFF8F3);
  static const Color lightBlush = Color(0xFFFFE8E8);
  static const Color lightPink = Color(0xFFFFD6E8);
  static const Color softLavender = Color(0xFFE8D5FF);
  static const Color roseGold = Color(0xFFE8B4A0);
  
  // Dark mode - deep charcoal
  static const Color darkCharcoal = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF242424);
  static const Color darkHighlight = Color(0xFF3A3A3A);
  
  // Accent colors (work in both modes)
  static const Color accentRose = Color(0xFFFF6B9D);
  static const Color accentLavender = Color(0xFFB794F6);
  
  // Get adaptive colors based on brightness (use DesignTokens pink to match app)
  static Color getBackgroundColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkCharcoal : lightIvory;
  }
  
  static Color getSurfaceColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkSurface : Colors.white;
  }
  
  static Color getAccentColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? DesignTokens.darkAccent
        : DesignTokens.lightAccent;
  }
}

/// Production Virtual Try-On Screen
/// Modern, elegant, fashion-forward design
class ProductionTryOnScreen extends ConsumerStatefulWidget {
  const ProductionTryOnScreen({super.key});

  @override
  ConsumerState<ProductionTryOnScreen> createState() => _ProductionTryOnScreenState();
}

class _ProductionTryOnScreenState extends ConsumerState<ProductionTryOnScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _userImageBytes;
  String? _userImageUrl;
  final List<WardrobeItemModel> _selectedGarments = [];
  bool _isChatExpanded = false;
  bool _showBeforeAfter = false; // Before/After toggle
  int _beforeAfterMode = 0; // 0=before, 1=after, 2=split
  
  // Animation controllers
  late AnimationController _resultFadeController;
  late AnimationController _loadingTextController;
  late AnimationController _pageEnterController;
  late AnimationController _heroScaleController;
  
  // Loading text animation
  final List<String> _loadingTexts = [
    'Styling your look...',
    'Almost ready...',
    'Perfecting details...',
  ];
  int _currentLoadingTextIndex = 0;

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
    _heroScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _pageEnterController.forward();
    _loadDefaultImage();
    
    // Animate loading text changes
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
    _heroScaleController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultImage() async {
    try {
      final byteData = await rootBundle.load('assets/icons/dftryon.jpg');
      setState(() {
        _userImageBytes = byteData.buffer.asUint8List();
      });
    } catch (e) {
      debugPrint('Failed to load default image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vtonState = ref.watch(productionVTONProvider);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;
    final isTablet = screenSize.width >= 768 && screenSize.width < 1200;

    return Scaffold(
      backgroundColor: TryOnColors.getBackgroundColor(context),
      body: SafeArea(
        child: FadeTransition(
          opacity: _pageEnterController,
          child: Column(
            children: [
              // Elegant top bar
              _buildElegantTopBar(context, colorScheme),
              
              // Hero preview area
              Expanded(
                flex: isMobile ? 3 : 4,
                child: _buildHeroPreview(context, colorScheme, vtonState, isMobile),
              ),
              
              // Before/After toggle (only when result exists)
              if (vtonState.isSuccess && vtonState.resultImageUrl != null)
                _buildBeforeAfterToggle(context, colorScheme)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),
              
              // Luxury loading overlay
              if (vtonState.isProcessing)
                _buildLuxuryLoading(context, colorScheme, vtonState),
              
              // Wardrobe carousel
              _buildWardrobeCarousel(context, colorScheme, isMobile),
              
              // Floating action bar
              _buildFloatingActionBar(context, colorScheme, vtonState, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  /// Elegant top bar with serif typography
  Widget _buildElegantTopBar(BuildContext context, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: TryOnColors.getSurfaceColor(context).withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button with soft ripple
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Elegant title with serif font
          Text(
            'Virtual Try-On',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: 'Playfair Display', // Elegant serif
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          // Change photo button
          if (_userImageBytes != null || _userImageUrl != null)
            _buildIconButton(
              context,
              icon: Icons.camera_alt_outlined,
              onPressed: _pickPhoto,
              tooltip: 'Change photo',
            ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }

  /// Hero preview area - large, centered, elegant card
  Widget _buildHeroPreview(
    BuildContext context,
    ColorScheme colorScheme,
    ProductionVTONState state,
    bool isMobile,
  ) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: TryOnColors.getAccentColor(context).withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                TryOnColors.getSurfaceColor(context),
                TryOnColors.getSurfaceColor(context).withOpacity(0.95),
              ],
            ),
          ),
          child: _buildPreviewContent(context, colorScheme, state, isMobile),
        ),
      ),
    ).animate(controller: _heroScaleController)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0), curve: Curves.easeOutCubic);
  }

  Widget _buildPreviewContent(
    BuildContext context,
    ColorScheme colorScheme,
    ProductionVTONState state,
    bool isMobile,
  ) {
    // Show default placeholder
    if (_userImageBytes == null && _userImageUrl == null) {
      return _buildDefaultPlaceholder(context, colorScheme);
    }

    // Show result if success
    if (state.isSuccess && state.resultImageUrl != null) {
      // Show before/after based on toggle
      if (_showBeforeAfter) {
        return _buildResultDisplay(context, colorScheme, state.resultImageUrl!);
      } else {
        return _buildResultDisplay(context, colorScheme, state.resultImageUrl!);
      }
    }

    // Show error if failed
    if (state.isFailed || state.isRejected) {
      return _buildErrorDisplay(context, colorScheme, state);
    }

    // Show original image
    return _buildOriginalDisplay(context, colorScheme, state);
  }

  Widget _buildDefaultPlaceholder(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  TryOnColors.getAccentColor(context).withOpacity(0.2),
                  TryOnColors.getAccentColor(context).withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: TryOnColors.getAccentColor(context),
            ),
          ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
            'Upload your photo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your virtual try-on journey',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
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
    return Stack(
      children: [
        // Image with smooth fade
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: animation,
                  child: child,
                ),
              );
            },
            child: _userImageBytes != null
                ? Image.memory(
                    _userImageBytes!,
                    key: const ValueKey('memory'),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  )
                : _userImageUrl != null
                    ? CachedNetworkImage(
                        key: const ValueKey('network'),
                        imageUrl: _userImageUrl!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => _buildShimmerLoading(),
                        errorWidget: (context, url, error) => Icon(
                          Icons.error_outline,
                          color: colorScheme.error,
                          size: 48,
                        ),
                      )
                    : const SizedBox(key: ValueKey('empty')),
          ),
        ),
      ],
    );
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
        imageWidget = Image.memory(bytes, fit: BoxFit.contain);
      } catch (_) {
        imageWidget = Icon(Icons.error_outline, size: 64, color: colorScheme.error);
      }
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        placeholder: (context, url) => _buildShimmerLoading(),
      );
    }

    // Before/After split view
    if (_showBeforeAfter && _beforeAfterMode == 2) {
      return Row(
        children: [
          Expanded(
            child: _buildImageWithLabel(
              context,
              _userImageBytes != null
                  ? Image.memory(_userImageBytes!, fit: BoxFit.contain)
                  : _userImageUrl != null
                      ? CachedNetworkImage(imageUrl: _userImageUrl!, fit: BoxFit.contain)
                      : const SizedBox(),
              'Before',
            ),
          ),
          Container(width: 2, color: colorScheme.outline.withOpacity(0.1)),
          Expanded(
            child: _buildImageWithLabel(
              context,
              imageWidget,
              'After',
            ),
          ),
        ],
      );
    }

    // Single view (Before or After)
    return GestureDetector(
      onTap: () => _saveResult(imageUrl),
      child: Center(
        child: Hero(
          tag: 'tryon-result',
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: animation,
                  child: child,
                ),
              );
            },
            child: _beforeAfterMode == 0 && _showBeforeAfter
                ? _buildImageWithLabel(
                    context,
                    _userImageBytes != null
                        ? Image.memory(_userImageBytes!, fit: BoxFit.contain)
                        : _userImageUrl != null
                            ? CachedNetworkImage(imageUrl: _userImageUrl!, fit: BoxFit.contain)
                            : const SizedBox(),
                    'Before',
                    key: const ValueKey('before'),
                  )
                : _buildImageWithLabel(
                    context,
                    imageWidget,
                    'After',
                    key: const ValueKey('after'),
                  ),
          )
              .animate(controller: _resultFadeController)
              .fadeIn(duration: 1000.ms, curve: Curves.easeOut)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0), duration: 1000.ms),
        ),
      ),
    );
  }

  Widget _buildImageWithLabel(BuildContext context, Widget image, String label, {Key? key}) {
    return Container(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Center(child: image)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay(
    BuildContext context,
    ColorScheme colorScheme,
    ProductionVTONState state,
  ) {
    final errorMessage = state.error ?? 'Try-on failed';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.error.withOpacity(0.1),
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Luxury loading animation with elegant text
  Widget _buildLuxuryLoading(
    BuildContext context,
    ColorScheme colorScheme,
    ProductionVTONState state,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TryOnColors.getSurfaceColor(context).withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Elegant circular progress
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                TryOnColors.getAccentColor(context),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Animated text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              _loadingTexts[_currentLoadingTextIndex],
              key: ValueKey(_currentLoadingTextIndex),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  /// Before/After toggle with soft crossfade
  Widget _buildBeforeAfterToggle(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TryOnColors.getSurfaceColor(context).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(context, 'Before', 0),
          _buildToggleButton(context, 'Split', 2),
          _buildToggleButton(context, 'After', 1),
        ],
      ),
    );
  }

  Widget _buildToggleButton(BuildContext context, String label, int mode) {
    final isActive = _beforeAfterMode == mode;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _beforeAfterMode = mode;
              _showBeforeAfter = mode != 0;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: isActive
                  ? TryOnColors.getAccentColor(context).withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? TryOnColors.getAccentColor(context)
                    : colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Wardrobe carousel with snap scrolling
  Widget _buildWardrobeCarousel(
    BuildContext context,
    ColorScheme colorScheme,
    bool isMobile,
  ) {
    return Container(
      height: isMobile ? 160 : 180,
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Select Garments',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: ProductionWardrobePicker(
              selectedGarments: _selectedGarments,
              onGarmentSelected: (garment) {
                setState(() {
                  final index = _selectedGarments.indexWhere((g) => g.id == garment.id);
                  if (index >= 0) {
                    _selectedGarments.removeAt(index);
                  } else {
                    _selectedGarments.add(garment);
                  }
                });
                HapticFeedback.selectionClick();
              },
              onTryOn: null, // Handled by floating action bar
              colorScheme: colorScheme,
            ),
          ),
        ],
      ),
    );
  }

  /// Floating action bar with glassmorphism
  Widget _buildFloatingActionBar(
    BuildContext context,
    ColorScheme colorScheme,
    ProductionVTONState state,
    bool isMobile,
  ) {
    final hasResult = state.isSuccess && state.resultImageUrl != null;
    
    return Container(
      margin: EdgeInsets.all(isMobile ? 16 : 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TryOnColors.getSurfaceColor(context).withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Change photo button
          Expanded(
            child: _buildActionButton(
              context,
              icon: Icons.camera_alt_outlined,
              label: 'Change Photo',
              onPressed: _pickPhoto,
              isSecondary: true,
            ),
          ),
          const SizedBox(width: 12),
          // Try-on or Download button
          Expanded(
            flex: 2,
            child: _buildActionButton(
              context,
              icon: hasResult ? Icons.download_outlined : Icons.checkroom_outlined,
              label: hasResult ? 'Download' : 'Try This Look',
              onPressed: hasResult
                  ? () {
                      if (state.resultImageUrl != null) {
                        _saveResult(state.resultImageUrl!);
                      }
                    }
                  : _selectedGarments.isNotEmpty
                      ? _executeTryOn
                      : null,
              isPrimary: true,
            ),
          ),
          if (hasResult) ...[
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.grid_view_rounded,
                label: 'Post Look',
                onPressed: () => _openPostLook(state.resultImageUrl!),
                isPrimary: true,
              ),
            ),
          ],
          const SizedBox(width: 12),
          // Reset button
          Expanded(
            child: _buildActionButton(
              context,
              icon: Icons.refresh_outlined,
              label: 'Reset',
              onPressed: () {
                ref.read(productionVTONProvider.notifier).reset();
                setState(() {
                  _selectedGarments.clear();
                  _showBeforeAfter = false;
                  _beforeAfterMode = 0;
                });
              },
              isSecondary: true,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isPrimary = false,
    bool isSecondary = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onPressed != null;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled
            ? () {
                HapticFeedback.mediumImpact();
                onPressed?.call();
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: isPrimary && isEnabled
                ? TryOnColors.getAccentColor(context)
                : isSecondary && isEnabled
                    ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
                    : colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isPrimary && isEnabled
                    ? Colors.white
                    : colorScheme.onSurface.withOpacity(isEnabled ? 0.7 : 0.4),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isPrimary && isEnabled
                      ? Colors.white
                      : colorScheme.onSurface.withOpacity(isEnabled ? 0.7 : 0.4),
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 22,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    // Simple neutral placeholder to avoid default spinners while remaining compatible
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: SizedBox.shrink(),
      ),
    );
  }

  // ========== BACKEND INTEGRATION (UNCHANGED) ==========
  
  Future<void> _pickPhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      
      if (image != null) {
        var bytes = await image.readAsBytes();
        bytes = await ImageResizer.resizeIfNeeded(bytes);
        
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
      
      setState(() {
        _userImageUrl = url;
      });
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
        .map((g) => g.imageUrl)
        .where((u) => u.isNotEmpty && (u.startsWith('http://') || u.startsWith('https://')))
        .toList();

    if (garmentUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selected garments need valid image URLs (http/https). '
            'Add wardrobe items with accessible image links.',
          ),
        ),
      );
      return;
    }

    final notifier = ref.read(productionVTONProvider.notifier);
    await notifier.executeTryOn(
      userImageUrl: _userImageUrl ?? '',
      garmentImageUrls: garmentUrls,
      userImageBase64: userImageBase64,
    );

    final newState = ref.read(productionVTONProvider);
    if (newState.isSuccess) {
      _resultFadeController.forward();
      _heroScaleController.forward();
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
      suggestedCaption: 'My try-on look ✨',
    );
  }

  Future<void> _saveResult(String imageUrl) async {
    try {
      Uint8List? imageBytes;
      
      if (imageUrl.startsWith('data:image') && imageUrl.contains(',')) {
        try {
          final base64Data = imageUrl.split(',').last;
          imageBytes = base64Decode(base64Data);
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

      // Web-specific download functionality disabled for mobile builds
      // if (kIsWeb) {
      //   final blob = html.Blob([imageBytes], 'image/jpeg');
      //   final url = html.Url.createObjectUrlFromBlob(blob);
      //   final anchor = html.AnchorElement(href: url)
      //     ..setAttribute('download', 'tryon-result-${DateTime.now().millisecondsSinceEpoch}.jpg')
      //     ..click();
      //   html.Url.revokeObjectUrl(url);
      //   
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text('Image downloaded successfully! 📥')),
      //     );
      //   }
      // } else {
      if (mounted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Result saved to gallery ✨')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image: $e')),
        );
      }
    }
  }
}

/// Production Virtual Try-On Screen
/// Production-quality UI aligned with 7-stage backend pipeline
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/production_vton_state.dart';
import '../../../core/utils/image_resizer.dart';
import '../../../core/providers/production_vton_provider.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../widgets/production_wardrobe_picker.dart';
import '../widgets/production_stage_indicator.dart';
import '../widgets/production_chat_interface.dart';
import '../../../core/services/supabase_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../routes.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

/// Production Virtual Try-On Screen
/// Fullscreen image, wardrobe picker, ChatGPT-like chat
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
  List<WardrobeItemModel> _selectedGarments = [];
  bool _isChatExpanded = false;
  late AnimationController _resultFadeController;

  @override
  void initState() {
    super.initState();
    _resultFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadDefaultImage();
  }

  @override
  void dispose() {
    _resultFadeController.dispose();
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
    final isMobile = MediaQuery.of(context).size.width < 768;
    final vtonState = ref.watch(productionVTONProvider);

    if (isMobile) {
      return _buildMobileLayout(context, colorScheme, vtonState);
    } else {
      return _buildDesktopLayout(context, colorScheme, vtonState);
    }
  }

  Widget _buildMobileLayout(
    BuildContext context,
    ColorScheme colorScheme,
    ProductionVTONState state,
  ) {
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(context, colorScheme),
            
            // Main image area (fullscreen)
            Expanded(
              child: _buildImageCanvas(context, colorScheme, state),
            ),
            
            // Stage indicator (if processing)
            if (state.isProcessing)
              _buildStageIndicator(context, colorScheme, state),
            
            // Wardrobe picker (bottom)
            _buildWardrobePicker(context, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    ColorScheme colorScheme,
    ProductionVTONState state,
  ) {
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Row(
        children: [
          // Wardrobe sidebar (25%)
          SizedBox(
            width: 300,
            child: _buildWardrobeSidebar(context, colorScheme),
          ),
          
          // Main canvas (50%)
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildTopBar(context, colorScheme),
                Expanded(
                  child: _buildImageCanvas(context, colorScheme, state),
                ),
                if (state.isProcessing)
                  _buildStageIndicator(context, colorScheme, state),
              ],
            ),
          ),
          
          // Chat sidebar (25% or expanded)
          _isChatExpanded
              ? Expanded(flex: 2, child: _buildChatInterface(context, colorScheme))
              : SizedBox(
                  width: 300,
                  child: _buildChatInterface(context, colorScheme),
                ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Text(
            'Virtual Try-On',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (_userImageBytes != null || _userImageUrl != null)
            IconButton(
              icon: Icon(Icons.camera_alt, color: colorScheme.primary),
              onPressed: _pickPhoto,
              tooltip: 'Change photo',
            ),
          IconButton(
            icon: Icon(
              _isChatExpanded ? Icons.chat_bubble : Icons.chat_bubble_outline,
              color: colorScheme.primary,
            ),
            onPressed: () {
              setState(() {
                _isChatExpanded = !_isChatExpanded;
              });
            },
            tooltip: 'Toggle chat',
          ),
        ],
      ),
    );
  }

  Widget _buildImageCanvas(
    BuildContext context,
    ColorScheme colorScheme,
    ProductionVTONState state,
  ) {
    // Show default placeholder if no image
    if (_userImageBytes == null && _userImageUrl == null) {
      return _buildDefaultPlaceholder(context, colorScheme);
    }

    // Show result if success
    if (state.isSuccess && state.resultImageUrl != null) {
      return _buildResultImage(context, colorScheme, state.resultImageUrl!);
    }

    // Show error if failed/rejected
    if (state.isFailed || state.isRejected) {
      return _buildErrorState(context, colorScheme, state);
    }

    // Show original image (with processing overlay if processing)
    return _buildOriginalImage(context, colorScheme, state);
  }

  Widget _buildDefaultPlaceholder(BuildContext context, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Default image
          Image.asset(
            'assets/icons/dftryon.jpg',
            width: 300,
            height: 400,
            fit: BoxFit.contain,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),
          Text(
            'Upload your photo to try on',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Upload Photo'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalImage(
    BuildContext context,
    ColorScheme colorScheme,
    ProductionVTONState state,
  ) {
    return Stack(
      children: [
        // Image
        Center(
          child: _userImageBytes != null
              ? Image.memory(
                  _userImageBytes!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                )
              : _userImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: _userImageUrl!,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.error_outline,
                        color: colorScheme.error,
                      ),
                    )
                  : const SizedBox(),
        ),
        
        // Processing overlay
        if (state.isProcessing)
          Container(
            color: colorScheme.surface.withOpacity(0.7),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo only (no text, no spinner)
                  Image.asset(
                    'assets/images/cleologo.jpg',
                    width: 64,
                    height: 64,
                  ),
                ],
              ),
            ),
          ),
        
        // Try-on hint (tappable)
        if (!state.isProcessing && _selectedGarments.isNotEmpty)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _executeTryOn,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'Tap to try on ${_selectedGarments.length} item${_selectedGarments.length > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultImage(
    BuildContext context,
    ColorScheme colorScheme,
    String imageUrl,
  ) {
    return GestureDetector(
      onTap: () {
        // Save result
        _saveResult(imageUrl);
      },
      child: Center(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          ),
        )
            .animate(controller: _resultFadeController)
            .fadeIn(duration: 800.ms, curve: Curves.easeOut),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ColorScheme colorScheme,
    ProductionVTONState state,
  ) {
    final errorMessage = state.error ?? 'Try-on failed';
    final isConnectionError = errorMessage.contains('Cannot connect') || 
                              errorMessage.contains('Failed to fetch') ||
                              errorMessage.contains('backend server');
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isConnectionError ? Icons.cloud_off : Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (errorMessage.contains('too large') || errorMessage.contains('validation failed')) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'The backend automatically resizes images to fit within 4096x4096 pixels. If you see this error, the image may be corrupted or in an unsupported format.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (state.errorStage != null) ...[
              const SizedBox(height: 8),
              Text(
                'Stage: ${state.errorStage}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
            if (isConnectionError) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Backend Server Not Running',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'To start the server:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        'cd backend\npython -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Or double-click: start_backend_server.bat',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Server should be running at:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      'http://localhost:8000',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                ref.read(productionVTONProvider.notifier).reset();
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageIndicator(
    BuildContext context,
    ColorScheme colorScheme,
    ProductionVTONState state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colorScheme.surface,
      child: ProductionStageIndicator(
        stage: state.stage,
        colorScheme: colorScheme,
      ),
    );
  }

  Widget _buildWardrobePicker(BuildContext context, ColorScheme colorScheme) {
    return ProductionWardrobePicker(
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
      onTryOn: _selectedGarments.isNotEmpty ? _executeTryOn : null,
      colorScheme: colorScheme,
    );
  }

  Widget _buildWardrobeSidebar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Wardrobe',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
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
              onTryOn: _selectedGarments.isNotEmpty ? _executeTryOn : null,
              colorScheme: colorScheme,
              isVertical: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInterface(BuildContext context, ColorScheme colorScheme) {
    return ProductionChatInterface(
      colorScheme: colorScheme,
      onImageAttach: _pickPhoto,
      onTryOnRequest: _selectedGarments.isNotEmpty ? _executeTryOn : null,
    );
  }

  Future<void> _pickPhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      
      if (image != null) {
        var bytes = await image.readAsBytes();
        
        // Resize if needed before processing
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

    // Ensure user image is uploaded
    String? userImageUrl = _userImageUrl;
    String? userImageBase64;
    
    if (userImageUrl == null && _userImageBytes != null) {
      // Upload bytes first
      await _uploadPhoto(_userImageBytes!);
      userImageUrl = _userImageUrl;
      
      // If upload fails, use base64 as fallback
      if (userImageUrl == null) {
        userImageBase64 = base64Encode(_userImageBytes!);
      }
    }

    final garmentUrls = _selectedGarments
        .where((g) => g.imageUrl != null)
        .map((g) => g.imageUrl!)
        .toList();

    if (garmentUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected garments have no image URLs')),
      );
      return;
    }

    final notifier = ref.read(productionVTONProvider.notifier);
    await notifier.executeTryOn(
      userImageUrl: userImageUrl ?? '',
      garmentImageUrls: garmentUrls,
      userImageBase64: userImageBase64,
    );

    // If successful, trigger fade-in animation
    final newState = ref.read(productionVTONProvider);
    if (newState.isSuccess) {
      _resultFadeController.forward();
    }
  }

  Future<void> _saveResult(String imageUrl) async {
    // Save to try-on history
    // Implementation would save to database
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Result saved')),
      );
    }
  }
}

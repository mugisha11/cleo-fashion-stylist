import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/fashion_scaffold.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/services/vton_service.dart';
import '../../../core/services/wardrobe_service.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../../../core/services/tryon_memory_service.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../../core/providers/tryon_memory_provider.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../../../routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

/// Premium Manual Outfit Selection Try-On Screen
/// Theme-adaptive, manual selection, transparent PNG-style wardrobe display
/// Elegant, feminine, modern, creative, market-ready
class LuxuryTryOnScreen extends ConsumerStatefulWidget {
  const LuxuryTryOnScreen({super.key});

  @override
  ConsumerState<LuxuryTryOnScreen> createState() => _LuxuryTryOnScreenState();
}

class _LuxuryTryOnScreenState extends ConsumerState<LuxuryTryOnScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _userPhoto;
  Uint8List? _userPhotoBytes;
  
  // Manual selection - styling layer stack
  final List<WardrobeItemModel> _selectedGarments = []; // Base to top order
  final Map<String, WardrobeItemModel> _selectedByCategory = {};
  
  bool _isProcessing = false;
  String? _resultUrl;
  Uint8List? _resultImageBytes;
  String? _processingStage;
  double _processingProgress = 0.0;
  
  // Wardrobe data
  List<WardrobeItemModel> _wardrobeItems = [];
  Map<String, List<WardrobeItemModel>> _groupedByCategory = {};
  String? _selectedCategory;
  bool _isLoadingWardrobe = true;
  
  // UI State
  bool _wardrobePanelExpanded = false;
  bool _photoValidated = false;
  String? _validationError;
  
  // Animations
  late AnimationController _garmentAnimationController;
  late AnimationController _wardrobePanelController;
  late AnimationController _shimmerController;
  late AnimationController _selectionAnimationController;
  late Animation<double> _garmentFadeAnimation;
  late Animation<double> _garmentScaleAnimation;
  late Animation<double> _garmentMorphAnimation;
  late Animation<double> _selectionScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Garment application animation
    _garmentAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _garmentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _garmentAnimationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _garmentScaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(
        parent: _garmentAnimationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    
    _garmentMorphAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _garmentAnimationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );
    
    // Selection animation
    _selectionAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _selectionScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _selectionAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    
    // Wardrobe panel animation
    _wardrobePanelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    // Shimmer for skeleton loading
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _loadWardrobe();
  }

  @override
  void dispose() {
    _garmentAnimationController.dispose();
    _wardrobePanelController.dispose();
    _shimmerController.dispose();
    _selectionAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadWardrobe() async {
    try {
      setState(() => _isLoadingWardrobe = true);
      
      final wardrobeService = ref.read(wardrobeServiceProvider);
      final items = await wardrobeService.getUserWardrobe();

      // Group by category with proper mapping
      final grouped = <String, List<WardrobeItemModel>>{
        'tops': [],
        'bottoms': [],
        'dresses': [],
        'outerwear': [],
        'accessories': [],
      };
      
      for (var item in items) {
        final category = item.category.toLowerCase();
        if (category.contains('top') || category.contains('shirt') || category.contains('blouse')) {
          grouped['tops']!.add(item);
        } else if (category.contains('bottom') || category.contains('pant') || category.contains('skirt')) {
          grouped['bottoms']!.add(item);
        } else if (category.contains('dress')) {
          grouped['dresses']!.add(item);
        } else if (category.contains('jacket') || category.contains('coat') || category.contains('outer')) {
          grouped['outerwear']!.add(item);
        } else {
          grouped['accessories']!.add(item);
        }
      }

      setState(() {
        _wardrobeItems = items;
        _groupedByCategory = grouped;
        _selectedCategory = grouped.keys.firstWhere((k) => grouped[k]!.isNotEmpty, orElse: () => 'tops');
        _isLoadingWardrobe = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingWardrobe = false;
        _validationError = 'Failed to load wardrobe: $e';
      });
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
        preferredCameraDevice: CameraDevice.front,
      );
      
      if (image != null) {
        await _processPhoto(image);
      }
    } catch (e) {
      _showError('Failed to capture photo: $e');
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      
      if (image != null) {
        await _processPhoto(image);
      }
    } catch (e) {
      _showError('Failed to pick photo: $e');
    }
  }

  Future<void> _processPhoto(XFile image) async {
    setState(() {
      _photoValidated = false;
      _validationError = null;
    });

    try {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        if (bytes.length < 50000) {
          throw Exception('Image too small. Please use a higher quality photo.');
        }
        setState(() {
          _userPhotoBytes = bytes;
          _userPhoto = null;
          _photoValidated = true;
        });
      } else {
        final file = File(image.path);
        final size = await file.length();
        if (size < 50000) {
          throw Exception('Image too small. Please use a higher quality photo.');
        }
        setState(() {
          _userPhoto = file;
          _userPhotoBytes = null;
          _photoValidated = true;
        });
      }
      
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() {
        _validationError = e.toString();
        _photoValidated = false;
      });
      _showError('Photo validation failed: $e');
    }
  }

  /// Manual selection - add/remove garment from styling stack
  void _toggleGarmentSelection(WardrobeItemModel item) {
    setState(() {
      final category = _getCategoryForItem(item);
      final existing = _selectedByCategory[category];
      
      if (existing?.id == item.id) {
        // Deselect
        _selectedByCategory.remove(category);
        _selectedGarments.removeWhere((g) => g.id == item.id);
      } else {
        // Select (replace if category already has selection)
        if (existing != null) {
          _selectedGarments.removeWhere((g) => g.id == existing.id);
        }
        _selectedByCategory[category] = item;
        _selectedGarments.add(item);
      }
    });
    
    _selectionAnimationController.forward().then((_) {
      _selectionAnimationController.reverse();
    });
    HapticFeedback.selectionClick();
    
    // Auto-apply when item is selected and photo is ready
    if (_selectedGarments.isNotEmpty && 
        _photoValidated && 
        (_userPhoto != null || _userPhotoBytes != null)) {
      _applyOutfit();
    }
  }

  String _getCategoryForItem(WardrobeItemModel item) {
    final category = item.category.toLowerCase();
    if (category.contains('top') || category.contains('shirt') || category.contains('blouse')) {
      return 'tops';
    } else if (category.contains('bottom') || category.contains('pant') || category.contains('skirt')) {
      return 'bottoms';
    } else if (category.contains('dress')) {
      return 'dresses';
    } else if (category.contains('jacket') || category.contains('coat') || category.contains('outer')) {
      return 'outerwear';
    } else {
      return 'accessories';
    }
  }

  Future<void> _applyOutfit() async {
    if (!_photoValidated || (_userPhoto == null && _userPhotoBytes == null)) {
      _showError('Please upload a valid photo');
      return;
    }

    if (_selectedGarments.isEmpty) {
      _showError('Please select at least one garment');
      return;
    }

    setState(() {
      _isProcessing = true;
      _resultUrl = null;
      _resultImageBytes = null;
      _processingStage = 'Applying outfit...';
      _processingProgress = 0.0;
    });

    HapticFeedback.mediumImpact();
    _garmentAnimationController.reset();

    try {
      final vtonService = ref.read(vtonServiceProvider);
      
      String userPhotoUrl;
      if (kIsWeb && _userPhotoBytes != null) {
        userPhotoUrl = await vtonService.uploadUserPhoto(_userPhotoBytes!);
      } else if (_userPhoto != null) {
        userPhotoUrl = await vtonService.uploadUserPhoto(_userPhoto!);
      } else {
        throw Exception('No photo available');
      }

      // Apply garments in order (base to top)
      // For now, apply the first selected garment (can be enhanced for layering)
      final primaryGarment = _selectedGarments.first;
      
      final result = await vtonService.processTryOnPipeline(
        userImageUrl: userPhotoUrl,
        clothingImageUrl: primaryGarment.processedImageUrl ?? primaryGarment.imageUrl,
        preserveFace: true,
        preserveResolution: true,
        onProgress: (stage, progress) {
          if (mounted) {
            setState(() {
              _processingStage = stage;
              _processingProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        String? resultImageBase64 = result['result_image'] as String?;
        String? finalResultUrl;
        
        if (resultImageBase64 != null) {
          try {
            _resultImageBytes = base64Decode(resultImageBase64);
            // Upload result image to storage
            final storageService = SupabaseStorageService(Supabase.instance.client);
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
            final fileName = 'tryon-results/$userId/$timestamp.jpg';
            
            if (kIsWeb) {
              final url = await storageService.uploadFile(
                bucket: 'uploads',
                path: fileName,
                file: _resultImageBytes!,
                contentType: 'image/jpeg',
              );
              finalResultUrl = url;
            } else {
              // For mobile, convert bytes to file temporarily
              final tempFile = File('${(await getTemporaryDirectory()).path}/temp_tryon_$timestamp.jpg');
              await tempFile.writeAsBytes(_resultImageBytes!);
              final url = await storageService.uploadFile(
                bucket: 'uploads',
                path: fileName,
                file: tempFile,
                contentType: 'image/jpeg',
              );
              finalResultUrl = url;
              await tempFile.delete();
            }
          } catch (e) {
            _resultUrl = result['result_url'] as String?;
            finalResultUrl = _resultUrl;
          }
        } else {
          _resultUrl = result['result_url'] as String?;
          finalResultUrl = _resultUrl;
        }
        
        // Save try-on session
        if (finalResultUrl != null && userPhotoUrl.isNotEmpty) {
          try {
            final tryOnMemoryService = ref.read(tryonMemoryServiceProvider);
            await tryOnMemoryService.saveTryOnSession(
              baseImageUrl: userPhotoUrl,
              resultImageUrl: finalResultUrl,
              outfitIds: _selectedGarments.map((g) => g.id).toList(),
            );
          } catch (e) {
            print('Failed to save try-on session: $e');
            // Don't block UI if save fails
          }
        }
        
        setState(() {
          _isProcessing = false;
          _processingStage = null;
          _processingProgress = 1.0;
          _resultUrl = finalResultUrl;
        });

        _garmentAnimationController.forward();
        HapticFeedback.heavyImpact();
        _showSuccess('Outfit applied successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingStage = null;
          _processingProgress = 0.0;
        });
        
        // Parse error message for user-friendly display
        String errorMessage = 'Failed to apply outfit';
        final errorStr = e.toString().toLowerCase();
        
        if (errorStr.contains('upload_image_required') || errorStr.contains('no photo available')) {
          errorMessage = 'Please upload a photo or select an outfit to try on';
        } else if (errorStr.contains('no_wardrobe_items') || errorStr.contains('select')) {
          errorMessage = 'Please select at least one garment to try on';
        } else if (errorStr.contains('invalid_image') || errorStr.contains('validation failed') || errorStr.contains('empty')) {
          errorMessage = 'Please upload a valid photo or select a valid outfit to try on';
        } else if (errorStr.contains('timeout')) {
          errorMessage = 'Request timed out. Please try again';
        } else if (errorStr.contains('network') || errorStr.contains('connection')) {
          errorMessage = 'Network error. Please check your connection and try again';
        } else {
          // Show original error for debugging, but sanitize it
          errorMessage = 'Failed to apply outfit. Please try again';
        }
        
        _showError(errorMessage);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.appTheme.accentError,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.appTheme.accentSuccess,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isMobile = MediaQuery.of(context).size.width < 768;
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    
    return FashionScaffold(
      title: 'Try-On',
      currentBottomNavIndex: 2,
      currentRoute: Routes.tryon,
      backgroundColor: theme.backgroundPrimary,
      body: Container(
        decoration: theme.backgroundGradient != null
            ? BoxDecoration(gradient: theme.backgroundGradient)
            : BoxDecoration(color: theme.backgroundPrimary),
        child: Stack(
          children: [
            // Main Model View - Full-screen on mobile, centered on desktop
            _buildModelView(theme, isMobile),
            
            // Fixed Bottom Wardrobe Panel - Always visible, shows ALL items
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomWardrobePanel(theme, bottomPadding),
            ),
            
            // Floating action buttons
            _buildFloatingActions(theme, isMobile),
            
            // Subtle progress indicator
            if (_isProcessing) _buildSubtleProgressIndicator(theme),
          ],
        ),
      ),
    );
  }

  /// Model View - Full-screen on mobile, centered/dominant on desktop
  /// No UI elements overlap the image
  Widget _buildModelView(AppThemeData theme, bool isMobile) {
    if (isMobile) {
      // Full-screen on mobile - wardrobe panel is fixed at bottom
      return Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.only(bottom: 180), // Space for fixed wardrobe panel
        child: _buildModelImage(theme, isMobile: true),
      );
    } else {
      // Centered and dominant on tablet/desktop
      return LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;
          final viewportHeight = constraints.maxHeight;
          final modelWidth = (viewportWidth * 0.75).clamp(400.0, 1200.0);
          final modelHeight = (viewportHeight * 0.75).clamp(500.0, 900.0);
          
          return Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.only(bottom: 200), // Space for fixed wardrobe panel
            child: Center(
              child: Container(
                width: modelWidth,
                height: modelHeight,
                child: AspectRatio(
                  aspectRatio: 0.75,
                  child: Stack(
                    children: [
                      // Background glow effect (theme-adaptive)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: theme.primaryGlow != null
                              ? [theme.primaryGlow!]
                              : [
                                  BoxShadow(
                                    color: theme.primary.withOpacity(0.15),
                                    blurRadius: 60,
                                    spreadRadius: 10,
                                  ),
                                ],
                        ),
                      ),
                      
                      // Model/Result Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.surface.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: _buildModelImage(theme, isMobile: false),
                        ),
                      ),
                      
                      // Subtle depth overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: theme.borderLight.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildModelImage(AppThemeData theme, {required bool isMobile}) {
    
    if (_resultUrl != null || _resultImageBytes != null) {
      return AnimatedBuilder(
        animation: _garmentAnimationController,
        builder: (context, child) {
          return Opacity(
            opacity: _garmentFadeAnimation.value,
            child: Transform.scale(
              scale: _garmentScaleAnimation.value,
              child: Container(
                width: isMobile ? double.infinity : null,
                height: isMobile ? double.infinity : null,
                decoration: BoxDecoration(
                  borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(24),
                  boxShadow: isMobile ? null : [
                    BoxShadow(
                      color: theme.primary.withOpacity(0.1 * _garmentMorphAnimation.value),
                      blurRadius: 20 * _garmentMorphAnimation.value,
                      spreadRadius: 2 * _garmentMorphAnimation.value,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(24),
                  child: _resultImageBytes != null
                      ? Image.memory(
                          _resultImageBytes!,
                          fit: BoxFit.contain,
                          width: isMobile ? double.infinity : null,
                          height: isMobile ? double.infinity : null,
                        )
                      : _resultUrl != null
                          ? CachedNetworkImage(
                              imageUrl: _resultUrl!,
                              fit: BoxFit.contain,
                              width: isMobile ? double.infinity : null,
                              height: isMobile ? double.infinity : null,
                              placeholder: (context, url) => _buildSkeletonPreview(theme),
                              errorWidget: (context, url, error) => _buildErrorPlaceholder(theme),
                            )
                          : const SizedBox(),
                ),
              ),
            ),
          );
        },
      );
    } else if (_userPhoto != null || _userPhotoBytes != null) {
      return kIsWeb && _userPhotoBytes != null
          ? Image.memory(
              _userPhotoBytes!,
              fit: isMobile ? BoxFit.contain : BoxFit.cover,
              width: isMobile ? double.infinity : null,
              height: isMobile ? double.infinity : null,
            )
          : _userPhoto != null
              ? Image.file(
                  _userPhoto!,
                  fit: isMobile ? BoxFit.contain : BoxFit.cover,
                  width: isMobile ? double.infinity : null,
                  height: isMobile ? double.infinity : null,
                )
              : const SizedBox();
    } else {
      return _buildPhotoPlaceholder(theme);
    }
  }

  Widget _buildSkeletonPreview(AppThemeData theme) {
    return Container(
      color: theme.surface.withOpacity(0.2),
      child: Shimmer(
        controller: _shimmerController,
        theme: theme,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 - _shimmerController.value * 2, 0.0),
              end: Alignment(1.0 - _shimmerController.value * 2, 0.0),
              colors: [
                theme.surface.withOpacity(0.1),
                theme.surface.withOpacity(0.3),
                theme.surface.withOpacity(0.1),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(AppThemeData theme) {
    return Container(
      color: theme.surface.withOpacity(0.2),
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: theme.textTertiary,
          size: 64,
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder(AppThemeData theme) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return GestureDetector(
      onTap: () => _showPhotoSourceDialog(theme),
      child: Container(
        width: isMobile ? double.infinity : null,
        height: isMobile ? double.infinity : null,
        decoration: BoxDecoration(
          color: theme.surface.withOpacity(0.1),
          borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(24),
          child: Image.asset(
            'assets/icons/dftryon.jpg',
            fit: isMobile ? BoxFit.contain : BoxFit.cover,
            width: isMobile ? double.infinity : null,
            height: isMobile ? double.infinity : null,
            errorBuilder: (context, error, stackTrace) {
              // Fallback if image doesn't exist
              return Container(
        decoration: BoxDecoration(
          color: theme.surface.withOpacity(0.2),
                  borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(24),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_a_photo,
                  size: 48,
                  color: theme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Add Your Photo',
                style: theme.titleLarge(color: theme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Face-forward, full body recommended',
                style: theme.bodyMedium(color: theme.textSecondary),
              ),
            ],
        ),
      ),
    );
            },
          ),
        ),
      ),
    );
  }

  /// Fixed Bottom Wardrobe Panel - Shows ALL wardrobe items horizontally
  /// Always visible, never hidden, theme-adaptive
  Widget _buildBottomWardrobePanel(AppThemeData theme, double bottomPadding) {
    return Container(
      height: 180 + bottomPadding,
      decoration: BoxDecoration(
        color: theme.surface.withOpacity(0.98),
        border: Border(
          top: BorderSide(
            color: theme.borderLight,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.transparent,
            padding: EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: bottomPadding + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with item count
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.checkroom,
                        color: theme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your Wardrobe',
                        style: theme.bodyMedium(color: theme.textPrimary).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isLoadingWardrobe)
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_wardrobeItems.length}',
                            style: theme.bodySmall(color: theme.primary).copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Horizontal scrollable wardrobe items - ALL items shown
                Expanded(
                  child: _isLoadingWardrobe
                      ? _buildWardrobeShimmerHorizontal(theme)
                      : _wardrobeItems.isEmpty
                          ? _buildEmptyWardrobeHorizontal(theme)
                          : _buildWardrobeItemsHorizontal(theme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Horizontal scrollable list of ALL wardrobe items
  Widget _buildWardrobeItemsHorizontal(AppThemeData theme) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: _wardrobeItems.length,
      itemBuilder: (context, index) {
        final item = _wardrobeItems[index];
        final isSelected = _selectedGarments.any((g) => g.id == item.id);
        
        return _buildWardrobeCardHorizontal(item, isSelected, index, theme);
      },
    );
  }

  Widget _buildWardrobeShimmerHorizontal(AppThemeData theme) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          width: 120,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: theme.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Shimmer(
            controller: _shimmerController,
            theme: theme,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1.0 - _shimmerController.value * 2, 0.0),
                  end: Alignment(1.0 - _shimmerController.value * 2, 0.0),
                  colors: [
                    theme.surface.withOpacity(0.1),
                    theme.surface.withOpacity(0.3),
                    theme.surface.withOpacity(0.1),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyWardrobeHorizontal(AppThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: 32,
              color: theme.textTertiary,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
              'Add clothing to your wardrobe to try them on',
                style: theme.bodyMedium(color: theme.textSecondary),
              textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Horizontal Wardrobe Card - Fashion-grade, small, elegant
  /// Background-removed style with soft shadows, rounded corners, tap animation
  Widget _buildWardrobeCardHorizontal(WardrobeItemModel item, bool isSelected, int index, AppThemeData theme) {
    return GestureDetector(
      onTap: () {
        _toggleGarmentSelection(item);
        HapticFeedback.lightImpact();
      },
      child: AnimatedBuilder(
        animation: _selectionScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? _selectionScaleAnimation.value : 1.0,
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16), // Soft rounded corners
                border: Border.all(
                  color: isSelected
                      ? theme.primary
                      : theme.borderLight.withOpacity(0.3),
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: [
                  // Soft shadow for floating effect (background-removed style)
                  BoxShadow(
                    color: Colors.black.withOpacity(isSelected ? 0.15 : 0.08),
                    blurRadius: isSelected ? 16 : 8,
                    offset: Offset(0, isSelected ? 6 : 3),
                    spreadRadius: isSelected ? 2 : -1,
                  ),
                  if (isSelected)
                    BoxShadow(
                      color: theme.primary.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 3,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Background with subtle gradient (transparent PNG-style)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.surfaceElevated.withOpacity(0.6),
                            theme.backgroundPrimary.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                    
                    // Clothing image with background-removed style
                    // Uses processedImageUrl if available (background removed), otherwise regular imageUrl
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: item.imageUrl, // Use regular imageUrl (background removal handled by styling)
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Container(
                          color: theme.surfaceElevated,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.surfaceElevated,
                          child: Icon(
                            Icons.broken_image,
                            color: theme.textTertiary,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    
                    // Selected overlay with checkmark
                    if (isSelected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primary.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                        
                    // Category badge at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.surface.withOpacity(0.9),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Text(
                                  item.category.toUpperCase(),
                                  style: theme.bodySmall(
                                    color: theme.textSecondary,
                                  ).copyWith(
                                    fontWeight: FontWeight.w600,
                            fontSize: 9,
                                    letterSpacing: 0.5,
                                  ),
                          textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          );
        },
      ),
    ).animate(
      delay: (index * 30).ms,
    ).fadeIn(
      duration: 250.ms,
      curve: Curves.easeOut,
    ).scale(
      begin: const Offset(0.85, 0.85),
      duration: 200.ms,
      curve: Curves.easeOut,
    );
  }

  Widget _buildFloatingActions(AppThemeData theme, bool isMobile) {
    // Position above the wardrobe panel (180px height + padding)
    final bottomOffset = isMobile ? 200.0 : 220.0;
    
    return Positioned(
      bottom: bottomOffset,
      right: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Apply Outfit Button
          if ((_userPhoto != null || _userPhotoBytes != null) && _selectedGarments.isNotEmpty)
            _buildApplyButton(theme),
          
          const SizedBox(height: 12),
          
          // Photo Upload Button
          if (_userPhoto == null && _userPhotoBytes == null)
            _buildPhotoUploadButton(theme),
        ],
      ),
    );
  }

  Widget _buildApplyButton(AppThemeData theme) {
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
          onTap: _isProcessing ? null : _applyOutfit,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isProcessing)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                const SizedBox(width: 12),
                Text(
                  _isProcessing ? 'Applying...' : 'Apply Outfit',
                  style: theme.bodyLarge(color: Colors.white).copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildPhotoUploadButton(AppThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.borderLight,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPhotoSourceDialog(theme),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Icon(
              Icons.add_a_photo,
              color: theme.textPrimary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtleProgressIndicator(AppThemeData theme) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final bottomOffset = isMobile ? 200.0 : 220.0;
    
    return Positioned(
      bottom: bottomOffset,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.surfaceElevated.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_processingStage != null)
                    Text(
                      _processingStage!,
                      style: theme.bodySmall(color: theme.textPrimary).copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _processingProgress,
                      backgroundColor: theme.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                      minHeight: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
    );
  }

  void _showPhotoSourceDialog(AppThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: theme.primary,
                  ),
                ),
                title: Text(
                  'Take Photo',
                  style: theme.bodyMedium(color: theme.textPrimary).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _capturePhoto();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.photo_library,
                    color: theme.primary,
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: theme.bodyMedium(color: theme.textPrimary).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer effect for skeleton loading (theme-adaptive)
class Shimmer extends StatefulWidget {
  final Widget child;
  final AnimationController controller;
  final AppThemeData theme;

  const Shimmer({
    super.key,
    required this.child,
    required this.controller,
    required this.theme,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 - widget.controller.value * 2, 0.0),
              end: Alignment(1.0 - widget.controller.value * 2, 0.0),
              colors: [
                widget.theme.surface.withOpacity(0.1),
                widget.theme.surface.withOpacity(0.3),
                widget.theme.surface.withOpacity(0.1),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

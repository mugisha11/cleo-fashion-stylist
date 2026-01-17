import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/fashion_scaffold.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../../../core/services/vton_service.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../../../routes.dart';

/// Mobile-Only AI Virtual Try-On Screen
/// Professional fashion-grade UI with real user photo processing
class MobileVTONScreen extends ConsumerStatefulWidget {
  const MobileVTONScreen({super.key});

  @override
  ConsumerState<MobileVTONScreen> createState() => _MobileVTONScreenState();
}

class _MobileVTONScreenState extends ConsumerState<MobileVTONScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _userPhoto;
  Uint8List? _userPhotoBytes;
  WardrobeItemModel? _selectedClothing;
  bool _isProcessing = false;
  String? _resultUrl;
  double _beforeAfterSlider = 0.5;
  Map<String, dynamic>? _qualityMetrics;
  String? _processingStage;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
        preferredCameraDevice: CameraDevice.front,
      );
      
      if (image != null) {
        setState(() {
          if (kIsWeb) {
            image.readAsBytes().then((bytes) {
              if (mounted) {
                setState(() {
                  _userPhotoBytes = bytes;
                  _userPhoto = null;
                  _resultUrl = null;
                });
              }
            });
          } else {
            _userPhoto = File(image.path);
            _userPhotoBytes = null;
            _resultUrl = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to capture photo: $e');
      }
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      
      if (image != null) {
        setState(() {
          if (kIsWeb) {
            image.readAsBytes().then((bytes) {
              if (mounted) {
                setState(() {
                  _userPhotoBytes = bytes;
                  _userPhoto = null;
                  _resultUrl = null;
                });
              }
            });
          } else {
            _userPhoto = File(image.path);
            _userPhotoBytes = null;
            _resultUrl = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to pick photo: $e');
      }
    }
  }

  Future<void> _processTryOn() async {
    if (_userPhoto == null && _userPhotoBytes == null) {
      _showError('Please capture or select your photo');
      return;
    }

    if (_selectedClothing == null) {
      _showError('Please select a clothing item');
      return;
    }

    setState(() {
      _isProcessing = true;
      _resultUrl = null;
      _qualityMetrics = null;
      _processingStage = 'Uploading photos...';
      _progressController.reset();
      _progressController.forward();
    });

    try {
      // Check if widget is still mounted before using ref
      if (!mounted) return;
      
      final vtonService = ref.read(vtonServiceProvider);
      
      // Upload user photo
      String userPhotoUrl;
      if (kIsWeb && _userPhotoBytes != null) {
        userPhotoUrl = await vtonService.uploadUserPhoto(_userPhotoBytes!);
      } else if (_userPhoto != null) {
        userPhotoUrl = await vtonService.uploadUserPhoto(_userPhoto!);
      } else {
        throw Exception('No photo available');
      }

      // Check again after async operation
      if (!mounted) return;

      setState(() {
        _processingStage = 'Generating try-on...';
      });

      // Process try-on with Nano Banana (Gemini image generation)
      final result = await vtonService.processTryOn(
        userImageUrl: userPhotoUrl,
        clothingImageUrl: _selectedClothing!.imageUrl,
        preserveFace: true,
        preserveResolution: true,
        useDiffusion: false,
      );
      
      // Check again after async operation
      if (!mounted) return;

      if (mounted) {
        setState(() {
          _isProcessing = false;
          // Try multiple possible field names for result URL
          _resultUrl = result['result_url'] as String? ?? 
                      result['result_image_url'] as String? ??
                      result['image_url'] as String?;
          
          // If no URL but we have base64, create data URL
          if (_resultUrl == null && result['result_image_base64'] != null) {
            final base64 = result['result_image_base64'] as String;
            // Remove data:image prefix if present
            final cleanBase64 = base64.contains(',') ? base64.split(',')[1] : base64;
            _resultUrl = 'data:image/png;base64,$cleanBase64';
          }
          
          _qualityMetrics = result['quality_scores'] as Map<String, dynamic>? ??
                           result['metrics'] as Map<String, dynamic>?;
          _processingStage = null;
          _progressController.forward();
        });

        final faceSimilarity = result['face_similarity'] as double? ?? 
                              (result['quality_scores'] as Map<String, dynamic>?)?.['face_similarity'] as double? ??
                              0.0;
        final modelUsed = result['model_used'] as String? ?? 
                         (result['stages'] as Map<String, dynamic>?)?.['stage5']?['model'] as String? ??
                         'nano-banana';
        
        if (mounted) {
          _showSuccess('Try-on complete!');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingStage = null;
          _progressController.reset();
        });
        _showError('Try-on failed: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: FashionDesignSystem.errorColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: FashionDesignSystem.primaryColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wardrobeAsync = ref.watch(wardrobeItemsProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    return FashionScaffold(
      title: 'Virtual Try-On',
      currentBottomNavIndex: 2,
      currentRoute: Routes.tryon,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Step 1: User Photo Section
              _buildPhotoSection(screenHeight),
              
              SizedBox(height: FashionDesignSystem.spacingLG),
              
              // Step 2: Clothing Selection
              _buildClothingSection(wardrobeAsync),
              
              SizedBox(height: FashionDesignSystem.spacingLG),
              
              // Step 3: Process Button
              if (_userPhoto != null || _userPhotoBytes != null)
                if (_selectedClothing != null)
                  _buildProcessButton(),
              
              SizedBox(height: FashionDesignSystem.spacingLG),
              
              // Step 4: Processing Indicator
              if (_isProcessing) _buildProcessingIndicator(),
              
              SizedBox(height: FashionDesignSystem.spacingLG),
              
              // Step 5: Result with Before/After
              if (_resultUrl != null) _buildResultSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(double screenHeight) {
    return Container(
      margin: EdgeInsets.all(FashionDesignSystem.spacingMD),
      padding: EdgeInsets.all(FashionDesignSystem.spacingLG),
      decoration: BoxDecoration(
        color: FashionDesignSystem.backgroundWhite,
        borderRadius: BorderRadius.circular(FashionDesignSystem.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.camera_alt,
                color: FashionDesignSystem.primaryColor,
                size: 24,
              ),
              SizedBox(width: FashionDesignSystem.spacingSM),
              Text(
                'Your Photo',
                style: FashionDesignSystem.headlineSmall().copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: FashionDesignSystem.spacingMD),
          if (_userPhoto == null && _userPhotoBytes == null)
            _buildPhotoPlaceholder(screenHeight * 0.35)
          else
            _buildPhotoPreview(screenHeight * 0.35),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPhotoPlaceholder(double height) {
    return GestureDetector(
      onTap: () => _showPhotoSourceDialog(),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: FashionDesignSystem.backgroundLight,
          borderRadius: BorderRadius.circular(FashionDesignSystem.radiusLG),
          border: Border.all(
            color: FashionDesignSystem.borderColor,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(FashionDesignSystem.spacingLG),
              decoration: BoxDecoration(
                color: FashionDesignSystem.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_a_photo,
                size: 48,
                color: FashionDesignSystem.primaryColor,
              ),
            ),
            SizedBox(height: FashionDesignSystem.spacingMD),
            Text(
              'Tap to add your photo',
              style: FashionDesignSystem.titleMedium().copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: FashionDesignSystem.spacingXS),
            Text(
              'Face-forward, full body recommended',
              style: FashionDesignSystem.bodySmall().copyWith(
                color: FashionDesignSystem.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(double height) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(FashionDesignSystem.radiusLG),
          child: kIsWeb && _userPhotoBytes != null
              ? Image.memory(
                  _userPhotoBytes!,
                  height: height,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : _userPhoto != null
                  ? Image.file(
                      _userPhoto!,
                      height: height,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : const SizedBox(),
        ),
        Positioned(
          top: FashionDesignSystem.spacingSM,
          right: FashionDesignSystem.spacingSM,
          child: Material(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () {
                setState(() {
                  _userPhoto = null;
                  _userPhotoBytes = null;
                  _resultUrl = null;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClothingSection(AsyncValue<List<WardrobeItemModel>> wardrobeAsync) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: FashionDesignSystem.spacingMD),
      padding: EdgeInsets.all(FashionDesignSystem.spacingLG),
      decoration: BoxDecoration(
        color: FashionDesignSystem.backgroundWhite,
        borderRadius: BorderRadius.circular(FashionDesignSystem.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.checkroom,
                color: FashionDesignSystem.primaryColor,
                size: 24,
              ),
              SizedBox(width: FashionDesignSystem.spacingSM),
              Text(
                'Select Clothing',
                style: FashionDesignSystem.headlineSmall().copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: FashionDesignSystem.spacingMD),
          wardrobeAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return _buildEmptyWardrobe();
              }
              return _buildClothingGrid(items);
            },
            loading: () => Center(
              child: Padding(
                padding: EdgeInsets.all(FashionDesignSystem.spacingXXL),
                child: CircularProgressIndicator(
                  color: FashionDesignSystem.primaryColor,
                ),
              ),
            ),
            error: (error, _) => Padding(
              padding: EdgeInsets.all(FashionDesignSystem.spacingLG),
              child: Text(
                'Error loading wardrobe: $error',
                style: FashionDesignSystem.bodyMedium().copyWith(
                  color: FashionDesignSystem.errorColor,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildEmptyWardrobe() {
    return Container(
      padding: EdgeInsets.all(FashionDesignSystem.spacingXXL),
      child: Column(
        children: [
          Icon(
            Icons.checkroom_outlined,
            size: 64,
            color: FashionDesignSystem.textTertiary,
          ),
          SizedBox(height: FashionDesignSystem.spacingMD),
          Text(
            'No items in wardrobe',
            style: FashionDesignSystem.titleMedium(),
          ),
          SizedBox(height: FashionDesignSystem.spacingSM),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(Routes.addItem);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Clothing'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FashionDesignSystem.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: FashionDesignSystem.spacingLG,
                vertical: FashionDesignSystem.spacingMD,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClothingGrid(List<WardrobeItemModel> items) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = _selectedClothing?.id == item.id;
          
          return GestureDetector(
            onTap: () async {
              setState(() {
                _selectedClothing = item;
                _resultUrl = null;
              });
              HapticFeedback.selectionClick();
              
              // Auto-trigger try-on if user photo is already uploaded
              if ((_userPhoto != null || _userPhotoBytes != null) && !_isProcessing) {
                // Small delay to show selection feedback
                await Future.delayed(const Duration(milliseconds: 300));
                if (mounted && _selectedClothing?.id == item.id) {
                  await _processTryOn();
                }
              }
            },
            child: Container(
              width: 160,
              margin: EdgeInsets.only(right: FashionDesignSystem.spacingMD),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(FashionDesignSystem.radiusMD),
                border: Border.all(
                  color: isSelected
                      ? FashionDesignSystem.primaryColor
                      : FashionDesignSystem.borderColor,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: FashionDesignSystem.primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(FashionDesignSystem.radiusMD),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (isSelected)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: FashionDesignSystem.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(FashionDesignSystem.radiusMD),
                        ),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: FashionDesignSystem.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ).animate().scale(duration: 200.ms, begin: const Offset(0.95, 0.95));
        },
      ),
    );
  }

  Widget _buildProcessButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: FashionDesignSystem.spacingLG),
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processTryOn,
        style: ElevatedButton.styleFrom(
          backgroundColor: FashionDesignSystem.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: FashionDesignSystem.spacingLG,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FashionDesignSystem.radiusMD),
          ),
          elevation: 6,
          shadowColor: FashionDesignSystem.primaryColor.withOpacity(0.4),
        ),
        child: _isProcessing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: FashionDesignSystem.spacingMD),
                  Text(
                    'Processing...',
                    style: FashionDesignSystem.bodyLarge().copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 24),
                  SizedBox(width: FashionDesignSystem.spacingMD),
                  Text(
                    'Try On',
                    style: FashionDesignSystem.bodyLarge().copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildProcessingIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: FashionDesignSystem.spacingLG),
      padding: EdgeInsets.all(FashionDesignSystem.spacingLG),
      decoration: BoxDecoration(
        color: FashionDesignSystem.backgroundWhite,
        borderRadius: BorderRadius.circular(FashionDesignSystem.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_processingStage != null)
            Text(
              _processingStage!,
              style: FashionDesignSystem.bodyMedium().copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          SizedBox(height: FashionDesignSystem.spacingMD),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: FashionDesignSystem.backgroundLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  FashionDesignSystem.primaryColor,
                ),
                minHeight: 4,
              );
            },
          ),
          SizedBox(height: FashionDesignSystem.spacingSM),
          Text(
            'AI is processing your try-on...',
            style: FashionDesignSystem.bodySmall().copyWith(
              color: FashionDesignSystem.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildResultSection() {
    return Container(
      margin: EdgeInsets.all(FashionDesignSystem.spacingMD),
      padding: EdgeInsets.all(FashionDesignSystem.spacingLG),
      decoration: BoxDecoration(
        color: FashionDesignSystem.backgroundWhite,
        borderRadius: BorderRadius.circular(FashionDesignSystem.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: FashionDesignSystem.primaryColor,
                size: 24,
              ),
              SizedBox(width: FashionDesignSystem.spacingSM),
              Text(
                'Result',
                style: FashionDesignSystem.headlineSmall().copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: FashionDesignSystem.spacingMD),
          
          // Before/After Slider
          _buildBeforeAfterSlider(),
          
          SizedBox(height: FashionDesignSystem.spacingMD),
          
          // Quality Metrics
          if (_qualityMetrics != null) _buildQualityMetrics(),
          
          SizedBox(height: FashionDesignSystem.spacingMD),
          
          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildBeforeAfterSlider() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(FashionDesignSystem.radiusLG),
          child: AspectRatio(
            aspectRatio: 0.75,
            child: Stack(
              children: [
                // Before (original)
                if (_userPhoto != null || _userPhotoBytes != null)
                  Positioned.fill(
                    child: kIsWeb && _userPhotoBytes != null
                        ? Image.memory(_userPhotoBytes!, fit: BoxFit.cover)
                        : _userPhoto != null
                            ? Image.file(_userPhoto!, fit: BoxFit.cover)
                            : const SizedBox(),
                  ),
                
                // After (result) - clipped based on slider
                Positioned.fill(
                  child: ClipRect(
                    clipper: _SliderClipper(_beforeAfterSlider),
                    child: _buildResultImage(_resultUrl!),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Slider Control
        Positioned.fill(
          child: GestureDetector(
            onPanUpdate: (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              final width = box.size.width;
              final newValue = (localPosition.dx / width).clamp(0.0, 1.0);
              setState(() {
                _beforeAfterSlider = newValue;
              });
              HapticFeedback.selectionClick();
            },
            child: Container(
              alignment: Alignment(_beforeAfterSlider * 2 - 1, 0),
              child: Container(
                width: 4,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build result image widget that handles both URLs and base64
  Widget _buildResultImage(String imageUrl) {
    // Check if it's a data URL (base64)
    if (imageUrl.startsWith('data:image')) {
      try {
        // Extract base64 data
        final base64String = imageUrl.contains(',') ? imageUrl.split(',')[1] : imageUrl;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.error, color: Colors.red),
            );
          },
        );
      } catch (e) {
        return const Center(
          child: Icon(Icons.error, color: Colors.red),
        );
      }
    } else {
      // Regular network URL
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.error, color: Colors.red),
        ),
      );
    }
  }

  Widget _buildQualityMetrics() {
    final metrics = _qualityMetrics!;
    return Container(
      padding: EdgeInsets.all(FashionDesignSystem.spacingMD),
      decoration: BoxDecoration(
        color: FashionDesignSystem.backgroundLight,
        borderRadius: BorderRadius.circular(FashionDesignSystem.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quality Metrics',
            style: FashionDesignSystem.titleMedium().copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: FashionDesignSystem.spacingSM),
          _buildMetricRow(
            'Face Similarity',
            metrics['face_similarity'] ?? 0.0,
            isCritical: true,
          ),
          _buildMetricRow(
            'Sharpness',
            metrics['sharpness'] ?? 0.0,
          ),
          _buildMetricRow(
            'Pose Accuracy',
            metrics['pose_accuracy'] ?? 0.0,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, double value, {bool isCritical = false}) {
    final percentage = (value * 100).toStringAsFixed(1);
    final color = isCritical && value < 0.99
        ? FashionDesignSystem.errorColor
        : value >= 0.8
            ? Colors.green
            : value >= 0.6
                ? Colors.orange
                : FashionDesignSystem.errorColor;
    
    return Padding(
      padding: EdgeInsets.only(bottom: FashionDesignSystem.spacingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: FashionDesignSystem.bodySmall(),
          ),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: FashionDesignSystem.backgroundLight,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
              SizedBox(width: FashionDesignSystem.spacingSM),
              Text(
                '$percentage%',
                style: FashionDesignSystem.bodySmall().copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.share,
          label: 'Share',
          onPressed: () {
            // TODO: Implement share
            HapticFeedback.mediumImpact();
          },
        ),
        _buildActionButton(
          icon: Icons.download,
          label: 'Save',
          onPressed: () {
            // TODO: Implement save
            HapticFeedback.mediumImpact();
          },
        ),
        _buildActionButton(
          icon: Icons.refresh,
          label: 'Try Another',
          onPressed: () {
            setState(() {
              _resultUrl = null;
              _selectedClothing = null;
              _qualityMetrics = null;
            });
            HapticFeedback.mediumImpact();
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: FashionDesignSystem.spacingXS),
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(label),
          style: TextButton.styleFrom(
            foregroundColor: FashionDesignSystem.textCharcoal,
            padding: EdgeInsets.symmetric(
              vertical: FashionDesignSystem.spacingMD,
            ),
          ),
        ),
      ),
    );
  }

  void _showPhotoSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: FashionDesignSystem.backgroundWhite,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(FashionDesignSystem.radiusXL),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: FashionDesignSystem.spacingMD),
                decoration: BoxDecoration(
                  color: FashionDesignSystem.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FashionDesignSystem.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: FashionDesignSystem.primaryColor,
                  ),
                ),
                title: Text(
                  'Take Photo',
                  style: FashionDesignSystem.bodyMedium().copyWith(
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
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FashionDesignSystem.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.photo_library,
                    color: FashionDesignSystem.primaryColor,
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: FashionDesignSystem.bodyMedium().copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto();
                },
              ),
              SizedBox(height: FashionDesignSystem.spacingMD),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom clipper for before/after slider effect
class _SliderClipper extends CustomClipper<Rect> {
  final double sliderValue;

  _SliderClipper(this.sliderValue);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(
      size.width * sliderValue,
      0,
      size.width * (1 - sliderValue),
      size.height,
    );
  }

  @override
  bool shouldReclip(_SliderClipper oldClipper) {
    return oldClipper.sliderValue != sliderValue;
  }
}

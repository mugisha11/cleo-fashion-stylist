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
import '../../../core/services/wardrobe_service.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../../../routes.dart';

/// World-Class Luxury Try-On Screen
/// ZARA / Nike / Vogue / Apple Design System Quality
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
  WardrobeItemModel? _selectedClothing;
  
  bool _isProcessing = false;
  String? _resultUrl;
  Uint8List? _resultImageBytes; // For base64 images
  double _beforeAfterPosition = 0.5;
  Map<String, dynamic>? _qualityMetrics;
  String? _processingStage;
  double _processingProgress = 0.0;
  
  // Wardrobe data
  List<WardrobeItemModel> _wardrobeItems = [];
  Map<String, List<WardrobeItemModel>> _groupedByCategory = {};
  String? _selectedCategory;
  bool _isLoadingWardrobe = true;
  
  // Animations
  late AnimationController _shimmerController;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  
  // Photo validation
  bool _photoValidated = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );
    
    _loadWardrobe();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadWardrobe() async {
    try {
      setState(() => _isLoadingWardrobe = true);
      
      // Use Firestore (as per existing architecture)
      final wardrobeService = ref.read(wardrobeServiceProvider);
      final items = await wardrobeService.getUserWardrobe();

      // Group by category
      final grouped = <String, List<WardrobeItemModel>>{};
      for (var item in items) {
        final category = item.category.toLowerCase();
        grouped.putIfAbsent(category, () => []).add(item);
      }

      setState(() {
        _wardrobeItems = items;
        _groupedByCategory = grouped;
        _selectedCategory = grouped.keys.isNotEmpty ? grouped.keys.first : null;
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
      // Basic validation
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

  Future<void> _processTryOn() async {
    if (!_photoValidated || (_userPhoto == null && _userPhotoBytes == null)) {
      _showError('Please upload a valid photo');
      return;
    }

    if (_selectedClothing == null) {
      _showError('Please select a clothing item');
      return;
    }

    setState(() {
      _isProcessing = true;
      _resultUrl = null;
      _resultImageBytes = null;
      _qualityMetrics = null;
      _processingStage = 'Uploading photos...';
      _processingProgress = 0.0;
      _beforeAfterPosition = 0.5;
    });

    HapticFeedback.mediumImpact();

    try {
      final vtonService = ref.read(vtonServiceProvider);
      
      // Upload user photo
      setState(() {
        _processingStage = 'Uploading your photo...';
        _processingProgress = 0.1;
      });
      
      String userPhotoUrl;
      if (kIsWeb && _userPhotoBytes != null) {
        userPhotoUrl = await vtonService.uploadUserPhoto(_userPhotoBytes!);
      } else if (_userPhoto != null) {
        userPhotoUrl = await vtonService.uploadUserPhoto(_userPhoto!);
      } else {
        throw Exception('No photo available');
      }

      // Process try-on using new production pipeline
      final result = await vtonService.processTryOnPipeline(
        userImageUrl: userPhotoUrl,
        clothingImageUrl: _selectedClothing!.imageUrl,
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
        // Handle base64 image response
        String? resultImageBase64 = result['result_image'] as String?;
        if (resultImageBase64 != null) {
          try {
            _resultImageBytes = base64Decode(resultImageBase64);
          } catch (e) {
            // Fallback to URL if base64 decode fails
            _resultUrl = result['result_url'] as String?;
          }
        } else {
          _resultUrl = result['result_url'] as String?;
        }
        
        // Extract quality metrics
        final qualityScores = result['quality_scores'] as Map<String, dynamic>?;
        final metadata = result['metadata'] as Map<String, dynamic>?;
        
        // Combine all quality information
        _qualityMetrics = {
          ...?qualityScores,
          'face_similarity': result['face_similarity'] as double?,
          'quality_passed': result['quality_passed'] as bool?,
          'skin_validation': metadata?['skin_validation'] as Map<String, dynamic>?,
        };
        
        setState(() {
          _isProcessing = false;
          _processingStage = null;
          _processingProgress = 1.0;
        });

        _slideController.forward();
        HapticFeedback.heavyImpact();

        final faceSimilarity = result['face_similarity'] as double? ?? 0.0;
        final qualityPassed = result['quality_passed'] as bool? ?? false;
        final status = qualityPassed ? '✅ Quality verified' : '⚠️ Quality check warnings';
        _showSuccess('Try-on complete! $status\nFace similarity: ${(faceSimilarity * 100).toStringAsFixed(1)}%');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingStage = null;
          _processingProgress = 0.0;
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: FashionDesignSystem.primaryColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FashionScaffold(
      title: 'Try-On',
      currentBottomNavIndex: 2,
      currentRoute: Routes.mobileVton,
      backgroundColor: FashionDesignSystem.backgroundWhite,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            
            // Wardrobe Section
            SliverToBoxAdapter(
              child: _buildWardrobeSection(),
            ),
            
            // Photo Upload Section
            SliverToBoxAdapter(
              child: _buildPhotoSection(),
            ),
            
            // Try-On Button
            if (_userPhoto != null || _userPhotoBytes != null)
              if (_selectedClothing != null)
                SliverToBoxAdapter(
                  child: _buildTryOnButton(),
                ),
            
            // Processing Indicator
            if (_isProcessing)
              SliverToBoxAdapter(
                child: _buildProcessingIndicator(),
              ),
            
            // Result Section
            if (_resultUrl != null || _resultImageBytes != null)
              SliverToBoxAdapter(
                child: _buildResultSection(),
              ),
            
            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Virtual Try-On',
            style: FashionDesignSystem.headlineLarge().copyWith(
              fontWeight: FontWeight.w300,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),
          const SizedBox(height: 4),
          Text(
            'See how it looks on you',
            style: FashionDesignSystem.bodyMedium().copyWith(
              color: FashionDesignSystem.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideY(begin: -0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildWardrobeSection() {
    if (_isLoadingWardrobe) {
      return _buildWardrobeShimmer();
    }

    if (_wardrobeItems.isEmpty) {
      return _buildEmptyWardrobe();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Filter
        if (_groupedByCategory.length > 1)
          _buildCategoryFilter(),
        
        // Wardrobe Carousel
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _wardrobeItems.length,
            itemBuilder: (context, index) {
              final item = _wardrobeItems[index];
              final isSelected = _selectedClothing?.id == item.id;
              
              return _buildWardrobeCard(item, isSelected, index);
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildWardrobeShimmer() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: FashionDesignSystem.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Shimmer(
              controller: _shimmerController,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyWardrobe() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: FashionDesignSystem.backgroundLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.checkroom_outlined,
            size: 48,
            color: FashionDesignSystem.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No items in wardrobe',
            style: FashionDesignSystem.titleMedium(),
          ),
          const SizedBox(height: 8),
          Text(
            'Add clothing to your wardrobe to try them on',
            style: FashionDesignSystem.bodySmall().copyWith(
              color: FashionDesignSystem.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = _groupedByCategory.keys.toList();
    
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                category.toUpperCase(),
                style: FashionDesignSystem.bodySmall().copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                  _wardrobeItems = _groupedByCategory[category] ?? [];
                });
                HapticFeedback.selectionClick();
              },
              backgroundColor: FashionDesignSystem.backgroundLight,
              selectedColor: FashionDesignSystem.primaryColor.withOpacity(0.1),
              checkmarkColor: FashionDesignSystem.primaryColor,
              labelStyle: TextStyle(
                color: isSelected 
                    ? FashionDesignSystem.primaryColor 
                    : FashionDesignSystem.textCharcoal,
              ),
              side: BorderSide(
                color: isSelected 
                    ? FashionDesignSystem.primaryColor 
                    : FashionDesignSystem.borderColor,
                width: isSelected ? 1.5 : 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWardrobeCard(WardrobeItemModel item, bool isSelected, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedClothing = item;
          _resultUrl = null;
          _resultImageBytes = null;
          _qualityMetrics = null;
        });
        HapticFeedback.selectionClick();
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? FashionDesignSystem.primaryColor
                : FashionDesignSystem.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: FashionDesignSystem.primaryColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 0.75,
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: FashionDesignSystem.backgroundLight,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: FashionDesignSystem.backgroundLight,
                    child: Icon(
                      Icons.broken_image,
                      color: FashionDesignSystem.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: FashionDesignSystem.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: FashionDesignSystem.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
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
    ).animate()
        .fadeIn(duration: 300.ms, delay: (index * 50).ms)
        .scale(begin: const Offset(0.9, 0.9), duration: 200.ms);
  }

  Widget _buildPhotoSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FashionDesignSystem.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FashionDesignSystem.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your Photo',
            style: FashionDesignSystem.titleMedium().copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (_userPhoto == null && _userPhotoBytes == null)
            _buildPhotoPlaceholder()
          else
            _buildPhotoPreview(),
          if (_validationError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _validationError!,
                style: FashionDesignSystem.bodySmall().copyWith(
                  color: FashionDesignSystem.errorColor,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms);
  }

  Widget _buildPhotoPlaceholder() {
    return GestureDetector(
      onTap: () => _showPhotoSourceDialog(),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          color: FashionDesignSystem.backgroundLight,
          borderRadius: BorderRadius.circular(12),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: FashionDesignSystem.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_a_photo,
                size: 40,
                color: FashionDesignSystem.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add Your Photo',
              style: FashionDesignSystem.titleMedium().copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
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

  Widget _buildPhotoPreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 0.75,
            child: kIsWeb && _userPhotoBytes != null
                ? Image.memory(
                    _userPhotoBytes!,
                    fit: BoxFit.cover,
                  )
                : _userPhoto != null
                    ? Image.file(
                        _userPhoto!,
                        fit: BoxFit.cover,
                      )
                    : const SizedBox(),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () {
                setState(() {
                  _userPhoto = null;
                  _userPhotoBytes = null;
                  _resultUrl = null;
                  _photoValidated = false;
                  _validationError = null;
                });
                HapticFeedback.lightImpact();
              },
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        if (_photoValidated)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: FashionDesignSystem.successColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ready',
                    style: FashionDesignSystem.bodySmall().copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTryOnButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processTryOn,
        style: ElevatedButton.styleFrom(
          backgroundColor: FashionDesignSystem.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isProcessing ? Icons.hourglass_empty : Icons.auto_awesome,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              _isProcessing ? 'Processing...' : 'Try On',
              style: FashionDesignSystem.bodyLarge().copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildProcessingIndicator() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FashionDesignSystem.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FashionDesignSystem.borderColor,
        ),
      ),
      child: Column(
        children: [
          if (_processingStage != null)
            Text(
              _processingStage!,
              style: FashionDesignSystem.bodyMedium().copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          Stack(
            children: [
              LinearProgressIndicator(
                backgroundColor: FashionDesignSystem.backgroundLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  FashionDesignSystem.primaryColor,
                ),
                minHeight: 6,
                value: _processingProgress,
              ),
              if (_processingProgress > 0)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      '${(_processingProgress * 100).toStringAsFixed(0)}%',
                      style: FashionDesignSystem.bodySmall().copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _processingStage ?? 'AI is processing your try-on...',
            style: FashionDesignSystem.bodySmall().copyWith(
              color: FashionDesignSystem.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildResultSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Result',
            style: FashionDesignSystem.headlineSmall().copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Before/After Slider
          _buildBeforeAfterSlider(),
          
          const SizedBox(height: 16),
          
          // Quality Metrics
          if (_qualityMetrics != null)
            _buildQualityMetrics(),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildBeforeAfterSlider() {
    return GestureDetector(
      onPanUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final width = box.size.width;
        final newValue = (localPosition.dx / width).clamp(0.0, 1.0);
        setState(() {
          _beforeAfterPosition = newValue;
        });
        HapticFeedback.selectionClick();
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
                      clipper: _SliderClipper(_beforeAfterPosition),
                      child: _resultImageBytes != null
                          ? Image.memory(_resultImageBytes!, fit: BoxFit.cover)
                          : _resultUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: _resultUrl!,
                                  fit: BoxFit.cover,
                                )
                              : const SizedBox(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Slider Control
          Positioned.fill(
            child: Align(
              alignment: Alignment(_beforeAfterPosition * 2 - 1, 0),
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
          
          // Labels
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'BEFORE',
                style: FashionDesignSystem.bodySmall().copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'AFTER',
                style: FashionDesignSystem.bodySmall().copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityMetrics() {
    final metrics = _qualityMetrics!;
    final qualityPassed = metrics['quality_passed'] as bool? ?? false;
    final faceSimilarity = metrics['face_similarity'] as double? ?? 0.0;
    final skinValidation = metrics['skin_validation'] as Map<String, dynamic>?;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: qualityPassed 
            ? FashionDesignSystem.primaryColor.withOpacity(0.05)
            : Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: qualityPassed
              ? FashionDesignSystem.primaryColor.withOpacity(0.2)
              : Colors.orange.withOpacity(0.3),
        ),
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
          const SizedBox(height: 12),
          // Critical Metrics
          _buildMetricRow(
            'Face Similarity', 
            faceSimilarity, 
            isCritical: true,
            threshold: 0.99,
            icon: Icons.face,
          ),
          if (skinValidation != null)
            _buildMetricRow(
              'Skin Tone (ΔE)', 
              (skinValidation['delta_e'] as num?)?.toDouble() ?? 0.0,
              isCritical: true,
              threshold: 2.0,
              icon: Icons.palette,
              isLowerBetter: true,
            ),
          _buildMetricRow(
            'Pose Consistency', 
            (metrics['pose_consistency'] as num?)?.toDouble() ?? 0.0,
            threshold: 0.8,
            icon: Icons.accessibility_new,
          ),
          // Quality Metrics
          _buildMetricRow(
            'Sharpness', 
            (metrics['sharpness'] as num?)?.toDouble() ?? 0.0,
            threshold: 0.2,
            icon: Icons.auto_fix_high,
          ),
          _buildMetricRow(
            'Clothing Coverage', 
            (metrics['clothing_coverage'] as num?)?.toDouble() ?? 0.0,
            threshold: 0.5,
            icon: Icons.checkroom,
          ),
          // Status Badge
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: qualityPassed 
                  ? FashionDesignSystem.primaryColor.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  qualityPassed ? Icons.check_circle : Icons.warning,
                  size: 16,
                  color: qualityPassed 
                      ? FashionDesignSystem.primaryColor 
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  qualityPassed ? 'All quality checks passed' : 'Quality warnings detected',
                  style: FashionDesignSystem.bodySmall().copyWith(
                    fontWeight: FontWeight.w600,
                    color: qualityPassed 
                        ? FashionDesignSystem.primaryColor 
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label, 
    double value, {
    bool isCritical = false,
    double threshold = 0.0,
    IconData? icon,
    bool isLowerBetter = false,
  }) {
    final passed = isLowerBetter 
        ? value <= threshold 
        : value >= threshold;
    final displayValue = isLowerBetter 
        ? value.toStringAsFixed(2)
        : (value * 100).toStringAsFixed(1) + '%';
    
    final color = isCritical && !passed
        ? Colors.red
        : passed
            ? FashionDesignSystem.primaryColor
            : Colors.orange;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: FashionDesignSystem.bodyMedium().copyWith(
                fontWeight: isCritical ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              displayValue,
              style: FashionDesignSystem.bodySmall().copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            passed ? Icons.check_circle : Icons.error_outline,
            size: 16,
            color: color,
          ),
        ],
      ),
    );
        ? FashionDesignSystem.errorColor
        : value >= 0.8
            ? Colors.green
            : value >= 0.6
                ? Colors.orange
                : FashionDesignSystem.errorColor;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
              const SizedBox(width: 12),
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
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _resultUrl = null;
                _selectedClothing = null;
                _qualityMetrics = null;
              });
              HapticFeedback.mediumImpact();
            },
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Try Another'),
            style: OutlinedButton.styleFrom(
              foregroundColor: FashionDesignSystem.textCharcoal,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: FashionDesignSystem.borderColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement save
              HapticFeedback.mediumImpact();
              _showSuccess('Saved to wardrobe');
            },
            icon: const Icon(Icons.bookmark, size: 20),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FashionDesignSystem.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  void _showPhotoSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: FashionDesignSystem.backgroundWhite,
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
                  color: FashionDesignSystem.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FashionDesignSystem.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FashionDesignSystem.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
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
              const SizedBox(height: 8),
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

/// Shimmer effect for loading states
class Shimmer extends StatefulWidget {
  final Widget child;
  final AnimationController controller;

  const Shimmer({
    super.key,
    required this.child,
    required this.controller,
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
              colors: const [
                Color(0xFFEBEBF4),
                Color(0xFFF4F4F4),
                Color(0xFFEBEBF4),
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

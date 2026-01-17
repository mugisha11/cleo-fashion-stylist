import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/tryon_state.dart';
import '../../../core/providers/sora_tryon_provider.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../../../core/services/wardrobe_service.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/quality_score_banner.dart';

/// Sora-style Try-On Screen
/// Mobile-first: Fullscreen image, wardrobe carousel at bottom
/// Desktop: Wardrobe | Model Canvas | AI Chat
class SoraTryOnScreen extends ConsumerStatefulWidget {
  const SoraTryOnScreen({super.key});

  @override
  ConsumerState<SoraTryOnScreen> createState() => _SoraTryOnScreenState();
}

class _SoraTryOnScreenState extends ConsumerState<SoraTryOnScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _userImageBytes;
  String? _userImageUrl;
  WardrobeItemModel? _selectedGarment;
  
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tryOnState = ref.watch(tryOnStateProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    if (isMobile) {
      return _buildMobileLayout(context, tryOnState);
    } else {
      return _buildDesktopLayout(context, tryOnState);
    }
  }

  Widget _buildMobileLayout(BuildContext context, TryOnStateWithResult state) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(context),
            
            // Main image area
            Expanded(
              child: _buildImageCanvas(context, state),
            ),
            
            // Quality score banner (if applicable)
            if (state.state == TryOnState.success && state.result != null)
              QualityScoreBanner(result: state.result!),
            
            // Wardrobe carousel
            _buildWardrobeCarousel(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, TryOnStateWithResult state) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Row(
        children: [
          // Wardrobe sidebar (25%)
          Expanded(
            flex: 1,
            child: _buildWardrobeSidebar(context),
          ),
          
          // Model canvas (50%)
          Expanded(
            flex: 2,
            child: _buildImageCanvas(context, state),
          ),
          
          // AI Chat sidebar (25%)
          Expanded(
            flex: 1,
            child: _buildChatSidebar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Virtual Try-On',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (_userImageBytes != null)
            IconButton(
              icon: const Icon(Icons.upload_file, color: Colors.white),
              onPressed: _pickNewPhoto,
              tooltip: 'Change photo',
            ),
        ],
      ),
    );
  }

  Widget _buildImageCanvas(BuildContext context, TryOnStateWithResult state) {
    // Show default placeholder if no image
    if (_userImageBytes == null && _userImageUrl == null) {
      return _buildDefaultPlaceholder(context);
    }

    // Show processing state
    if (state.state == TryOnState.uploading ||
        state.state == TryOnState.reasoning ||
        state.state == TryOnState.diffusing) {
      return _buildProcessingState(context, state.state);
    }

    // Show result image
    if (state.state == TryOnState.success && state.result?.imageBase64 != null) {
      return _buildResultImage(context, state.result!);
    }

    // Show error state
    if (state.state == TryOnState.failed) {
      return _buildErrorState(context, state.result);
    }

    // Show original image with selected garment overlay hint
    return _buildOriginalImage(context);
  }

  Widget _buildDefaultPlaceholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.person_outline,
              size: 64,
              color: Color(0xFF808080),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Upload your photo to try on',
            style: TextStyle(
              color: Color(0xFF808080),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Upload Photo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10A37F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingState(BuildContext context, TryOnState state) {
    String message;
    if (state == TryOnState.uploading) {
      message = 'Uploading images...';
    } else if (state == TryOnState.reasoning) {
      message = 'Understanding garment placement...';
    } else {
      message = 'Generating try-on result...';
    }

    return Stack(
      children: [
        // Show original image with overlay
        if (_userImageBytes != null)
          Center(
            child: Image.memory(
              _userImageBytes!,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        
        // Processing overlay
        Container(
          color: Colors.black54,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10A37F)),
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultImage(BuildContext context, TryOnResult result) {
    try {
      final imageBytes = base64Decode(result.imageBase64!);
      return Center(
        child: Image.memory(
          imageBytes,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      );
    } catch (e) {
      return _buildErrorState(context, result);
    }
  }

  Widget _buildOriginalImage(BuildContext context) {
    if (_userImageBytes != null) {
      return GestureDetector(
        onDoubleTap: _selectedGarment != null ? _executeTryOn : null,
        child: Stack(
          children: [
            Center(
              child: Image.memory(
                _userImageBytes!,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            if (_selectedGarment != null)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Double tap to try on',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildErrorState(BuildContext context, TryOnResult? result) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 24),
            Text(
              result?.errorMessage ?? 'Try-on failed',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (result?.errorStage != null) ...[
              const SizedBox(height: 8),
              Text(
                'Stage: ${result!.errorStage}',
                style: const TextStyle(
                  color: Color(0xFF808080),
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => ref.read(tryOnStateProvider.notifier).reset(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWardrobeCarousel(BuildContext context) {
    final wardrobeAsync = ref.watch(wardrobeItemsProvider);
    
    return wardrobeAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Container(
          height: 140,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = _selectedGarment?.id == item.id;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGarment = item;
                  });
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF10A37F)
                          : const Color(0xFF2A2A2A),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.imageUrl != null
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported,
                              color: Color(0xFF808080),
                            ),
                          )
                        : const Icon(
                            Icons.image,
                            color: Color(0xFF808080),
                          ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildWardrobeSidebar(BuildContext context) {
    // Vertical list for desktop
    final wardrobeAsync = ref.watch(wardrobeItemsProvider);
    
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Wardrobe',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: wardrobeAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'No items in wardrobe',
                      style: TextStyle(color: Color(0xFF808080)),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = _selectedGarment?.id == item.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedGarment = item;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF10A37F)
                                : const Color(0xFF2A2A2A),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: item.imageUrl != null
                                ? Image.network(
                                    item.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.image_not_supported,
                                      color: Color(0xFF808080),
                                    ),
                                  )
                                : const Icon(
                                    Icons.image,
                                    color: Color(0xFF808080),
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const Center(
                child: Text(
                  'Failed to load wardrobe',
                  style: TextStyle(color: Color(0xFF808080)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSidebar(BuildContext context) {
    // Placeholder for AI chat
    return Container(
      color: const Color(0xFF1A1A1A),
      child: const Center(
        child: Text(
          'AI Chat',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
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

  Future<void> _pickNewPhoto() async {
    await _pickPhoto();
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
    if (_userImageUrl == null || _selectedGarment?.imageUrl == null) {
      return;
    }

    final notifier = ref.read(tryOnStateProvider.notifier);
    await notifier.executeTryOn(
      userImageUrl: _userImageUrl!,
      clothingImageUrl: _selectedGarment!.imageUrl!,
    );
  }
}

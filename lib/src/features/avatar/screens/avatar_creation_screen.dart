import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/utils/file_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/platform_image.dart';
import '../providers/avatar_provider.dart';
import '../../../routes.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AvatarCreationScreen extends ConsumerStatefulWidget {
  const AvatarCreationScreen({super.key});

  @override
  ConsumerState<AvatarCreationScreen> createState() => _AvatarCreationScreenState();
}

class _AvatarCreationScreenState extends ConsumerState<AvatarCreationScreen> {
  io.File? _selectedImage;
  Uint8List? _selectedImageBytes; // For web compatibility
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        if (kIsWeb) {
          // For web, read bytes from XFile
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null;
          });
        } else {
          setState(() {
            _selectedImage = createPlatformFile(image.path) as io.File?;
            _selectedImageBytes = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _generateAvatar() async {
    if (_selectedImage == null && _selectedImageBytes == null) return;

    // Pass bytes for web, file for mobile
    if (kIsWeb && _selectedImageBytes != null) {
      await ref.read(avatarGenerationProvider.notifier).generateAvatar(_selectedImageBytes!);
    } else if (!kIsWeb && _selectedImage != null) {
      await ref.read(avatarGenerationProvider.notifier).generateAvatar(_selectedImage!);
    }
  }

  void _continueToHome() {
    Navigator.of(context).pushReplacementNamed(Routes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final avatarState = ref.watch(avatarGenerationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Virtual Twin'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Upload a selfie to create your virtual twin',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 16),
            Text(
              'We\'ll use AI to generate a realistic 3D avatar of you',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
            const SizedBox(height: 48),
            // Image picker/display
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: (_selectedImageBytes != null || (!kIsWeb && _selectedImage != null))
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: PlatformImage(
                          file: kIsWeb ? null : _selectedImage, // Never pass file on web
                          bytes: _selectedImageBytes,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to take a selfie',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
              ),
            ).animate().scale(duration: 300.ms, delay: 200.ms),
            const SizedBox(height: 32),
            // Generate button
            if ((_selectedImage != null || _selectedImageBytes != null) && !avatarState.isLoading)
              ElevatedButton(
                onPressed: _generateAvatar,
                child: const Text('Generate Avatar'),
              ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 24),
            // Avatar result display
            avatarState.when(
              loading: () => _buildLoadingState(),
              success: (modelUrl, previewUrl, isFallback) => _buildSuccessState(
                modelUrl: modelUrl,
                previewUrl: previewUrl,
                isFallback: isFallback,
              ),
              error: (error) => _buildErrorState(error),
              initial: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Generating your virtual twin...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few moments',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSuccessState({
    required String? modelUrl,
    required String previewUrl,
    required bool isFallback,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isFallback ? '2D Avatar Created' : '3D Avatar Created!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              child: modelUrl != null && !isFallback
                  ? ModelViewer(
                      src: modelUrl,
                      alt: '3D Avatar',
                      ar: true,
                      autoRotate: true,
                      cameraControls: true,
                    )
                  : CachedNetworkImage(
                      imageUrl: previewUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const SkeletonLoader(
                        width: double.infinity,
                        height: 300,
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _continueToHome,
              child: const Text('Continue to App'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
          duration: 300.ms,
          begin: const Offset(0.95, 0.95),
        );
  }

  Widget _buildErrorState(String error) {
    return AppErrorWidget(
      message: error,
      onRetry: () {
        if (_selectedImage != null || _selectedImageBytes != null) {
          _generateAvatar();
        }
      },
    );
  }
}

extension AvatarStateExtension on AvatarGenerationState {
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(String? modelUrl, String previewUrl, bool isFallback) success,
    required T Function(String error) error,
  }) {
    if (isLoading) {
      return loading();
    } else if (this.error != null) {
      return error(this.error!);
    } else if (previewUrl != null) {
      return success(modelUrl, previewUrl!, isFallback);
    } else {
      return initial();
    }
  }
}


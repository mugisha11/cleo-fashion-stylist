import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/vton_service.dart';
import '../../../core/services/mediapipe_service.dart';
import 'outfit_source_screen.dart';

/// Photo capture screen with quality checks
class PhotoCaptureScreen extends ConsumerStatefulWidget {
  const PhotoCaptureScreen({super.key});

  @override
  ConsumerState<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends ConsumerState<PhotoCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String? _qualityMessage;

  Future<void> _capturePhoto(ImageSource source) async {
    setState(() {
      _isProcessing = true;
      _qualityMessage = null;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 95, // High quality
      );

      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      // Check quality using MediaPipe
      final qualityResult = await ref
          .read(mediapipeServiceProvider)
          .checkPhotoQuality(await image.readAsBytes());

      if (!qualityResult.isHighQuality) {
        setState(() {
          _qualityMessage = qualityResult.message;
          _isProcessing = false;
        });
        _showQualityWarning(qualityResult);
        return;
      }

      // Upload photo
      final photoUrl = await ref.read(vtonServiceProvider).uploadUserPhoto(
            await image.readAsBytes(),
          );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OutfitSourceScreen(photoUrl: photoUrl),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showQualityWarning(QualityResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Photo Quality Warning'),
        content: Text(result.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Retake'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Allow proceed anyway
            },
            child: const Text('Use Anyway'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text('Take Your Photo'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_rounded,
                size: 80,
                color: Color(0xFF8C7AE6),
              ),
              const SizedBox(height: 24),
              const Text(
                'Capture Your Photo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'For best results, use a full-body photo with good lighting',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              if (_qualityMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _qualityMessage!,
                          style: TextStyle(color: Colors.orange[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              _CaptureButton(
                icon: Icons.camera_alt_rounded,
                label: 'Take Photo',
                onTap: _isProcessing
                    ? null
                    : () => _capturePhoto(ImageSource.camera),
                isLoading: _isProcessing,
              ),
              const SizedBox(height: 16),
              _CaptureButton(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
                onTap: _isProcessing
                    ? null
                    : () => _capturePhoto(ImageSource.gallery),
                isLoading: false,
                isSecondary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isSecondary;

  const _CaptureButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.white : const Color(0xFF8C7AE6),
          foregroundColor: isSecondary ? const Color(0xFF8C7AE6) : Colors.white,
          elevation: isSecondary ? 0 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isSecondary
                ? const BorderSide(color: Color(0xFFE3E6EF))
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}


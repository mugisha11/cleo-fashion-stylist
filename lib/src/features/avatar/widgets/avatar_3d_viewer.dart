import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium 3D Avatar Viewer Widget
/// Renders GLB models with high-quality settings
class Avatar3DViewer extends StatelessWidget {
  final String glbUrl;
  final double? height;
  final bool autoRotate;
  final bool showControls;
  final String? errorMessage;
  final VoidCallback? onError;

  const Avatar3DViewer({
    super.key,
    required this.glbUrl,
    this.height = 400,
    this.autoRotate = true,
    this.showControls = true,
    this.errorMessage,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.grey.shade900,
                  Colors.grey.shade800,
                ]
              : [
                  Colors.grey.shade100,
                  Colors.grey.shade50,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 3D Model Viewer
            ModelViewer(
              src: glbUrl,
              alt: '3D Avatar',
              ar: true,
              autoRotate: autoRotate,
              cameraControls: showControls,
              backgroundColor: Colors.transparent,
              loading: Loading.auto,
              interactionPrompt: InteractionPrompt.auto,
              interactionPromptThreshold: 1000,
              // High quality settings
              skyboxImage: null,
              environmentImage: null,
              // Shadow and lighting
              shadowIntensity: 1.0,
              shadowSoftness: 1.0,
              exposure: 1.0,
              // Animation
              animationName: null,
            ),
            // Loading overlay
            if (errorMessage != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (onError != null) ...[
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: onError,
                          child: const Text('Retry'),
                        ),
                      ],
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms),
          ],
        ),
      ),
    );
  }
}

/// Loading shimmer for avatar preview
class AvatarLoadingShimmer extends StatelessWidget {
  final double? height;

  const AvatarLoadingShimmer({super.key, this.height = 400});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade200,
            Colors.grey.shade300,
          ],
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1500.ms);
  }
}


import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Platform-aware image widget that handles web and mobile differently
/// Completely prevents Image.file errors on web by using factory pattern
class PlatformImage extends StatelessWidget {
  final io.File? file;
  final Uint8List? bytes;
  final BoxFit fit;
  final double? width;
  final double? height;

  const PlatformImage({
    super.key,
    this.file,
    this.bytes,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // On web, ONLY use bytes - completely ignore file
    if (kIsWeb) {
      return _buildWebImage();
    }

    // On mobile/desktop, use file if available
    return _buildMobileImage();
  }

  // Web-specific implementation - never references Image.file
  Widget _buildWebImage() {
    if (bytes != null) {
      return Image.memory(
        bytes!,
        fit: fit,
        width: width,
        height: height,
      );
    }
    // No file support on web - return placeholder
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 48),
      ),
    );
  }

  // Mobile-specific implementation
  Widget _buildMobileImage() {
    // Use bytes if available (works on both platforms)
    if (bytes != null) {
      return Image.memory(
        bytes!,
        fit: fit,
        width: width,
        height: height,
      );
    }

    // Only use file on mobile - this code path is never reached on web
    if (file == null) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 48),
        ),
      );
    }

    // Final safety check - this should never be true on mobile
    if (kIsWeb) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: Icon(Icons.error_outline, size: 48),
        ),
      );
    }

    // Use a factory method that creates the file image widget
    // This isolates Image.file from the widget tree
    return _createFileImageWidget();
  }

  // Factory method to create Image.file widget
  // This is only called when we're absolutely certain we're not on web
  Widget _createFileImageWidget() {
    // Triple-check we're not on web (defensive programming)
    if (kIsWeb) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: Icon(Icons.error_outline, size: 48),
        ),
      );
    }

    if (file == null) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 48),
        ),
      );
    }

    // At this point:
    // - We're guaranteed !kIsWeb (multiple checks above)
    // - file is not null
    // - io.File is dart:io.File (not html.File due to conditional import)
    
    // Create Image.file widget using a helper that further isolates it
    return _buildFileImageHelper();
  }

  // Helper method that actually creates Image.file
  // This is the ONLY place in the entire codebase where Image.file is called
  Widget _buildFileImageHelper() {
    // Final runtime check
    if (kIsWeb || file == null) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: Icon(Icons.error_outline, size: 48),
        ),
      );
    }

    // Create Image.file widget
    // This will only execute on mobile/desktop platforms
    // The conditional import ensures io.File is dart:io.File here
    // Cast to ensure it's dart:io.File (not dart:html.File)
    return Image.file(
      file! as dynamic,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: Icon(Icons.error_outline, size: 48),
          ),
        );
      },
    );
  }
}

/// Image Resizer Utility
/// Resizes images to fit within maximum dimensions while maintaining aspect ratio
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ImageResizer {
  /// Maximum dimensions for images sent to backend
  static const int maxWidth = 4096;
  static const int maxHeight = 4096;
  
  /// Maximum file size in bytes (10MB)
  static const int maxFileSize = 10 * 1024 * 1024;

  /// Resize image if it exceeds maximum dimensions
  /// Returns resized image bytes, or original if no resize needed
  static Future<Uint8List> resizeIfNeeded(Uint8List imageBytes) async {
    try {
      // Decode image to get dimensions
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      final width = image.width;
      final height = image.height;
      
      // Check if resize is needed
      if (width <= maxWidth && height <= maxHeight && imageBytes.length <= maxFileSize) {
        image.dispose();
        return imageBytes; // No resize needed
      }
      
      // Calculate new dimensions maintaining aspect ratio
      double scale = 1.0;
      if (width > maxWidth || height > maxHeight) {
        final widthScale = maxWidth / width;
        final heightScale = maxHeight / height;
        scale = widthScale < heightScale ? widthScale : heightScale;
      }
      
      final newWidth = (width * scale).round();
      final newHeight = (height * scale).round();
      
      // Resize image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..filterQuality = FilterQuality.high;
      
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
        paint,
      );
      
      image.dispose();
      
      final picture = recorder.endRecording();
      final resizedImage = await picture.toImage(newWidth, newHeight);
      picture.dispose();
      
      // Convert to bytes (JPEG format, quality 90)
      final byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
      resizedImage.dispose();
      
      if (byteData == null) {
        return imageBytes; // Fallback to original
      }
      
      // If still too large, compress further
      var resizedBytes = byteData.buffer.asUint8List();
      if (resizedBytes.length > maxFileSize) {
        // Compress by reducing quality
        resizedBytes = await _compressImage(resizedBytes, newWidth, newHeight);
      }
      
      return resizedBytes;
    } catch (e) {
      // If resize fails, return original
      return imageBytes;
    }
  }
  
  /// Compress image by reducing quality
  static Future<Uint8List> _compressImage(
    Uint8List imageBytes,
    int width,
    int height,
  ) async {
    try {
      // Decode and re-encode with lower quality
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      // Re-encode with compression
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImage(image, Offset.zero, Paint());
      image.dispose();
      
      final picture = recorder.endRecording();
      final compressedImage = await picture.toImage(width, height);
      picture.dispose();
      
      final byteData = await compressedImage.toByteData(format: ui.ImageByteFormat.png);
      compressedImage.dispose();
      
      return byteData?.buffer.asUint8List() ?? imageBytes;
    } catch (e) {
      return imageBytes;
    }
  }
  
  /// Get image dimensions without full decode
  static Future<Map<String, int>> getImageDimensions(Uint8List imageBytes) async {
    try {
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      final dimensions = {
        'width': image.width,
        'height': image.height,
      };
      
      image.dispose();
      return dimensions;
    } catch (e) {
      return {'width': 0, 'height': 0};
    }
  }
}

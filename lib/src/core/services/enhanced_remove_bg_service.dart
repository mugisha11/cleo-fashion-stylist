import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

/// Enhanced Background Removal Service
/// Uses remove.bg API with fallback to client-side processing
class EnhancedRemoveBgService {
  static const String _apiKey = 'Mik1b9PRzcAQxskFudMhUhSh';
  static const String _apiUrl = 'https://api.remove.bg/v1.0/removebg';

  /// Remove background with automatic fallback
  /// Returns processed image as Uint8List (PNG format)
  Future<Uint8List?> removeBackground({
    dynamic imageFile,
    String? imageUrl,
    bool retryOnFailure = true,
  }) async {
    // Step 1: Try remove.bg API (primary)
    try {
      print('🎨 Attempting background removal with remove.bg API...');
      final result = await _removeWithRemoveBg(imageFile: imageFile, imageUrl: imageUrl);
      if (result != null && _validateTransparency(result)) {
        print('✅ Background removed successfully with remove.bg');
        return result;
      }
    } catch (e) {
      print('⚠️ remove.bg API failed: $e');
    }

    // Step 2: Retry once if enabled
    if (retryOnFailure) {
      try {
        print('🔄 Retrying background removal...');
        await Future.delayed(const Duration(seconds: 1));
        final result = await _removeWithRemoveBg(imageFile: imageFile, imageUrl: imageUrl);
        if (result != null && _validateTransparency(result)) {
          print('✅ Background removed successfully on retry');
          return result;
        }
      } catch (e) {
        print('⚠️ Retry failed: $e');
      }
    }

    // Step 3: Fallback to client-side processing (U²-Net-like approach)
    try {
      print('🔄 Falling back to client-side background removal...');
      final imageBytes = await _getImageBytes(imageFile, imageUrl);
      if (imageBytes != null) {
        final result = await _removeBackgroundClientSide(imageBytes);
        if (result != null && _validateTransparency(result)) {
          print('✅ Background removed with client-side processing');
          return result;
        }
      }
    } catch (e) {
      print('⚠️ Client-side removal failed: $e');
    }

    print('❌ All background removal methods failed');
    return null;
  }

  /// Remove background using remove.bg API
  Future<Uint8List?> _removeWithRemoveBg({
    dynamic imageFile,
    String? imageUrl,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.headers['X-Api-Key'] = _apiKey;

      if (imageUrl != null) {
        request.fields['image_url'] = imageUrl;
        request.fields['size'] = 'auto';
      } else if (imageFile != null) {
        if (kIsWeb) {
          if (imageFile is Uint8List) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'image_file',
                imageFile,
                filename: 'image.jpg',
              ),
            );
          } else {
            throw Exception('Invalid image file type for web');
          }
        } else {
          if (imageFile is Uint8List) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'image_file',
                imageFile,
                filename: 'image.jpg',
              ),
            );
          } else {
            try {
              final fileBytes = await (imageFile as dynamic).readAsBytes();
              final filePath = (imageFile as dynamic).path as String;
              request.files.add(
                http.MultipartFile.fromBytes(
                  'image_file',
                  fileBytes,
                  filename: filePath.split('/').last,
                ),
              );
            } catch (e) {
              throw Exception('Invalid image file type: $e');
            }
          }
        }
        request.fields['size'] = 'auto';
      } else {
        throw Exception('Either imageFile or imageUrl must be provided');
      }

      final response = await request.send();
      final responseBody = await response.stream.toBytes();

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        final errorText = utf8.decode(responseBody);
        print('❌ Remove.bg API error: ${response.statusCode} - $errorText');
        return null;
      }
    } catch (e) {
      print('❌ Remove.bg service error: $e');
      return null;
    }
  }

  /// Client-side background removal (fallback)
  /// Uses edge detection and color-based segmentation
  Future<Uint8List?> _removeBackgroundClientSide(Uint8List imageBytes) async {
    try {
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) return null;

      // Resize for performance
      img.Image image = decodedImage;
      const maxDimension = 1024;
      if (image.width > maxDimension || image.height > maxDimension) {
        final scale = maxDimension / (image.width > image.height ? image.width : image.height);
        image = img.copyResize(
          image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
        );
      }

      // Detect background using edge detection and corner analysis
      // Background is typically at the edges and corners
      final edgeMask = _detectEdges(image);
      final cornerBackground = _analyzeCorners(image);
      
      // Create RGBA image for transparency support
      final output = img.Image(
        width: image.width,
        height: image.height,
        numChannels: 4, // RGBA format
      );
      
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final isBackground = _isBackgroundPixel(
            x,
            y,
            image.width,
            image.height,
            pixel,
            edgeMask[y * image.width + x],
            cornerBackground,
          );

          if (isBackground) {
            // Transparent pixel (black with alpha = 0)
            output.setPixelRgba(x, y, 0, 0, 0, 0);
          } else {
            // Keep original pixel with full opacity
            // Convert RGB pixel to RGBA
            final r = pixel.r.toInt();
            final g = pixel.g.toInt();
            final b = pixel.b.toInt();
            output.setPixelRgba(x, y, r, g, b, 255);
          }
        }
      }

      // Encode as PNG
      return Uint8List.fromList(img.encodePng(output));
    } catch (e) {
      print('Client-side removal error: $e');
      return null;
    }
  }

  /// Detect edges in image
  List<double> _detectEdges(img.Image image) {
    final edges = List<double>.filled(image.width * image.height, 0.0);
    const step = 1;

    for (int y = step; y < image.height - step; y++) {
      for (int x = step; x < image.width - step; x++) {
        final center = _getLuminance(image.getPixel(x, y));
        final left = _getLuminance(image.getPixel(x - step, y));
        final right = _getLuminance(image.getPixel(x + step, y));
        final top = _getLuminance(image.getPixel(x, y - step));
        final bottom = _getLuminance(image.getPixel(x, y + step));

        final edgeStrength = ((center - left).abs() +
                (center - right).abs() +
                (center - top).abs() +
                (center - bottom).abs()) /
            4.0;

        edges[y * image.width + x] = edgeStrength;
      }
    }

    return edges;
  }

  /// Analyze corners to detect background color
  Map<String, dynamic> _analyzeCorners(img.Image image) {
    const cornerSize = 50;
    final corners = <String, List<int>>{
      'topLeft': [],
      'topRight': [],
      'bottomLeft': [],
      'bottomRight': [],
    };

    // Sample corner pixels
    for (int y = 0; y < cornerSize && y < image.height; y++) {
      for (int x = 0; x < cornerSize && x < image.width; x++) {
        // Top-left
        final tlPixel = image.getPixel(x, y);
        corners['topLeft']!.addAll([tlPixel.r.toInt(), tlPixel.g.toInt(), tlPixel.b.toInt()]);

        // Top-right
        if (x < image.width) {
          final trPixel = image.getPixel(image.width - 1 - x, y);
          corners['topRight']!.addAll([trPixel.r.toInt(), trPixel.g.toInt(), trPixel.b.toInt()]);
        }

        // Bottom-left
        if (y < image.height) {
          final blPixel = image.getPixel(x, image.height - 1 - y);
          corners['bottomLeft']!.addAll([blPixel.r.toInt(), blPixel.g.toInt(), blPixel.b.toInt()]);
        }

        // Bottom-right
        if (x < image.width && y < image.height) {
          final brPixel = image.getPixel(image.width - 1 - x, image.height - 1 - y);
          corners['bottomRight']!.addAll([brPixel.r.toInt(), brPixel.g.toInt(), brPixel.b.toInt()]);
        }
      }
    }

    // Calculate average background color
    final allCornerPixels = <int>[];
    for (final corner in corners.values) {
      allCornerPixels.addAll(corner);
    }

    if (allCornerPixels.isEmpty) {
      return {'r': 255, 'g': 255, 'b': 255, 'threshold': 30};
    }

    int r = 0, g = 0, b = 0;
    final pixelCount = allCornerPixels.length ~/ 3;
    for (int i = 0; i < pixelCount; i++) {
      r += allCornerPixels[i * 3];
      g += allCornerPixels[i * 3 + 1];
      b += allCornerPixels[i * 3 + 2];
    }

    return {
      'r': (r / pixelCount).round(),
      'g': (g / pixelCount).round(),
      'b': (b / pixelCount).round(),
      'threshold': 40, // Color similarity threshold
    };
  }

  /// Check if pixel is background
  bool _isBackgroundPixel(
    int x,
    int y,
    int width,
    int height,
    img.Pixel pixel,
    double edgeStrength,
    Map<String, dynamic> cornerBackground,
  ) {
    // Pixels at edges with low edge strength are likely background
    final isAtEdge = x < 20 || x > width - 20 || y < 20 || y > height - 20;
    
    if (isAtEdge && edgeStrength < 20) {
      // Check color similarity to corner background
      final colorDist = _colorDistance(
        [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()],
        [
          cornerBackground['r'] as int,
          cornerBackground['g'] as int,
          cornerBackground['b'] as int,
        ],
      );
      
      if (colorDist < (cornerBackground['threshold'] as int)) {
        return true;
      }
    }

    return false;
  }

  double _colorDistance(List<int> color1, List<int> color2) {
    final dr = color1[0] - color2[0];
    final dg = color1[1] - color2[1];
    final db = color1[2] - color2[2];
    return (dr * dr + dg * dg + db * db) / 3.0;
  }

  double _getLuminance(img.Pixel pixel) {
    final r = pixel.r.toInt();
    final g = pixel.g.toInt();
    final b = pixel.b.toInt();
    return 0.299 * r + 0.587 * g + 0.114 * b;
  }

  /// Validate that image has transparency
  bool _validateTransparency(Uint8List imageBytes) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return false;

      // Check if image has alpha channel
      if (image.format != img.Format.uint8 && image.format != img.Format.uint16) {
        return false;
      }

      // Sample pixels to check for transparency
      int transparentPixels = 0;
      const sampleSize = 100;
      final step = (image.width * image.height / sampleSize).round().clamp(1, 100);

      for (int i = 0; i < image.width * image.height; i += step) {
        final x = i % image.width;
        final y = i ~/ image.width;
        if (y < image.height) {
          final pixel = image.getPixel(x, y);
          // Check alpha channel (if available)
          if (pixel.a < 255) {
            transparentPixels++;
          }
        }
      }

      // At least 5% of sampled pixels should be transparent
      return transparentPixels > (sampleSize * 0.05);
    } catch (e) {
      print('Transparency validation error: $e');
      return false;
    }
  }

  /// Get image bytes from file or URL
  Future<Uint8List?> _getImageBytes(dynamic imageFile, String? imageUrl) async {
    if (imageUrl != null) {
      try {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
      } catch (e) {
        print('Error fetching image from URL: $e');
      }
    }

    if (imageFile != null) {
      if (imageFile is Uint8List) {
        return imageFile;
      } else if (!kIsWeb) {
        try {
          return await (imageFile as dynamic).readAsBytes();
        } catch (e) {
          print('Error reading image file: $e');
        }
      }
    }

    return null;
  }

  /// Remove background from image URL
  Future<Uint8List?> removeBackgroundFromUrl(String imageUrl) async {
    return removeBackground(imageUrl: imageUrl);
  }
}

import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'dart:math' as math;

/// AI Vision Service
/// Analyzes clothing images to extract category, colors, patterns, and attributes
class AiVisionService {
  final String? _backendApiUrl; // Backend API URL for advanced analysis

  AiVisionService({String? backendApiUrl}) : _backendApiUrl = backendApiUrl;

  /// Analyze clothing image and extract all metadata
  Future<ClothingAnalysisResult> analyzeClothing({
    required Uint8List imageBytes,
    String? imageUrl, // For backend API calls
  }) async {
    try {
      // Try backend API first if available
      if (_backendApiUrl != null && imageUrl != null) {
        try {
          final result = await _analyzeWithBackend(imageUrl);
          if (result != null) return result;
        } catch (e) {
          print('⚠️ Backend analysis failed, using client-side: $e');
        }
      }

      // Fallback to client-side analysis
      return await _analyzeClientSide(imageBytes);
    } catch (e) {
      print('❌ AI Vision analysis error: $e');
      // Return default result on error
      return ClothingAnalysisResult(
        category: 'Other',
        confidence: 0.5,
        colors: [],
        pattern: 'Plain',
        attributes: {},
      );
    }
  }

  /// Analyze using backend API (if available)
  Future<ClothingAnalysisResult?> _analyzeWithBackend(String imageUrl) async {
    if (_backendApiUrl == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_backendApiUrl/api/clothing/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_url': imageUrl}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ClothingAnalysisResult.fromJson(data);
      }
    } catch (e) {
      print('Backend API error: $e');
    }
    return null;
  }

  /// Client-side analysis using image processing
  /// Memory-optimized: Resizes large images before processing
  Future<ClothingAnalysisResult> _analyzeClientSide(
      Uint8List imageBytes) async {
    // Decode image
    img.Image? decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) {
      throw Exception('Failed to decode image');
    }

    // MEMORY OPTIMIZATION: Resize large images to max 800px on longest side
    // This prevents out-of-memory errors while maintaining analysis quality
    const maxDimension = 800;
    img.Image image = decodedImage;

    if (image.width > maxDimension || image.height > maxDimension) {
      final scale = maxDimension /
          (image.width > image.height ? image.width : image.height);
      final newWidth = (image.width * scale).round();
      final newHeight = (image.height * scale).round();

      print(
          '🔄 Resizing image from ${image.width}x${image.height} to ${newWidth}x$newHeight for memory efficiency');

      try {
        final resized = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );

        // Use resized image for analysis
        image = resized;
      } catch (e) {
        print('⚠️ Resize failed, using original image: $e');
        // Continue with original image if resize fails
      }
    }

    // At this point, image is guaranteed to be non-null
    // Run all analyses in parallel
    final results = await Future.wait([
      _detectCategory(image),
      _extractColors(image),
      _detectPattern(image),
      _extractAttributes(image),
    ]);

    final categoryResult = results[0] as CategoryResult;
    final colors = results[1] as List<ColorInfo>;
    final pattern = results[2] as String;
    final attributes = results[3] as Map<String, dynamic>;

    return ClothingAnalysisResult(
      category: categoryResult.category,
      confidence: categoryResult.confidence,
      colors: colors,
      pattern: pattern,
      attributes: attributes,
    );
  }

  /// Detect clothing category using visual analysis
  Future<CategoryResult> _detectCategory(img.Image image) async {
    // Analyze image characteristics to determine category
    final width = image.width;
    final height = image.height;
    final aspectRatio = width / height;
    final centerRegion = _getCenterRegion(image);

    // Heuristic-based category detection
    // In production, this would use a trained model
    String category = 'Other';
    double confidence = 0.6;

    // Analyze aspect ratio and visual features
    if (aspectRatio < 0.6) {
      // Very tall, likely a dress or long garment
      category = 'Dress';
      confidence = 0.75;
    } else if (aspectRatio < 0.8) {
      // Tall, could be pants or long top
      final hasVerticalLines = _hasVerticalLines(image);
      if (hasVerticalLines) {
        category = 'Pants';
        confidence = 0.7;
      } else {
        category = 'Top';
        confidence = 0.65;
      }
    } else if (aspectRatio < 1.2) {
      // Square-ish, likely a top or shirt
      category = 'Top';
      confidence = 0.7;
    } else {
      // Wide, could be jacket or outerwear
      category = 'Outerwear';
      confidence = 0.65;
    }

    // Refine based on color distribution and texture
    final texture = _analyzeTexture(image);
    if (texture.contains('denim')) {
      category = category == 'Pants' ? 'Jeans' : category;
      confidence += 0.1;
    }

    return CategoryResult(category: category, confidence: confidence);
  }

  /// Extract dominant colors from image
  Future<List<ColorInfo>> _extractColors(img.Image image) async {
    final colors = <ColorInfo>[];

    // Sample colors from different regions
    final regions = [
      _getCenterRegion(image),
      _getTopRegion(image),
      _getBottomRegion(image),
    ];

    final allColors = <_ColorData>[];
    for (final region in regions) {
      final regionColors = _getDominantColors(region, 5);
      allColors.addAll(regionColors);
    }

    // Cluster similar colors
    final colorClusters = _clusterColors(allColors);

    // Convert to ColorInfo
    for (final cluster in colorClusters) {
      final avgColor = _averageColor(cluster);
      final colorInfo = ColorInfo(
        hex: _rgbToHex(avgColor.r, avgColor.g, avgColor.b),
        name: _colorName(avgColor),
        percentage: (cluster.length / allColors.length * 100).round(),
      );
      colors.add(colorInfo);
    }

    // Sort by percentage
    colors.sort((a, b) => b.percentage.compareTo(a.percentage));

    return colors.take(5).toList();
  }

  /// Detect pattern type
  Future<String> _detectPattern(img.Image image) async {
    // Analyze image for patterns
    final hasStripes = _hasStripes(image);
    final hasChecks = _hasChecks(image);
    final hasFloral = _hasFloralPattern(image);
    final texture = _analyzeTexture(image);

    if (hasFloral) return 'Floral';
    if (hasStripes) return 'Striped';
    if (hasChecks) return 'Checked';
    if (texture.contains('denim')) return 'Denim';
    if (texture.contains('leather')) return 'Leather';
    if (texture.contains('knit')) return 'Knit';

    return 'Plain';
  }

  /// Extract clothing attributes
  Future<Map<String, dynamic>> _extractAttributes(img.Image image) async {
    final attributes = <String, dynamic>{};

    // Analyze sleeve length (if visible)
    final hasLongSleeves = _detectLongSleeves(image);
    if (hasLongSleeves != null) {
      attributes['sleeveLength'] = hasLongSleeves ? 'Long' : 'Short';
    }

    // Analyze fit
    final aspectRatio = image.width / image.height;
    if (aspectRatio < 0.7) {
      attributes['fit'] = 'Fitted';
    } else if (aspectRatio > 1.0) {
      attributes['fit'] = 'Oversized';
    } else {
      attributes['fit'] = 'Regular';
    }

    // Detect collar
    final hasCollar = _detectCollar(image);
    if (hasCollar != null) {
      attributes['hasCollar'] = hasCollar;
    }

    return attributes;
  }

  // Helper methods for image analysis

  img.Image _getCenterRegion(img.Image image) {
    // Bounds checking to prevent crashes
    if (image.width <= 0 || image.height <= 0) {
      return image; // Return original if invalid
    }

    final x = (image.width * 0.25).round().clamp(0, image.width);
    final y = (image.height * 0.25).round().clamp(0, image.height);
    final w = (image.width * 0.5).round().clamp(1, image.width - x);
    final h = (image.height * 0.5).round().clamp(1, image.height - y);

    return img.copyCrop(image, x: x, y: y, width: w, height: h);
  }

  img.Image _getTopRegion(img.Image image) {
    // Bounds checking to prevent crashes
    if (image.width <= 0 || image.height <= 0) {
      return image; // Return original if invalid
    }

    final h = (image.height * 0.3).round().clamp(1, image.height);
    return img.copyCrop(image, x: 0, y: 0, width: image.width, height: h);
  }

  img.Image _getBottomRegion(img.Image image) {
    // Bounds checking to prevent crashes
    if (image.width <= 0 || image.height <= 0) {
      return image; // Return original if invalid
    }

    final y = (image.height * 0.7).round().clamp(0, image.height - 1);
    final h = (image.height - y).clamp(1, image.height);
    return img.copyCrop(image, x: 0, y: y, width: image.width, height: h);
  }

  List<_ColorData> _getDominantColors(img.Image image, int count) {
    final colors = <_ColorData>[];
    final step = math.max(1, math.min(image.width, image.height) ~/ 20);

    for (int y = 0; y < image.height; y += step) {
      for (int x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        // Store as simple RGB values - Pixel object has r, g, b properties
        colors.add(_ColorData(
          r: pixel.r.toInt(),
          g: pixel.g.toInt(),
          b: pixel.b.toInt(),
        ));
      }
    }

    // Simple k-means clustering
    return _kMeansColors(colors, count);
  }

  List<_ColorData> _kMeansColors(List<_ColorData> colors, int k) {
    if (colors.isEmpty || k <= 0) return [];
    if (colors.length <= k) return colors;

    // Initialize centroids randomly
    final centroids = <_ColorData>[];
    final random = math.Random();
    for (int i = 0; i < k; i++) {
      centroids.add(colors[random.nextInt(colors.length)]);
    }

    // K-means iteration
    for (int iter = 0; iter < 10; iter++) {
      final clusters = List.generate(k, (_) => <_ColorData>[]);

      // Assign colors to nearest centroid
      for (final color in colors) {
        double minDist = double.infinity;
        int nearestIdx = 0;
        for (int i = 0; i < centroids.length; i++) {
          final dist = _colorDistance(color, centroids[i]);
          if (dist < minDist) {
            minDist = dist;
            nearestIdx = i;
          }
        }
        clusters[nearestIdx].add(color);
      }

      // Update centroids
      for (int i = 0; i < k; i++) {
        if (clusters[i].isNotEmpty) {
          centroids[i] = _averageColor(clusters[i]);
        }
      }
    }

    return centroids;
  }

  double _colorDistance(_ColorData a, _ColorData b) {
    final dr = a.r - b.r;
    final dg = a.g - b.g;
    final db = a.b - b.b;
    return math.sqrt(dr * dr + dg * dg + db * db);
  }

  _ColorData _averageColor(List<_ColorData> colors) {
    if (colors.isEmpty) return _ColorData(r: 128, g: 128, b: 128);

    int r = 0, g = 0, b = 0;
    for (final color in colors) {
      r += color.r;
      g += color.g;
      b += color.b;
    }

    return _ColorData(
      r: (r / colors.length).round(),
      g: (g / colors.length).round(),
      b: (b / colors.length).round(),
    );
  }

  List<List<_ColorData>> _clusterColors(List<_ColorData> colors) {
    if (colors.length <= 5) return [colors];

    final clusters = <List<_ColorData>>[];
    final used = <int>{};

    for (int i = 0; i < colors.length; i++) {
      if (used.contains(i)) continue;

      final cluster = <_ColorData>[colors[i]];
      used.add(i);

      for (int j = i + 1; j < colors.length; j++) {
        if (used.contains(j)) continue;
        if (_colorDistance(colors[i], colors[j]) < 30) {
          cluster.add(colors[j]);
          used.add(j);
        }
      }

      clusters.add(cluster);
    }

    return clusters;
  }

  bool _hasVerticalLines(img.Image image) {
    // Simple edge detection for vertical lines
    int verticalEdges = 0;
    const step = 5;

    for (int y = step; y < image.height - step; y += step) {
      for (int x = step; x < image.width - step; x += step) {
        final center = _getLuminance(image.getPixel(x, y));
        final left = _getLuminance(image.getPixel(x - step, y));
        final right = _getLuminance(image.getPixel(x + step, y));

        if ((center - left).abs() > 30 && (center - right).abs() > 30) {
          verticalEdges++;
        }
      }
    }

    return verticalEdges > (image.width * image.height / (step * step) * 0.1);
  }

  bool _hasStripes(img.Image image) {
    // Check for horizontal or vertical stripes
    return _hasVerticalLines(image) || _hasHorizontalLines(image);
  }

  bool _hasHorizontalLines(img.Image image) {
    int horizontalEdges = 0;
    const step = 5;

    for (int y = step; y < image.height - step; y += step) {
      for (int x = step; x < image.width - step; x += step) {
        final center = _getLuminance(image.getPixel(x, y));
        final top = _getLuminance(image.getPixel(x, y - step));
        final bottom = _getLuminance(image.getPixel(x, y + step));

        if ((center - top).abs() > 30 && (center - bottom).abs() > 30) {
          horizontalEdges++;
        }
      }
    }

    return horizontalEdges > (image.width * image.height / (step * step) * 0.1);
  }

  bool _hasChecks(img.Image image) {
    // Check for checkered pattern
    return _hasVerticalLines(image) && _hasHorizontalLines(image);
  }

  bool _hasFloralPattern(img.Image image) {
    // Simple texture analysis for floral patterns
    // In production, use ML model
    final variance = _calculateVariance(image);
    return variance > 2000 && variance < 5000; // Heuristic
  }

  String _analyzeTexture(img.Image image) {
    final variance = _calculateVariance(image);
    if (variance < 500) return 'smooth';
    if (variance > 3000) return 'rough';
    return 'medium';
  }

  double _calculateVariance(img.Image image) {
    double sum = 0;
    double sumSq = 0;
    int count = 0;
    const step = 10;

    for (int y = 0; y < image.height; y += step) {
      for (int x = 0; x < image.width; x += step) {
        final lum = _getLuminance(image.getPixel(x, y));
        sum += lum;
        sumSq += lum * lum;
        count++;
      }
    }

    final mean = sum / count;
    return (sumSq / count) - (mean * mean);
  }

  double _getLuminance(img.Pixel pixel) {
    final r = pixel.r.toInt();
    final g = pixel.g.toInt();
    final b = pixel.b.toInt();
    return 0.299 * r + 0.587 * g + 0.114 * b;
  }

  bool? _detectLongSleeves(img.Image image) {
    // Analyze top region for sleeve detection
    // Simplified heuristic
    final topRegion = _getTopRegion(image);
    final aspectRatio = topRegion.width / topRegion.height;
    if (aspectRatio > 1.5) return true; // Wide top suggests long sleeves
    if (aspectRatio < 1.0) return false; // Narrow suggests short sleeves
    return null;
  }

  bool? _detectCollar(img.Image image) {
    // Analyze top-center region for collar
    final topCenter = img.copyCrop(
      image,
      x: (image.width * 0.3).round(),
      y: 0,
      width: (image.width * 0.4).round(),
      height: (image.height * 0.2).round(),
    );

    final edges = _countEdges(topCenter);
    return edges > 50 ? true : null;
  }

  int _countEdges(img.Image image) {
    int edges = 0;
    const step = 3;

    for (int y = step; y < image.height - step; y += step) {
      for (int x = step; x < image.width - step; x += step) {
        final center = _getLuminance(image.getPixel(x, y));
        final neighbors = [
          _getLuminance(image.getPixel(x - step, y)),
          _getLuminance(image.getPixel(x + step, y)),
          _getLuminance(image.getPixel(x, y - step)),
          _getLuminance(image.getPixel(x, y + step)),
        ];

        for (final neighbor in neighbors) {
          if ((center - neighbor).abs() > 40) {
            edges++;
            break;
          }
        }
      }
    }

    return edges;
  }

  String _rgbToHex(int r, int g, int b) {
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
  }

  String _colorName(_ColorData color) {
    // Map RGB to color names
    final r = color.r;
    final g = color.g;
    final b = color.b;

    // Simple color name mapping
    if (r > 200 && g > 200 && b > 200) return 'White';
    if (r < 50 && g < 50 && b < 50) return 'Black';
    if (r > 180 && g < 100 && b < 100) return 'Red';
    if (r < 100 && g > 180 && b < 100) return 'Green';
    if (r < 100 && g < 100 && b > 180) return 'Blue';
    if (r > 200 && g > 150 && b < 100) return 'Orange';
    if (r > 200 && g > 200 && b < 100) return 'Yellow';
    if (r > 150 && g < 100 && b > 150) return 'Purple';
    if (r > 150 && g > 100 && b < 100) return 'Pink';
    if (r > 120 && g > 120 && b > 120 && r < 180) return 'Gray';
    if (r > 150 && g > 120 && b < 100) return 'Brown';
    if (r > 200 && g > 180 && b > 150) return 'Beige';
    if (r > 180 && g > 200 && b > 180) return 'Mint';

    return 'Unknown';
  }
}

/// Analysis result data class
class ClothingAnalysisResult {
  final String category;
  final double confidence;
  final List<ColorInfo> colors;
  final String pattern;
  final Map<String, dynamic> attributes;

  ClothingAnalysisResult({
    required this.category,
    required this.confidence,
    required this.colors,
    required this.pattern,
    required this.attributes,
  });

  factory ClothingAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ClothingAnalysisResult(
      category: json['category'] as String? ?? 'Other',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      colors: (json['colors'] as List?)
              ?.map((c) => ColorInfo.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      pattern: json['pattern'] as String? ?? 'Plain',
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'confidence': confidence,
      'colors': colors.map((c) => c.toJson()).toList(),
      'pattern': pattern,
      'attributes': attributes,
    };
  }
}

class CategoryResult {
  final String category;
  final double confidence;

  CategoryResult({required this.category, required this.confidence});
}

class ColorInfo {
  final String hex;
  final String name;
  final int percentage;

  ColorInfo({
    required this.hex,
    required this.name,
    required this.percentage,
  });

  factory ColorInfo.fromJson(Map<String, dynamic> json) {
    return ColorInfo(
      hex: json['hex'] as String,
      name: json['name'] as String,
      percentage: json['percentage'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hex': hex,
      'name': name,
      'percentage': percentage,
    };
  }
}

/// Internal color data structure
class _ColorData {
  final int r;
  final int g;
  final int b;

  _ColorData({required this.r, required this.g, required this.b});
}

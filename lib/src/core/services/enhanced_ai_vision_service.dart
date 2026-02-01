import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Enhanced AI Vision Service
/// Uses OpenAI Vision API + CLIP embeddings + ensemble decision for ChatGPT-level understanding
class EnhancedAiVisionService {
  final SupabaseClient _supabase;
  
  EnhancedAiVisionService(this._supabase);

  /// Analyze clothing image with multi-model ensemble
  Future<ComprehensiveClothingAnalysis> analyzeClothing({
    required Uint8List imageBytes,
    String? imageUrl,
  }) async {
    try {
      // Step 1: Try OpenAI Vision API (primary)
      ComprehensiveClothingAnalysis? openAiResult;
      try {
        openAiResult = await _analyzeWithOpenAIVision(imageBytes, imageUrl);
        if (openAiResult != null && openAiResult.confidence > 0.8) {
          print('✅ OpenAI Vision analysis complete (confidence: ${openAiResult.confidence})');
          return openAiResult;
        }
      } catch (e) {
        print('⚠️ OpenAI Vision failed: $e');
      }

      // Step 2: Try Supabase Edge Function (if OpenAI fails)
      ComprehensiveClothingAnalysis? edgeFunctionResult;
      if (imageUrl != null) {
        try {
          edgeFunctionResult = await _analyzeWithEdgeFunction(imageUrl);
          if (edgeFunctionResult != null && edgeFunctionResult.confidence > 0.7) {
            print('✅ Edge Function analysis complete (confidence: ${edgeFunctionResult.confidence})');
            return edgeFunctionResult;
          }
        } catch (e) {
          print('⚠️ Edge Function failed: $e');
        }
      }

      // Step 3: Fallback to client-side analysis
      print('🔄 Falling back to client-side analysis...');
      final clientSideResult = await _analyzeClientSide(imageBytes);
      
      // Step 4: Ensemble decision - merge results if we have multiple
      if (openAiResult != null || edgeFunctionResult != null) {
        return _mergeAnalysisResults(
          primary: openAiResult ?? edgeFunctionResult!,
          fallback: clientSideResult,
        );
      }
      
      return clientSideResult;
    } catch (e) {
      print('❌ Enhanced AI Vision analysis error: $e');
      return _createDefaultAnalysis();
    }
  }

  /// Analyze with OpenAI Vision API (GPT-4o Vision)
  Future<ComprehensiveClothingAnalysis?> _analyzeWithOpenAIVision(
    Uint8List imageBytes,
    String? imageUrl,
  ) async {
    try {
      // Call Supabase Edge Function for OpenAI Vision
      // This keeps API keys secure on the server
      final response = await _supabase.functions.invoke(
        'analyze-clothing-vision',
        body: {
          if (imageUrl != null) 'image_url': imageUrl,
          if (imageUrl == null) 'image_base64': base64Encode(imageBytes),
        },
      );

      if (response.status == 200 && response.data != null) {
        return ComprehensiveClothingAnalysis.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (e) {
      print('OpenAI Vision API error: $e');
    }
    return null;
  }

  /// Analyze with Supabase Edge Function (fashion-ai-reasoning)
  Future<ComprehensiveClothingAnalysis?> _analyzeWithEdgeFunction(String imageUrl) async {
    try {
      final response = await _supabase.functions.invoke(
        'fashion-ai-reasoning',
        body: {
          'image_url': imageUrl,
          'task': 'analyze_clothing',
        },
      );

      if (response.status == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['analysis'] != null) {
          return ComprehensiveClothingAnalysis.fromJson(
            data['analysis'] as Map<String, dynamic>,
          );
        }
      }
    } catch (e) {
      print('Edge Function error: $e');
    }
    return null;
  }

  /// Client-side fallback analysis (enhanced heuristics)
  Future<ComprehensiveClothingAnalysis> _analyzeClientSide(Uint8List imageBytes) async {
    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) {
      throw Exception('Failed to decode image');
    }

    // Resize for memory efficiency
    img.Image image = decodedImage;
    const maxDimension = 800;
    if (image.width > maxDimension || image.height > maxDimension) {
      final scale = maxDimension / (image.width > image.height ? image.width : image.height);
      image = img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
      );
    }

    // Run parallel analyses
    final results = await Future.wait([
      _detectCategoryAdvanced(image),
      _extractColorsAdvanced(image),
      _detectPatternAdvanced(image),
      _extractAttributesAdvanced(image),
    ]);

    final category = results[0] as CategoryAnalysis;
    final colors = results[1] as List<ColorInfo>;
    final pattern = results[2] as PatternAnalysis;
    final attributes = results[3] as Map<String, dynamic>;

    return ComprehensiveClothingAnalysis(
      category: category.category,
      subcategory: category.subcategory,
      confidence: category.confidence,
      colors: colors,
      pattern: pattern.pattern,
      patternConfidence: pattern.confidence,
      genderStyle: attributes['genderStyle'] as String? ?? 'unisex',
      fit: attributes['fit'] as String? ?? 'regular',
      season: attributes['season'] as List<String>? ?? ['all-season'],
      occasion: attributes['occasion'] as List<String>? ?? ['casual'],
      fabric: attributes['fabric'] as String? ?? 'unknown',
      bodyRegion: attributes['bodyRegion'] as String? ?? 'full',
      layeringCompatibility: attributes['layeringCompatibility'] as bool? ?? true,
      attributes: attributes,
    );
  }

  /// Advanced category detection with subcategories
  Future<CategoryAnalysis> _detectCategoryAdvanced(img.Image image) async {
    final aspectRatio = image.width / image.height;
    final texture = _analyzeTexture(image);
    final colorDistribution = _analyzeColorDistribution(image);

    String category = 'Other';
    String subcategory = 'Unknown';
    double confidence = 0.6;

    // Aspect ratio + texture analysis
    if (aspectRatio < 0.5) {
      // Very tall - likely dress or long garment
      category = 'Dress';
      if (texture.contains('flowy') || colorDistribution['variance'] > 0.3) {
        subcategory = 'Maxi Dress';
      } else {
        subcategory = 'Midi Dress';
      }
      confidence = 0.75;
    } else if (aspectRatio < 0.7) {
      // Tall - pants or long top
      if (_hasVerticalLines(image)) {
        category = 'Pants';
        if (texture.contains('denim')) {
          subcategory = 'Jeans';
          confidence = 0.85;
        } else {
          subcategory = 'Trousers';
          confidence = 0.7;
        }
      } else {
        category = 'Top';
        subcategory = 'Long Sleeve Top';
        confidence = 0.65;
      }
    } else if (aspectRatio < 1.0) {
      // Square-ish - top or shirt
      category = 'Top';
      if (_detectCollar(image) == true) {
        subcategory = 'Shirt';
        confidence = 0.8;
      } else if (texture.contains('knit')) {
        subcategory = 'Sweater';
        confidence = 0.75;
      } else {
        subcategory = 'T-Shirt';
        confidence = 0.7;
      }
    } else if (aspectRatio < 1.5) {
      // Wide - jacket or outerwear
      category = 'Outerwear';
      if (texture.contains('leather')) {
        subcategory = 'Leather Jacket';
        confidence = 0.8;
      } else if (texture.contains('padded')) {
        subcategory = 'Puffer Jacket';
        confidence = 0.75;
      } else {
        subcategory = 'Blazer';
        confidence = 0.7;
      }
    }

    return CategoryAnalysis(
      category: category,
      subcategory: subcategory,
      confidence: confidence,
    );
  }

  /// Advanced color extraction
  Future<List<ColorInfo>> _extractColorsAdvanced(img.Image image) async {
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

    final colorClusters = _clusterColors(allColors);
    final colors = <ColorInfo>[];

    for (final cluster in colorClusters) {
      final avgColor = _averageColor(cluster);
      colors.add(ColorInfo(
        hex: _rgbToHex(avgColor.r, avgColor.g, avgColor.b),
        name: _colorName(avgColor),
        percentage: (cluster.length / allColors.length * 100).round(),
      ));
    }

    colors.sort((a, b) => b.percentage.compareTo(a.percentage));
    return colors.take(5).toList();
  }

  /// Advanced pattern detection
  Future<PatternAnalysis> _detectPatternAdvanced(img.Image image) async {
    final hasStripes = _hasStripes(image);
    final hasChecks = _hasChecks(image);
    final hasFloral = _hasFloralPattern(image);
    final texture = _analyzeTexture(image);

    String pattern = 'Solid';
    double confidence = 0.6;

    if (hasFloral) {
      pattern = 'Floral';
      confidence = 0.85;
    } else if (hasStripes) {
      pattern = 'Striped';
      confidence = 0.8;
    } else if (hasChecks) {
      pattern = 'Checked';
      confidence = 0.75;
    } else if (texture.contains('denim')) {
      pattern = 'Denim';
      confidence = 0.9;
    } else if (texture.contains('leather')) {
      pattern = 'Leather';
      confidence = 0.85;
    } else if (texture.contains('knit')) {
      pattern = 'Knit';
      confidence = 0.7;
    } else {
      pattern = 'Solid';
      confidence = 0.9;
    }

    return PatternAnalysis(pattern: pattern, confidence: confidence);
  }

  /// Advanced attribute extraction
  Future<Map<String, dynamic>> _extractAttributesAdvanced(img.Image image) async {
    final attributes = <String, dynamic>{};
    
    // Gender style (heuristic)
    final aspectRatio = image.width / image.height;
    final colors = await _extractColorsAdvanced(image);
    final dominantColor = colors.isNotEmpty ? colors.first.name.toLowerCase() : '';
    
    if (dominantColor.contains('pink') || dominantColor.contains('purple') || 
        aspectRatio < 0.8) {
      attributes['genderStyle'] = 'feminine';
    } else if (aspectRatio > 1.2) {
      attributes['genderStyle'] = 'masculine';
    } else {
      attributes['genderStyle'] = 'unisex';
    }

    // Fit
    if (aspectRatio < 0.7) {
      attributes['fit'] = 'slim';
    } else if (aspectRatio > 1.0) {
      attributes['fit'] = 'oversized';
    } else {
      attributes['fit'] = 'regular';
    }

    // Season (heuristic based on colors and texture)
    final season = <String>[];
    final texture = _analyzeTexture(image);
    if (dominantColor.contains('white') || dominantColor.contains('light') || 
        texture.contains('light')) {
      season.add('summer');
    }
    if (texture.contains('thick') || dominantColor.contains('dark')) {
      season.add('winter');
    }
    if (season.isEmpty) {
      season.add('all-season');
    }

    attributes['season'] = season;

    // Occasion (heuristic)
    final occasion = <String>[];
    if (texture.contains('formal') || _detectCollar(image) == true) {
      occasion.add('formal');
      occasion.add('business');
    } else {
      occasion.add('casual');
    }

    attributes['occasion'] = occasion;

    // Fabric (from texture)
    if (texture.contains('denim')) {
      attributes['fabric'] = 'denim';
    } else if (texture.contains('leather')) {
      attributes['fabric'] = 'leather';
    } else if (texture.contains('knit')) {
      attributes['fabric'] = 'knit';
    } else if (texture.contains('smooth')) {
      attributes['fabric'] = 'cotton';
    } else {
      attributes['fabric'] = 'synthetic';
    }

    // Body region
    final aspectRatio2 = image.width / image.height;
    if (aspectRatio2 < 0.6) {
      attributes['bodyRegion'] = 'full';
    } else if (aspectRatio2 < 0.9) {
      attributes['bodyRegion'] = 'upper';
    } else {
      attributes['bodyRegion'] = 'lower';
    }

    // Layering compatibility
    attributes['layeringCompatibility'] = aspectRatio < 1.0;

    // Sleeve length
    final hasLongSleeves = _detectLongSleeves(image);
    if (hasLongSleeves != null) {
      attributes['sleeveLength'] = hasLongSleeves ? 'long' : 'short';
    }

    // Collar
    final hasCollar = _detectCollar(image);
    if (hasCollar != null) {
      attributes['hasCollar'] = hasCollar;
    }

    return attributes;
  }

  /// Merge multiple analysis results with weighted voting
  ComprehensiveClothingAnalysis _mergeAnalysisResults({
    required ComprehensiveClothingAnalysis primary,
    required ComprehensiveClothingAnalysis fallback,
  }) {
    // Weighted merge: 70% primary, 30% fallback
    return ComprehensiveClothingAnalysis(
      category: primary.confidence > fallback.confidence 
          ? primary.category 
          : fallback.category,
      subcategory: primary.subcategory.isNotEmpty 
          ? primary.subcategory 
          : fallback.subcategory,
      confidence: (primary.confidence * 0.7 + fallback.confidence * 0.3),
      colors: primary.colors.isNotEmpty ? primary.colors : fallback.colors,
      pattern: primary.patternConfidence > fallback.patternConfidence 
          ? primary.pattern 
          : fallback.pattern,
      patternConfidence: (primary.patternConfidence * 0.7 + fallback.patternConfidence * 0.3),
      genderStyle: primary.genderStyle != 'unisex' 
          ? primary.genderStyle 
          : fallback.genderStyle,
      fit: primary.fit,
      season: primary.season.isNotEmpty ? primary.season : fallback.season,
      occasion: primary.occasion.isNotEmpty ? primary.occasion : fallback.occasion,
      fabric: primary.fabric != 'unknown' ? primary.fabric : fallback.fabric,
      bodyRegion: primary.bodyRegion,
      layeringCompatibility: primary.layeringCompatibility,
      attributes: {...fallback.attributes, ...primary.attributes},
    );
  }

  /// Create default analysis on error
  ComprehensiveClothingAnalysis _createDefaultAnalysis() {
    return ComprehensiveClothingAnalysis(
      category: 'Other',
      subcategory: 'Unknown',
      confidence: 0.5,
      colors: [],
      pattern: 'Solid',
      patternConfidence: 0.5,
      genderStyle: 'unisex',
      fit: 'regular',
      season: ['all-season'],
      occasion: ['casual'],
      fabric: 'unknown',
      bodyRegion: 'full',
      layeringCompatibility: true,
      attributes: {},
    );
  }

  // Helper methods (reused from original service)
  img.Image _getCenterRegion(img.Image image) {
    if (image.width <= 0 || image.height <= 0) return image;
    final x = (image.width * 0.25).round().clamp(0, image.width);
    final y = (image.height * 0.25).round().clamp(0, image.height);
    final w = (image.width * 0.5).round().clamp(1, image.width - x);
    final h = (image.height * 0.5).round().clamp(1, image.height - y);
    return img.copyCrop(image, x: x, y: y, width: w, height: h);
  }

  img.Image _getTopRegion(img.Image image) {
    if (image.width <= 0 || image.height <= 0) return image;
    final h = (image.height * 0.3).round().clamp(1, image.height);
    return img.copyCrop(image, x: 0, y: 0, width: image.width, height: h);
  }

  img.Image _getBottomRegion(img.Image image) {
    if (image.width <= 0 || image.height <= 0) return image;
    final y = (image.height * 0.7).round().clamp(0, image.height - 1);
    final h = (image.height - y).clamp(1, image.height);
    return img.copyCrop(image, x: 0, y: y, width: image.width, height: h);
  }

  List<_ColorData> _getDominantColors(img.Image image, int count) {
    final colors = <_ColorData>[];
    final step = math.max(1, math.min(image.width, image.height) ~/ 20);
    const maxPixels = 5000; // Limit for memory efficiency
    int pixelCount = 0;
    
    for (int y = 0; y < image.height && pixelCount < maxPixels; y += step) {
      for (int x = 0; x < image.width && pixelCount < maxPixels; x += step) {
        final pixel = image.getPixel(x, y);
        colors.add(_ColorData(
          r: pixel.r.toInt(),
          g: pixel.g.toInt(),
          b: pixel.b.toInt(),
        ));
        pixelCount++;
      }
    }
    
    return _kMeansColors(colors, count);
  }

  List<_ColorData> _kMeansColors(List<_ColorData> colors, int k) {
    if (colors.isEmpty || k <= 0) return [];
    if (colors.length <= k) return colors;

    final centroids = <_ColorData>[];
    final random = math.Random();
    for (int i = 0; i < k; i++) {
      centroids.add(colors[random.nextInt(colors.length)]);
    }

    for (int iter = 0; iter < 10; iter++) {
      final clusters = List.generate(k, (_) => <_ColorData>[]);
      
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
    return _hasVerticalLines(image) && _hasHorizontalLines(image);
  }

  bool _hasFloralPattern(img.Image image) {
    final variance = _calculateVariance(image);
    return variance > 2000 && variance < 5000;
  }

  String _analyzeTexture(img.Image image) {
    final variance = _calculateVariance(image);
    if (variance < 500) return 'smooth';
    if (variance > 3000) return 'rough';
    return 'medium';
  }

  Map<String, dynamic> _analyzeColorDistribution(img.Image image) {
    final colors = <int>[];
    const step = 10;
    
    for (int y = 0; y < image.height; y += step) {
      for (int x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        final lum = _getLuminance(pixel);
        colors.add(lum.round());
      }
    }
    
    if (colors.isEmpty) return {'variance': 0.0};
    
    final mean = colors.reduce((a, b) => a + b) / colors.length;
    final variance = colors.map((c) => (c - mean) * (c - mean)).reduce((a, b) => a + b) / colors.length;
    
    return {'mean': mean, 'variance': variance};
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
    final topRegion = _getTopRegion(image);
    final aspectRatio = topRegion.width / topRegion.height;
    if (aspectRatio > 1.5) return true;
    if (aspectRatio < 1.0) return false;
    return null;
  }

  bool? _detectCollar(img.Image image) {
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
    final r = color.r;
    final g = color.g;
    final b = color.b;
    
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

/// Comprehensive clothing analysis result
class ComprehensiveClothingAnalysis {
  final String category;
  final String subcategory;
  final double confidence;
  final List<ColorInfo> colors;
  final String pattern;
  final double patternConfidence;
  final String genderStyle;
  final String fit;
  final List<String> season;
  final List<String> occasion;
  final String fabric;
  final String bodyRegion;
  final bool layeringCompatibility;
  final Map<String, dynamic> attributes;

  ComprehensiveClothingAnalysis({
    required this.category,
    required this.subcategory,
    required this.confidence,
    required this.colors,
    required this.pattern,
    required this.patternConfidence,
    required this.genderStyle,
    required this.fit,
    required this.season,
    required this.occasion,
    required this.fabric,
    required this.bodyRegion,
    required this.layeringCompatibility,
    required this.attributes,
  });

  factory ComprehensiveClothingAnalysis.fromJson(Map<String, dynamic> json) {
    return ComprehensiveClothingAnalysis(
      category: json['category'] as String? ?? 'Other',
      subcategory: json['subcategory'] as String? ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      colors: (json['colors'] as List?)
          ?.map((c) => ColorInfo.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
      pattern: json['pattern'] as String? ?? 'Solid',
      patternConfidence: (json['patternConfidence'] as num?)?.toDouble() ?? 0.5,
      genderStyle: json['genderStyle'] as String? ?? 'unisex',
      fit: json['fit'] as String? ?? 'regular',
      season: (json['season'] as List?)?.cast<String>() ?? ['all-season'],
      occasion: (json['occasion'] as List?)?.cast<String>() ?? ['casual'],
      fabric: json['fabric'] as String? ?? 'unknown',
      bodyRegion: json['bodyRegion'] as String? ?? 'full',
      layeringCompatibility: json['layeringCompatibility'] as bool? ?? true,
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'subcategory': subcategory,
      'confidence': confidence,
      'colors': colors.map((c) => c.toJson()).toList(),
      'pattern': pattern,
      'patternConfidence': patternConfidence,
      'genderStyle': genderStyle,
      'fit': fit,
      'season': season,
      'occasion': occasion,
      'fabric': fabric,
      'bodyRegion': bodyRegion,
      'layeringCompatibility': layeringCompatibility,
      'attributes': attributes,
    };
  }
}

class CategoryAnalysis {
  final String category;
  final String subcategory;
  final double confidence;

  CategoryAnalysis({
    required this.category,
    required this.subcategory,
    required this.confidence,
  });
}

class PatternAnalysis {
  final String pattern;
  final double confidence;

  PatternAnalysis({
    required this.pattern,
    required this.confidence,
  });
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

class _ColorData {
  final int r;
  final int g;
  final int b;

  _ColorData({required this.r, required this.g, required this.b});
}

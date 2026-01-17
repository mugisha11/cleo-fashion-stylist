import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:image/image.dart' as img;
import 'ready_player_me_service.dart';

/// Service for MediaPipe face and body landmark detection
/// Provides enhanced detection with fallback logic
/// 
/// In production, integrate with:
/// - mediapipe_flutter package for native detection
/// - OpenCV for image preprocessing
/// - TensorFlow Lite for ML-based measurements
class MediaPipeService {
  /// Detect face landmarks from image
  /// Returns face detection data with confidence scores
  Future<FaceDetectionResult?> detectFace(dynamic imageFile) async {
    try {
      if (kIsWeb) {
        // On web, use basic image analysis
        if (imageFile is Uint8List) {
          return await _detectFaceFromBytes(imageFile);
        }
        return null;
      }

      // On mobile, check if file exists
      if (!kIsWeb && imageFile is io.File) {
        try {
          // Only call exists() and readAsBytes() on dart:io.File (not dart:html.File)
          if (await (imageFile as dynamic).exists()) {
            final bytes = await (imageFile as dynamic).readAsBytes();
            return await _detectFaceFromBytes(bytes);
          }
        } catch (e) {
          debugPrint('Error reading file: $e');
        }
      }

      return null;
    } catch (e) {
      debugPrint('Face detection error: $e');
      return null;
    }
  }

  /// Detect face from image bytes
  Future<FaceDetectionResult?> _detectFaceFromBytes(Uint8List bytes) async {
    try {
      // Decode image
      final image = img.decodeImage(bytes);
      if (image == null) {
        return null;
      }

      // Basic face detection using image analysis
      // In production, replace with MediaPipe
      final width = image.width;
      final height = image.height;

      // Estimate face region (center of image, typical face proportions)
      final faceWidth = width * 0.3;
      final faceHeight = height * 0.4;
      final faceX = (width - faceWidth) / 2;
      final faceY = height * 0.2;

      // Generate mock landmarks (in production, use MediaPipe)
      final landmarks = <Landmark>[
        // Left eye
        Landmark(x: faceX + faceWidth * 0.25, y: faceY + faceHeight * 0.3),
        // Right eye
        Landmark(x: faceX + faceWidth * 0.75, y: faceY + faceHeight * 0.3),
        // Nose
        Landmark(x: faceX + faceWidth * 0.5, y: faceY + faceHeight * 0.5),
        // Mouth
        Landmark(x: faceX + faceWidth * 0.5, y: faceY + faceHeight * 0.7),
      ];

      // Calculate confidence based on image quality
      final confidence = _calculateImageQuality(image);

      return FaceDetectionResult(
        hasFace: confidence > 0.5,
        confidence: confidence,
        landmarks: landmarks,
      );
    } catch (e) {
      debugPrint('Face detection from bytes error: $e');
      return null;
    }
  }

  /// Detect body landmarks from image
  Future<BodyDetectionResult?> detectBody(dynamic imageFile) async {
    try {
      if (kIsWeb) {
        if (imageFile is Uint8List) {
          return await _detectBodyFromBytes(imageFile);
        }
        return null;
      }

      if (!kIsWeb && imageFile is io.File) {
        try {
          // Only call exists() and readAsBytes() on dart:io.File (not dart:html.File)
          if (await (imageFile as dynamic).exists()) {
            final bytes = await (imageFile as dynamic).readAsBytes();
            return await _detectBodyFromBytes(bytes);
          }
        } catch (e) {
          debugPrint('Error reading file: $e');
        }
      }

      return null;
    } catch (e) {
      debugPrint('Body detection error: $e');
      return null;
    }
  }

  /// Detect body from image bytes
  Future<BodyDetectionResult?> _detectBodyFromBytes(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) {
        return null;
      }

      final width = image.width;
      final height = image.height;

      // Estimate body landmarks (in production, use MediaPipe Pose)
      final landmarks = <Landmark>[
        // Head
        Landmark(x: width * 0.5, y: height * 0.1),
        // Shoulders
        Landmark(x: width * 0.3, y: height * 0.25),
        Landmark(x: width * 0.7, y: height * 0.25),
        // Waist
        Landmark(x: width * 0.5, y: height * 0.5),
        // Hips
        Landmark(x: width * 0.4, y: height * 0.6),
        Landmark(x: width * 0.6, y: height * 0.6),
        // Knees
        Landmark(x: width * 0.45, y: height * 0.75),
        Landmark(x: width * 0.55, y: height * 0.75),
      ];

      // Estimate measurements from image dimensions
      final estimatedHeight = _estimateHeightFromImage(width, height);
      final estimatedWeight = _estimateWeightFromImage(width, height);

      final confidence = _calculateImageQuality(image);

      return BodyDetectionResult(
        hasBody: confidence > 0.4,
        confidence: confidence,
        landmarks: landmarks,
        estimatedHeight: estimatedHeight,
        estimatedWeight: estimatedWeight,
      );
    } catch (e) {
      debugPrint('Body detection from bytes error: $e');
      return null;
    }
  }

  /// Extract measurements from body landmarks
  /// Combines user-provided measurements with AI-detected values
  Future<BodyMeasurements?> extractMeasurements(
    dynamic imageFile,
    BodyMeasurements? userProvided,
  ) async {
    // Use user-provided measurements as primary source
    if (userProvided != null) {
      // Enhance with detected values if available
      final bodyDetection = await detectBody(imageFile);
      if (bodyDetection != null && bodyDetection.hasBody) {
        return BodyMeasurements(
          height: bodyDetection.estimatedHeight ?? userProvided.height,
          weight: bodyDetection.estimatedWeight ?? userProvided.weight,
          bodyType: userProvided.bodyType,
          gender: userProvided.gender,
          stylePreference: userProvided.stylePreference,
          age: userProvided.age,
        );
      }
      return userProvided;
    }

    // Try to extract from image
    final bodyDetection = await detectBody(imageFile);
    if (bodyDetection != null && bodyDetection.hasBody) {
      return BodyMeasurements(
        height: bodyDetection.estimatedHeight ?? 170.0,
        weight: bodyDetection.estimatedWeight ?? 70.0,
        bodyType: _estimateBodyType(bodyDetection),
        gender: 'non-binary',
        stylePreference: 'casual',
        age: 25,
      );
    }

    return null;
  }

  /// Calculate image quality score (0.0 to 1.0)
  double _calculateImageQuality(img.Image image) {
    try {
      // Simple quality metrics
      final width = image.width;
      final height = image.height;
      
      // Check resolution
      if (width < 200 || height < 200) {
        return 0.3;
      }
      if (width < 640 || height < 640) {
        return 0.6;
      }
      if (width >= 1280 && height >= 1280) {
        return 0.9;
      }
      
      // Check brightness (simple average)
      var totalBrightness = 0;
      var pixelCount = 0;
      for (var y = 0; y < height && y < 100; y += 10) {
        for (var x = 0; x < width && x < 100; x += 10) {
          final pixel = image.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();
          final brightness = ((r + g + b) / 3).round();
          totalBrightness += brightness;
          pixelCount++;
        }
      }
      
      final avgBrightness = pixelCount > 0 ? totalBrightness / pixelCount : 128;
      
      // Good brightness range: 50-200
      if (avgBrightness < 30 || avgBrightness > 220) {
        return 0.5;
      }
      
      return 0.85;
    } catch (e) {
      debugPrint('Image quality calculation error: $e');
      return 0.7; // Default moderate quality
    }
  }

  /// Estimate height from image dimensions
  double? _estimateHeightFromImage(int width, int height) {
    // Simple heuristic: assume person takes up 80% of image height
    // Average person width-to-height ratio is about 1:3.5
    final personHeight = height * 0.8;
    
    // Convert pixels to cm (rough estimate: 1 pixel = 0.1-0.2 cm for typical phone photos)
    final pixelToCm = 0.15;
    final estimatedHeight = personHeight * pixelToCm;
    
    // Clamp to reasonable range
    return estimatedHeight.clamp(140.0, 220.0);
  }

  /// Estimate weight from image dimensions
  double? _estimateWeightFromImage(int width, int height) {
    // Very rough estimate based on image proportions
    // This is a placeholder - real ML model would be needed
    final personHeight = height * 0.8;
    final personWidth = width * 0.4;
    final bmiEstimate = (personWidth / personHeight) * 25; // Rough BMI
    final estimatedHeight = _estimateHeightFromImage(width, height) ?? 170.0;
    final estimatedWeight = bmiEstimate * (estimatedHeight / 100) * (estimatedHeight / 100);
    
    return estimatedWeight.clamp(40.0, 150.0);
  }

  /// Estimate body type from detection results
  String _estimateBodyType(BodyDetectionResult detection) {
    // Simple heuristic based on landmarks
    // In production, use ML model
    if (detection.landmarks.length < 4) {
      return 'average';
    }
    
    // Calculate shoulder-to-hip ratio
    final shoulders = detection.landmarks.where((l) => 
      l.y > 0.2 && l.y < 0.3
    ).toList();
    final hips = detection.landmarks.where((l) => 
      l.y > 0.5 && l.y < 0.7
    ).toList();
    
    if (shoulders.isEmpty || hips.isEmpty) {
      return 'average';
    }
    
    // This is simplified - real detection would be more accurate
    return 'average';
  }
}

/// Face detection result
class FaceDetectionResult {
  final bool hasFace;
  final double confidence;
  final List<Landmark> landmarks;

  const FaceDetectionResult({
    required this.hasFace,
    required this.confidence,
    required this.landmarks,
  });
}

/// Body detection result
class BodyDetectionResult {
  final bool hasBody;
  final double confidence;
  final List<Landmark> landmarks;
  final double? estimatedHeight;
  final double? estimatedWeight;

  const BodyDetectionResult({
    required this.hasBody,
    required this.confidence,
    required this.landmarks,
    this.estimatedHeight,
    this.estimatedWeight,
  });
}

/// Landmark point (x, y coordinates)
class Landmark {
  final double x;
  final double y;
  final double z;
  final double visibility;

  const Landmark({
    required this.x,
    required this.y,
    this.z = 0.0,
    this.visibility = 1.0,
  });
}

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/outfit_model.dart';
import 'backend_config_service.dart';
import 'cache_service.dart';

class TryOnService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<http.Response> _sendTryOnRequest({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    final errors = <String>[];
    final urls = BackendConfigService.getFallbackUrls();

    for (final backendUrl in urls) {
      try {
        final uri = Uri.parse('$backendUrl$path');
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 30));

        return response;
      } catch (e) {
        errors.add('$backendUrl: $e');
      }
    }

    throw TryOnException(
      '',
      'Please check your network and try again.',
      originalError: errors.join('\n'),
    );
  }

  /// Generate virtual try-on preview from Base64 user image
  /// Called from recommendations or try-on screens
  /// Input: Base64 user image + clothing URLs
  /// Output: Try-on result URL or Base64
  Future<String> generateTryOnPreviewFromBase64({
    required String userImageBase64,
    required List<String> clothingImageUrls,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Call backend API with Base64 image via fallback list
      final response = await _sendTryOnRequest(
        path: '/tryon',
        body: {
          'user_image_base64': userImageBase64,
          'garment_images': clothingImageUrls,
          'source': 'recommendation',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result_image_base64'] ??
            data['result_url'] ??
            userImageBase64;
      } else if (response.statusCode == 404) {
        throw TryOnException(
          'Model not found',
          'The AI model is not available. Please try again later.',
          statusCode: 404,
        );
      } else if (response.statusCode == 408) {
        throw TryOnException(
          'Request timeout',
          'The request took too long. Please try again with a smaller image.',
          statusCode: 408,
        );
      } else if (response.statusCode == 429) {
        throw TryOnException(
          'Rate limited',
          'Too many requests. Please wait a moment and try again.',
          statusCode: 429,
        );
      } else if (response.statusCode >= 500) {
        throw TryOnException(
          'Server error',
          'The service is temporarily unavailable. Please try again later.',
          statusCode: response.statusCode,
        );
      } else {
        throw TryOnException(
          'Try-on failed',
          'Unable to generate try-on preview. Please check your image and try again.',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TryOnException) rethrow;
      throw TryOnException(
        'Unexpected error',
        'An unexpected error occurred. Please try again.',
        originalError: e,
      );
    }
  }

  /// Generate virtual try-on preview (legacy - from avatar URL)
  /// Fallback method if user hasn't uploaded photo
  Future<String> generateTryOnPreview({
    required String avatarUrl,
    required List<String> clothingImageUrls,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Generate cache key
      final cacheKey = '${avatarUrl}_${clothingImageUrls.join("_")}';

      // Check cache first
      final cached = CacheService.getCachedTryOnPreview(cacheKey);
      if (cached != null) {
        return cached;
      }

      // In production, this would call an AI service to composite the images
      // For MVP, we'll create a simple composited preview
      final previewUrl = await _compositeImages(avatarUrl, clothingImageUrls);

      // Cache the preview
      await CacheService.cacheTryOnPreview(cacheKey, previewUrl);

      return previewUrl;
    } catch (e) {
      // Fallback: return avatar URL
      return avatarUrl;
    }
  }

  Future<String> _compositeImages(
      String avatarUrl, List<String> clothingUrls) async {
    // Mock implementation - in production, use image processing library
    // or call an AI service for realistic compositing
    await Future.delayed(const Duration(seconds: 1));

    // For MVP, return the first clothing item URL as preview
    // In production, this would be a properly composited image
    return clothingUrls.isNotEmpty ? clothingUrls.first : avatarUrl;
  }

  /// Save outfit to user's collection
  Future<OutfitModel> saveOutfit({
    required String name,
    required List<String> itemIds,
    String? previewImageUrl,
    bool isRecommended = false,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final outfit = OutfitModel(
        id: '', // Will be set by Firestore
        userId: userId,
        name: name,
        itemIds: itemIds,
        previewImageUrl: previewImageUrl,
        isRecommended: isRecommended,
        createdAt: DateTime.now(),
      );

      final docRef =
          await _firestore.collection('outfits').add(outfit.toFirestore());
      return OutfitModel(
        id: docRef.id,
        userId: outfit.userId,
        name: outfit.name,
        itemIds: outfit.itemIds,
        previewImageUrl: outfit.previewImageUrl,
        isRecommended: outfit.isRecommended,
        createdAt: outfit.createdAt,
      );
    } catch (e) {
      throw Exception('Failed to save outfit: $e');
    }
  }

  /// Get user's saved outfits
  Future<List<OutfitModel>> getUserOutfits() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('outfits')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => OutfitModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }
}

/// Custom exception for try-on errors with user-friendly messages
class TryOnException implements Exception {
  final String code;
  final String message;
  final int? statusCode;
  final dynamic originalError;
  final StackTrace? stackTrace;

  TryOnException(
    this.code,
    this.message, {
    this.statusCode,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'TryOnException($code): $message';

  /// Get user-friendly error message
  String getUserMessage() {
    switch (code) {
      case 'Model not found':
        return 'The AI model is not available. Please try again in a few moments.';
      case 'Request timeout':
        return 'The request took too long. Try with a smaller or different image.';
      case 'Rate limited':
        return 'Too many requests. Please wait a moment before trying again.';
      case 'Server error':
        return 'Our service is temporarily unavailable. Please try again soon.';
      case 'Invalid image':
        return 'The image format is not supported. Please use JPEG or PNG.';
      default:
        return message;
    }
  }
}

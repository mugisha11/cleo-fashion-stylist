import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/outfit_model.dart';
import 'cache_service.dart';

class TryOnService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate virtual try-on preview
  /// Combines avatar and clothing items into a composited preview
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

  Future<String> _compositeImages(String avatarUrl, List<String> clothingUrls) async {
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

      final docRef = await _firestore.collection('outfits').add(outfit.toFirestore());
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


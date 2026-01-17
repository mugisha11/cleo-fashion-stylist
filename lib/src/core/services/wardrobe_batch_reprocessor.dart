import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wardrobe_item_model.dart';
import 'supabase_storage_service.dart';
import 'enhanced_remove_bg_service.dart';
import 'enhanced_ai_vision_service.dart';
import 'package:http/http.dart' as http;

/// Batch Reprocessing Service
/// Reprocesses existing wardrobe images to remove backgrounds and re-analyze with enhanced AI
class WardrobeBatchReprocessor {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseStorageService _storage = SupabaseStorageService(Supabase.instance.client);
  final EnhancedRemoveBgService _removeBgService = EnhancedRemoveBgService();
  final EnhancedAiVisionService _aiVisionService = EnhancedAiVisionService(Supabase.instance.client);

  /// Reprocess all wardrobe items for a user
  /// Returns progress updates via callback
  Future<BatchReprocessResult> reprocessAllItems({
    required Function(int current, int total, String itemId) onProgress,
    bool reprocessBackground = true,
    bool reprocessAI = true,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Fetch all wardrobe items
      final snapshot = await _firestore
          .collection('wardrobe')
          .where('userId', isEqualTo: userId)
          .get();

      final items = snapshot.docs;
      final total = items.length;
      int processed = 0;
      int successCount = 0;
      int failureCount = 0;
      final failures = <String, String>{};

      print('🔄 Starting batch reprocessing: $total items');

      for (final doc in items) {
        try {
          final item = WardrobeItemModel.fromFirestore(doc);
          onProgress(processed, total, item.id);

          // Reprocess background removal if needed
          if (reprocessBackground && (item.processedImageUrl == null || item.processedImageUrl!.isEmpty)) {
            print('🎨 Reprocessing background removal for ${item.id}...');
            await _reprocessBackground(item);
          }

          // Reprocess AI analysis if needed
          if (reprocessAI && (item.aiConfidence == null || item.aiConfidence! < 0.7)) {
            print('🤖 Reprocessing AI analysis for ${item.id}...');
            await _reprocessAIAnalysis(item);
          }

          successCount++;
        } catch (e) {
          print('❌ Failed to reprocess ${doc.id}: $e');
          failureCount++;
          failures[doc.id] = e.toString();
        }

        processed++;
        onProgress(processed, total, doc.id);
      }

      print('✅ Batch reprocessing complete: $successCount success, $failureCount failures');

      return BatchReprocessResult(
        total: total,
        success: successCount,
        failures: failureCount,
        failureDetails: failures,
      );
    } catch (e) {
      print('❌ Batch reprocessing error: $e');
      throw Exception('Batch reprocessing failed: $e');
    }
  }

  /// Reprocess background removal for a single item
  Future<void> _reprocessBackground(WardrobeItemModel item) async {
    try {
      // Download original image
      final imageResponse = await http.get(Uri.parse(item.imageUrl));
      if (imageResponse.statusCode != 200) {
        throw Exception('Failed to download image: ${imageResponse.statusCode}');
      }

      final imageBytes = imageResponse.bodyBytes;

      // Remove background
      final processedBytes = await _removeBgService.removeBackground(
        imageFile: imageBytes,
        retryOnFailure: true,
      );

      if (processedBytes == null) {
        throw Exception('Background removal failed');
      }

      // Upload processed image
      final userId = _auth.currentUser?.uid!;
      final imageId = item.id;
      final processedImagePath = 'wardrobe/$userId/${imageId}_processed.png';
      
      final processedImageUrl = await _storage.uploadFile(
        bucket: 'wardrobe',
        path: processedImagePath,
        file: processedBytes,
        contentType: 'image/png',
      );

      // Update Firestore
      await _firestore.collection('wardrobe').doc(item.id).update({
        'processedImageUrl': processedImageUrl,
      });

      print('✅ Background reprocessed for ${item.id}');
    } catch (e) {
      print('❌ Background reprocessing failed for ${item.id}: $e');
      rethrow;
    }
  }

  /// Reprocess AI analysis for a single item
  Future<void> _reprocessAIAnalysis(WardrobeItemModel item) async {
    try {
      // Use processed image if available, otherwise original
      final imageUrl = item.processedImageUrl ?? item.imageUrl;

      // Download image
      final imageResponse = await http.get(Uri.parse(imageUrl));
      if (imageResponse.statusCode != 200) {
        throw Exception('Failed to download image: ${imageResponse.statusCode}');
      }

      final imageBytes = imageResponse.bodyBytes;

      // Run enhanced AI analysis
      final analysis = await _aiVisionService.analyzeClothing(
        imageBytes: imageBytes,
        imageUrl: imageUrl,
      );

      // Update Firestore with new analysis
      await _firestore.collection('wardrobe').doc(item.id).update({
        'category': analysis.category,
        'subcategory': analysis.subcategory,
        'aiConfidence': analysis.confidence,
        'pattern': analysis.pattern,
        'patternConfidence': analysis.patternConfidence,
        'genderStyle': analysis.genderStyle,
        'fit': analysis.fit,
        'season': analysis.season,
        'occasion': analysis.occasion,
        'fabric': analysis.fabric,
        'bodyRegion': analysis.bodyRegion,
        'layeringCompatibility': analysis.layeringCompatibility,
        'colorTags': analysis.colors.map((c) => c.name).toList(),
        'colorPalette': analysis.colors.map((c) => c.toJson()).toList(),
        'aiAttributes': analysis.attributes,
      });

      print('✅ AI analysis reprocessed for ${item.id}');
    } catch (e) {
      print('❌ AI analysis reprocessing failed for ${item.id}: $e');
      rethrow;
    }
  }

  /// Reprocess a single item by ID
  Future<void> reprocessItem(String itemId, {
    bool reprocessBackground = true,
    bool reprocessAI = true,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final doc = await _firestore.collection('wardrobe').doc(itemId).get();
    if (!doc.exists) {
      throw Exception('Item not found: $itemId');
    }

    final item = WardrobeItemModel.fromFirestore(doc);
    if (item.userId != userId) {
      throw Exception('Unauthorized: Item belongs to different user');
    }

    if (reprocessBackground) {
      await _reprocessBackground(item);
    }

    if (reprocessAI) {
      await _reprocessAIAnalysis(item);
    }
  }
}

/// Batch reprocessing result
class BatchReprocessResult {
  final int total;
  final int success;
  final int failures;
  final Map<String, String> failureDetails;

  BatchReprocessResult({
    required this.total,
    required this.success,
    required this.failures,
    required this.failureDetails,
  });

  double get successRate => total > 0 ? success / total : 0.0;
}

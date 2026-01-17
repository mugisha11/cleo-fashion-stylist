import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wardrobe_item_model.dart';
import 'cache_service.dart';
import 'supabase_storage_service.dart';
import 'enhanced_remove_bg_service.dart';
import 'enhanced_ai_vision_service.dart';

class WardrobeService {
  final SupabaseStorageService _storage;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EnhancedRemoveBgService _removeBgService = EnhancedRemoveBgService();
  final EnhancedAiVisionService _aiVisionService = EnhancedAiVisionService(Supabase.instance.client);

  WardrobeService() : _storage = SupabaseStorageService(Supabase.instance.client);

  /// Upload a clothing item to wardrobe
  /// Automatically processes background removal and AI analysis
  /// Accepts File (mobile) or Uint8List (web)
  Future<WardrobeItemModel> uploadItem({
    required dynamic imageFile, // File on mobile, Uint8List on web
    String? category, // Optional - will be auto-detected if not provided
    List<String>? colorTags, // Optional - will be auto-extracted if not provided
    String? brand,
    String? notes,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Upload original image to Supabase Storage
      final imageId = DateTime.now().millisecondsSinceEpoch.toString();
      final imagePath = 'wardrobe/$userId/$imageId.jpg';
      
      String imageUrl;
      try {
        imageUrl = await _storage.uploadFile(
        bucket: 'wardrobe',
        path: imagePath,
        file: imageFile,
        contentType: 'image/jpeg',
      );
      } catch (storageError) {
        throw Exception('Storage upload failed: $storageError. Make sure the "wardrobe" bucket exists in Supabase Storage.');
      }

      // Step 1: Process image with remove.bg to remove background
      String? processedImageUrl;
      Uint8List? processedImageBytes;
      try {
        print('🎨 Step 1: Processing image with remove.bg...');
        processedImageBytes = await _removeBgService.removeBackground(
          imageFile: imageFile,
        );
        
        if (processedImageBytes != null) {
          // Upload processed image (PNG format)
          final processedImagePath = 'wardrobe/$userId/${imageId}_processed.png';
          processedImageUrl = await _storage.uploadFile(
            bucket: 'wardrobe',
            path: processedImagePath,
            file: processedImageBytes,
            contentType: 'image/png',
          );
          print('✅ Background removed successfully');
        } else {
          print('⚠️ Background removal failed, using original image');
        }
      } catch (e) {
        print('⚠️ Background removal error: $e - continuing with original image');
        // Continue with original image if processing fails
      }

      // Step 2: AI Vision Analysis - Analyze the processed image (or original if processing failed)
      String detectedCategory = category ?? 'Other';
      List<String> extractedColors = colorTags ?? [];
      String? detectedPattern;
      Map<String, dynamic>? aiAttributes;
      double? aiConfidence;
      List<Map<String, dynamic>>? colorPalette;

      try {
        print('🤖 Step 2: Running AI vision analysis...');
        
        // Use processed image if available, otherwise use original
        final imageBytesForAnalysis = processedImageBytes ?? 
            (kIsWeb 
                ? (imageFile is Uint8List ? imageFile : null)
                : await _getImageBytes(imageFile));
        
        if (imageBytesForAnalysis != null) {
          // MEMORY OPTIMIZATION: Limit image size before analysis
          // Large images can cause out-of-memory errors
          final maxSizeBytes = 5 * 1024 * 1024; // 5MB limit
          Uint8List? optimizedBytes = imageBytesForAnalysis;
          
          if (imageBytesForAnalysis.length > maxSizeBytes) {
            print('⚠️ Image is large (${(imageBytesForAnalysis.length / 1024 / 1024).toStringAsFixed(2)}MB), optimizing for analysis...');
            // The AI vision service will resize internally, but we can also
            // pre-optimize here if needed
            optimizedBytes = imageBytesForAnalysis;
          }
          
          final analysis = await _aiVisionService.analyzeClothing(
            imageBytes: optimizedBytes!,
            imageUrl: processedImageUrl ?? imageUrl,
          );

          // Use AI-detected category if not provided
          if (category == null || category.isEmpty) {
            detectedCategory = _normalizeCategory(analysis.category);
            aiConfidence = analysis.confidence;
            print('✅ AI detected category: $detectedCategory (confidence: ${analysis.confidence.toStringAsFixed(2)})');
          }

          // Extract colors from AI analysis
          if (colorTags == null || colorTags.isEmpty) {
            extractedColors = analysis.colors.map((c) => c.name).toList();
            colorPalette = analysis.colors.map((c) => c.toJson()).toList();
            print('✅ AI extracted colors: ${extractedColors.join(", ")}');
          }

          // Store pattern and attributes
          detectedPattern = analysis.pattern;
          aiAttributes = analysis.attributes;
          
          print('✅ AI analysis complete: pattern=$detectedPattern, attributes=${aiAttributes?.keys.join(", ")}');
        } else {
          print('⚠️ Could not get image bytes for AI analysis');
        }
      } catch (e) {
        print('⚠️ AI vision analysis error: $e - using provided/default values');
        // Continue with provided or default values
      }

      // Extract additional attributes from AI analysis or set defaults
      final detectedSubcategory = aiAttributes?['subcategory'] as String?;
      final genderStyle = aiAttributes?['genderStyle'] as String? ?? aiAttributes?['gender_style'] as String?;
      final fit = aiAttributes?['fit'] as String?;
      final season = aiAttributes?['season'] != null 
          ? (aiAttributes!['season'] is List 
              ? List<String>.from(aiAttributes!['season'] as List)
              : [aiAttributes!['season'].toString()])
          : null;
      final occasion = aiAttributes?['occasion'] != null
          ? (aiAttributes!['occasion'] is List
              ? List<String>.from(aiAttributes!['occasion'] as List)
              : [aiAttributes!['occasion'].toString()])
          : null;
      final fabric = aiAttributes?['fabric'] as String?;
      final bodyRegion = aiAttributes?['bodyRegion'] as String? ?? aiAttributes?['body_region'] as String?;
      final layeringCompatibility = aiAttributes?['layeringCompatibility'] as bool? ?? aiAttributes?['layering_compatibility'] as bool?;
      final patternConfidence = aiAttributes?['patternConfidence'] != null
          ? (aiAttributes!['patternConfidence'] as num?)?.toDouble()
          : aiAttributes?['pattern_confidence'] != null
              ? (aiAttributes!['pattern_confidence'] as num?)?.toDouble()
              : null;

      // Step 3: Create Firestore document with all comprehensive metadata
      final item = WardrobeItemModel(
        id: '', // Will be set by Firestore
        userId: userId,
        imageUrl: imageUrl,
        processedImageUrl: processedImageUrl, // MUST be set - no background images allowed
        category: detectedCategory,
        colorTags: extractedColors,
        brand: brand,
        notes: notes,
        createdAt: DateTime.now(),
        aiConfidence: aiConfidence,
        pattern: detectedPattern,
        patternConfidence: patternConfidence,
        aiAttributes: aiAttributes,
        colorPalette: colorPalette,
        subcategory: detectedSubcategory,
        genderStyle: genderStyle,
        fit: fit,
        season: season,
        occasion: occasion,
        fabric: fabric,
        bodyRegion: bodyRegion,
        layeringCompatibility: layeringCompatibility,
      );

      WardrobeItemModel createdItem;
      try {
        final firestoreData = item.toFirestore();
        print('💾 Saving to Firestore: userId=$userId, category=${item.category}');
        print('💾 Firestore data: $firestoreData');
        
        final docRef = await _firestore.collection('wardrobe').add(firestoreData);
        createdItem = item.copyWith(id: docRef.id);
        
        print('✅ Successfully saved to Firestore with ID: ${docRef.id}');
      } catch (firestoreError) {
        print('❌ Firestore save failed: $firestoreError');
        // If Firestore fails, try to delete the uploaded image
        try {
          await _storage.deleteFile(bucket: 'wardrobe', path: imagePath);
        } catch (_) {
          // Ignore cleanup errors
        }
        throw Exception('Firestore save failed: $firestoreError');
      }

      // Cache item - convert Timestamp to String for Hive
      try {
      final cacheData = createdItem.toFirestore();
      final createdAt = cacheData['createdAt'];
      if (createdAt is Timestamp) {
        cacheData['createdAt'] = createdAt.toDate().toIso8601String();
      }
        await CacheService.cacheWardrobeItem(createdItem.id, cacheData);
      } catch (cacheError) {
        // Don't fail upload if caching fails
        print('Warning: Failed to cache item: $cacheError');
      }

      return createdItem;
    } catch (e) {
      // Re-throw with more context
      if (e is Exception) {
        throw e;
      }
      throw Exception('Failed to upload item: $e');
    }
  }

  /// Helper: Get image bytes from file
  Future<Uint8List?> _getImageBytes(dynamic imageFile) async {
    if (kIsWeb) {
      // On web, only Uint8List is supported
      return imageFile is Uint8List ? imageFile : null;
    } else {
      try {
        // On mobile, File has readAsBytes() method
        if (imageFile is Uint8List) {
          return imageFile;
        } else {
          // Try to read as File (dart:io)
          try {
            final fileBytes = await (imageFile as dynamic).readAsBytes();
            return fileBytes;
          } catch (e) {
            print('Error reading image file: $e');
            return null;
          }
        }
      } catch (e) {
        print('Error reading image file: $e');
      }
    }
    return null;
  }

  /// Normalize category name to standard format
  String _normalizeCategory(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('top') || cat.contains('shirt') || cat.contains('blouse') || cat.contains('t-shirt')) {
      return 'Top';
    } else if (cat.contains('bottom') || cat.contains('pant') || cat.contains('jean')) {
      return cat.contains('jean') ? 'Jeans' : 'Pants';
    } else if (cat.contains('dress')) {
      return 'Dress';
    } else if (cat.contains('skirt')) {
      return 'Skirt';
    } else if (cat.contains('jacket') || cat.contains('coat') || cat.contains('outer')) {
      return 'Outerwear';
    } else if (cat.contains('shoe') || cat.contains('sneaker') || cat.contains('boot')) {
      return 'Shoes';
    } else if (cat.contains('accessory') || cat.contains('bag') || cat.contains('hat')) {
      return 'Accessories';
    }
    return category;
  }

  /// Get all wardrobe items for current user
  Future<List<WardrobeItemModel>> getUserWardrobe() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('⚠️ getUserWardrobe: User not authenticated');
      return [];
    }

    print('📦 getUserWardrobe: Fetching for userId: $userId');

    try {
      // Always fetch from Firestore first (don't rely on cache for fresh data)
      print('📦 getUserWardrobe: Querying Firestore...');
      QuerySnapshot snapshot;
      List<QueryDocumentSnapshot> docsToProcess;
      
      try {
        snapshot = await _firestore
            .collection('wardrobe')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();
        docsToProcess = snapshot.docs;
      } catch (e) {
        // If orderBy fails (missing index), try without orderBy
        print('⚠️ OrderBy query failed, trying without orderBy: $e');
        snapshot = await _firestore
            .collection('wardrobe')
            .where('userId', isEqualTo: userId)
            .get();
        // Sort manually
        final docs = snapshot.docs.toList()
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime); // Descending
          });
        docsToProcess = docs;
      }
      
      print('📦 getUserWardrobe: Found ${docsToProcess.length} items in Firestore');

      final items = docsToProcess
          .map((doc) {
            try {
              return WardrobeItemModel.fromFirestore(doc);
            } catch (e) {
              print('⚠️ Error parsing document ${doc.id}: $e');
              return null;
            }
          })
          .whereType<WardrobeItemModel>()
          .toList();

      print('📦 getUserWardrobe: Successfully parsed ${items.length} items');

      // Cache all items
      for (final item in items) {
        try {
          final cacheData = item.toFirestore();
          // Convert Timestamp to String for Hive
          if (cacheData['createdAt'] is Timestamp) {
            cacheData['createdAt'] = (cacheData['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          await CacheService.cacheWardrobeItem(item.id, cacheData);
        } catch (e) {
          print('⚠️ Error caching item ${item.id}: $e');
        }
      }

      return items;
    } catch (e) {
      print('❌ getUserWardrobe: Firestore error: $e');
      // Try to return cached items as fallback
      final cachedItems = _getCachedWardrobe();
      print('📦 getUserWardrobe: Returning ${cachedItems.length} cached items as fallback');
      return cachedItems;
    }
  }

  List<WardrobeItemModel> _getCachedWardrobe() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final box = CacheService.wardrobeBox;
    if (box == null) return [];
    
    final items = <WardrobeItemModel>[];

    final boxKeys = box.keys.toList();
    for (final key in boxKeys) {
      final data = box.get(key) as Map<String, dynamic>?;
      if (data != null && data['userId'] == userId) {
        try {
          // Parse createdAt - handle both Timestamp and String
          DateTime createdAt;
          if (data['createdAt'] is String) {
            createdAt = DateTime.parse(data['createdAt'] as String);
          } else {
            createdAt = DateTime.now();
          }
          
          items.add(WardrobeItemModel(
            id: key.toString(),
            userId: data['userId'] as String,
            imageUrl: data['imageUrl'] as String,
            processedImageUrl: data['processedImageUrl'] as String?,
            category: data['category'] as String,
            colorTags: List<String>.from(data['colorTags'] as List),
            brand: data['brand'] as String?,
            notes: data['notes'] as String?,
            createdAt: createdAt,
            aiConfidence: (data['aiConfidence'] as num?)?.toDouble(),
            pattern: data['pattern'] as String?,
            aiAttributes: data['aiAttributes'] as Map<String, dynamic>?,
            colorPalette: data['colorPalette'] != null
                ? List<Map<String, dynamic>>.from(data['colorPalette'] as List)
                : null,
          ));
        } catch (e) {
          // Skip invalid cached items
        }
      }
    }

    return items;
  }

  Future<void> _syncWardrobeFromFirestore(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('wardrobe')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        final item = WardrobeItemModel.fromFirestore(doc);
        await CacheService.cacheWardrobeItem(item.id, item.toFirestore());
      }
    } catch (e) {
      // Silent fail - cache is still available
    }
  }

  /// Delete a wardrobe item
  /// Deletes from Firestore, Storage (both original and processed images), and cache
  Future<void> deleteItem(String itemId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    print('🗑️ Deleting wardrobe item: $itemId');

    try {
      // First, fetch the item to get image URLs
      final doc = await _firestore.collection('wardrobe').doc(itemId).get();
      if (!doc.exists) {
        throw Exception('Item not found');
      }

      // Verify userId matches (security check)
      final data = doc.data() as Map<String, dynamic>;
      final itemUserId = data['userId'] as String?;
      if (itemUserId != userId) {
        throw Exception('Permission denied: You can only delete your own items');
      }

      final imageUrl = data['imageUrl'] as String?;
      final processedImageUrl = data['processedImageUrl'] as String?;

      // Delete from Firestore first
      print('🗑️ Deleting from Firestore...');
      await _firestore.collection('wardrobe').doc(itemId).delete();
      print('✅ Deleted from Firestore');

      // Delete original image from Supabase Storage
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final imagePath = _extractPathFromUrl(imageUrl);
          if (imagePath != null && imagePath.isNotEmpty) {
            print('🗑️ Deleting original image: $imagePath');
            await _storage.deleteFile(
              bucket: 'wardrobe',
              path: imagePath,
            );
            print('✅ Deleted original image');
          } else {
            print('⚠️ Could not extract path from imageUrl: $imageUrl');
          }
        } catch (e) {
          print('⚠️ Failed to delete original image: $e');
          // Continue - don't fail if image deletion fails
        }
      }

      // Delete processed image from Supabase Storage
      if (processedImageUrl != null && processedImageUrl.isNotEmpty) {
        try {
          final processedPath = _extractPathFromUrl(processedImageUrl);
          if (processedPath != null && processedPath.isNotEmpty) {
            print('🗑️ Deleting processed image: $processedPath');
        await _storage.deleteFile(
          bucket: 'wardrobe',
              path: processedPath,
            );
            print('✅ Deleted processed image');
          } else {
            print('⚠️ Could not extract path from processedImageUrl: $processedImageUrl');
          }
        } catch (e) {
          print('⚠️ Failed to delete processed image: $e');
          // Continue - don't fail if image deletion fails
        }
      }

      // Remove from cache
      try {
      final cacheBox = CacheService.wardrobeBox;
      if (cacheBox != null) {
        await cacheBox.delete(itemId);
          print('✅ Removed from cache');
        }
      } catch (e) {
        print('⚠️ Failed to remove from cache: $e');
        // Continue - cache cleanup is not critical
      }

      print('✅ Successfully deleted item: $itemId');
    } catch (e) {
      print('❌ Failed to delete item: $e');
      throw Exception('Failed to delete item: $e');
    }
  }

  /// Extract storage path from Supabase public URL
  String? _extractPathFromUrl(String url) {
    try {
      // Supabase URLs are typically:
      // https://[project].supabase.co/storage/v1/object/public/wardrobe/path/to/file.jpg
      // OR
      // https://[project].supabase.co/storage/v1/object/sign/wardrobe/path/to/file.jpg?token=...
      
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      // Find 'wardrobe' in the path segments
      final wardrobeIndex = pathSegments.indexOf('wardrobe');
      if (wardrobeIndex != -1 && wardrobeIndex < pathSegments.length - 1) {
        // Get everything after 'wardrobe'
        final pathParts = pathSegments.sublist(wardrobeIndex + 1);
        final extractedPath = pathParts.join('/');
        print('📂 Extracted path from URL: $extractedPath');
        return extractedPath;
      }
      
      // Alternative: Check if URL contains '/wardrobe/' directly
      final wardrobeMatch = RegExp(r'/wardrobe/(.+)').firstMatch(url);
      if (wardrobeMatch != null) {
        final extractedPath = wardrobeMatch.group(1);
        // Remove query parameters if present
        final cleanPath = extractedPath?.split('?').first;
        if (cleanPath != null && cleanPath.isNotEmpty) {
          print('📂 Extracted path from URL (regex): $cleanPath');
          return cleanPath;
        }
      }
      
      print('⚠️ Could not extract path from URL: $url');
      return null;
    } catch (e) {
      print('⚠️ Error extracting path from URL: $e');
      return null;
    }
  }

  /// Get wardrobe item by ID
  /// Fetches from Firestore with userId verification for security
  Future<WardrobeItemModel?> getItemById(String itemId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('⚠️ getItemById: User not authenticated');
      throw Exception('User not authenticated');
    }

    try {
      print('📋 Fetching item by ID: $itemId');
      
      // Always fetch from Firestore for fresh data
      // Cache is only used as fallback if Firestore fails
      final doc = await _firestore.collection('wardrobe').doc(itemId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          print('⚠️ Document exists but has no data');
          return null;
        }

        // Security check: verify userId matches
        final itemUserId = data['userId'] as String?;
        if (itemUserId != userId) {
          print('⚠️ Permission denied: Item belongs to different user');
          throw Exception('Permission denied: You can only view your own items');
        }

        final item = WardrobeItemModel.fromFirestore(doc);
        print('✅ Item loaded successfully: ${item.category}');
        
        // Cache item for offline access
        try {
        final cacheData = item.toFirestore();
        final createdAt = cacheData['createdAt'];
        if (createdAt is Timestamp) {
          cacheData['createdAt'] = createdAt.toDate().toIso8601String();
        }
        await CacheService.cacheWardrobeItem(itemId, cacheData);
        } catch (cacheError) {
          print('⚠️ Failed to cache item: $cacheError');
          // Non-critical, continue
        }
        
        return item;
      } else {
        print('⚠️ Item not found in Firestore: $itemId');
        // Try cache as fallback
        final cached = CacheService.getCachedWardrobeItem(itemId);
        if (cached != null) {
          print('📋 Using cached item as fallback');
          return WardrobeItemModel(
            id: itemId,
            userId: cached['userId'] as String,
            imageUrl: cached['imageUrl'] as String,
            processedImageUrl: cached['processedImageUrl'] as String?,
            category: cached['category'] as String,
            colorTags: List<String>.from(cached['colorTags'] as List),
            brand: cached['brand'] as String?,
            notes: cached['notes'] as String?,
            createdAt: cached['createdAt'] is String
                ? DateTime.parse(cached['createdAt'] as String)
                : DateTime.now(),
            aiConfidence: (cached['aiConfidence'] as num?)?.toDouble(),
            pattern: cached['pattern'] as String?,
            aiAttributes: cached['aiAttributes'] as Map<String, dynamic>?,
            colorPalette: cached['colorPalette'] != null
                ? List<Map<String, dynamic>>.from(cached['colorPalette'] as List)
                : null,
          );
        }
        return null;
      }
    } catch (e) {
      print('❌ Error fetching item by ID: $e');
      rethrow; // Re-throw to let caller handle the error
    }
  }
}


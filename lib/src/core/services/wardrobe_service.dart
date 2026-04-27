import 'dart:typed_data';
import 'dart:convert' show jsonEncode, jsonDecode;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
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
  final EnhancedAiVisionService _aiVisionService =
      EnhancedAiVisionService(Supabase.instance.client);

  WardrobeService()
      : _storage = SupabaseStorageService(Supabase.instance.client);

  /// Upload a clothing item to wardrobe
  /// Automatically processes background removal and AI analysis
  /// Accepts File (mobile) or Uint8List (web)
  Future<WardrobeItemModel> uploadItem({
    required dynamic imageFile, // File on mobile, Uint8List on web
    String? category, // Optional - will be auto-detected if not provided
    List<String>?
        colorTags, // Optional - will be auto-extracted if not provided
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
        throw Exception(
            'Storage upload failed: $storageError. Make sure the "wardrobe" bucket exists in Supabase Storage.');
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
          final processedImagePath =
              'wardrobe/$userId/${imageId}_processed.png';
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
        print(
            '⚠️ Background removal error: $e - continuing with original image');
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
          const maxSizeBytes = 5 * 1024 * 1024; // 5MB limit
          Uint8List? optimizedBytes = imageBytesForAnalysis;

          if (imageBytesForAnalysis.length > maxSizeBytes) {
            print(
                '⚠️ Image is large (${(imageBytesForAnalysis.length / 1024 / 1024).toStringAsFixed(2)}MB), optimizing for analysis...');
            // The AI vision service will resize internally, but we can also
            // pre-optimize here if needed
            optimizedBytes = imageBytesForAnalysis;
          }

          final analysis = await _aiVisionService.analyzeClothing(
            imageBytes: optimizedBytes,
            imageUrl: processedImageUrl ?? imageUrl,
          );

          // Use AI-detected category if not provided
          if (category == null || category.isEmpty) {
            detectedCategory = _normalizeCategory(analysis.category);
            aiConfidence = analysis.confidence;
            print(
                '✅ AI detected category: $detectedCategory (confidence: ${analysis.confidence.toStringAsFixed(2)})');
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

          print(
              '✅ AI analysis complete: pattern=$detectedPattern, attributes=${aiAttributes.keys.join(", ")}');
        } else {
          print('⚠️ Could not get image bytes for AI analysis');
        }
      } catch (e) {
        print(
            '⚠️ AI vision analysis error: $e - using provided/default values');
        // Continue with provided or default values
      }

      // Extract additional attributes from AI analysis or set defaults
      final detectedSubcategory = aiAttributes?['subcategory'] as String?;
      final genderStyle = aiAttributes?['genderStyle'] as String? ??
          aiAttributes?['gender_style'] as String?;
      final fit = aiAttributes?['fit'] as String?;
      final season = aiAttributes?['season'] != null
          ? (aiAttributes!['season'] is List
              ? List<String>.from(aiAttributes['season'] as List)
              : [aiAttributes['season'].toString()])
          : null;
      final occasion = aiAttributes?['occasion'] != null
          ? (aiAttributes!['occasion'] is List
              ? List<String>.from(aiAttributes['occasion'] as List)
              : [aiAttributes['occasion'].toString()])
          : null;
      final fabric = aiAttributes?['fabric'] as String?;
      final bodyRegion = aiAttributes?['bodyRegion'] as String? ??
          aiAttributes?['body_region'] as String?;
      final layeringCompatibility =
          aiAttributes?['layeringCompatibility'] as bool? ??
              aiAttributes?['layering_compatibility'] as bool?;
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
        processedImageUrl:
            processedImageUrl, // MUST be set - no background images allowed
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
        print(
            '💾 Saving to Firestore: userId=$userId, category=${item.category}');
        print('💾 Firestore data: $firestoreData');

        final docRef =
            await _firestore.collection('wardrobe').add(firestoreData);
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
        rethrow;
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
    if (cat.contains('top') ||
        cat.contains('shirt') ||
        cat.contains('blouse') ||
        cat.contains('t-shirt')) {
      return 'Top';
    } else if (cat.contains('bottom') ||
        cat.contains('pant') ||
        cat.contains('jean')) {
      return cat.contains('jean') ? 'Jeans' : 'Pants';
    } else if (cat.contains('dress')) {
      return 'Dress';
    } else if (cat.contains('skirt')) {
      return 'Skirt';
    } else if (cat.contains('jacket') ||
        cat.contains('coat') ||
        cat.contains('outer')) {
      return 'Outerwear';
    } else if (cat.contains('shoe') ||
        cat.contains('sneaker') ||
        cat.contains('boot')) {
      return 'Shoes';
    } else if (cat.contains('accessory') ||
        cat.contains('bag') ||
        cat.contains('hat')) {
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

      print(
          '📦 getUserWardrobe: Found ${docsToProcess.length} items in Firestore');

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
            cacheData['createdAt'] = (cacheData['createdAt'] as Timestamp)
                .toDate()
                .toIso8601String();
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
      print(
          '📦 getUserWardrobe: Returning ${cachedItems.length} cached items as fallback');
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
        throw Exception(
            'Permission denied: You can only delete your own items');
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
            print(
                '⚠️ Could not extract path from processedImageUrl: $processedImageUrl');
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
        final data = doc.data();
        if (data == null) {
          print('⚠️ Document exists but has no data');
          return null;
        }

        // Security check: verify userId matches
        final itemUserId = data['userId'] as String?;
        if (itemUserId != userId) {
          print('⚠️ Permission denied: Item belongs to different user');
          throw Exception(
              'Permission denied: You can only view your own items');
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
                ? List<Map<String, dynamic>>.from(
                    cached['colorPalette'] as List)
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

  /// Generate professional AI description for a wardrobe item
  /// Uses backend API with Gemini Nano via OpenRouter or OpenAI
  Future<String> generateItemDescription(WardrobeItemModel item) async {
    try {
      print('🤖 Generating AI description for: ${item.id}');

      // Prepare request data
      final requestBody = {
        'item': {
          'category': item.category,
          'subcategory': item.subcategory,
          'brand': item.brand,
          'fit': item.fit,
          'fabric': item.fabric,
          'pattern': item.pattern,
          'colors': item.colorTags,
          'occasion': item.occasion ?? [],
          'season': item.season ?? [],
        }
      };

      // Call backend API
      final response = await http
          .post(
            Uri.parse('http://localhost:8000/wardrobe-ai/description'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final description = data['description'] as String? ?? '';

        if (description.isNotEmpty) {
          print('✅ Description generated successfully (${data["model"]})');
          return description;
        }
      }

      print('⚠️ API returned non-200 status: ${response.statusCode}');
      return _createFallbackDescription(item);
    } catch (e) {
      print('❌ Error generating description: $e');
      return _createFallbackDescription(item);
    }
  }

  /// Create a fallback description when AI fails
  String _createFallbackDescription(WardrobeItemModel item) {
    final parts = <String>[];

    // Add main description
    if (item.subcategory != null && item.subcategory!.isNotEmpty) {
      parts.add('A ${item.subcategory!.toLowerCase()}');
    } else {
      parts.add('A ${item.category.toLowerCase()}');
    }

    // Add style info
    if (item.fit != null && item.fit!.isNotEmpty) {
      parts.add('with ${item.fit!.toLowerCase()} fit');
    }

    if (item.pattern != null && item.pattern!.isNotEmpty) {
      parts.add('featuring a ${item.pattern!.toLowerCase()} pattern');
    }

    // Add occasion if available
    if (item.occasion != null && item.occasion!.isNotEmpty) {
      parts.add('perfect for ${item.occasion!.join(", ")}');
    }

    return '${parts.join(' ').replaceAll('  ', ' ')}.';
  }

  /// Generate outfit recommendations that match this item
  /// Returns list of recommended outfit combinations
  Future<List<WardrobeOutfitSuggestion>> generateOutfitRecommendations(
    WardrobeItemModel item,
  ) async {
    try {
      print('👔 Generating outfit recommendations for: ${item.id}');

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get user's wardrobe (up to 20 items for context)
      final wardrobe = await getUserWardrobe();
      final wardrobeForContext = wardrobe
          .where((i) => i.id != item.id) // Exclude current item
          .take(20)
          .map((i) => {
                'category': i.category,
                'subcategory': i.subcategory,
                'brand': i.brand,
                'colors': i.colorTags,
                'pattern': i.pattern,
                'occasion': i.occasion ?? [],
              })
          .toList();

      // Prepare request data
      final requestBody = {
        'main_item': {
          'category': item.category,
          'subcategory': item.subcategory,
          'brand': item.brand,
          'fit': item.fit,
          'fabric': item.fabric,
          'pattern': item.pattern,
          'colors': item.colorTags,
          'occasion': item.occasion ?? [],
          'season': item.season ?? [],
        },
        'wardrobe_items': wardrobeForContext,
        'limit': 3,
        'include_online': true, // Include online shopping recommendations
      };

      // Call backend API
      final response = await http
          .post(
            Uri.parse('http://localhost:8000/wardrobe-ai/recommendations'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final recommendations = data['recommendations'] as List?;

        if (recommendations != null && recommendations.isNotEmpty) {
          print(
              '✅ Generated ${recommendations.length} outfit recommendations (${data["model"]})');

          return recommendations.asMap().entries.map((entry) {
            final idx = entry.key;
            final rec = entry.value as Map<String, dynamic>? ?? {};
            final itemIds = rec['item_ids'] != null && rec['item_ids'] is List
                ? List<String>.from(
                    (rec['item_ids'] as List).map((e) => e.toString()))
                : <String>[];

            return WardrobeOutfitSuggestion(
              id: 'rec-$idx',
              title: rec['title'] as String? ?? 'Outfit ${idx + 1}',
              description: rec['description'] as String? ?? '',
              reason: rec['reason'] as String? ??
                  'Works well with ${item.category}',
              itemIds: itemIds.isNotEmpty ? itemIds : [item.id],
              source: rec['source'] as String? ?? 'wardrobe',
              price: (rec['price'] as num?)?.toDouble(),
              sourceLink: rec['source_link'] as String?,
              sourceStore: rec['source_store'] as String?,
            );
          }).toList();
        }
      }

      print(
          '⚠️ API returned non-200 status or empty recommendations: ${response.statusCode}');
      return _createFallbackRecommendations(item, wardrobe);
    } catch (e) {
      print('❌ Error generating recommendations: $e');
      try {
        final wardrobe = await getUserWardrobe();
        return _createFallbackRecommendations(item, wardrobe);
      } catch (_) {
        return [];
      }
    }
  }

  /// Create fallback recommendations when AI fails
  List<WardrobeOutfitSuggestion> _createFallbackRecommendations(
    WardrobeItemModel item,
    List<WardrobeItemModel> wardrobe,
  ) {
    final recommendations = <WardrobeOutfitSuggestion>[];
    final usedItemIds = <String>{
      item.id
    }; // Track used items to avoid duplicates

    // 1. Complete Outfit - Find the best complementary pieces
    final completeOutfit = _createCompleteOutfit(item, wardrobe, usedItemIds);
    if (completeOutfit != null) {
      recommendations.add(completeOutfit);
    }

    // 2. Seasonal/Weather Appropriate Outfit
    final seasonalOutfit = _createSeasonalOutfit(item, wardrobe, usedItemIds);
    if (seasonalOutfit != null) {
      recommendations.add(seasonalOutfit);
    }

    // 3. Occasion-Specific Outfit
    final occasionOutfit = _createOccasionOutfit(item, wardrobe, usedItemIds);
    if (occasionOutfit != null) {
      recommendations.add(occasionOutfit);
    }

    // 4. Style-Coordinated Outfit (similar colors/patterns)
    final styleOutfit =
        _createStyleCoordinatedOutfit(item, wardrobe, usedItemIds);
    if (styleOutfit != null) {
      recommendations.add(styleOutfit);
    }

    // 5. Online Enhancement Suggestions (when wardrobe is limited)
    final onlineSuggestions =
        _createOnlineEnhancementSuggestions(item, wardrobe);
    recommendations.addAll(onlineSuggestions);

    // Ensure we have at least one recommendation
    if (recommendations.isEmpty) {
      recommendations.add(WardrobeOutfitSuggestion(
        id: 'basic-match',
        title: 'Simple Coordination',
        description:
            'A basic outfit pairing your selected item with complementary pieces.',
        reason: 'This creates a balanced look using items from your wardrobe.',
        itemIds: [item.id],
        source: 'wardrobe',
      ));
    }

    return recommendations.take(4).toList(); // Limit to 4 recommendations
  }

  WardrobeOutfitSuggestion? _createCompleteOutfit(
    WardrobeItemModel mainItem,
    List<WardrobeItemModel> wardrobe,
    Set<String> usedItemIds,
  ) {
    final complementaryCategories =
        _getComplementaryCategories(mainItem.category);
    final matchedItems = <WardrobeItemModel>[];

    for (final category in complementaryCategories) {
      final candidates = wardrobe
          .where((item) =>
              !usedItemIds.contains(item.id) &&
              item.category.toLowerCase() == category.toLowerCase())
          .toList();

      if (candidates.isEmpty) continue;

      // Sort by stylist-like matching score
      candidates.sort((a, b) => _stylistMatchScore(b, mainItem, matchedItems)
          .compareTo(_stylistMatchScore(a, mainItem, matchedItems)));

      final bestMatch = candidates.first;
      matchedItems.add(bestMatch);
      usedItemIds.add(bestMatch.id);
    }

    if (matchedItems.isEmpty) return null;

    final allItemIds = [mainItem.id, ...matchedItems.map((item) => item.id)];
    final title = _generateOutfitTitle(mainItem, matchedItems);
    final description = _generateOutfitDescription(mainItem, matchedItems);
    final reason = _generateStylistReason(mainItem, matchedItems);

    return WardrobeOutfitSuggestion(
      id: 'complete-outfit-${mainItem.id}',
      title: title,
      description: description,
      reason: reason,
      itemIds: allItemIds,
      source: 'wardrobe',
    );
  }

  WardrobeOutfitSuggestion? _createSeasonalOutfit(
    WardrobeItemModel mainItem,
    List<WardrobeItemModel> wardrobe,
    Set<String> usedItemIds,
  ) {
    final currentSeason = _getCurrentSeason();
    final seasonalItems = wardrobe.where((item) {
      if (usedItemIds.contains(item.id)) return false;
      final itemSeasons = item.season ?? [];
      return itemSeasons.isEmpty ||
          itemSeasons.any((season) =>
              season.toLowerCase().contains(currentSeason.toLowerCase()));
    }).toList();

    if (seasonalItems.length < 2) return null;

    // Find complementary pieces for the season
    final complementaryCategories =
        _getComplementaryCategories(mainItem.category);
    final matchedItems = <WardrobeItemModel>[];

    for (final category in complementaryCategories.take(2)) {
      // Limit to 2 additional pieces
      final candidates = seasonalItems
          .where(
              (item) => item.category.toLowerCase() == category.toLowerCase())
          .toList();

      if (candidates.isEmpty) continue;

      candidates.sort((a, b) => _seasonalMatchScore(b, mainItem)
          .compareTo(_seasonalMatchScore(a, mainItem)));

      final bestMatch = candidates.first;
      matchedItems.add(bestMatch);
      usedItemIds.add(bestMatch.id);
    }

    if (matchedItems.isEmpty) return null;

    final allItemIds = [mainItem.id, ...matchedItems.map((item) => item.id)];

    return WardrobeOutfitSuggestion(
      id: 'seasonal-outfit-${mainItem.id}',
      title: '$currentSeason ${mainItem.category} Look',
      description:
          'A seasonal outfit that\'s perfect for ${currentSeason.toLowerCase()} weather.',
      reason:
          'This combination works beautifully for ${currentSeason.toLowerCase()} and keeps you comfortable in current conditions.',
      itemIds: allItemIds,
      source: 'wardrobe',
    );
  }

  WardrobeOutfitSuggestion? _createOccasionOutfit(
    WardrobeItemModel mainItem,
    List<WardrobeItemModel> wardrobe,
    Set<String> usedItemIds,
  ) {
    final mainOccasions = mainItem.occasion ?? [];
    if (mainOccasions.isEmpty) return null;

    // Find items that match the same occasions
    final occasionItems = wardrobe.where((item) {
      if (usedItemIds.contains(item.id)) return false;
      final itemOccasions = item.occasion ?? [];
      return itemOccasions.isNotEmpty &&
          itemOccasions.any((occasion) => mainOccasions.contains(occasion));
    }).toList();

    if (occasionItems.length < 2) return null;

    final complementaryCategories =
        _getComplementaryCategories(mainItem.category);
    final matchedItems = <WardrobeItemModel>[];

    for (final category in complementaryCategories.take(2)) {
      final candidates = occasionItems
          .where(
              (item) => item.category.toLowerCase() == category.toLowerCase())
          .toList();

      if (candidates.isEmpty) continue;

      candidates.sort((a, b) => _occasionMatchScore(b, mainItem)
          .compareTo(_occasionMatchScore(a, mainItem)));

      final bestMatch = candidates.first;
      matchedItems.add(bestMatch);
      usedItemIds.add(bestMatch.id);
    }

    if (matchedItems.isEmpty) return null;

    final primaryOccasion = mainOccasions.first;
    final allItemIds = [mainItem.id, ...matchedItems.map((item) => item.id)];

    return WardrobeOutfitSuggestion(
      id: 'occasion-outfit-${mainItem.id}',
      title: '$primaryOccasion Ready',
      description: 'A polished outfit perfect for $primaryOccasion events.',
      reason:
          'These pieces are specifically chosen for $primaryOccasion wear and create a cohesive, appropriate look.',
      itemIds: allItemIds,
      source: 'wardrobe',
    );
  }

  WardrobeOutfitSuggestion? _createStyleCoordinatedOutfit(
    WardrobeItemModel mainItem,
    List<WardrobeItemModel> wardrobe,
    Set<String> usedItemIds,
  ) {
    // Find items with similar colors or patterns
    final styleItems = wardrobe.where((item) {
      if (usedItemIds.contains(item.id)) return false;

      // Color matching
      final mainColors = mainItem.colorTags.map((c) => c.toLowerCase()).toSet();
      final itemColors = item.colorTags.map((c) => c.toLowerCase()).toSet();
      final colorMatch = mainColors.intersection(itemColors).isNotEmpty;

      // Pattern matching
      final patternMatch = mainItem.pattern != null &&
          item.pattern != null &&
          mainItem.pattern!.toLowerCase() == item.pattern!.toLowerCase();

      return colorMatch || patternMatch;
    }).toList();

    if (styleItems.length < 2) return null;

    final complementaryCategories =
        _getComplementaryCategories(mainItem.category);
    final matchedItems = <WardrobeItemModel>[];

    for (final category in complementaryCategories.take(2)) {
      final candidates = styleItems
          .where(
              (item) => item.category.toLowerCase() == category.toLowerCase())
          .toList();

      if (candidates.isEmpty) continue;

      candidates.sort((a, b) => _styleMatchScore(b, mainItem)
          .compareTo(_styleMatchScore(a, mainItem)));

      final bestMatch = candidates.first;
      matchedItems.add(bestMatch);
      usedItemIds.add(bestMatch.id);
    }

    if (matchedItems.isEmpty) return null;

    final allItemIds = [mainItem.id, ...matchedItems.map((item) => item.id)];

    return WardrobeOutfitSuggestion(
      id: 'style-outfit-${mainItem.id}',
      title: 'Style-Coordinated Look',
      description:
          'A cohesive outfit that matches your selected item\'s colors and patterns.',
      reason:
          'This combination creates visual harmony through matching colors and complementary patterns.',
      itemIds: allItemIds,
      source: 'wardrobe',
    );
  }

  List<WardrobeOutfitSuggestion> _createOnlineEnhancementSuggestions(
    WardrobeItemModel mainItem,
    List<WardrobeItemModel> wardrobe,
  ) {
    final suggestions = <WardrobeOutfitSuggestion>[];
    final complementaryCategories =
        _getComplementaryCategories(mainItem.category);

    // Check which categories are missing from wardrobe
    final wardrobeCategories =
        wardrobe.map((item) => item.category.toLowerCase()).toSet();
    final missingCategories = complementaryCategories
        .where((cat) => !wardrobeCategories.contains(cat.toLowerCase()))
        .toList();

    if (missingCategories.isNotEmpty) {
      // Suggest online pieces for missing categories
      for (final category in missingCategories.take(2)) {
        suggestions.add(WardrobeOutfitSuggestion(
          id: 'online-${category.toLowerCase()}-${mainItem.id}',
          title: 'Add $category to Complete Look',
          description:
              'Find the perfect $category to complement your ${mainItem.category.toLowerCase()}.',
          reason:
              'Your wardrobe would benefit from a $category that matches this piece\'s style and colors.',
          itemIds: [mainItem.id],
          source: 'online',
          price: _estimatePriceForCategory(category),
          sourceStore: _suggestStoreForCategory(category),
          sourceLink: _generateStoreLink(mainItem, category),
        ));
      }
    }

    // Always suggest one general enhancement
    if (suggestions.isEmpty) {
      suggestions.add(WardrobeOutfitSuggestion(
        id: 'online-enhancement-${mainItem.id}',
        title: 'Elevate Your Look',
        description:
            'Discover new pieces that would perfectly complement your wardrobe.',
        reason:
            'Adding thoughtfully chosen pieces can transform your outfit combinations.',
        itemIds: [mainItem.id],
        source: 'online',
        price: null,
        sourceStore: 'Fashion Retailers',
        sourceLink: 'https://www.google.com/search?q=fashion+outfits',
      ));
    }

    return suggestions.take(2).toList();
  }

  // Helper methods for stylist-like matching

  double _stylistMatchScore(
    WardrobeItemModel candidate,
    WardrobeItemModel mainItem,
    List<WardrobeItemModel> existingMatches,
  ) {
    var score = 0.0;

    // Color harmony (most important)
    final mainColors = mainItem.colorTags.map((c) => c.toLowerCase()).toSet();
    final candidateColors =
        candidate.colorTags.map((c) => c.toLowerCase()).toSet();
    final colorOverlap = mainColors.intersection(candidateColors).length;
    score += colorOverlap * 3.0;

    // Pattern coordination
    if (mainItem.pattern != null && candidate.pattern != null) {
      if (mainItem.pattern!.toLowerCase() == candidate.pattern!.toLowerCase()) {
        score += 2.0; // Same pattern is great
      } else if (_patternsComplement(mainItem.pattern!, candidate.pattern!)) {
        score += 1.5; // Complementary patterns
      }
    } else if (mainItem.pattern == null && candidate.pattern == null) {
      score += 1.0; // Both solid colors work well together
    }

    // Brand consistency (slight preference for same brand)
    if (mainItem.brand != null &&
        candidate.brand != null &&
        mainItem.brand!.toLowerCase() == candidate.brand!.toLowerCase()) {
      score += 0.5;
    }

    // Occasion matching
    final mainOccasions = mainItem.occasion ?? [];
    final candidateOccasions = candidate.occasion ?? [];
    if (mainOccasions.isNotEmpty && candidateOccasions.isNotEmpty) {
      final sharedOccasions = mainOccasions
          .map((o) => o.toLowerCase())
          .toSet()
          .intersection(candidateOccasions.map((o) => o.toLowerCase()).toSet());
      score += sharedOccasions.length * 1.0;
    }

    // Seasonal compatibility
    final mainSeasons = mainItem.season ?? [];
    final candidateSeasons = candidate.season ?? [];
    if (mainSeasons.isNotEmpty && candidateSeasons.isNotEmpty) {
      final sharedSeasons = mainSeasons
          .map((s) => s.toLowerCase())
          .toSet()
          .intersection(candidateSeasons.map((s) => s.toLowerCase()).toSet());
      score += sharedSeasons.length * 0.8;
    }

    // Avoid conflicting fits/styles
    if (mainItem.fit != null && candidate.fit != null) {
      if (_fitsComplement(mainItem.fit!, candidate.fit!)) {
        score += 0.7;
      }
    }

    // Consider existing matches for overall outfit balance
    for (final existing in existingMatches) {
      score += _itemCompatibilityScore(candidate, existing) * 0.3;
    }

    return score;
  }

  double _seasonalMatchScore(
      WardrobeItemModel candidate, WardrobeItemModel mainItem) {
    var score = _stylistMatchScore(candidate, mainItem, []);

    // Boost score for seasonal relevance
    final currentSeason = _getCurrentSeason();
    final candidateSeasons = candidate.season ?? [];
    if (candidateSeasons.any((season) =>
        season.toLowerCase().contains(currentSeason.toLowerCase()))) {
      score += 2.0;
    }

    return score;
  }

  double _occasionMatchScore(
      WardrobeItemModel candidate, WardrobeItemModel mainItem) {
    var score = _stylistMatchScore(candidate, mainItem, []);

    // Boost score for occasion relevance
    final mainOccasions = mainItem.occasion ?? [];
    final candidateOccasions = candidate.occasion ?? [];
    final sharedOccasions = mainOccasions
        .map((o) => o.toLowerCase())
        .toSet()
        .intersection(candidateOccasions.map((o) => o.toLowerCase()).toSet());

    score += sharedOccasions.length * 2.0;

    return score;
  }

  double _styleMatchScore(
      WardrobeItemModel candidate, WardrobeItemModel mainItem) {
    var score = 0.0;

    // Heavy weight on color matching
    final mainColors = mainItem.colorTags.map((c) => c.toLowerCase()).toSet();
    final candidateColors =
        candidate.colorTags.map((c) => c.toLowerCase()).toSet();
    final colorOverlap = mainColors.intersection(candidateColors).length;
    score += colorOverlap * 4.0;

    // Pattern matching
    if (mainItem.pattern != null && candidate.pattern != null) {
      if (mainItem.pattern!.toLowerCase() == candidate.pattern!.toLowerCase()) {
        score += 3.0;
      }
    }

    return score;
  }

  double _itemCompatibilityScore(
      WardrobeItemModel item1, WardrobeItemModel item2) {
    var score = 0.0;

    // Color compatibility
    final colors1 = item1.colorTags.map((c) => c.toLowerCase()).toSet();
    final colors2 = item2.colorTags.map((c) => c.toLowerCase()).toSet();
    final colorOverlap = colors1.intersection(colors2).length;
    score += colorOverlap * 2.0;

    // Pattern compatibility
    if (item1.pattern != null && item2.pattern != null) {
      if (item1.pattern == item2.pattern) {
        score += 1.5;
      } else if (_patternsComplement(item1.pattern!, item2.pattern!)) {
        score += 1.0;
      }
    }

    return score;
  }

  bool _patternsComplement(String pattern1, String pattern2) {
    final p1 = pattern1.toLowerCase();
    final p2 = pattern2.toLowerCase();

    // Stripes go well with solids, florals with solids, etc.
    final complementaryPairs = [
      ['stripe', 'solid'],
      ['floral', 'solid'],
      ['polka dot', 'solid'],
      ['plaid', 'solid'],
      ['stripe', 'floral'],
      ['geometric', 'solid'],
    ];

    return complementaryPairs.any((pair) =>
        (p1.contains(pair[0]) && p2.contains(pair[1])) ||
        (p1.contains(pair[1]) && p2.contains(pair[0])));
  }

  bool _fitsComplement(String fit1, String fit2) {
    final f1 = fit1.toLowerCase();
    final f2 = fit2.toLowerCase();

    // Slim fits work well with relaxed, fitted with loose, etc.
    final complementaryFits = [
      ['slim', 'relaxed'],
      ['fitted', 'loose'],
      ['tailored', 'casual'],
      ['fitted', 'oversized'],
    ];

    return complementaryFits.any((pair) =>
        (f1.contains(pair[0]) && f2.contains(pair[1])) ||
        (f1.contains(pair[1]) && f2.contains(pair[0])));
  }

  String _getCurrentSeason() {
    final now = DateTime.now();
    final month = now.month;

    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer';
    if (month >= 9 && month <= 11) return 'Fall';
    return 'Winter';
  }

  String _generateOutfitTitle(
      WardrobeItemModel mainItem, List<WardrobeItemModel> matches) {
    final categories = matches.map((item) => item.category).toSet();

    if (categories.contains('Shoes') && categories.contains('Top')) {
      return 'Complete ${mainItem.category} Ensemble';
    } else if (categories.contains('Bottom') && categories.contains('Top')) {
      return 'Full ${mainItem.category} Look';
    } else {
      return 'Coordinated ${mainItem.category} Outfit';
    }
  }

  String _generateOutfitDescription(
      WardrobeItemModel mainItem, List<WardrobeItemModel> matches) {
    final pieces =
        matches.map((item) => item.category.toLowerCase()).join(', ');
    return 'A thoughtfully curated outfit featuring your ${mainItem.category.toLowerCase()} with $pieces.';
  }

  String _generateStylistReason(
      WardrobeItemModel mainItem, List<WardrobeItemModel> matches) {
    final reasons = <String>[];

    // Color harmony
    final allColors = [mainItem, ...matches]
        .expand((item) => item.colorTags)
        .map((c) => c.toLowerCase())
        .toSet();

    if (allColors.length <= 3) {
      reasons.add('the colors work beautifully together');
    }

    // Pattern coordination
    final patterns = [mainItem, ...matches]
        .where((item) => item.pattern != null)
        .map((item) => item.pattern!.toLowerCase())
        .toSet();

    if (patterns.length == 1) {
      reasons.add('the pattern creates a cohesive look');
    } else if (patterns.length > 1) {
      reasons.add('the patterns complement each other perfectly');
    }

    // Occasion consistency
    final occasions =
        [mainItem, ...matches].expand((item) => item.occasion ?? []).toSet();

    if (occasions.length == 1) {
      reasons.add('it\'s perfect for ${occasions.first} occasions');
    }

    if (reasons.isEmpty) {
      return 'This combination creates a balanced, stylish outfit that showcases your personal taste.';
    }

    return 'This outfit works because ${reasons.join(' and ')}.';
  }

  double? _estimatePriceForCategory(String category) {
    final categoryPrices = {
      'Top': 45.0,
      'Bottom': 65.0,
      'Pants': 70.0,
      'Shoes': 85.0,
      'Accessories': 35.0,
      'Outerwear': 120.0,
      'Dress': 80.0,
    };

    return categoryPrices[category] ?? 50.0;
  }

  String _suggestStoreForCategory(String category) {
    final categoryStores = {
      'Top': 'H&M',
      'Bottom': 'Zara',
      'Pants': 'Uniqlo',
      'Shoes': 'Nike',
      'Accessories': 'ASOS',
      'Outerwear': 'Mango',
      'Dress': 'Forever 21',
    };

    return categoryStores[category] ?? 'Fashion Retailer';
  }

  String _generateStoreLink(WardrobeItemModel mainItem, String category) {
    final brand = mainItem.brand ?? '';
    final colors = mainItem.colorTags.take(2).join(' ');
    final query = '$brand $category $colors ${mainItem.category}'.trim();
    return 'https://www.google.com/search?q=${Uri.encodeComponent(query)}+outfit';
  }

  List<String> _getComplementaryCategories(String category) {
    final normalized = category.toLowerCase();

    if (normalized.contains('shoe')) {
      return ['Bottom', 'Top', 'Accessories'];
    }
    if (normalized.contains('top')) {
      return ['Bottom', 'Shoes', 'Outerwear', 'Accessories'];
    }
    if (normalized.contains('bottom')) {
      return ['Top', 'Shoes', 'Outerwear', 'Accessories'];
    }
    if (normalized.contains('dress')) {
      return ['Shoes', 'Outerwear', 'Accessories'];
    }
    if (normalized.contains('outerwear')) {
      return ['Top', 'Bottom', 'Shoes', 'Accessories'];
    }
    if (normalized.contains('access')) {
      return ['Top', 'Bottom', 'Shoes'];
    }

    return ['Top', 'Bottom', 'Shoes', 'Accessories'];
  }

  List<WardrobeItemModel> _selectTopItemsForCategories(
    WardrobeItemModel mainItem,
    List<String> categories,
    List<WardrobeItemModel> wardrobe,
  ) {
    final selectedItems = <WardrobeItemModel>[];

    for (final category in categories) {
      final candidates = wardrobe
          .where((wardrobeItem) =>
              wardrobeItem.id != mainItem.id &&
              wardrobeItem.category.toLowerCase() == category.toLowerCase())
          .toList();

      if (candidates.isEmpty) continue;

      candidates.sort((a, b) =>
          _itemMatchScore(b, mainItem).compareTo(_itemMatchScore(a, mainItem)));
      selectedItems.add(candidates.first);
    }

    return selectedItems;
  }

  double _itemMatchScore(
    WardrobeItemModel item,
    WardrobeItemModel mainItem,
  ) {
    var score = 0.0;

    final mainColors =
        mainItem.colorTags.map((color) => color.toLowerCase()).toSet();
    final itemColors =
        item.colorTags.map((color) => color.toLowerCase()).toSet();

    score += mainColors.intersection(itemColors).length * 2.0;

    if (item.pattern != null && mainItem.pattern != null) {
      if (item.pattern!.toLowerCase() == mainItem.pattern!.toLowerCase()) {
        score += 1.0;
      }
    }

    if (item.brand != null && mainItem.brand != null) {
      if (item.brand!.toLowerCase() == mainItem.brand!.toLowerCase()) {
        score += 1.0;
      }
    }

    if (item.fit != null && mainItem.fit != null) {
      if (item.fit!.toLowerCase() == mainItem.fit!.toLowerCase()) {
        score += 0.5;
      }
    }

    if (item.occasion != null && mainItem.occasion != null) {
      final sharedOccasions = item.occasion!
          .map((o) => o.toLowerCase())
          .toSet()
          .intersection(mainItem.occasion!.map((o) => o.toLowerCase()).toSet());
      score += sharedOccasions.length * 0.5;
    }

    return score;
  }
}

/// Model for wardrobe outfit suggestions (with online & wardrobe sources)
class WardrobeOutfitSuggestion {
  final String id;
  final String title;
  final String description;
  final String reason;
  final List<String> itemIds;
  final String source; // 'wardrobe' or 'online'
  final double? price; // For online items
  final String? sourceLink; // URL for online items
  final String?
      sourceStore; // Store name for online items (e.g., 'Amazon', 'H&M')

  WardrobeOutfitSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.reason,
    required this.itemIds,
    this.source = 'wardrobe',
    this.price,
    this.sourceLink,
    this.sourceStore,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'reason': reason,
        'item_ids': itemIds,
        'source': source,
        'price': price,
        'source_link': sourceLink,
        'source_store': sourceStore,
      };
}

import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wardrobe_item_model.dart';
import 'cache_service.dart';
import 'supabase_storage_service.dart';

class WardrobeService {
  final SupabaseStorageService _storage;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  WardrobeService() : _storage = SupabaseStorageService(Supabase.instance.client);

  /// Upload a clothing item to wardrobe
  /// Accepts File (mobile) or Uint8List (web)
  Future<WardrobeItemModel> uploadItem({
    required dynamic imageFile, // File on mobile, Uint8List on web
    required String category,
    required List<String> colorTags,
    String? brand,
    String? notes,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Upload image to Supabase Storage
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

      // Create Firestore document
      final item = WardrobeItemModel(
        id: '', // Will be set by Firestore
        userId: userId,
        imageUrl: imageUrl,
        category: category,
        colorTags: colorTags,
        brand: brand,
        notes: notes,
        createdAt: DateTime.now(),
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
            category: data['category'] as String,
            colorTags: List<String>.from(data['colorTags'] as List),
            brand: data['brand'] as String?,
            notes: data['notes'] as String?,
            createdAt: createdAt,
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
  Future<void> deleteItem(String itemId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Delete from Firestore
      await _firestore.collection('wardrobe').doc(itemId).delete();

      // Delete image from Supabase Storage
      try {
        await _storage.deleteFile(
          bucket: 'wardrobe',
          path: 'wardrobe/$userId/$itemId.jpg',
        );
      } catch (_) {
        // Ignore if file doesn't exist
      }

      // Remove from cache
      final cacheBox = CacheService.wardrobeBox;
      if (cacheBox != null) {
        await cacheBox.delete(itemId);
      }
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  /// Get wardrobe item by ID
  Future<WardrobeItemModel?> getItemById(String itemId) async {
    try {
      // Try cache first
      final cached = CacheService.getCachedWardrobeItem(itemId);
      if (cached != null) {
        return WardrobeItemModel(
          id: itemId,
          userId: cached['userId'] as String,
          imageUrl: cached['imageUrl'] as String,
          category: cached['category'] as String,
          colorTags: List<String>.from(cached['colorTags'] as List),
          brand: cached['brand'] as String?,
          notes: cached['notes'] as String?,
          createdAt: DateTime.parse(cached['createdAt'] as String),
        );
      }

      // Fetch from Firestore
      final doc = await _firestore.collection('wardrobe').doc(itemId).get();
      if (doc.exists) {
        final item = WardrobeItemModel.fromFirestore(doc);
        // Cache item - convert Timestamp to String for Hive
        final cacheData = item.toFirestore();
        final createdAt = cacheData['createdAt'];
        if (createdAt is Timestamp) {
          cacheData['createdAt'] = createdAt.toDate().toIso8601String();
        }
        await CacheService.cacheWardrobeItem(itemId, cacheData);
        return item;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}


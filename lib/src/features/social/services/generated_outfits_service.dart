import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/generated_outfit_model.dart';
import '../../../core/services/supabase_storage_service.dart';

/// Saves and lists generated outfits (e.g. from Try-On). Images in Supabase Storage; metadata in Firestore.
class GeneratedOutfitsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'generated_outfits';
  static const String _bucket = 'generated_outfits';

  Future<String> _uploadImage({required String userId, required String outfitId, required Uint8List bytes}) async {
    final client = Supabase.instance.client;
    final storage = SupabaseStorageService(client);
    final path = '$userId/$outfitId.jpg';
    return await storage.uploadFile(
      bucket: _bucket,
      path: path,
      file: bytes,
      contentType: 'image/jpeg',
    );
  }

  /// Save a generated outfit. Uploads [imageBytes] to Supabase and stores metadata in Firestore.
  /// If Supabase upload fails (e.g. bucket missing), see docs/setup/SUPABASE_STORAGE_BUCKETS.md
  Future<GeneratedOutfitModel> saveGeneratedOutfit({
    required String userId,
    required Uint8List imageBytes,
    String? caption,
  }) async {
    final ref = _firestore.collection(_collection).doc();
    final outfitId = ref.id;
    String imageUrl;
    try {
      imageUrl = await _uploadImage(userId: userId, outfitId: outfitId, bytes: imageBytes);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Bucket not found') ||
          msg.contains('does not exist') ||
          msg.contains('Permission denied') ||
          msg.contains('policy') ||
          msg.contains('400')) {
        throw Exception(
          'Supabase storage failed. Create the "$_bucket" bucket: '
          'Supabase Dashboard → Storage → New bucket "$_bucket" (public), '
          'then add Policies to allow INSERT and SELECT for anon. '
          'Or run docs/setup/supabase_storage_buckets.sql in SQL Editor.',
        );
      }
      rethrow;
    }
    final model = GeneratedOutfitModel(
      id: outfitId,
      userId: userId,
      imageUrl: imageUrl,
      caption: caption,
      createdAt: DateTime.now(),
    );
    await ref.set(model.toFirestore());
    return model;
  }

  /// Save when you already have a public image URL (e.g. from Try-On backend).
  Future<GeneratedOutfitModel> saveGeneratedOutfitWithUrl({
    required String userId,
    required String imageUrl,
    String? caption,
  }) async {
    final ref = _firestore.collection(_collection).doc();
    final model = GeneratedOutfitModel(
      id: ref.id,
      userId: userId,
      imageUrl: imageUrl,
      caption: caption,
      createdAt: DateTime.now(),
    );
    await ref.set(model.toFirestore());
    return model;
  }

  Stream<List<GeneratedOutfitModel>> watchGeneratedOutfits(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => GeneratedOutfitModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> deleteGeneratedOutfit(String outfitId, String userId) async {
    final ref = _firestore.collection(_collection).doc(outfitId);
    final doc = await ref.get();
    if (doc.exists && (doc.data()?['userId'] == userId)) {
      await ref.delete();
    }
  }
}

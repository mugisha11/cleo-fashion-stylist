import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tryon_session_model.dart';

/// Try-On Memory Service - Saves and retrieves try-on sessions
class TryOnMemoryService {
  final SupabaseClient _supabase;
  final FirebaseAuth _auth;

  TryOnMemoryService(this._supabase, this._auth);

  String get _userId => _auth.currentUser?.uid ?? '';

  /// Save a try-on session
  Future<TryOnSession> saveTryOnSession({
    required String baseImageUrl,
    required String resultImageUrl,
    required List<String> outfitIds,
    String? poseSignature,
    String? occasion,
    String? eventType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final sessionData = {
        'user_id': _userId,
        'base_image_url': baseImageUrl,
        'result_image_url': resultImageUrl,
        'outfit_ids': outfitIds,
        'pose_signature': poseSignature,
        'occasion': occasion,
        'event_type': eventType,
        'metadata': metadata,
      };

      final response = await _supabase
          .from('tryon_sessions')
          .insert(sessionData)
          .select()
          .single();

      return TryOnSession.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save try-on session: $e');
    }
  }

  /// Get all saved try-on sessions for user
  Future<List<TryOnSession>> getSavedTryOns({
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      if (_userId.isEmpty) return [];

      var queryBuilder = _supabase
          .from('tryon_sessions')
          .select()
          .eq('user_id', _userId);

      if (before != null) {
        queryBuilder = queryBuilder.lte('created_at', before.toIso8601String());
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => TryOnSession.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching saved try-ons: $e');
      return [];
    }
  }

  /// Get try-on session by ID
  Future<TryOnSession?> getTryOnSession(String sessionId) async {
    try {
      if (_userId.isEmpty) return null;

      final response = await _supabase
          .from('tryon_sessions')
          .select()
          .eq('id', sessionId)
          .eq('user_id', _userId)
          .maybeSingle();

      if (response == null) return null;
      return TryOnSession.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Delete a try-on session
  Future<void> deleteTryOnSession(String sessionId) async {
    try {
      if (_userId.isEmpty) return;

      // Get session to get image URLs
      final session = await getTryOnSession(sessionId);
      if (session == null) return;

      // Delete from database
      await _supabase
          .from('tryon_sessions')
          .delete()
          .eq('id', sessionId)
          .eq('user_id', _userId);

      // TODO: Delete images from storage if needed
      // For now, we keep images in storage for potential reuse
    } catch (e) {
      throw Exception('Failed to delete try-on session: $e');
    }
  }

  /// Get most recent base image for user (for reuse)
  Future<String?> getLatestBaseImage() async {
    try {
      if (_userId.isEmpty) return null;

      final response = await _supabase
          .from('tryon_sessions')
          .select('base_image_url')
          .eq('user_id', _userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return response['base_image_url'] as String?;
    } catch (e) {
      return null;
    }
  }
}

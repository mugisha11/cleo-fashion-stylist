import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Ready Player Me Avatar Service
/// Handles avatar creation, GLB URL construction, and Firebase storage
/// 
/// API Documentation: https://docs.readyplayer.me/ready-player-me/api-reference
class ReadyPlayerMeAvatarService {
  // Ready Player Me CDN base URL
  static const String _modelsBaseUrl = 'https://models.readyplayer.me';
  
  // Ready Player Me Creator URL (iframe)
  static const String _creatorUrl = 'https://readyplayer.me/avatar';
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Construct optimized GLB URL with quality parameters
  /// 
  /// Parameters:
  /// - avatarId: The Ready Player Me avatar ID
  /// - quality: 'high', 'medium', or 'low' (default: 'high')
  /// - lod: Level of detail (0 = highest, 1 = medium, 2 = low)
  /// - textureQuality: 'high', 'medium', or 'low'
  /// - textureFormat: 'webp', 'png', or 'jpg'
  /// - textureAtlas: Texture atlas size (512, 1024, 2048)
  /// - pose: Avatar pose ('A', 'T', 'I', etc.)
  /// - useDracoMeshCompression: Enable Draco compression for smaller file size
  String buildAvatarGlbUrl({
    required String avatarId,
    String quality = 'high',
    int lod = 0,
    String textureQuality = 'high',
    String textureFormat = 'webp',
    int textureAtlas = 1024,
    String? pose,
    bool useDracoMeshCompression = true,
  }) {
    final uri = Uri.parse('$_modelsBaseUrl/$avatarId.glb');
    
    final queryParams = <String, String>{
      'quality': quality,
      'lod': lod.toString(),
      'textureQuality': textureQuality,
      'textureFormat': textureFormat,
      'textureAtlas': textureAtlas.toString(),
      if (pose != null) 'pose': pose,
      if (useDracoMeshCompression) 'useDracoMeshCompression': 'true',
    };
    
    return uri.replace(queryParameters: queryParams).toString();
  }

  /// Get Ready Player Me creator URL with configuration
  String getCreatorUrl({
    String? userId,
    String? clearCache,
  }) {
    final uri = Uri.parse(_creatorUrl);
    final queryParams = <String, String>{};
    
    if (userId != null) {
      queryParams['userId'] = userId;
    }
    if (clearCache == 'true') {
      queryParams['clearCache'] = 'true';
    }
    
    return uri.replace(queryParameters: queryParams).toString();
  }

  /// Validate avatar exists by checking HTTP status
  /// Returns true if avatar is accessible (HTTP 200)
  Future<bool> validateAvatarExists(String glbUrl) async {
    try {
      final response = await http.head(Uri.parse(glbUrl));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Avatar validation error: $e');
      return false;
    }
  }

  /// Try multiple avatar URL configurations with fallback
  /// Returns the first valid URL or null if all fail
  Future<String?> getValidAvatarUrl(String avatarId) async {
    // Try high quality first
    final urls = [
      buildAvatarGlbUrl(avatarId: avatarId, quality: 'high'),
      buildAvatarGlbUrl(avatarId: avatarId, quality: 'medium'),
      buildAvatarGlbUrl(avatarId: avatarId, quality: 'low'),
      // Try without compression
      buildAvatarGlbUrl(
        avatarId: avatarId,
        quality: 'high',
        useDracoMeshCompression: false,
      ),
      // Try basic URL
      '$_modelsBaseUrl/$avatarId.glb',
    ];

    for (final url in urls) {
      final isValid = await validateAvatarExists(url);
      if (isValid) {
        debugPrint('✅ Valid avatar URL found: $url');
        return url;
      }
    }

    debugPrint('❌ No valid avatar URL found for avatarId: $avatarId');
    return null;
  }

  /// Save avatar data to Firebase
  /// Stores avatarId, GLB URL, and preview URL in user document
  Future<void> saveAvatarToFirebase({
    required String avatarId,
    required String glbUrl,
    String? previewUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final avatarData = {
        'avatarId': avatarId,
        'glbUrl': glbUrl,
        'previewUrl': previewUrl ?? '$_modelsBaseUrl/$avatarId.png',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to user document
      await _firestore.collection('users').doc(user.uid).update({
        'avatar': avatarData,
      });

      debugPrint('✅ Avatar saved to Firebase: $avatarId');
    } catch (e) {
      debugPrint('❌ Error saving avatar to Firebase: $e');
      rethrow;
    }
  }

  /// Get user's saved avatar data from Firebase
  Future<Map<String, dynamic>?> getSavedAvatar() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data();
      return data?['avatar'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getting saved avatar: $e');
      return null;
    }
  }

  /// Parse avatar ID from postMessage data
  /// Handles various message formats from Ready Player Me iframe
  String? parseAvatarIdFromMessage(dynamic message) {
    try {
      // Handle string messages
      if (message is String) {
        final json = jsonDecode(message);
        return json['avatarId'] as String?;
      }
      
      // Handle Map messages
      if (message is Map) {
        return message['avatarId'] as String?;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error parsing avatar ID: $e');
      return null;
    }
  }
}


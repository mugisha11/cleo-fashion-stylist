import 'dart:typed_data';
import 'dart:convert';
import '../utils/io_stub.dart' if (dart.library.io) 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/user_model.dart';
import 'cache_service.dart';
import 'supabase_storage_service.dart';
import '../../features/virtualwearon/services/ready_player_me_service.dart';

class AvatarService {
  // Ready Player Me API endpoint (mock for MVP - replace with actual API)
  static const String _readyPlayerMeApiUrl = 'https://models.readyplayer.me/api/v1/avatar';
  static const _logPath = 'd:\\styleapp\\.cursor\\debug.log';
  void _log(String location, String message,
      {Map<String, dynamic>? data,
      String runId = 'run1',
      String hypothesisId = 'H1'}) {
    final payload = jsonEncode({
      'location': location,
      'message': message,
      'data': data ?? {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'sessionId': 'debug-session',
      'runId': runId,
      'hypothesisId': hypothesisId,
    });
    if (!kIsWeb) {
      io.File(_logPath).writeAsStringSync('$payload\n', flush: true);
    } else {
      // ignore: avoid_print
      print(payload);
    }
  }

  late final SupabaseStorageService _storage;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ReadyPlayerMeService _readyPlayerMeService = ReadyPlayerMeService();

  AvatarService() {
    try {
      final client = Supabase.instance.client;
      _log('avatar_service.dart:21', 'Supabase client accessed',
          data: {'hasClient': client != null}, hypothesisId: 'H1');
      _storage = SupabaseStorageService(client);
      _log('avatar_service.dart:25', 'SupabaseStorageService created',
          hypothesisId: 'H1');
    } catch (e) {
      _log('avatar_service.dart:28', 'Supabase initialization error',
          data: {'error': e.toString()}, hypothesisId: 'H1');
      throw Exception('Supabase not initialized: $e');
    }
  }

  /// Generate 3D avatar from selfie using Ready Player Me API
  /// Falls back to 2D stylized avatar if API fails
  /// Accepts File (mobile) or Uint8List (web)
  /// Always returns a successful result - never fails completely
  Future<AvatarGenerationResult> generateAvatar(dynamic selfieFile) async {
    String? uploadedSelfieUrl;
    
    try {
      // Get user ID
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        // Even if not authenticated, try to create a default avatar
        return AvatarGenerationResult.fallback(
          previewUrl: 'https://ui-avatars.com/api/?name=User&size=200&background=random',
        );
      }

      // Upload selfie to Supabase Storage (try, but don't fail if it doesn't work)
      try {
        _log('avatar_service.dart:36', 'Before Supabase upload',
            data: {'userId': userId, 'fileType': selfieFile.runtimeType.toString()},
            hypothesisId: 'H1');
        final selfiePath = 'avatars/$userId/selfie.jpg';
        uploadedSelfieUrl = await _storage.uploadFile(
          bucket: 'avatars',
          path: selfiePath,
          file: selfieFile,
          contentType: 'image/jpeg',
        );
        _log('avatar_service.dart:45', 'Supabase upload success',
            data: {'url': uploadedSelfieUrl}, hypothesisId: 'H1');
      } catch (uploadError) {
        _log('avatar_service.dart:50', 'Selfie upload failed, will use fallback',
            data: {'error': uploadError.toString()}, hypothesisId: 'H1');
        // Continue to fallback - uploadedSelfieUrl will be null
      }

      // Try to create 3D avatar using Ready Player Me API
      try {
        // Get default body measurements (can be enhanced with user input later)
        const measurements = BodyMeasurements(
          height: 170.0, // Default height in cm
          weight: 70.0, // Default weight in kg
          bodyType: 'average',
          gender: 'non-binary',
          stylePreference: 'casual',
          age: 25,
        );

        // Call Ready Player Me service to generate 3D avatar
        final rpmResult = await _readyPlayerMeService.generateAvatar(
          selfieFile: selfieFile,
          measurements: measurements,
          userId: userId,
        );

        if (rpmResult.isSuccess) {
          // 3D avatar created successfully!
          final modelUrl = rpmResult.modelUrl ?? rpmResult.avatarUrl;
          final previewUrl = rpmResult.previewUrl ?? rpmResult.avatarUrl;
          
          if (modelUrl != null || previewUrl != null) {
            _log('avatar_service.dart:100', '3D Avatar created successfully',
                data: {
                  'modelUrl': modelUrl,
                  'previewUrl': previewUrl,
                  'isFromAPI': rpmResult.isFromAPI,
                },
                hypothesisId: 'H1');

            // Update user document
            try {
              await _firestore.collection('users').doc(userId).set({
                'avatarModelUrl': modelUrl,
                'avatarUrl': previewUrl ?? modelUrl,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            } catch (e) {
              _log('avatar_service.dart:115', 'Firestore update failed, continuing',
                  data: {'error': e.toString()}, hypothesisId: 'H1');
            }

            // Cache avatar data
            try {
              await CacheService.cacheAvatarData(userId, {
                'modelUrl': modelUrl,
                'previewUrl': previewUrl,
                'isFromAPI': rpmResult.isFromAPI,
                'timestamp': DateTime.now().toIso8601String(),
              });
            } catch (e) {
              _log('avatar_service.dart:125', 'Cache failed, continuing',
                  data: {'error': e.toString()}, hypothesisId: 'H1');
            }

            // Convert Ready Player Me result to our format
            return AvatarGenerationResult.success(
              modelUrl: modelUrl ?? '',
              previewUrl: previewUrl ?? modelUrl ?? '',
            );
          } else {
            // No URLs returned, use fallback
            _log('avatar_service.dart:135', 'Ready Player Me returned no URLs, using fallback',
                data: {'error': 'No modelUrl or previewUrl'}, hypothesisId: 'H1');
            return await _generateFallbackAvatar(selfieFile);
          }
        } else {
          // Ready Player Me failed, use fallback
          _log('avatar_service.dart:140', 'Ready Player Me failed, using fallback',
              data: {'error': rpmResult.errorMessage ?? 'Unknown error'}, hypothesisId: 'H1');
          return await _generateFallbackAvatar(selfieFile);
        }
      } catch (rpmError) {
        _log('avatar_service.dart:140', 'Ready Player Me error, using fallback',
            data: {'error': rpmError.toString()}, hypothesisId: 'H1');
        // Ready Player Me failed, use professional fallback
        return await _generateFallbackAvatar(selfieFile);
      }
    } catch (e) {
      _log('avatar_service.dart:120', 'Main generation error, using fallback',
          data: {'error': e.toString()}, hypothesisId: 'H1');
      // Always fallback, never hard-fail
      return await _generateFallbackAvatar(selfieFile);
    }
  }


  Future<AvatarGenerationResult> _generateFallbackAvatar(dynamic selfieFile) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      String? previewUrl;
      
      // Process and upload selfie as professional avatar preview
      // This creates a high-quality, optimized avatar from the user's selfie
      try {
        // Process image for better quality (crop to square, resize, optimize)
        final processedImage = await _processAvatarImage(selfieFile);
        
        final avatarPath = 'avatars/$userId/avatar_preview_${DateTime.now().millisecondsSinceEpoch}.jpg';
        previewUrl = await _storage.uploadFile(
          bucket: 'avatars',
          path: avatarPath,
          file: processedImage,
          contentType: 'image/jpeg',
        );
        _log('avatar_service.dart:175', 'Professional avatar uploaded successfully',
            data: {'url': previewUrl}, hypothesisId: 'H1');
      } catch (uploadError) {
        _log('avatar_service.dart:180', 'Primary upload failed, trying selfie URL',
            data: {'error': uploadError.toString()}, hypothesisId: 'H1');
        // If upload fails, try to use the selfie that was uploaded earlier
        try {
          final selfiePath = 'avatars/$userId/selfie.jpg';
          // Get public URL from Supabase
          final supabaseClient = Supabase.instance.client;
          final publicUrl = supabaseClient.storage.from('avatars').getPublicUrl(selfiePath);
          previewUrl = publicUrl;
          _log('avatar_service.dart:188', 'Using selfie as avatar',
              data: {'url': previewUrl}, hypothesisId: 'H1');
        } catch (e) {
          _log('avatar_service.dart:192', 'All uploads failed, using default',
              data: {'error': e.toString()}, hypothesisId: 'H1');
          // Last resort: use a professional default avatar generator
          final userName = _auth.currentUser?.displayName ?? _auth.currentUser?.email?.split('@').first ?? 'User';
          previewUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}&size=400&background=0D8ABC&color=fff&bold=true&font-size=0.5';
        }
      }

      // Try to update user document (don't fail if this fails)
      try {
        await _firestore.collection('users').doc(userId).set({
          'avatarUrl': previewUrl,
          'avatarModelUrl': null, // No 3D model for fallback
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (firestoreError) {
        _log('avatar_service.dart:170', 'Firestore update failed, continuing',
            data: {'error': firestoreError.toString()}, hypothesisId: 'H1');
        // Continue even if Firestore update fails
      }

      // Try to cache avatar data (don't fail if this fails)
      try {
        await CacheService.cacheAvatarData(userId, {
          'previewUrl': previewUrl,
          'isFallback': true,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (cacheError) {
        _log('avatar_service.dart:180', 'Cache failed, continuing',
            data: {'error': cacheError.toString()}, hypothesisId: 'H1');
        // Continue even if cache fails
      }

      // Always return success with fallback avatar
      return AvatarGenerationResult.fallback(previewUrl: previewUrl ?? '');
    } catch (e) {
      _log('avatar_service.dart:190', 'Fallback avatar generation error',
          data: {'error': e.toString()}, hypothesisId: 'H1');
      
      // Last resort: return a default avatar URL
      final userId = _auth.currentUser?.uid ?? 'user';
      final defaultUrl = 'https://ui-avatars.com/api/?name=${userId.substring(0, 2)}&size=200&background=random';
      
      // Try to save this default URL
      try {
        await _firestore.collection('users').doc(userId).set({
          'avatarUrl': defaultUrl,
          'avatarModelUrl': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {
        // Ignore errors
      }
      
      // Return fallback with default avatar
      return AvatarGenerationResult.fallback(previewUrl: defaultUrl);
    }
  }

  Future<String> _generatePreviewImage(String modelUrl) async {
    // In production, render 3D model and capture screenshot
    // For MVP, return a placeholder or the model URL
    return modelUrl;
  }

  /// Process avatar image for professional quality
  /// - Crops to square (centered)
  /// - Resizes to optimal size (400x400)
  /// - Optimizes JPEG quality
  /// - Adds subtle enhancements
  Future<Uint8List> _processAvatarImage(dynamic imageFile) async {
    try {
      Uint8List imageBytes;
      
      // Convert file to bytes
      if (kIsWeb && imageFile is Uint8List) {
        imageBytes = imageFile;
      } else if (!kIsWeb && imageFile is io.File) {
        imageBytes = await (imageFile as dynamic).readAsBytes();
      } else {
        // If already bytes, use directly
        imageBytes = imageFile as Uint8List;
      }

      // Decode image
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        // If processing fails, return original
        return imageBytes;
      }

      // Calculate square crop (center crop)
      final size = originalImage.width < originalImage.height 
          ? originalImage.width 
          : originalImage.height;
      final x = (originalImage.width - size) ~/ 2;
      final y = (originalImage.height - size) ~/ 2;

      // Crop to square
      final cropped = img.copyCrop(
        originalImage,
        x: x,
        y: y,
        width: size,
        height: size,
      );

      // Resize to optimal avatar size (400x400 for high quality)
      final resized = img.copyResize(
        cropped,
        width: 400,
        height: 400,
        interpolation: img.Interpolation.cubic, // High quality interpolation
      );

      // Optional: Apply subtle enhancements
      // - Slight contrast boost
      // - Slight saturation boost
      final enhanced = img.adjustColor(
        resized,
        contrast: 1.1, // 10% more contrast
        saturation: 1.05, // 5% more saturation
        brightness: 1.02, // 2% brighter
      );

      // Encode as high-quality JPEG
      final processedBytes = Uint8List.fromList(
        img.encodeJpg(enhanced, quality: 90), // High quality JPEG
      );

      return processedBytes;
    } catch (e) {
      _log('avatar_service.dart:260', 'Image processing failed, using original',
          data: {'error': e.toString()}, hypothesisId: 'H1');
      // If processing fails, return original image
      if (imageFile is Uint8List) {
        return imageFile;
      } else if (!kIsWeb && imageFile is io.File) {
        return await (imageFile as dynamic).readAsBytes();
      } else {
        return imageFile as Uint8List;
      }
    }
  }

  Future<UserModel?> getUserAvatar(String userId) async {
    try {
      // Try cache first
      final cached = CacheService.getCachedAvatarData(userId);
      if (cached != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          return UserModel.fromFirestore(userDoc);
        }
      }

      // Fetch from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final user = UserModel.fromFirestore(userDoc);
        // Cache it
        if (user.avatarUrl != null || user.avatarModelUrl != null) {
          await CacheService.cacheAvatarData(userId, {
            'modelUrl': user.avatarModelUrl,
            'previewUrl': user.avatarUrl,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

class AvatarGenerationResult {
  final bool isSuccess;
  final bool isFallback;
  final String? modelUrl;
  final String? previewUrl;
  final String? errorMessage;

  AvatarGenerationResult._({
    required this.isSuccess,
    required this.isFallback,
    this.modelUrl,
    this.previewUrl,
    this.errorMessage,
  });

  factory AvatarGenerationResult.success({
    required String modelUrl,
    required String previewUrl,
  }) {
    return AvatarGenerationResult._(
      isSuccess: true,
      isFallback: false,
      modelUrl: modelUrl,
      previewUrl: previewUrl,
    );
  }

  factory AvatarGenerationResult.fallback({required String previewUrl}) {
    return AvatarGenerationResult._(
      isSuccess: true,
      isFallback: true,
      previewUrl: previewUrl,
    );
  }

  factory AvatarGenerationResult.error({required String message}) {
    return AvatarGenerationResult._(
      isSuccess: false,
      isFallback: false,
      errorMessage: message,
    );
  }
}


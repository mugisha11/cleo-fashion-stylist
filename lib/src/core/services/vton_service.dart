import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/quiz_model.dart';
import 'supabase_storage_service.dart';
import 'dart:io' if (dart.library.html) 'dart:html' as io;

/// VTON Service - handles quiz, photo upload, and try-on operations
class VTONService {
  final SupabaseClient _supabase;
  final FirebaseAuth _auth;

  VTONService(this._supabase, this._auth);

  String get _userId => _auth.currentUser?.uid ?? '';

  /// Get active quiz questions
  Future<List<QuizQuestion>> getQuizQuestions() async {
    try {
      final response = await _supabase
          .from('quiz_questions')
          .select()
          .eq('is_active', true)
          .order('question_number');

      return (response as List)
          .map((json) => QuizQuestion.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load quiz questions: $e');
    }
  }

  /// Submit quiz answer
  Future<void> submitQuizAnswer(QuizAnswer answer) async {
    try {
      await _supabase.from('quiz_answers').insert({
        'user_id': _userId,
        'question_id': answer.questionId,
        'image_id': answer.imageId,
        'choice': answer.choice,
      });
    } catch (e) {
      throw Exception('Failed to save answer: $e');
    }
  }

  /// Complete quiz and compute style profile
  Future<void> completeQuiz() async {
    try {
      // Call server endpoint to compute style profile
      final response = await _supabase.functions.invoke(
        'compute-style-profile',
        body: {'user_id': _userId},
      );

      if (response.status != 200) {
        throw Exception('Failed to compute style profile');
      }
    } catch (e) {
      throw Exception('Failed to complete quiz: $e');
    }
  }

  /// Upload user photo for try-on
  Future<String> uploadUserPhoto(dynamic photoFile) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'tryon-uploads/$_userId/$timestamp.jpg';
      
      // Upload to Supabase Storage
      // Use 'uploads' bucket (already exists)
      final storageService = SupabaseStorageService(_supabase);
      final url = await storageService.uploadFile(
        bucket: 'uploads',
        path: fileName,
        file: photoFile,
        contentType: 'image/jpeg',
      );

      return url;
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  /// Submit try-on job
  Future<String> submitTryOnJob({
    required String photoUrl,
    required String outfitSource,
    String? outfitId,
    String? outfitUrl,
  }) async {
    try {
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create session record
      await _supabase.from('tryon_sessions').insert({
        'user_id': _userId,
        'session_id': sessionId,
        'raw_photo_url': photoUrl,
        'outfit_source': outfitSource,
        'outfit_id': outfitId,
        'outfit_url': outfitUrl,
        'status': 'pending',
      });

      // Call server endpoint to start processing
      final response = await _supabase.functions.invoke(
        'submit-tryon',
        body: {
          'session_id': sessionId,
          'photo_url': photoUrl,
          'outfit_source': outfitSource,
          'outfit_id': outfitId,
          'outfit_url': outfitUrl,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to submit try-on job');
      }

      return sessionId;
    } catch (e) {
      throw Exception('Failed to submit try-on: $e');
    }
  }

  /// Get try-on session status
  Future<Map<String, dynamic>> getTryOnStatus(String sessionId) async {
    try {
      final response = await _supabase
          .from('tryon_sessions')
          .select()
          .eq('session_id', sessionId)
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get try-on status: $e');
    }
  }

  /// Submit feedback for try-on result
  Future<void> submitFeedback(String sessionId, String feedback) async {
    try {
      await _supabase
          .from('tryon_sessions')
          .update({
            'user_feedback': feedback,
            'feedback_at': DateTime.now().toIso8601String(),
          })
          .eq('session_id', sessionId);
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }

  /// Process virtual try-on with advanced pipeline
  /// Calls the FastAPI backend directly
  Future<Map<String, dynamic>> processTryOn({
    required String userImageUrl,
    required String clothingImageUrl,
    bool preserveFace = true,
    bool preserveResolution = true,
    bool useDiffusion = false,
  }) async {
    try {
      // TODO: Configure backend URL from environment/config
      // For now, use localhost - update this in production
      const backendUrl = 'http://localhost:8000';
      
      final response = await http.post(
        Uri.parse('$backendUrl/try-on'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_image_url': userImageUrl,
          'cloth_image_url': clothingImageUrl,
          'preserve_face': preserveFace,
          'preserve_resolution': preserveResolution,
          'use_diffusion': useDiffusion,
          'source': 'wardrobe',
          'user_id': _userId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Try-on processing failed: ${response.body}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to process try-on: $e');
    }
  }

  /// Process virtual try-on using the new production pipeline
  /// Returns result with quality metrics and step-by-step progress
  Future<Map<String, dynamic>> processTryOnPipeline({
    required String userImageUrl,
    required String clothingImageUrl,
    bool preserveFace = true,
    bool preserveResolution = true,
    Function(String stage, double progress)? onProgress,
  }) async {
    try {
      const backendUrl = 'http://localhost:8000';
      
      // Call the complete pipeline endpoint
      onProgress?.call('Initializing pipeline...', 0.0);
      
      final response = await http.post(
        Uri.parse('$backendUrl/vton-pipeline/virtual-tryon'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_image_url': userImageUrl,
          'clothing_image_url': clothingImageUrl,
          'preserve_face': preserveFace,
          'preserve_resolution': preserveResolution,
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception('Try-on processing failed: ${errorBody['detail'] ?? response.body}');
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      onProgress?.call('Complete', 1.0);
      
      return result;
    } catch (e) {
      throw Exception('Failed to process try-on: $e');
    }
  }

  /// Process try-on step-by-step with detailed progress tracking
  Future<Map<String, dynamic>> processTryOnStepByStep({
    required String userImageUrl,
    required String clothingImageUrl,
    bool preserveFace = true,
    bool preserveResolution = true,
    Function(String stage, double progress)? onProgress,
  }) async {
    try {
      const backendUrl = 'http://localhost:8000';
      final results = <String, dynamic>{};
      
      // Step 1: Human Parsing
      onProgress?.call('Parsing human body...', 0.1);
      final parseResponse = await http.post(
        Uri.parse('$backendUrl/vton-pipeline/parse-human'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_url': userImageUrl}),
      );
      if (parseResponse.statusCode != 200) throw Exception('Parsing failed');
      results['parsing'] = jsonDecode(parseResponse.body);
      
      // Step 2: Pose Estimation
      onProgress?.call('Estimating pose...', 0.2);
      final poseResponse = await http.post(
        Uri.parse('$backendUrl/vton-pipeline/estimate-pose'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_url': userImageUrl}),
      );
      if (poseResponse.statusCode != 200) throw Exception('Pose estimation failed');
      results['pose'] = jsonDecode(poseResponse.body);
      
      // Step 3-4: Remove Clothing
      onProgress?.call('Removing existing clothing...', 0.3);
      final removalResponse = await http.post(
        Uri.parse('$backendUrl/vton-pipeline/remove-clothes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_url': userImageUrl}),
      );
      if (removalResponse.statusCode != 200) throw Exception('Clothing removal failed');
      results['removal'] = jsonDecode(removalResponse.body);
      
      // Step 6: Extract Clothing Features
      onProgress?.call('Analyzing clothing...', 0.5);
      final extractResponse = await http.post(
        Uri.parse('$backendUrl/vton-pipeline/extract-clothing'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'clothing_image_url': clothingImageUrl}),
      );
      if (extractResponse.statusCode != 200) throw Exception('Feature extraction failed');
      results['clothing_features'] = jsonDecode(extractResponse.body);
      
      // Step 7: Complete Virtual Try-On
      onProgress?.call('Applying new clothing...', 0.7);
      final tryonResponse = await http.post(
        Uri.parse('$backendUrl/vton-pipeline/virtual-tryon'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_image_url': userImageUrl,
          'clothing_image_url': clothingImageUrl,
          'preserve_face': preserveFace,
          'preserve_resolution': preserveResolution,
        }),
      );
      if (tryonResponse.statusCode != 200) throw Exception('Try-on failed');
      final tryonResult = jsonDecode(tryonResponse.body) as Map<String, dynamic>;
      results['tryon'] = tryonResult;
      
      // Step 9: Validate Output
      onProgress?.call('Validating quality...', 0.9);
      if (tryonResult['result_image'] != null) {
        // For validation, we'd need to upload the result first
        // For now, use the quality scores from try-on result
        results['validation'] = {
          'quality_scores': tryonResult['quality_scores'],
          'quality_passed': tryonResult['quality_passed'],
        };
      }
      
      onProgress?.call('Complete', 1.0);
      return results;
    } catch (e) {
      throw Exception('Failed to process try-on step-by-step: $e');
    }
  }
}

/// Provider for VTONService
final vtonServiceProvider = Provider<VTONService>((ref) {
  final supabase = Supabase.instance.client;
  final auth = FirebaseAuth.instance;
  return VTONService(supabase, auth);
});


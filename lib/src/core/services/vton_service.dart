import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../models/quiz_model.dart';
import 'supabase_storage_service.dart';
import 'backend_config_service.dart';

/// Custom timeout exception
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}

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

      return response;
    } catch (e) {
      throw Exception('Failed to get try-on status: $e');
    }
  }

  /// Submit feedback for try-on result
  Future<void> submitFeedback(String sessionId, String feedback) async {
    try {
      await _supabase.from('tryon_sessions').update({
        'user_feedback': feedback,
        'feedback_at': DateTime.now().toIso8601String(),
      }).eq('session_id', sessionId);
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }

  /// Process virtual try-on using simple OpenRouter + Gemini Nano Banana endpoint
  /// Calls POST /tryon with user image and garment image URLs
  Future<Map<String, dynamic>> processTryOn({
    required String userImageUrl,
    required String clothingImageUrl,
    bool preserveFace = true,
    bool preserveResolution = true,
    bool useDiffusion = false,
  }) async {
    final backendUrl = await BackendConfigService.getBackendUrl();
    final fallbackUrls = BackendConfigService.getFallbackUrls();

    Exception? lastException;

    // Try primary URL first, then fallbacks
    final urlsToTry = {backendUrl, ...fallbackUrls}.toList();

    for (int attempt = 0; attempt < urlsToTry.length; attempt++) {
      final url = urlsToTry[attempt];

      try {
        // Check health first (only on first attempt)
        // NOTE: Skip health check if it fails - still try the endpoint
        // Health check might fail due to CORS or other issues, but endpoint might work
        if (attempt == 0) {
          try {
            final isHealthy =
                await BackendConfigService.checkBackendHealth(url);
            if (!isHealthy) {
              print(
                  '⚠️ Health check failed for $url, but continuing to try endpoint...');
              // Don't skip - health check might fail but endpoint might work
            }
          } catch (e) {
            print('⚠️ Health check error (continuing anyway): $e');
            // Continue to try the endpoint
          }
        }

        // Call /try-on-openai endpoint (uses DALL-E 3 - working with quota!)
        final response = await http
            .post(
          Uri.parse('$url/try-on-openai'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_image_url': userImageUrl,
            'garment_image_urls': [
              clothingImageUrl
            ], // Convert single URL to list
          }),
        )
            .timeout(
          const Duration(seconds: 120), // Longer timeout for image generation
          onTimeout: () {
            throw TimeoutException(
                'Try-on request timed out after 120 seconds');
          },
        );

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body) as Map<String, dynamic>;

          // Validate response has required fields
          if (result['status'] == 'success') {
            // If we used a fallback URL, save it as the new primary
            if (attempt > 0) {
              await BackendConfigService.setBackendUrl(url);
            }

            // Log success for debugging
            print('✅ Try-on successful!');

            // Return in expected format
            return {
              'status': 'success',
              'result_image_url': result['result_image_url'],
              'result_url': result['result_image_url'], // For compatibility
            };
          } else {
            // Backend returned error status
            final errorMsg = result['message'] ??
                'Try-on generation failed. Please try another photo.';
            final errorCode = result['code'] ?? 'UNKNOWN_ERROR';

            // Clean up error message for user display
            String userFriendlyMsg = errorMsg;

            // Replace technical error messages with user-friendly ones
            if (errorCode == 'API_RATE_LIMIT' ||
                errorMsg.toLowerCase().contains('rate limit') ||
                errorMsg.toLowerCase().contains('429') ||
                errorMsg.toLowerCase().contains('quota exceeded') ||
                errorMsg.toLowerCase().contains('too many requests')) {
              userFriendlyMsg =
                  '⚠️ Service is temporarily busy due to API quota limits. Please wait a few minutes and try again, or contact support.';
            } else if (errorCode == 'CONFIG_MISSING_API_KEY' ||
                errorMsg.toLowerCase().contains('api key') ||
                errorMsg.toLowerCase().contains('authentication failed') ||
                errorMsg.toLowerCase().contains('401')) {
              userFriendlyMsg =
                  '🔑 Server configuration error: API key issue. Please contact support.';
            } else if (errorCode == 'API_MODEL_NOT_FOUND' ||
                errorMsg.toLowerCase().contains('model not found') ||
                (errorMsg.toLowerCase().contains('not found') &&
                    errorMsg.toLowerCase().contains('404'))) {
              userFriendlyMsg =
                  '❌ AI model unavailable. Please try again later or contact support.';
            } else if (errorMsg.toLowerCase().contains('network') ||
                errorMsg.toLowerCase().contains('connection')) {
              userFriendlyMsg =
                  '🌐 Network connection error. Please check your internet connection and try again.';
            } else if (errorMsg.toLowerCase().contains('timeout')) {
              userFriendlyMsg =
                  '⏱️ Request timed out. The server may be busy. Please try again.';
            } else if (errorMsg.toLowerCase().contains('server error') ||
                errorMsg.toLowerCase().contains('500')) {
              userFriendlyMsg =
                  '⚠️ Server error. Please try again later or contact support.';
            }

            throw Exception(userFriendlyMsg);
          }
        } else {
          String errorDetail = 'Try-on processing failed';
          try {
            final errorBody = jsonDecode(response.body);
            errorDetail =
                errorBody['detail'] ?? errorBody['message'] ?? response.body;
          } catch (_) {
            errorDetail = response.body;
          }
          lastException = Exception('Try-on processing failed: $errorDetail');

          // If it's a client error (4xx), don't retry
          if (response.statusCode >= 400 && response.statusCode < 500) {
            throw lastException;
          }
        }
      } on TimeoutException {
        lastException = TimeoutException('Request to $url timed out');
        if (attempt < urlsToTry.length - 1) {
          print('Timeout on $url, trying next URL...');
          continue;
        }
      } on SocketException catch (e) {
        lastException = Exception('Network error: ${e.message}');
        if (attempt < urlsToTry.length - 1) {
          print('Network error on $url, trying next URL...');
          continue;
        }
      } catch (e) {
        lastException = e is Exception ? e : Exception('Unknown error: $e');
        if (attempt < urlsToTry.length - 1) {
          print('Error on $url: $e, trying next URL...');
          continue;
        }
      }
    }

    // All URLs failed, get AI-powered diagnostic
    final diagnostic = await _getAIDiagnostic(
      userImageUrl: userImageUrl,
      clothingImageUrl: clothingImageUrl,
      error: lastException?.toString() ?? 'Unknown error',
    );

    throw Exception('Failed to process try-on on all backends. $diagnostic');
  }

  /// Get AI-powered diagnostic for try-on failures
  Future<String> _getAIDiagnostic({
    required String userImageUrl,
    required String clothingImageUrl,
    required String error,
  }) async {
    // Provide helpful error message based on error type
    final errorLower = error.toLowerCase();

    if (errorLower.contains('timeout') || errorLower.contains('timed out')) {
      return 'The request took too long. This might mean the backend server is slow or overloaded. Please try again in a moment.';
    }

    if (errorLower.contains('socket') ||
        errorLower.contains('network') ||
        errorLower.contains('connection')) {
      return 'Network connection error. Please check your internet connection and ensure the backend server is running at http://localhost:8000';
    }

    if (errorLower.contains('invalid_image') ||
        errorLower.contains('validation')) {
      return 'Image validation failed. Please ensure you uploaded a valid photo and selected a valid clothing item.';
    }

    if (errorLower.contains('upload_image_required') ||
        errorLower.contains('no photo')) {
      return 'Please upload a photo before trying on clothes.';
    }

    if (errorLower.contains('no_wardrobe_items') ||
        errorLower.contains('select')) {
      return 'Please select at least one clothing item from your wardrobe to try on.';
    }

    // Generic helpful message
    return 'Try-on failed. Please check:\n1. Backend server is running (http://localhost:8000)\n2. Images are valid and accessible\n3. Internet connection is stable\n\nError: ${error.length > 100 ? "${error.substring(0, 100)}..." : error}';
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
    final backendUrl = await BackendConfigService.getBackendUrl();
    final fallbackUrls = BackendConfigService.getFallbackUrls();
    final urlsToTry = {backendUrl, ...fallbackUrls}.toList();

    Exception? lastException;

    for (int attempt = 0; attempt < urlsToTry.length; attempt++) {
      final url = urlsToTry[attempt];

      try {
        onProgress?.call('Initializing pipeline...', 0.0);

        final response = await http
            .post(
          Uri.parse('$url/vton-pipeline/virtual-tryon'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_image_url': userImageUrl,
            'clothing_image_url': clothingImageUrl,
            'preserve_face': preserveFace,
            'preserve_resolution': preserveResolution,
          }),
        )
            .timeout(
          const Duration(seconds: 120), // Longer timeout for pipeline
          onTimeout: () {
            throw TimeoutException(
                'Pipeline request timed out after 120 seconds');
          },
        );

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body) as Map<String, dynamic>;
          onProgress?.call('Complete', 1.0);

          // If we used a fallback URL, save it
          if (attempt > 0) {
            await BackendConfigService.setBackendUrl(url);
          }

          return result;
        } else {
          String errorDetail = 'Try-on processing failed';
          try {
            final errorBody = jsonDecode(response.body);
            errorDetail =
                errorBody['detail'] ?? errorBody['message'] ?? response.body;
          } catch (_) {
            errorDetail = response.body;
          }
          lastException = Exception(errorDetail);

          // If it's a client error (4xx), don't retry
          if (response.statusCode >= 400 && response.statusCode < 500) {
            throw lastException;
          }
        }
      } on TimeoutException {
        lastException = TimeoutException('Pipeline request to $url timed out');
        if (attempt < urlsToTry.length - 1) {
          onProgress?.call('Timeout, trying alternative server...', 0.0);
          continue;
        }
      } on SocketException catch (e) {
        lastException = Exception('Network error: ${e.message}');
        if (attempt < urlsToTry.length - 1) {
          onProgress?.call('Network error, trying alternative server...', 0.0);
          continue;
        }
      } catch (e) {
        lastException = e is Exception ? e : Exception('Unknown error: $e');
        if (attempt < urlsToTry.length - 1) {
          onProgress?.call('Error occurred, trying alternative server...', 0.0);
          continue;
        }
      }
    }

    // All URLs failed, get AI diagnostic
    final diagnostic = await _getAIDiagnostic(
      userImageUrl: userImageUrl,
      clothingImageUrl: clothingImageUrl,
      error: lastException?.toString() ?? 'Unknown error',
    );

    throw Exception(
        'Failed to process try-on pipeline on all backends. $diagnostic');
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
      const backendUrl = 'http://localhost:8001';
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
      if (poseResponse.statusCode != 200) {
        throw Exception('Pose estimation failed');
      }
      results['pose'] = jsonDecode(poseResponse.body);

      // Step 3-4: Remove Clothing
      onProgress?.call('Removing existing clothing...', 0.3);
      final removalResponse = await http.post(
        Uri.parse('$backendUrl/vton-pipeline/remove-clothes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_url': userImageUrl}),
      );
      if (removalResponse.statusCode != 200) {
        throw Exception('Clothing removal failed');
      }
      results['removal'] = jsonDecode(removalResponse.body);

      // Step 6: Extract Clothing Features
      onProgress?.call('Analyzing clothing...', 0.5);
      final extractResponse = await http.post(
        Uri.parse('$backendUrl/vton-pipeline/extract-clothing'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'clothing_image_url': clothingImageUrl}),
      );
      if (extractResponse.statusCode != 200) {
        throw Exception('Feature extraction failed');
      }
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
      final tryonResult =
          jsonDecode(tryonResponse.body) as Map<String, dynamic>;
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

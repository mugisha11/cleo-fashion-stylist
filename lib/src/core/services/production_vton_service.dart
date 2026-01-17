/// Production Virtual Try-On Service
/// Calls the 7-stage production VTON backend API
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'backend_config_service.dart';
import '../models/production_vton_state.dart';

class ProductionVTONService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  /// Execute production virtual try-on
  /// 
  /// API Contract:
  /// Success: { "status": "success", "output_image_url": "...", "metadata": {...}, "quality_metrics": {...} }
  /// Failed: { "status": "failed", "stage": "...", "error": "..." }
  /// Rejected: { "status": "rejected", "stage": "...", "error": "..." }
  Future<Map<String, dynamic>> executeTryOn({
    required String userImageUrl,
    required List<String> garmentImageUrls,
    String? userImageBase64,
    List<String>? garmentImageBase64s,
  }) async {
    final backendUrl = await BackendConfigService.getBackendUrl();
    final fallbackUrls = BackendConfigService.getFallbackUrls();
    final urlsToTry = [backendUrl, ...fallbackUrls].toSet().toList();
    
    Exception? lastException;
    
    for (int attempt = 0; attempt < urlsToTry.length; attempt++) {
      final url = urlsToTry[attempt];
      
      try {
        // Check health first (only on first attempt)
        if (attempt == 0) {
          final isHealthy = await BackendConfigService.checkBackendHealth(url);
          if (!isHealthy && urlsToTry.length > 1) {
            continue; // Try next URL
          }
        }
        
        final endpoint = Uri.parse('$url/production-vton');

        final requestBody = <String, dynamic>{
          'garment_image_urls': garmentImageUrls,
          'user_id': _userId,
        };

        // Use base64 if URL is empty, otherwise use URL
        if (userImageUrl.isNotEmpty) {
          requestBody['user_image_url'] = userImageUrl;
        }
        if (userImageBase64 != null) {
          requestBody['user_image_base64'] = userImageBase64;
        }
        if (garmentImageBase64s != null) {
          requestBody['garment_image_base64s'] = garmentImageBase64s;
        }

        final response = await http.post(
          endpoint,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        ).timeout(
          const Duration(seconds: 180), // 3 minutes for full pipeline
        );

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body) as Map<String, dynamic>;
          
          // If we used a fallback URL, save it as the new primary
          if (attempt > 0) {
            await BackendConfigService.setBackendUrl(url);
          }
          
          return result;
        } else {
          String errorDetail = 'Try-on processing failed';
          try {
            final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
            errorDetail = errorBody['error'] ?? errorBody['detail'] ?? response.body;
          } catch (_) {
            errorDetail = response.body;
          }
          lastException = Exception(errorDetail);
          
          // If it's a client error (4xx), don't retry
          if (response.statusCode >= 400 && response.statusCode < 500) {
            throw lastException;
          }
        }
      } on http.ClientException catch (e) {
        lastException = Exception('Failed to connect to backend at $url. Make sure the backend server is running on $url');
        // Continue to next URL
        continue;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        // If it's a timeout or network error, try next URL
        if (e.toString().contains('timeout') || 
            e.toString().contains('Failed to fetch') ||
            e.toString().contains('NetworkError')) {
          continue;
        }
        // Otherwise, rethrow
        rethrow;
      }
    }
    
    // If we get here, all URLs failed
    throw lastException ?? Exception(
      'Failed to connect to backend. Tried: ${urlsToTry.join(", ")}. '
      'Please ensure the backend server is running.'
    );
  }

  /// Map backend stage to frontend stage
  static ProductionVTONStage mapStageFromBackend(String? backendStage) {
    if (backendStage == null) return ProductionVTONStage.idle;
    
    switch (backendStage) {
      case 'stage0_validation':
        return ProductionVTONStage.stage0_validation;
      case 'stage1_reasoning':
        return ProductionVTONStage.stage1_reasoning;
      case 'stage2_body_understanding':
        return ProductionVTONStage.stage2_body_understanding;
      case 'stage3_garment_segmentation':
        return ProductionVTONStage.stage3_garment_segmentation;
      case 'stage4_constraint':
        return ProductionVTONStage.stage4_constraint;
      case 'stage5_prompt_synthesis':
        return ProductionVTONStage.stage5_prompt_synthesis;
      case 'stage6_gemini_generation':
        return ProductionVTONStage.stage6_gemini_generation;
      case 'stage7_quality':
        return ProductionVTONStage.stage7_quality;
      default:
        return ProductionVTONStage.idle;
    }
  }
}

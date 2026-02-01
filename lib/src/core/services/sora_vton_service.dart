import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'backend_config_service.dart';
import '../models/tryon_state.dart';

/// Sora-like Virtual Try-On Service
/// Calls /sora-vton endpoint and handles API response contract exactly
class SoraVTONService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  /// Execute virtual try-on via Sora pipeline
  /// 
  /// API Contract (as specified):
  /// Success: { "status": "success", "image": "base64", "quality_scores": {...} }
  /// Failure: { "status": "failed", "stage": "...", "reason": "..." }
  Future<TryOnResult> executeTryOn({
    required String userImageUrl,
    required String clothingImageUrl,
  }) async {
    try {
      final backendUrl = await BackendConfigService.getBackendUrl();
      final url = Uri.parse('$backendUrl/sora-vton');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_image_url': userImageUrl,
          'cloth_image_url': clothingImageUrl,
          'source': 'wardrobe',
          'user_id': _userId,
          'preserve_face': true,
          'preserve_resolution': true,
          'use_diffusion': true,
        }),
      ).timeout(
        const Duration(seconds: 120), // 2 minutes timeout for diffusion
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseSuccessResponse(result);
      } else {
        return _parseErrorResponse(response);
      }
    } catch (e) {
      return TryOnResult(
        errorStage: 'network',
        errorReason: 'network_error',
        errorMessage: 'Failed to connect to try-on service: $e',
      );
    }
  }

  /// Parse success response from backend
  TryOnResult _parseSuccessResponse(Map<String, dynamic> result) {
    // Backend may return TryOnResponse format, map to our contract
    // Check for base64 image in various possible fields
    String? imageBase64;
    
    if (result.containsKey('image')) {
      imageBase64 = result['image'] as String?;
    } else if (result.containsKey('result_image_b64')) {
      imageBase64 = result['result_image_b64'] as String?;
    } else if (result.containsKey('result_url')) {
      // If backend returns URL, we'd need to download it
      // For now, treat as missing image
      imageBase64 = null;
    }

    // Parse quality scores
    Map<String, double>? qualityScores;
    if (result.containsKey('quality_scores')) {
      final scores = result['quality_scores'] as Map<String, dynamic>?;
      if (scores != null) {
        qualityScores = scores.map((key, value) {
          if (value is num) {
            return MapEntry(key, value.toDouble());
          }
          return MapEntry(key, 0.0);
        });
      }
    } else {
      // Fallback: check individual fields
      qualityScores = {};
      if (result.containsKey('face_similarity')) {
        qualityScores['face_similarity'] = (result['face_similarity'] as num?)?.toDouble() ?? 0.0;
      }
    }

    final status = (result['status'] as String?) ?? (result['success'] == true ? 'success' : 'failed');

    if (status == 'success' && imageBase64 != null) {
      return TryOnResult(
        imageBase64: imageBase64,
        qualityScores: qualityScores,
      );
    } else {
      return TryOnResult(
        errorStage: 'unknown',
        errorReason: 'invalid_response',
        errorMessage: 'Backend returned success but no image data',
      );
    }
  }

  /// Parse error response from backend
  TryOnResult _parseErrorResponse(http.Response response) {
    try {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      
      String? stage;
      String? reason;
      String? message;

      // Check for error in detail field (FastAPI format)
      if (error.containsKey('detail')) {
        final detail = error['detail'];
        if (detail is Map) {
          stage = detail['stage'] as String?;
          reason = detail['error_type'] as String? ?? detail['reason'] as String?;
          message = detail['message'] as String? ?? detail['error_message'] as String?;
        } else if (detail is String) {
          message = detail;
        }
      }

      // Check top-level fields
      stage ??= error['stage'] as String?;
      reason ??= error['error_type'] as String? ?? error['reason'] as String?;
      message ??= error['message'] as String? ?? error['error_message'] as String?;

      // Map backend error types to stages
      if (stage == null && reason != null) {
        if (reason.contains('STAGE_1') || reason.contains('VLM')) {
          stage = 'stage_1_vlm_reasoning';
        } else if (reason.contains('STAGE_2') || reason.contains('BODY')) {
          stage = 'stage_2_body_understanding';
        } else if (reason.contains('STAGE_3') || reason.contains('CONSTRAINT')) {
          stage = 'stage_3_constraint_engine';
        } else if (reason.contains('STAGE_4') || reason.contains('DIFFUSION')) {
          stage = 'stage_4_diffusion';
        }
      }

      return TryOnResult(
        errorStage: stage ?? 'unknown',
        errorReason: reason ?? 'unknown_error',
        errorMessage: message ?? 'Try-on processing failed',
      );
    } catch (e) {
      return TryOnResult(
        errorStage: 'unknown',
        errorReason: 'parse_error',
        errorMessage: 'Failed to parse error response: ${response.body}',
      );
    }
  }
}

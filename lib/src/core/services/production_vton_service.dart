/// Production Virtual Try-On Service
/// Calls the 7-stage production VTON backend API
library;

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
  /// API Contract (v2):
  /// Request: user_image (base64), and either garment_image (base64) or garment_image_url (backend fetches; avoids CORS on web).
  /// Success: { "status": "success", "image": "base64...", "result_image_url": "data:...", "stage": "complete" }
  /// Error: { "detail": "..." } with status 400 or 500
  ///
  /// [garmentImageBase64s] takes precedence. If null/empty, [garmentImageUrls] is used:
  /// a valid http(s) URL is sent as garment_image_url for the backend to fetch (avoids CORS in browser).
  Future<Map<String, dynamic>> executeTryOn({
    required String userImageUrl,
    required List<String> garmentImageUrls,
    String? userImageBase64,
    List<String>? garmentImageBase64s,
  }) async {
    final backendUrl = await BackendConfigService.getBackendUrl();
    final fallbackUrls = BackendConfigService.getFallbackUrls();
    final urlsToTry = {backendUrl, ...fallbackUrls}.toList();

    Exception? lastException;

    // Resolve user image: prefer base64; else fetch from userImageUrl
    String userB64;
    if (userImageBase64 != null && userImageBase64.isNotEmpty) {
      userB64 = userImageBase64.contains(',') ? userImageBase64.split(',').last : userImageBase64;
    } else if (userImageUrl.isNotEmpty) {
      userB64 = await _fetchImageAsBase64(userImageUrl);
    } else {
      throw Exception('user_image is required: provide userImageBase64 or userImageUrl');
    }
    if (userB64.isEmpty) {
      throw Exception('user_image is empty; check that the photo was encoded correctly.');
    }

    // Resolve garment: base64, or send URL for backend to fetch (avoids CORS on web)
    String? garmentImageBase64;
    String? garmentImageUrlToSend;
    if (garmentImageBase64s != null && garmentImageBase64s.isNotEmpty) {
      final g = garmentImageBase64s.first;
      garmentImageBase64 = g.contains(',') ? g.split(',').last : g;
      if (garmentImageBase64.isEmpty) {
        throw Exception('Garment image base64 is empty.');
      }
    } else if (garmentImageUrls.isNotEmpty) {
      final valid = garmentImageUrls.where((u) => u.isNotEmpty && (u.startsWith('http://') || u.startsWith('https://'))).toList();
      if (valid.isEmpty) {
        throw Exception('No valid garment image URL (http or https). Check wardrobe item imageUrl.');
      }
      garmentImageUrlToSend = valid.first;
    } else {
      throw Exception('At least one garment image is required (garmentImageUrls or garmentImageBase64s)');
    }

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
          'user_image': userB64,
          'user_id': _userId,
        };
        if (garmentImageBase64 != null && garmentImageBase64.isNotEmpty) {
          requestBody['garment_image'] = garmentImageBase64;
        } else if (garmentImageUrlToSend != null) {
          requestBody['garment_image_url'] = garmentImageUrlToSend;
        }

        final response = await http
            .post(
              endpoint,
              headers: {
                'Content-Type': 'application/json',
              },
              body: jsonEncode(requestBody),
            )
            .timeout(
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
          // Log 4xx/5xx for debugging (backend returns {"detail": "..."})
          if (response.statusCode >= 400) {
            print('[ProductionVTON] ${response.statusCode} response: ${response.body}');
          }
          String errorDetail = 'Try-on processing failed';
          try {
            final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
            final d = errorBody['error'] ?? errorBody['detail'] ?? response.body;
            if (d is List) {
              errorDetail = (d)
                  .map((e) => e is Map ? (e['msg'] ?? e.toString()) : e.toString())
                  .join('; ');
            } else {
              errorDetail = d.toString();
            }
          } catch (_) {
            errorDetail = response.body;
          }
          lastException = Exception(errorDetail);

          // If it's a client error (4xx), don't retry
          if (response.statusCode >= 400 && response.statusCode < 500) {
            throw lastException;
          }
        }
      } on http.ClientException {
        lastException = Exception(
            'Failed to connect to backend at $url. Make sure the backend server is running on $url');
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
    throw lastException ??
        Exception(
            'Failed to connect to backend. Tried: ${urlsToTry.join(", ")}. '
            'Please ensure the backend server is running.');
  }

  /// Fetch image from URL (or data URI) and return base64 string (no data URI prefix).
  static Future<String> _fetchImageAsBase64(String urlOrDataUri) async {
    if (urlOrDataUri.startsWith('data:image')) {
      final i = urlOrDataUri.indexOf(',');
      if (i >= 0) return urlOrDataUri.substring(i + 1);
      throw Exception('Invalid data URI for garment image');
    }
    if (!urlOrDataUri.startsWith('http://') && !urlOrDataUri.startsWith('https://')) {
      throw Exception('Invalid garment image URL: $urlOrDataUri');
    }
    final res = await http.get(Uri.parse(urlOrDataUri)).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch garment image: HTTP ${res.statusCode}');
    }
    return base64Encode(res.bodyBytes);
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

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'open_router_service.dart';

/// Result of AI outfit scoring (professional stylist evaluation).
class OutfitScoreResult {
  final int score;
  final String brief;

  const OutfitScoreResult({required this.score, required this.brief});
}

/// Uses OpenRouter vision model to score a try-on outfit (0–100) as a professional fashion stylist.
/// Criteria: color harmony, fit/silhouette, occasion appropriateness, trend alignment, styling.
class OutfitScoreService {
  final OpenRouterService _openRouter = OpenRouterService();

  static const String _systemPrompt = '''
You are a senior professional fashion stylist with 15+ years of experience. Your job is to evaluate outfit photos and give an honest, rigorous score from 0 to 100.

Evaluation criteria (weigh fairly):
- Color harmony and palette cohesion (do colors work together?)
- Fit and silhouette (proportions, balance, flattering lines)
- Occasion appropriateness (is the look suitable for a stated or implied context?)
- Trend alignment and modernity (does it feel current and intentional?)
- Styling details (tuck, layering, accessories if visible, overall polish)

Rules:
- Be strict and professional. A score of 100 is rare (near-perfect editorial look). Most good everyday outfits land in 70–85.
- Do not inflate scores. 50 is "acceptable", 60–69 is "decent", 70–79 is "good", 80–89 is "strong", 90+ is "excellent".
- Consider only what you see in the image. If the image is a virtual try-on or composite, evaluate the resulting outfit as shown.
- Reply with ONLY a single JSON object, no other text. Format: {"score": <number 0-100>, "brief": "<one concise sentence explaining the score>"}
''';

  static const String _userPrompt = '''
Evaluate this outfit as a professional stylist. Give a score from 0 to 100 and one short sentence. Reply with only this JSON, nothing else: {"score": <number>, "brief": "<sentence>"}
''';

  /// Max base64 length to send as-is; larger images are compressed to avoid API limits/timeouts.
  static const int _maxBase64Length = 350000;

  /// Score the outfit in the given image. [imageUrl] must be a data URL (data:image/...;base64,...) or a public https URL.
  /// Returns null on parse error or API failure so the UI can hide the score.
  Future<OutfitScoreResult?> scoreOutfit({required String imageUrl}) async {
    final urlToSend = await _prepareImageUrl(imageUrl);
    if (urlToSend == null || urlToSend.isEmpty) {
      debugPrint('OutfitScoreService: no image URL to send (prepare failed or empty)');
      return null;
    }
    try {
      final response = await _openRouter.chatWithImage(
        imageUrl: urlToSend,
        userPrompt: _userPrompt,
        systemPrompt: _systemPrompt,
        temperature: 0.2,
        maxTokens: 256,
      );
      final parsed = _parseResponse(response);
      if (parsed == null) {
        debugPrint('OutfitScoreService: failed to parse response: $response');
      }
      return parsed;
    } catch (e, st) {
      debugPrint('OutfitScoreService: score failed: $e');
      debugPrint('OutfitScoreService: $st');
      return null;
    }
  }

  /// If [imageUrl] is a large data URL, compress and return a smaller data URL; otherwise return as-is.
  static Future<String?> _prepareImageUrl(String imageUrl) async {
    if (!imageUrl.startsWith('data:image') || !imageUrl.contains(',')) {
      return imageUrl;
    }
    final base64 = imageUrl.contains(',') ? imageUrl.substring(imageUrl.indexOf(',') + 1) : '';
    if (base64.length <= _maxBase64Length) {
      return imageUrl;
    }
    try {
      final bytes = base64Decode(base64);
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return imageUrl;
      const int maxSize = 1024;
      final w = decoded.width;
      final h = decoded.height;
      img.Image resized = decoded;
      if (w > maxSize || h > maxSize) {
        if (w >= h) {
          resized = img.copyResize(decoded, width: maxSize);
        } else {
          resized = img.copyResize(decoded, height: maxSize);
        }
      }
      final jpeg = img.encodeJpg(resized, quality: 85);
      return 'data:image/jpeg;base64,${base64Encode(jpeg)}';
    } catch (e) {
      debugPrint('OutfitScoreService: compress failed, using original: $e');
      return imageUrl;
    }
  }

  OutfitScoreResult? _parseResponse(String response) {
    final trimmed = response.trim();
    // Allow optional markdown code block
    String jsonStr = trimmed;
    if (trimmed.startsWith('```')) {
      final end = trimmed.indexOf('```', 3);
      if (end > 0) {
        jsonStr = trimmed.substring(3, end).trim();
      }
    }
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final scoreRaw = map['score'];
      final brief = map['brief'] as String? ?? '';
      int score = 0;
      if (scoreRaw is int) {
        score = scoreRaw.clamp(0, 100);
      } else if (scoreRaw is num) {
        score = scoreRaw.round().clamp(0, 100);
      }
      return OutfitScoreResult(score: score, brief: brief);
    } catch (e) {
      debugPrint('OutfitScoreService: parse error: $e');
      return null;
    }
  }
}

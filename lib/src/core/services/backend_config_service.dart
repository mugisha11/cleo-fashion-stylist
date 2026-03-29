import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Backend Configuration Service
/// Manages backend API URLs and connection settings
class BackendConfigService {
  static const String _backendUrlKey = 'backend_url';

  // Local backend used during development and testing.
  static const String _localBackendUrl = 'http://localhost:8001';

  // Production backend on Railway.
  static const String _defaultProductionUrl =
      'https://cleo-fashion-stylist-production.up.railway.app';

  // Use local backend by default for all platforms when no override is saved.
  static const String _defaultBackendUrl = _localBackendUrl;

  /// Get backend URL
  static Future<String> getBackendUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_backendUrlKey);

      if (savedUrl != null && savedUrl.isNotEmpty) {
        return savedUrl;
      }

      return _defaultBackendUrl;
    } catch (e) {
      return _defaultBackendUrl;
    }
  }

  /// Set backend URL
  static Future<void> setBackendUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backendUrlKey, url);
    } catch (e) {
      throw Exception('Failed to save backend URL: $e');
    }
  }

  /// Check if backend is accessible
  static Future<bool> checkBackendHealth([String? url]) async {
    try {
      final backendUrl = url ?? await getBackendUrl();
      // Try both /health and / (root) endpoints
      final healthUrls = ['$backendUrl/health', '$backendUrl/'];

      for (final healthUrl in healthUrls) {
        try {
          final response = await http.get(
            Uri.parse(healthUrl),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            return true;
          }
        } catch (_) {
          continue;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get all possible backend URLs to try (production + local dev fallbacks)
  static List<String> getFallbackUrls() {
    return {
      _defaultProductionUrl,
      _defaultBackendUrl,
      'http://127.0.0.1:8001',
      'http://localhost:8001',
      'http://10.0.2.2:8001',
    }.toList();
  }
}

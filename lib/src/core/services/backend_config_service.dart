import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Backend Configuration Service
/// Manages backend API URLs and connection settings
class BackendConfigService {
  static const String _backendUrlKey = 'backend_url';

  // Default backend URLs
  // IMPORTANT: For Android emulator, use 10.0.2.2 instead of localhost
  // For physical devices, use your computer's IP address (e.g., http://192.168.1.100:8001)
  // For Flutter web, use localhost
  static const String _defaultBackendUrl = kIsWeb
      ? 'http://localhost:8001' // Flutter web - use localhost:8001
      : 'http://10.0.2.2:8001'; // Android emulator - port 8001
  static const String _defaultProductionUrl =
      'https://api.cleofashion.com'; // Update with your production URL

  /// Get backend URL
  static Future<String> getBackendUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_backendUrlKey);

      if (savedUrl != null && savedUrl.isNotEmpty) {
        return savedUrl;
      }

      // Use localhost by default on all platforms. Set api.cleofashion.com
      // explicitly via setBackendUrl when that host is deployed.
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

  /// Get all possible backend URLs to try (localhost only; production URL omitted to avoid ERR_NAME_NOT_RESOLVED when not deployed)
  static List<String> getFallbackUrls() {
    final urls = <String>[
      _defaultBackendUrl,
      'http://127.0.0.1:8001',
      'http://localhost:8001',
    ];
    // Avoid duplicate if _defaultBackendUrl is already localhost:8001
    return urls.toSet().toList();
  }
}

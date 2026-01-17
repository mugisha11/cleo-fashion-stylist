/// Deep Link Service
/// Handles navigation from notifications to app screens
import 'package:flutter/material.dart';
import '../../routes.dart';

class DeepLinkService {
  final BuildContext? context;
  
  DeepLinkService([this.context]);
  
  /// Handle deep link from notification
  Future<void> handleDeepLink(String? actionUrl) async {
    if (actionUrl == null || context == null) return;
    
    try {
      // Parse deep link format: /route?param1=value1&param2=value2
      final uri = Uri.parse(actionUrl);
      final route = uri.path;
      final params = uri.queryParameters;
      
      switch (route) {
        case '/tryon':
        case '/tryon-preview':
          if (params.containsKey('sessionId')) {
            Navigator.of(context!).pushNamed(
              Routes.tryonPreview,
              arguments: {'sessionId': params['sessionId']},
            );
          } else {
            Navigator.of(context!).pushNamed(Routes.tryon);
          }
          break;
          
        case '/calendar':
        case '/style-calendar':
          Navigator.of(context!).pushNamed(Routes.calendar);
          break;
          
        case '/wardrobe':
          Navigator.of(context!).pushNamed(Routes.wardrobe);
          break;
          
        case '/dashboard':
        case '/home':
          Navigator.of(context!).pushNamed(Routes.dashboard);
          break;
          
        case '/notifications':
        case '/notification-center':
          // Navigate to notification center if route exists
          Navigator.of(context!).pushNamed(Routes.dashboard);
          break;
          
        case '/recommendations':
          Navigator.of(context!).pushNamed(Routes.recommendations);
          break;
          
        case '/settings':
        case '/profile':
          Navigator.of(context!).pushNamed(Routes.settings);
          break;
          
        default:
          // Try to parse as direct route name
          if (route.startsWith('/')) {
            final routeName = route.substring(1);
            try {
              Navigator.of(context!).pushNamed(route);
            } catch (_) {
              // Fallback to dashboard
              Navigator.of(context!).pushNamed(Routes.dashboard);
            }
          } else {
            // Default to dashboard
            Navigator.of(context!).pushNamed(Routes.dashboard);
          }
      }
    } catch (e) {
      debugPrint('❌ Failed to handle deep link: $e');
    }
  }
  
  /// Generate deep link for notification
  static String generateDeepLink({
    required String route,
    Map<String, String>? params,
  }) {
    final uri = Uri(
      path: route,
      queryParameters: params,
    );
    return uri.toString();
  }
}

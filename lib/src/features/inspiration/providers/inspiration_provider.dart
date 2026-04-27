import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/backend_config_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';

class InspirationOutfit {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> keyPieces;
  final String occasion;
  final String style;

  InspirationOutfit({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.keyPieces,
    required this.occasion,
    required this.style,
  });

  factory InspirationOutfit.fromJson(Map<String, dynamic> json) {
    return InspirationOutfit(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Outfit',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      keyPieces: List<String>.from(json['key_pieces'] ?? []),
      occasion: json['occasion'] ?? 'casual',
      style: json['style'] ?? 'modern',
    );
  }
}

final personalizedInspirationProvider = FutureProvider<List<InspirationOutfit>>(
  (ref) async {
    try {
      final baseUrl = await BackendConfigService.getBackendUrl();
      final currentUser = ref.watch(currentUserProvider).valueOrNull;
      final settings = ref.watch(settingsProvider);
      final wardrobe = ref.watch(wardrobeItemsProvider).valueOrNull ?? [];

      if (currentUser == null) {
        return [];
      }

      final body = {
        'user_id': currentUser.id,
        'gender': currentUser.onboardingData.bodyInputs.gender,
        'style_preferences': settings.preferredStyles,
        'color_preferences': settings.colorPreferences,
        'budget': currentUser.onboardingData.budget,
        'wardrobe_count': wardrobe.length,
        'occasion_preferences': settings.eventPreferences,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/inspiration/personalized'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final outfits = (data['outfits'] as List?)
                ?.map((o) =>
                    InspirationOutfit.fromJson(o as Map<String, dynamic>))
                .toList() ??
            [];
        return outfits;
      }

      return [];
    } catch (e) {
      return [];
    }
  },
);

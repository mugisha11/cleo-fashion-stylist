import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/outfit_suggestion_service.dart';
import '../../../core/services/recommendations_service.dart';
import '../../calendar/providers/calendar_provider.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';

final outfitSuggestionServiceProvider = Provider<OutfitSuggestionService>((ref) {
  return OutfitSuggestionService();
});

/// Optional weather description for suggestions (e.g. "Sunny, 22°C"). Leave null to let AI assume.
final weatherForSuggestionsProvider = StateProvider<String?>((ref) => null);

/// Smart outfit suggestions for today using OpenRouter: wardrobe + calendar + weather + trends.
/// Uses only the user's clothes; considers calendar event for today and optional weather.
final smartOutfitSuggestionsProvider = FutureProvider<List<RecommendedOutfit>>((ref) async {
  final service = ref.read(outfitSuggestionServiceProvider);
  final wardrobe = await ref.read(wardrobeItemsProvider.future);
  if (wardrobe.isEmpty) return [];

  final now = DateTime.now();
  final monthKey = DateTime(now.year, now.month, 1);
  final calendarDays = await ref.read(calendarDaysProvider(monthKey).future);
  final todayKey = DateTime(now.year, now.month, now.day);
  final todayDay = calendarDays[todayKey];
  String? calendarEvent;
  if (todayDay != null) {
    if (todayDay.eventName != null && todayDay.eventName!.isNotEmpty) {
      calendarEvent = todayDay.eventName;
    } else if (todayDay.eventType != null && todayDay.eventType!.isNotEmpty) {
      calendarEvent = todayDay.eventType;
    }
  }

  final weather = ref.read(weatherForSuggestionsProvider);

  return service.suggestOutfits(
    wardrobeItems: wardrobe,
    date: now,
    weatherDescription: weather,
    calendarEvent: calendarEvent,
    userCountryCode: null,
  );
});

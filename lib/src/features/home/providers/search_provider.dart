import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/services/backend_config_service.dart';
import '../../../routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../calendar/providers/calendar_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../core/services/weather_service.dart';

/// Manages search history, context augmentation, and outfit suggestions
class SearchHistoryEntry {
  final String query;
  final DateTime timestamp;
  final String? scenario;
  final int confidence;

  SearchHistoryEntry({
    required this.query,
    required this.timestamp,
    this.scenario,
    this.confidence = 0,
  });

  Map<String, dynamic> toJson() => {
        'query': query,
        'timestamp': timestamp.toIso8601String(),
        'scenario': scenario,
        'confidence': confidence,
      };

  factory SearchHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SearchHistoryEntry(
      query: json['query'] ?? '',
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      scenario: json['scenario'],
      confidence: json['confidence'] ?? 0,
    );
  }
}

class OutfitSuggestionResult {
  final String scenario;
  final int confidence;
  final Map<String, dynamic> context;
  final String recommendedRoute;
  final List<String> suggestions;

  OutfitSuggestionResult({
    required this.scenario,
    required this.confidence,
    required this.context,
    required this.recommendedRoute,
    required this.suggestions,
  });

  factory OutfitSuggestionResult.fromJson(Map<String, dynamic> json) {
    return OutfitSuggestionResult(
      scenario: json['scenario'] ?? 'casual',
      confidence: json['confidence'] ?? 0,
      context: json['context'] ?? {},
      recommendedRoute: json['recommended_route'] ?? Routes.recommendations,
      suggestions: List<String>.from(json['suggestions'] ?? []),
    );
  }
}

// Search history provider - loads and saves to SharedPreferences
final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<SearchHistoryEntry>>(
        (ref) {
  return SearchHistoryNotifier();
});

class SearchHistoryNotifier extends StateNotifier<List<SearchHistoryEntry>> {
  SearchHistoryNotifier() : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('search_history') ?? [];
      state = historyJson
          .map((item) => SearchHistoryEntry.fromJson(jsonDecode(item)))
          .toList()
          .reversed
          .toList(); // Most recent first
    } catch (e) {
      state = [];
    }
  }

  Future<void> addSearchQuery(SearchHistoryEntry entry) async {
    try {
      // Add to state
      state = [entry, ...state];

      // Persist to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final historyJson = state.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList('search_history', historyJson);
    } catch (e) {
      // Silently fail
    }
  }

  void clearHistory() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
  }

  List<SearchHistoryEntry> getRecentQueries(int limit) {
    return state.take(limit).toList();
  }
}

// Occasion frequency provider - lets the app learn which occasion tabs are used most.
final occasionFrequencyProvider =
    StateNotifierProvider<OccasionFrequencyNotifier, Map<String, int>>((ref) {
  return OccasionFrequencyNotifier();
});

class OccasionFrequencyNotifier extends StateNotifier<Map<String, int>> {
  OccasionFrequencyNotifier() : super({}) {
    _loadFrequency();
  }

  Future<void> _loadFrequency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('occasion_frequency') ?? '{}';
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      state = parsed.map((key, value) => MapEntry(key, value as int));
    } catch (_) {
      state = {};
    }
  }

  Future<void> recordOccasionSelection(String occasion) async {
    final normalized = occasion.trim();
    if (normalized.isEmpty) return;

    state = {
      ...state,
      normalized: (state[normalized] ?? 0) + 1,
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('occasion_frequency', jsonEncode(state));
    } catch (_) {
      // ignore persistence failures
    }
  }

  List<String> getTopOccasions([int limit = 3]) {
    final sorted = state.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((entry) => entry.key).toList();
  }
}

// Context augmentation provider - gathers user context for better suggestions
final contextAugmentationProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final settings = ref.watch(settingsProvider);
    final weatherService = WeatherService();
    final currentWeather = await weatherService.getCurrentWeather();

    // Get upcoming events from calendar (next 3 days)
    final now = DateTime.now();
    final calendarEvents = ref
            .watch(calendarEventsProvider(DateTime(now.year, now.month)))
            .valueOrNull ??
        [];
    final upcomingEvents = calendarEvents
        .where((e) => e.date.isAfter(now))
        .take(3)
        .map((e) =>
            {'name': e.eventName ?? 'Event', 'date': e.date.toIso8601String()})
        .toList();

    return {
      'user_gender': currentUser?.onboardingData?.bodyInputs.gender,
      'preferred_styles': settings.preferredStyles,
      'color_preferences': settings.colorPreferences,
      'body_type': currentUser?.onboardingData?.bodyInputs.bodyType,
      'budget': currentUser?.onboardingData?.budget,
      'current_weather': currentWeather,
      'current_date': DateTime.now().toIso8601String(),
      'upcoming_events': upcomingEvents,
      'time_of_day': _getTimeOfDay(),
    };
  } catch (e) {
    return {};
  }
});

String _getTimeOfDay() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'morning';
  if (hour < 18) return 'afternoon';
  return 'evening';
}

/// Process user query and return outfit suggestions with scenario detection
final outfitSuggestionsProvider =
    FutureProvider.family<OutfitSuggestionResult, String>((ref, query) async {
  try {
    final context = ref.watch(contextAugmentationProvider).valueOrNull ?? {};
    final augmentedQuery = _augmentQuery(query, context);

    final baseUrl = await BackendConfigService.getBackendUrl();
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    final response = await http
        .post(
          Uri.parse('$baseUrl/ai-reasoning/suggest-outfit'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'prompt': augmentedQuery,
            'user_id': currentUser?.id,
            'context': context,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OutfitSuggestionResult.fromJson(data);
    }

    // Fallback to recommendations if backend fails
    return OutfitSuggestionResult(
      scenario: 'casual',
      confidence: 0,
      context: context,
      recommendedRoute: Routes.recommendations,
      suggestions: ['casual wear', 'comfortable outfit'],
    );
  } catch (e) {
    return OutfitSuggestionResult(
      scenario: 'casual',
      confidence: 0,
      context: {},
      recommendedRoute: Routes.recommendations,
      suggestions: ['casual wear'],
    );
  }
});

String _augmentQuery(String baseQuery, Map<String, dynamic> context) {
  final parts = [baseQuery];

  // Add weather context
  if (context['current_weather'] != null) {
    final weather = context['current_weather'] as String;
    parts.add('Weather: $weather');
  }

  // Add time context
  if (context['time_of_day'] != null) {
    parts.add('Time: ${context['time_of_day']}');
  }

  // Add upcoming event context
  if (context['upcoming_events'] is List &&
      (context['upcoming_events'] as List).isNotEmpty) {
    final nextEvent = (context['upcoming_events'] as List).first as Map;
    parts.add('Upcoming: ${nextEvent['name']}');
  }

  // Add body type context
  if (context['body_type'] != null &&
      context['body_type'].toString().isNotEmpty) {
    parts.add('Flattering for ${context['body_type']} body type');
  }

  return parts.join(' | ');
}

// Simpler provider for just getting recent search suggestions
final searchSuggestionsProvider = Provider<List<String>>((ref) {
  final history = ref.watch(searchHistoryProvider);
  return history.take(5).map((e) => e.query).toList();
});

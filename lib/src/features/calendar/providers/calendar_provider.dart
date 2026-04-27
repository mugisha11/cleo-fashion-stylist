import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../../core/models/calendar_day_model.dart';
import '../../../core/services/calendar_service.dart';
import '../../../core/services/open_router_service.dart';

final calendarServiceProvider = Provider<CalendarService>((ref) {
  try {
    final supabase = Supabase.instance.client;
    final auth = FirebaseAuth.instance;
    return CalendarService(supabase, auth);
  } catch (e) {
    throw Exception('CalendarService not available: $e');
  }
});

/// Provider for calendar state (current month/year)
final calendarStateProvider =
    StateNotifierProvider<CalendarStateNotifier, CalendarState>(
  (ref) => CalendarStateNotifier(),
);

class CalendarStateNotifier extends StateNotifier<CalendarState> {
  CalendarStateNotifier() : super(CalendarState(DateTime.now()));

  void setMonth(DateTime month) {
    state = CalendarState(month);
  }

  void nextMonth() {
    final next =
        DateTime(state.currentMonth.year, state.currentMonth.month + 1);
    state = CalendarState(next);
  }

  void previousMonth() {
    final prev =
        DateTime(state.currentMonth.year, state.currentMonth.month - 1);
    state = CalendarState(prev);
  }

  void goToToday() {
    state = CalendarState(DateTime.now());
  }
}

class CalendarState {
  final DateTime currentMonth;

  CalendarState(this.currentMonth);
}

/// Provider for calendar days data
final calendarDaysProvider =
    FutureProvider.family<Map<DateTime, CalendarDay>, DateTime>(
  (ref, month) async {
    try {
      final service = ref.watch(calendarServiceProvider);
      final days = await service.getCalendarDays(
        year: month.year,
        month: month.month,
      );
      // Always return a map, even if empty
      return days;
    } catch (e) {
      // Return empty map on error instead of throwing
      // This ensures the calendar still displays
      return <DateTime, CalendarDay>{};
    }
  },
);

/// Provider for calendar events data
final calendarEventsProvider =
    FutureProvider.family<List<OutfitEvent>, DateTime>(
  (ref, month) async {
    try {
      final service = ref.watch(calendarServiceProvider);
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      final events = await service.getEvents(
        startDate: startDate,
        endDate: endDate,
      );
      return events;
    } catch (e) {
      // Return empty list on error
      return <OutfitEvent>[];
    }
  },
);

/// Provider for single-day events
final dayEventsProvider = FutureProvider.family<List<OutfitEvent>, DateTime>(
  (ref, date) async {
    try {
      final service = ref.watch(calendarServiceProvider);
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final events = await service.getEvents(
        startDate: startDate,
        endDate: endDate,
      );
      return events;
    } catch (e) {
      return <OutfitEvent>[];
    }
  },
);

/// Provider for selected day
final selectedDayProvider = StateProvider<DateTime?>((ref) => null);

/// Provider for calendar actions
final calendarActionsProvider = Provider<CalendarActions>((ref) {
  final service = ref.watch(calendarServiceProvider);
  return CalendarActions(service, ref);
});

class CalendarActions {
  final CalendarService _service;
  final Ref _ref;

  CalendarActions(this._service, this._ref);

  Future<void> saveDay(CalendarDay day) async {
    await _service.saveCalendarDay(day);
    _ref.invalidate(
        calendarDaysProvider(DateTime(day.date.year, day.date.month)));
  }

  Future<void> removeOutfit(DateTime date) async {
    await _service.removeOutfitFromDay(date);
    _ref.invalidate(calendarDaysProvider(DateTime(date.year, date.month)));
  }

  Future<void> saveEvent(OutfitEvent event) async {
    await _service.saveEvent(event);
    _ref.invalidate(
        calendarDaysProvider(DateTime(event.date.year, event.date.month)));
  }

  Future<void> saveOutfit(DateTime date, WardrobeItemModel outfit) async {
    final calendarDay = CalendarDay(
      date: date,
      outfitId: outfit.id,
      outfitName: outfit.subcategory ?? outfit.category,
      outfitImageUrl: outfit.imageUrl,
      source: 'manual',
      isRecommended: false,
    );

    await _service.saveCalendarDay(calendarDay);
    _ref.invalidate(calendarDaysProvider(DateTime(date.year, date.month)));
  }

  Future<void> scheduleReminder(
    DateTime date, {
    required String title,
    required String message,
  }) async {
    // Placeholder reminder scheduling for future integration.
    // No-op for now to keep the flow functional.
    await Future.delayed(const Duration(milliseconds: 150));
  }

  Future<void> deleteEvent(String eventId, DateTime date) async {
    await _service.deleteEvent(eventId);
    _ref.invalidate(calendarEventsProvider(DateTime(date.year, date.month)));
    _ref.invalidate(calendarDaysProvider(DateTime(date.year, date.month)));
  }

  Future<void> generateAIOutfit(DateTime date) async {
    // Generate AI outfit recommendation for the given date
    try {
      // Get the calendar day to understand context (event type, etc.)
      final day = await _service.getCalendarDay(date);

      // Build context for AI
      final eventContext = day?.eventType ?? 'casual';
      final dayOfWeek = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ][date.weekday - 1];

      // Create a prompt for the AI
      final prompt = '''
Generate a stylish outfit recommendation for a $dayOfWeek $eventContext event.
Respond with:
1. A brief outfit name (max 10 words)
2. A description of the suggested outfit
3. Style tags (casual, formal, trendy, etc.)

Keep the response concise and fashion-forward.
''';

      // Use OpenRouter to generate outfit suggestions
      final openRouter = OpenRouterService();
      final systemPrompt = OpenRouterService.buildFashionSystemPrompt(
        userName: 'Fashion User',
        userPreferencesSummary:
            'Generate creative fashion outfit recommendations based on the event type and day of week.',
      );

      final response = await openRouter.chatWithFallback(
        messages: [
          {'role': 'user', 'content': prompt}
        ],
        systemPrompt: systemPrompt,
        model: OpenRouterService.defaultModel,
        temperature: 0.8,
        maxTokens: 256,
      );

      // Parse response to extract outfit name (first line usually)
      final lines =
          response.split('\n').where((line) => line.isNotEmpty).toList();
      final outfitName = lines.isNotEmpty
          ? lines[0].replaceAll(RegExp(r'^[\d\.\-*]+\s*'), '').trim()
          : 'AI Suggested Outfit';

      // Create the AI recommendation
      final recommendedOutfit = CalendarDay(
        date: date,
        outfitName: outfitName,
        outfitImageUrl:
            '', // Placeholder - would fetch actual image from wardrobe or API
        eventType: day?.eventType,
        eventName: day?.eventName,
        source: 'ai',
        confidenceScore: 0.85,
        isRecommended: true,
      );

      // Save the recommendation
      await _service.saveCalendarDay(recommendedOutfit);

      // Refresh the calendar
      _ref.invalidate(calendarDaysProvider(DateTime(date.year, date.month)));
    } catch (e) {
      // Log error for debugging
      debugPrintStack(label: 'Error generating AI outfit: $e');
      // Create a fallback suggestion if AI fails
      final fallbackOutfit = CalendarDay(
        date: date,
        outfitName: 'Smart Casual Look',
        outfitImageUrl: '',
        source: 'ai',
        confidenceScore: 0.7,
        isRecommended: false,
      );

      await _service.saveCalendarDay(fallbackOutfit);
      _ref.invalidate(calendarDaysProvider(DateTime(date.year, date.month)));
    }
  }

  Future<void> repeatLastOutfit(DateTime date) async {
    // Find the most recent outfit from previous days
    for (int i = 1; i <= 30; i++) {
      // Look back up to 30 days
      final checkDate = date.subtract(Duration(days: i));
      final day = await _service.getCalendarDay(checkDate);

      if (day != null && day.hasOutfit) {
        // Found a recent outfit, copy it to the target date
        final repeatedDay = CalendarDay(
          date: date,
          outfitId: day.outfitId,
          outfitName: day.outfitName,
          outfitImageUrl: day.outfitImageUrl,
          eventType: day.eventType,
          eventName: day.eventName,
          source: 'repeated',
          confidenceScore: day.confidenceScore,
          isRecommended: false,
        );

        await _service.saveCalendarDay(repeatedDay);
        _ref.invalidate(calendarDaysProvider(DateTime(date.year, date.month)));
        return;
      }
    }

    // No previous outfit found
    throw Exception('No previous outfit found to repeat');
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/calendar_service.dart';
import '../../../core/models/calendar_day_model.dart';

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
final calendarStateProvider = StateNotifierProvider<CalendarStateNotifier, CalendarState>(
  (ref) => CalendarStateNotifier(),
);

class CalendarStateNotifier extends StateNotifier<CalendarState> {
  CalendarStateNotifier() : super(CalendarState(DateTime.now()));

  void setMonth(DateTime month) {
    state = CalendarState(month);
  }

  void nextMonth() {
    final next = DateTime(state.currentMonth.year, state.currentMonth.month + 1);
    state = CalendarState(next);
  }

  void previousMonth() {
    final prev = DateTime(state.currentMonth.year, state.currentMonth.month - 1);
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
final calendarDaysProvider = FutureProvider.family<Map<DateTime, CalendarDay>, DateTime>(
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
    _ref.invalidate(calendarDaysProvider(DateTime(day.date.year, day.date.month)));
  }

  Future<void> removeOutfit(DateTime date) async {
    await _service.removeOutfitFromDay(date);
    _ref.invalidate(calendarDaysProvider(DateTime(date.year, date.month)));
  }

  Future<void> saveEvent(OutfitEvent event) async {
    await _service.saveEvent(event);
    _ref.invalidate(calendarDaysProvider(DateTime(event.date.year, event.date.month)));
  }
}


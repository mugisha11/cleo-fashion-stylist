import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/calendar_day_model.dart';

/// Service for managing calendar data in Supabase
class CalendarService {
  final SupabaseClient _supabase;
  final FirebaseAuth _auth;

  CalendarService(this._supabase, this._auth);

  String get _userId => _auth.currentUser?.uid ?? '';

  /// Get calendar days for a specific month
  Future<Map<DateTime, CalendarDay>> getCalendarDays({
    required int year,
    required int month,
  }) async {
    try {
      if (_userId.isEmpty) return {};

      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      final response = await _supabase
          .from('calendar_days')
          .select()
          .eq('user_id', _userId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0]);

      final Map<DateTime, CalendarDay> days = {};
      for (final item in response as List) {
        final day = CalendarDay.fromJson(item as Map<String, dynamic>);
        // Normalize date to midnight for key
        final dateKey = DateTime(day.date.year, day.date.month, day.date.day);
        days[dateKey] = day;
      }

      return days;
    } catch (e) {
      return {};
    }
  }

  /// Get a specific calendar day
  Future<CalendarDay?> getCalendarDay(DateTime date) async {
    try {
      if (_userId.isEmpty) return null;

      final dateStr = DateTime(date.year, date.month, date.day)
          .toIso8601String()
          .split('T')[0];
      final response = await _supabase
          .from('calendar_days')
          .select()
          .eq('user_id', _userId)
          .eq('date', dateStr)
          .maybeSingle();

      if (response == null) return null;
      return CalendarDay.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Save or update a calendar day
  Future<void> saveCalendarDay(CalendarDay day) async {
    try {
      if (_userId.isEmpty) return;

      final dateStr = DateTime(day.date.year, day.date.month, day.date.day)
          .toIso8601String()
          .split('T')[0];

      await _supabase.from('calendar_days').upsert({
        'user_id': _userId,
        'date': dateStr,
        ...day.toJson(),
      });
    } catch (e) {
      throw Exception('Failed to save calendar day: $e');
    }
  }

  /// Remove outfit from a calendar day
  Future<void> removeOutfitFromDay(DateTime date) async {
    try {
      if (_userId.isEmpty) return;

      final dateStr = DateTime(date.year, date.month, date.day)
          .toIso8601String()
          .split('T')[0];

      await _supabase
          .from('calendar_days')
          .update({
            'outfit_id': null,
            'outfit_name': null,
            'outfit_image_url': null,
            'is_recommended': false,
            'confidence_score': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', _userId)
          .eq('date', dateStr);
    } catch (e) {
      throw Exception('Failed to remove outfit: $e');
    }
  }

  /// Get events for a date range
  Future<List<OutfitEvent>> getEvents({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (_userId.isEmpty) return [];

      final response = await _supabase
          .from('outfit_events')
          .select()
          .eq('user_id', _userId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date', ascending: true);

      return (response as List)
          .map((item) => OutfitEvent.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save an event
  Future<void> saveEvent(OutfitEvent event) async {
    try {
      if (_userId.isEmpty) return;

      await _supabase.from('outfit_events').upsert({
        'id': event.id,
        'user_id': _userId,
        ...event.toJson(),
      });
    } catch (e) {
      throw Exception('Failed to save event: $e');
    }
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      if (_userId.isEmpty) return;

      await _supabase
          .from('outfit_events')
          .delete()
          .eq('user_id', _userId)
          .eq('id', eventId);
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }
}


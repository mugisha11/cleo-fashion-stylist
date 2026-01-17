/// Calendar Intelligence Service
/// AI-powered outfit planning and calendar integration
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/calendar_day_model.dart';
import '../models/wardrobe_item_model.dart';
import 'ai_reasoning_service.dart';

class CalendarIntelligenceService {
  final SupabaseClient _supabase;
  final FirebaseAuth _auth;
  final AIReasoningService _aiReasoning;

  CalendarIntelligenceService(this._supabase, this._auth, this._aiReasoning);

  String get _userId => _auth.currentUser?.uid ?? '';

  /// Get outfit-required events for the next N days
  Future<List<OutfitRequiredEvent>> getOutfitRequiredEvents({
    int daysAhead = 7,
  }) async {
    try {
      final now = DateTime.now();
      final endDate = now.add(Duration(days: daysAhead));
      
      final response = await _supabase
          .from('calendar_days')
          .select()
          .eq('user_id', _userId)
          .gte('date', now.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .or('event_type.not.is.null,event_name.not.is.null');

      final events = <OutfitRequiredEvent>[];
      for (final item in response as List) {
        final day = CalendarDay.fromJson(item as Map<String, dynamic>);
        if (day.eventType != null || day.eventName != null) {
          events.add(OutfitRequiredEvent(
            date: day.date,
            eventType: day.eventType,
            eventName: day.eventName,
            hasOutfit: day.outfitId != null,
            outfitId: day.outfitId,
          ));
        }
      }

      return events;
    } catch (e) {
      return [];
    }
  }

  /// Get events missing outfit assignments
  Future<List<OutfitRequiredEvent>> getMissingOutfitEvents({
    int daysAhead = 7,
  }) async {
    final events = await getOutfitRequiredEvents(daysAhead: daysAhead);
    return events.where((e) => !e.hasOutfit).toList();
  }

  /// AI suggests outfit for a specific event
  Future<OutfitSuggestion> suggestOutfitForEvent({
    required DateTime date,
    String? eventType,
    String? eventName,
  }) async {
    try {
      final recommendation = await _aiReasoning.generateOutfit(
        date: date,
        eventType: eventType,
        eventName: eventName,
      );

      return OutfitSuggestion(
        date: date,
        eventType: eventType,
        eventName: eventName,
        recommendation: recommendation,
        canAddToCalendar: true,
      );
    } catch (e) {
      return OutfitSuggestion(
        date: date,
        eventType: eventType,
        eventName: eventName,
        recommendation: null,
        canAddToCalendar: false,
      );
    }
  }

  /// Add outfit suggestion to calendar
  Future<void> addOutfitToCalendar({
    required DateTime date,
    required OutfitRecommendation recommendation,
  }) async {
    try {
      final dateStr = DateTime(date.year, date.month, date.day)
          .toIso8601String()
          .split('T')[0];

      await _supabase.from('calendar_days').upsert({
        'user_id': _userId,
        'date': dateStr,
        'outfit_id': recommendation.outfitId,
        'outfit_name': recommendation.explanation,
        'source': 'ai',
        'confidence_score': recommendation.confidence,
        'is_recommended': true,
      });
    } catch (e) {
      throw Exception('Failed to add outfit to calendar: $e');
    }
  }

  /// Get upcoming events with outfit status
  Future<List<EventWithOutfit>> getUpcomingEventsWithOutfits({
    int limit = 5,
  }) async {
    try {
      final events = await getOutfitRequiredEvents(daysAhead: 30);
      events.sort((a, b) => a.date.compareTo(b.date));

      final result = <EventWithOutfit>[];
      for (final event in events.take(limit)) {
        result.add(EventWithOutfit(
          date: event.date,
          eventType: event.eventType,
          eventName: event.eventName,
          hasOutfit: event.hasOutfit,
          outfitId: event.outfitId,
        ));
      }

      return result;
    } catch (e) {
      return [];
    }
  }
}

/// Event that requires an outfit
class OutfitRequiredEvent {
  final DateTime date;
  final String? eventType;
  final String? eventName;
  final bool hasOutfit;
  final String? outfitId;

  OutfitRequiredEvent({
    required this.date,
    this.eventType,
    this.eventName,
    required this.hasOutfit,
    this.outfitId,
  });
}

/// Outfit suggestion for an event
class OutfitSuggestion {
  final DateTime date;
  final String? eventType;
  final String? eventName;
  final OutfitRecommendation? recommendation;
  final bool canAddToCalendar;

  OutfitSuggestion({
    required this.date,
    this.eventType,
    this.eventName,
    this.recommendation,
    required this.canAddToCalendar,
  });
}

/// Event with outfit status
class EventWithOutfit {
  final DateTime date;
  final String? eventType;
  final String? eventName;
  final bool hasOutfit;
  final String? outfitId;

  EventWithOutfit({
    required this.date,
    this.eventType,
    this.eventName,
    required this.hasOutfit,
    this.outfitId,
  });
}

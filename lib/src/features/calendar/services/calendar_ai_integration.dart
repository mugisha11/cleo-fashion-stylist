import '../../../core/models/calendar_day_model.dart';
import '../../../core/services/calendar_service.dart';
import '../providers/calendar_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Calendar AI Integration Service
/// Handles integration between AI chat and calendar system
class CalendarAIIntegration {
  final CalendarService _calendarService;
  final Ref _ref;

  CalendarAIIntegration(this._calendarService, this._ref);

  /// Create a calendar event from AI chat suggestion
  /// Called when AI suggests an outfit for a specific date/time
  Future<CalendarDay> createEventFromAI({
    required DateTime date,
    required String outfitName,
    required String outfitImageUrl,
    String? outfitId,
    String? eventType,
    String? eventName,
    double? confidenceScore,
  }) async {
    final calendarDay = CalendarDay(
      date: date,
      outfitId: outfitId,
      outfitName: outfitName,
      outfitImageUrl: outfitImageUrl,
      eventType: eventType,
      eventName: eventName,
      source: 'ai',
      confidenceScore: confidenceScore,
      isRecommended: confidenceScore != null && confidenceScore > 0.7,
    );

    await _calendarService.saveCalendarDay(calendarDay);
    
    // Invalidate provider to refresh UI
    _ref.invalidate(calendarDaysProvider(DateTime(date.year, date.month)));

    return calendarDay;
  }

  /// Parse date/time from natural language
  /// Examples: "Friday dinner at 7pm", "Saturday brunch", "next Monday"
  DateTime? parseDateTimeFromText(String text, {DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    final lowerText = text.toLowerCase();

    // Simple parsing - can be enhanced with NLP
    if (lowerText.contains('today')) {
      return now;
    }
    if (lowerText.contains('tomorrow')) {
      return now.add(const Duration(days: 1));
    }
    if (lowerText.contains('friday')) {
      final daysUntilFriday = (5 - now.weekday) % 7;
      return now.add(Duration(days: daysUntilFriday == 0 ? 7 : daysUntilFriday));
    }
    if (lowerText.contains('saturday')) {
      final daysUntilSaturday = (6 - now.weekday) % 7;
      return now.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
    }
    if (lowerText.contains('sunday')) {
      final daysUntilSunday = (7 - now.weekday) % 7;
      return now.add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
    }

    // Default to tomorrow if can't parse
    return now.add(const Duration(days: 1));
  }

  /// Extract event type from natural language
  String? extractEventType(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('work') || lowerText.contains('office') || lowerText.contains('meeting')) {
      return 'work';
    }
    if (lowerText.contains('casual') || lowerText.contains('relaxed')) {
      return 'casual';
    }
    if (lowerText.contains('party') || lowerText.contains('celebration') || lowerText.contains('event')) {
      return 'event';
    }
    if (lowerText.contains('formal') || lowerText.contains('dinner') || lowerText.contains('gala')) {
      return 'formal';
    }
    if (lowerText.contains('sport') || lowerText.contains('gym') || lowerText.contains('workout')) {
      return 'sport';
    }
    
    return null;
  }
}

/// Provider for calendar AI integration
final calendarAIIntegrationProvider = Provider<CalendarAIIntegration>((ref) {
  final service = ref.watch(calendarServiceProvider);
  return CalendarAIIntegration(service, ref);
});

import '../models/wardrobe_item_model.dart';
import 'open_router_service.dart';
import 'recommendations_service.dart';

/// Uses OpenRouter to suggest outfits from the user's wardrobe only,
/// considering calendar, weather, and current fashion trends.
class OutfitSuggestionService {
  final OpenRouterService _openRouter = OpenRouterService();

  /// Suggest 2–3 outfits using only [wardrobeItems], considering [date],
  /// [weatherDescription], [calendarEvent], and current trends.
  /// Returns empty list if wardrobe is empty or API fails.
  Future<List<RecommendedOutfit>> suggestOutfits({
    required List<WardrobeItemModel> wardrobeItems,
    required DateTime date,
    String? weatherDescription,
    String? calendarEvent,
    String? userCountryCode,
  }) async {
    if (wardrobeItems.isEmpty) return [];

    final wardrobeSummary = _buildWardrobeSummary(wardrobeItems);
    final systemPrompt = _buildSystemPrompt(
      wardrobeSummary: wardrobeSummary,
      date: date,
      weatherDescription: weatherDescription,
      calendarEvent: calendarEvent,
      userCountryCode: userCountryCode,
    );
    final userPrompt = _buildUserPrompt(date, calendarEvent);

    try {
      final response = await _openRouter.chat(
        messages: [
          {'role': 'user', 'content': userPrompt},
        ],
        systemPrompt: systemPrompt,
        temperature: 0.6,
        maxTokens: 1200,
      );
      return _parseResponse(response, wardrobeItems);
    } catch (_) {
      return [];
    }
  }

  String _buildWardrobeSummary(List<WardrobeItemModel> items) {
    final buffer = StringBuffer();
    for (final item in items) {
      buffer.writeln(
        '- id: ${item.id} | category: ${item.category}'
        '${item.subcategory != null ? ' | subcategory: ${item.subcategory}' : ''}'
        ' | colors: ${item.colorTags.join(", ")}'
        '${item.occasion != null && item.occasion!.isNotEmpty ? ' | occasion: ${item.occasion!.join(", ")}' : ''}'
        '${item.season != null && item.season!.isNotEmpty ? ' | season: ${item.season!.join(", ")}' : ''}'
        '${item.fabric != null ? ' | fabric: ${item.fabric}' : ''}'
        '${item.fit != null ? ' | fit: ${item.fit}' : ''}'
        '${item.pattern != null ? ' | pattern: ${item.pattern}' : ''}',
      );
    }
    return buffer.toString();
  }

  String _buildSystemPrompt({
    required String wardrobeSummary,
    required DateTime date,
    String? weatherDescription,
    String? calendarEvent,
    String? userCountryCode,
  }) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final buffer = StringBuffer();
    buffer.writeln('You are Nikonyx, a professional fashion stylist. Your task is to suggest outfits using ONLY the wardrobe items listed below. Do not suggest any item that is not in the list.');
    buffer.writeln('');
    buffer.writeln('## Context');
    buffer.writeln('Date: $dateStr');
    if (weatherDescription != null && weatherDescription.isNotEmpty) {
      buffer.writeln('Weather: $weatherDescription');
    } else {
      buffer.writeln('Weather: not specified — assume comfortable everyday conditions for the season.');
    }
    if (calendarEvent != null && calendarEvent.isNotEmpty) {
      buffer.writeln('Calendar / occasion: $calendarEvent');
    }
    if (userCountryCode != null && userCountryCode.isNotEmpty) {
      buffer.writeln('User region: $userCountryCode (consider local season and trends).');
    }
    buffer.writeln('');
    buffer.writeln('## Current fashion trends to consider');
    buffer.writeln('Apply your knowledge of current and seasonal fashion trends (e.g. colors, silhouettes, layering, casual vs smart) for this date and region. Suggest outfits that feel modern and on-trend while using ONLY the user\'s clothes below.');
    buffer.writeln('');
    buffer.writeln('## User\'s wardrobe (use ONLY these items; each id must be used exactly as written)');
    buffer.writeln(wardrobeSummary);
    buffer.writeln('');
    buffer.writeln('## Output format (strict)');
    buffer.writeln('Reply with exactly 2 or 3 outfit suggestions. For each outfit use these two lines:');
    buffer.writeln('OUTFIT: <short name> | <id1>,<id2>,<id3>');
    buffer.writeln('REASON: <one short sentence>');
    buffer.writeln('Use only comma-separated ids from the wardrobe list. Then a blank line before the next outfit.');
    buffer.writeln('Do not include any other text before or after the outfit blocks.');
    return buffer.toString();
  }

  String _buildUserPrompt(DateTime date, String? calendarEvent) {
    final buffer = StringBuffer();
    buffer.write('Suggest 2–3 outfits for ');
    buffer.write(date.day);
    buffer.write('/');
    buffer.write(date.month);
    buffer.write('/');
    buffer.write(date.year);
    if (calendarEvent != null && calendarEvent.isNotEmpty) {
      buffer.write(' considering: $calendarEvent');
    }
    buffer.write('. Use only my wardrobe items listed above and consider the weather and current trends.');
    return buffer.toString();
  }

  List<RecommendedOutfit> _parseResponse(String response, List<WardrobeItemModel> wardrobeItems) {
    final validIds = wardrobeItems.map((e) => e.id).toSet();
    final results = <RecommendedOutfit>[];
    final blocks = response.split(RegExp(r'\n\s*\n'));
    for (final block in blocks) {
      final lines = block.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      String? name;
      List<String>? ids;
      String? reason;
      for (final line in lines) {
        if (line.toUpperCase().startsWith('OUTFIT:')) {
          final rest = line.substring(6).trim();
          final pipe = rest.indexOf('|');
          if (pipe >= 0) {
            name = rest.substring(0, pipe).trim();
            final idPart = rest.substring(pipe + 1).trim();
            ids = idPart.split(RegExp(r'[,;]')).map((s) => s.trim()).where((s) => s.isNotEmpty && validIds.contains(s)).toList();
          }
        } else if (line.toUpperCase().startsWith('REASON:')) {
          reason = line.substring(6).trim();
        }
      }
      if (name != null && name.isNotEmpty && ids != null && ids.isNotEmpty) {
        results.add(RecommendedOutfit(
          name: name,
          itemIds: ids,
          confidence: 0.85,
          reasoning: reason ?? 'Stylish combination from your wardrobe.',
        ));
      }
    }
    return results;
  }
}

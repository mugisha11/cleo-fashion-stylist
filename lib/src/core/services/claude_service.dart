import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config_service.dart';

/// Claude AI Service
/// Handles communication with Anthropic Claude API for fashion reasoning
class ClaudeService {
  final String apiKey;
  final String model;
  
  static const String _baseUrl = 'https://api.anthropic.com/v1';
  
  ClaudeService({
    required this.apiKey,
    this.model = 'claude-3-5-sonnet-20241022',
  });
  
  /// Create a message with Claude API
  Future<Map<String, dynamic>> createMessage({
    required List<Map<String, dynamic>> messages,
    double temperature = 0.7,
    int maxTokens = 1000,
    String? system,
  }) async {
    try {
      final body = {
        'model': model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
      };
      
      if (system != null) {
        body['system'] = system;
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception('Claude API error: ${errorBody['error']?['message'] ?? response.body}');
      }
    } catch (e) {
      throw Exception('Failed to call Claude API: $e');
    }
  }
  
  /// Analyze image using Claude Vision API
  Future<String> analyzeImage({
    required Uint8List imageBytes,
    required String prompt,
    String imageFormat = 'jpeg',
  }) async {
    try {
      // Convert image to base64
      final base64Image = base64Encode(imageBytes);
      final mediaType = 'image/$imageFormat';
      
      final messages = [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': mediaType,
                'data': base64Image,
              },
            },
            {
              'type': 'text',
              'text': prompt,
            },
          ],
        },
      ];
      
      final response = await createMessage(
        messages: messages,
        temperature: 0.7,
        maxTokens: 2000,
      );
      
      // Claude returns content as a list of blocks
      final content = response['content'] as List;
      if (content.isNotEmpty && content[0]['type'] == 'text') {
        return content[0]['text'] ?? '';
      }
      return '';
    } catch (e) {
      throw Exception('Failed to analyze image: $e');
    }
  }
  
  /// Understand fashion image (clothing, outfit, inspiration)
  Future<Map<String, dynamic>> understandFashionImage({
    required Uint8List imageBytes,
    String? userQuery,
    String? wardrobeContext,
  }) async {
    const systemPrompt = '''You are a luxury fashion AI stylist with deep expertise in:
- Clothing identification and categorization
- Color theory and color harmony
- Style analysis (casual, formal, streetwear, bohemian, etc.)
- Occasion appropriateness
- Fit and silhouette assessment
- Outfit coordination and styling

Provide detailed, structured analysis of fashion images. Be concise, elegant, and helpful.''';
    
    final prompt = userQuery != null
        ? '''Analyze this fashion image and answer the user's question: "$userQuery"
        
        ${wardrobeContext != null ? 'User\'s wardrobe context: $wardrobeContext' : ''}
        
        Provide:
        1. What type of clothing/item is shown
        2. Colors, patterns, style
        3. Occasion appropriateness
        4. How it could work with the user's wardrobe
        5. Any styling suggestions
        
        Be concise, elegant, and helpful.'''
        : '''Analyze this fashion image.
        
        ${wardrobeContext != null ? 'User\'s wardrobe context: $wardrobeContext' : ''}
        
        Identify:
        1. Type of clothing/item (top, bottom, dress, outerwear, accessory)
        2. Colors and patterns
        3. Style (casual, formal, streetwear, etc.)
        4. Occasion appropriateness
        5. Fit and silhouette
        6. Styling suggestions
        
        Respond in a structured, helpful way.''';
    
    try {
      final analysis = await analyzeImage(
        imageBytes: imageBytes,
        prompt: prompt,
      );
      
      // Try to extract structured data
      return {
        'analysis': analysis,
        'type': _extractClothingType(analysis),
        'colors': _extractColors(analysis),
        'style': _extractStyle(analysis),
        'occasion': _extractOccasion(analysis),
      };
    } catch (e) {
      throw Exception('Failed to understand fashion image: $e');
    }
  }
  
  /// Generate try-on reasoning and recommendations
  Future<Map<String, dynamic>> generateTryOnReasoning({
    required String userImageUrl,
    required String clothingImageUrl,
    String? userQuery,
    Map<String, dynamic>? wardrobeContext,
  }) async {
    const systemPrompt = '''You are an expert fashion AI assistant specializing in virtual try-on recommendations.
    
    Your role:
    1. Analyze clothing items and user photos
    2. Provide intelligent reasoning about outfit compatibility
    3. Suggest styling improvements
    4. Assess color harmony and style coherence
    5. Recommend complementary items from the wardrobe
    
    Be thoughtful, detailed, and fashion-forward in your analysis.''';
    
    final wardrobeContextStr = wardrobeContext != null
        ? 'User wardrobe: ${wardrobeContext.toString()}'
        : '';
    
    final prompt = '''Analyze this try-on scenario:
    
    User Photo: $userImageUrl
    Clothing Item: $clothingImageUrl
    ${userQuery != null ? 'User Question: $userQuery' : ''}
    $wardrobeContextStr
    
    Provide:
    1. Compatibility assessment (0-100 score)
    2. Style analysis and reasoning
    3. Color harmony evaluation
    4. Fit and silhouette assessment
    5. Styling suggestions
    6. Alternative outfit combinations from wardrobe (if applicable)
    
    Respond in a structured, helpful format.''';
    
    try {
      final messages = [
        {
          'role': 'user',
          'content': prompt,
        },
      ];
      
      final response = await createMessage(
        messages: messages,
        system: systemPrompt,
        temperature: 0.7,
        maxTokens: 2000,
      );
      
      final content = response['content'] as List;
      final text = content.isNotEmpty && content[0]['type'] == 'text'
          ? content[0]['text'] ?? ''
          : '';
      
      return {
        'reasoning': text,
        'score': _extractScore(text),
        'suggestions': _extractSuggestions(text),
      };
    } catch (e) {
      throw Exception('Failed to generate try-on reasoning: $e');
    }
  }
  
  /// Generate fashion advice or recommendations
  Future<String> generateFashionAdvice({
    required String context,
    required String question,
  }) async {
    const systemPrompt = '''You are a luxury fashion stylist and AI assistant. 
Provide elegant, feminine, and modern fashion advice.

Be warm, professional, and inspiring in your responses.''';
    
    final prompt = '''Context: $context

Question: $question

Provide a helpful, inspiring response.''';
    
    final messages = [
      {
        'role': 'user',
        'content': prompt,
      },
    ];
    
    final response = await createMessage(
      messages: messages,
      system: systemPrompt,
      temperature: 0.8,
      maxTokens: 1000,
    );
    
    final content = response['content'] as List;
    return content.isNotEmpty && content[0]['type'] == 'text'
        ? content[0]['text'] ?? ''
        : '';
  }
  
  /// Analyze outfit compatibility
  Future<Map<String, dynamic>> analyzeOutfit({
    required List<String> clothingItems,
    required String occasion,
  }) async {
    const systemPrompt = '''You are an expert fashion stylist analyzing outfit compatibility.
Provide detailed assessments with scores, suggestions, and color harmony analysis.''';
    
    final prompt = '''Analyze this outfit for a $occasion occasion:
${clothingItems.join(', ')}

Provide:
1. Compatibility score (0-100)
2. Style assessment
3. Suggestions for improvement
4. Color harmony analysis

Respond in JSON format with keys: score, assessment, suggestions, colorHarmony.''';
    
    final messages = [
      {
        'role': 'user',
        'content': prompt,
      },
    ];
    
    final response = await createMessage(
      messages: messages,
      system: systemPrompt,
      temperature: 0.6,
      maxTokens: 1500,
    );
    
    final content = response['content'] as List;
    final text = content.isNotEmpty && content[0]['type'] == 'text'
        ? content[0]['text'] ?? ''
        : '';
    
    try {
      // Try to parse as JSON
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      // If not JSON, return as text
      return {
        'score': _extractScore(text),
        'assessment': text,
        'suggestions': _extractSuggestions(text),
        'colorHarmony': _extractColorHarmony(text),
      };
    }
  }
  
  // Helper methods for extracting structured data
  String _extractClothingType(String analysis) {
    final lower = analysis.toLowerCase();
    if (lower.contains('dress')) return 'dress';
    if (lower.contains('top') || lower.contains('shirt') || lower.contains('blouse')) return 'top';
    if (lower.contains('bottom') || lower.contains('pants') || lower.contains('jeans') || lower.contains('skirt')) return 'bottom';
    if (lower.contains('outerwear') || lower.contains('jacket') || lower.contains('coat')) return 'outerwear';
    if (lower.contains('shoe') || lower.contains('accessory')) return 'accessories';
    return 'unknown';
  }
  
  List<String> _extractColors(String analysis) {
    final colors = <String>[];
    final colorKeywords = ['black', 'white', 'red', 'blue', 'green', 'yellow', 'pink', 'purple', 'orange', 'brown', 'gray', 'grey', 'beige', 'navy', 'burgundy', 'tan', 'cream', 'ivory'];
    final lower = analysis.toLowerCase();
    for (final color in colorKeywords) {
      if (lower.contains(color)) colors.add(color);
    }
    return colors;
  }
  
  String _extractStyle(String analysis) {
    final lower = analysis.toLowerCase();
    if (lower.contains('formal') || lower.contains('elegant')) return 'formal';
    if (lower.contains('casual')) return 'casual';
    if (lower.contains('streetwear') || lower.contains('urban')) return 'streetwear';
    if (lower.contains('bohemian') || lower.contains('boho')) return 'bohemian';
    if (lower.contains('minimalist') || lower.contains('minimal')) return 'minimalist';
    return 'casual';
  }
  
  String _extractOccasion(String analysis) {
    final lower = analysis.toLowerCase();
    if (lower.contains('work') || lower.contains('office') || lower.contains('professional')) return 'work';
    if (lower.contains('party') || lower.contains('night') || lower.contains('evening')) return 'evening';
    if (lower.contains('wedding') || lower.contains('formal event')) return 'formal';
    if (lower.contains('date') || lower.contains('romantic')) return 'date';
    if (lower.contains('casual') || lower.contains('everyday')) return 'casual';
    return 'casual';
  }
  
  int _extractScore(String text) {
    final lower = text.toLowerCase();
    final regex = RegExp(r'(\d+)\s*(?:out of 100|/100|score|%)');
    final match = regex.firstMatch(lower);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? 75;
    }
    // Try to find any number between 0-100
    final numberMatch = RegExp(r'\b([0-9]|[1-9][0-9]|100)\b').firstMatch(lower);
    if (numberMatch != null) {
      final num = int.tryParse(numberMatch.group(0) ?? '');
      if (num != null && num >= 0 && num <= 100) return num;
    }
    return 75; // Default score
  }
  
  List<String> _extractSuggestions(String text) {
    final suggestions = <String>[];
    final lines = text.split('\n');
    for (final line in lines) {
      if (line.trim().startsWith('-') || 
          line.trim().startsWith('•') || 
          line.trim().startsWith('*') ||
          (line.toLowerCase().contains('suggest') && line.length > 20)) {
        suggestions.add(line.trim());
      }
    }
    return suggestions;
  }
  
  String _extractColorHarmony(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('excellent') || lower.contains('perfect') || lower.contains('harmonious')) return 'Excellent';
    if (lower.contains('good') || lower.contains('well')) return 'Good';
    if (lower.contains('fair') || lower.contains('okay')) return 'Fair';
    if (lower.contains('poor') || lower.contains('clash')) return 'Poor';
    return 'Good';
  }
}

/// Provider for Claude Service
final claudeServiceProvider = FutureProvider<ClaudeService>((ref) async {
  // Initialize default keys if needed
  await ConfigService.initializeDefaultKeys();
  
  final apiKey = await ConfigService.getClaudeApiKey();
  
  if (apiKey == null || apiKey.isEmpty) {
    throw Exception('Claude API key not configured. Please set it in settings.');
  }
  
  return ClaudeService(
    apiKey: apiKey,
  );
});

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config_service.dart';

/// OpenAI Service
/// Handles communication with OpenAI API using GPT-5-mini model
class OpenAIService {
  final String apiKey;
  final String model;
  
  static const String _baseUrl = 'https://api.openai.com/v1';
  
  OpenAIService({
    required this.apiKey,
    required this.model,
  });
  
  /// Create a chat completion with optional image support
  Future<Map<String, dynamic>> createChatCompletion({
    required List<Map<String, dynamic>> messages,
    double temperature = 0.7,
    int maxTokens = 1000,
    bool useVision = false,
  }) async {
    try {
      // Use vision model if images are present
      final modelToUse = useVision ? 'gpt-4o-mini' : model;
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': modelToUse,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception('OpenAI API error: ${errorBody['error']?['message'] ?? response.body}');
      }
    } catch (e) {
      throw Exception('Failed to call OpenAI API: $e');
    }
  }
  
  /// Analyze image using Vision API
  Future<String> analyzeImage({
    required Uint8List imageBytes,
    required String prompt,
    String imageFormat = 'jpeg',
  }) async {
    try {
      // Convert image to base64
      final base64Image = base64Encode(imageBytes);
      final imageUrl = 'data:image/$imageFormat;base64,$base64Image';
      
      final messages = [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': prompt,
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': imageUrl,
              },
            },
          ],
        },
      ];
      
      final response = await createChatCompletion(
        messages: messages,
        temperature: 0.7,
        maxTokens: 1000,
        useVision: true,
      );
      
      return response['choices']?[0]?['message']?['content'] ?? '';
    } catch (e) {
      throw Exception('Failed to analyze image: $e');
    }
  }
  
  /// Understand fashion image (clothing, outfit, inspiration)
  Future<Map<String, dynamic>> understandFashionImage({
    required Uint8List imageBytes,
    String? userQuery,
  }) async {
    final prompt = userQuery != null
        ? '''You are a luxury fashion AI stylist. Analyze this fashion image and answer the user's question: "$userQuery"
        
        Provide:
        1. What type of clothing/item is shown
        2. Colors, patterns, style
        3. Occasion appropriateness
        4. How it could work with the user's wardrobe
        5. Any styling suggestions
        
        Be concise, elegant, and helpful.'''
        : '''You are a luxury fashion AI stylist. Analyze this fashion image.
        
        Identify:
        1. Type of clothing/item (top, bottom, dress, outerwear, accessory)
        2. Colors and patterns
        3. Style (casual, formal, streetwear, etc.)
        4. Occasion appropriateness
        5. Fit and silhouette
        
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
      };
    } catch (e) {
      throw Exception('Failed to understand fashion image: $e');
    }
  }
  
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
    final colorKeywords = ['black', 'white', 'red', 'blue', 'green', 'yellow', 'pink', 'purple', 'orange', 'brown', 'gray', 'grey', 'beige', 'navy', 'burgundy'];
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
    return 'casual';
  }
  
  /// Generate text completion
  Future<String> generateText({
    required String prompt,
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async {
    final messages = [
      {'role': 'user', 'content': prompt}
    ];
    
    final response = await createChatCompletion(
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
    );
    
    return response['choices']?[0]?['message']?['content'] ?? '';
  }
  
  /// Generate fashion advice or recommendations
  Future<String> generateFashionAdvice({
    required String context,
    required String question,
  }) async {
    final prompt = '''You are a luxury fashion stylist and AI assistant. 
Provide elegant, feminine, and modern fashion advice.

Context: $context

Question: $question

Provide a helpful, inspiring response in a warm, professional tone.''';
    
    return generateText(
      prompt: prompt,
      temperature: 0.8,
      maxTokens: 500,
    );
  }
  
  /// Analyze outfit compatibility
  Future<Map<String, dynamic>> analyzeOutfit({
    required List<String> clothingItems,
    required String occasion,
  }) async {
    final prompt = '''Analyze this outfit for a $occasion occasion:
${clothingItems.join(', ')}

Provide:
1. Compatibility score (0-100)
2. Style assessment
3. Suggestions for improvement
4. Color harmony analysis

Respond in JSON format with keys: score, assessment, suggestions, colorHarmony.''';
    
    final response = await generateText(
      prompt: prompt,
      temperature: 0.6,
      maxTokens: 800,
    );
    
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      // If not JSON, return as text
      return {
        'score': 75,
        'assessment': response,
        'suggestions': [],
        'colorHarmony': 'Good',
      };
    }
  }
}

/// Provider for OpenAI Service
final openAIServiceProvider = FutureProvider<OpenAIService>((ref) async {
  // Initialize default keys if needed
  await ConfigService.initializeDefaultKeys();
  
  final apiKey = await ConfigService.getOpenAIApiKey();
  final model = await ConfigService.getOpenAIModel();
  
  if (apiKey == null || apiKey.isEmpty) {
    throw Exception('OpenAI API key not configured. Please set it in settings.');
  }
  
  return OpenAIService(
    apiKey: apiKey,
    model: model,
  );
});

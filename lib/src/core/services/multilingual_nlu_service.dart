/// Multilingual Natural Language Understanding Service
/// Handles multilingual user input and AI responses
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MultilingualNLUService {
  final SupabaseClient _supabase;
  final FirebaseAuth _auth;
  static const String _backendUrl = 'http://localhost:8001';

  MultilingualNLUService(this._supabase, this._auth);

  String get _userId => _auth.currentUser?.uid ?? '';

  /// Detect language from user input
  Future<String> detectLanguage(String text) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/nlu/detect-language'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        return 'en'; // Default to English
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['language'] as String? ?? 'en';
    } catch (e) {
      return 'en'; // Default fallback
    }
  }

  /// Process multilingual user query and return AI response in same language
  Future<String> processQuery(String userQuery) async {
    try {
      final language = await detectLanguage(userQuery);

      final response = await http
          .post(
            Uri.parse('$_backendUrl/nlu/process-query'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': userQuery,
              'language': language,
              'user_id': _userId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('NLU processing failed: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['response'] as String? ?? userQuery;
    } catch (e) {
      // Fallback: return original query
      return userQuery;
    }
  }

  /// Translate text to target language
  Future<String> translate(String text, String targetLanguage) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/nlu/translate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'text': text,
              'target_language': targetLanguage,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return text; // Return original on failure
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['translated_text'] as String? ?? text;
    } catch (e) {
      return text;
    }
  }
}

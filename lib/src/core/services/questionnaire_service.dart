import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fashion_questionnaire_model.dart';

/// Questionnaire Service - Stores user fashion preferences
class QuestionnaireService {
  final SupabaseClient _supabase;
  final FirebaseAuth _auth;

  QuestionnaireService(this._supabase, this._auth);

  String get _userId => _auth.currentUser?.uid ?? '';
  String get userId => _userId;

  /// Check if user has completed questionnaire
  Future<bool> hasCompletedQuestionnaire() async {
    try {
      final response = await _supabase
          .from('user_preferences')
          .select('id')
          .eq('user_id', _userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Save questionnaire responses
  Future<void> saveQuestionnaireResponse(QuestionnaireResponse response) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      // Extract preferences from answers
      final preferences = _extractPreferences(response.answers);

      // Save to user_preferences table
      await _supabase.from('user_preferences').upsert({
        'user_id': _userId,
        'preferences': preferences,
        'questionnaire_answers': response.toMap(),
        'completed_at': response.completedAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      // Provide more helpful error message
      if (e.toString().contains('PGRST205') || e.toString().contains('table') || e.toString().contains('schema cache')) {
        throw Exception('Database table not found. Please run the migration: supabase_user_preferences_migration.sql');
      }
      throw Exception('Failed to save questionnaire: $e');
    }
  }

  /// Extract structured preferences from answers
  Map<String, dynamic> _extractPreferences(List<QuestionnaireAnswer> answers) {
    final preferences = <String, dynamic>{};

    for (var answer in answers) {
      // Get question details
      final question = FashionQuestionnaire.getQuestions().firstWhere(
        (q) => q.id == answer.questionId,
        orElse: () => FashionQuestionnaire.getQuestions().first,
      );

      // Extract metadata from selected options
      for (var optionId in answer.selectedOptionIds) {
        final option = question.options.firstWhere(
          (o) => o.id == optionId,
          orElse: () => question.options.first,
        );

        // Merge metadata into preferences
        option.metadata.forEach((key, value) {
          if (preferences.containsKey(key)) {
            if (preferences[key] is List) {
              (preferences[key] as List).add(value);
            } else {
              preferences[key] = [preferences[key], value];
            }
          } else {
            preferences[key] = value;
          }
        });
      }
    }

    return preferences;
  }

  /// Get user preferences
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final response = await _supabase
          .from('user_preferences')
          .select('preferences')
          .eq('user_id', _userId)
          .maybeSingle();

      return response?['preferences'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      return {};
    }
  }
}

/// Provider for QuestionnaireService
final questionnaireServiceProvider = Provider<QuestionnaireService>((ref) {
  final supabase = Supabase.instance.client;
  final auth = FirebaseAuth.instance;
  return QuestionnaireService(supabase, auth);
});


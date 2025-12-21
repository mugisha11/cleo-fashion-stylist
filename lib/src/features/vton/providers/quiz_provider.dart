import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/vton_service.dart';
import '../../../core/models/quiz_model.dart';

/// Quiz questions provider
final quizQuestionsProvider = FutureProvider<List<QuizQuestion>>((ref) async {
  final service = ref.read(vtonServiceProvider);
  return await service.getQuizQuestions();
});

/// Quiz answers state provider
final quizProvider = StateNotifierProvider<QuizNotifier, List<QuizAnswer>>((ref) {
  final service = ref.read(vtonServiceProvider);
  return QuizNotifier(service);
});

class QuizNotifier extends StateNotifier<List<QuizAnswer>> {
  final VTONService _service;

  QuizNotifier(this._service) : super([]);

  Future<void> submitAnswer({
    required String questionId,
    required String imageId,
    required String choice,
  }) async {
    final answer = QuizAnswer(
      questionId: questionId,
      imageId: imageId,
      choice: choice,
      answeredAt: DateTime.now(),
    );

    // Save to database
    await _service.submitQuizAnswer(answer);

    // Update local state
    state = [...state, answer];
  }

  Future<void> completeQuiz() async {
    await _service.completeQuiz();
  }
}


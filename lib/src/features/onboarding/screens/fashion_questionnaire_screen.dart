import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/fashion_questionnaire_model.dart';
import '../../../core/services/questionnaire_service.dart';
import '../../../core/theme/grok_design_system.dart';
import '../../../routes.dart';

/// Fashion Questionnaire Screen
/// 10 questions with image-based options
/// User selects Like/Dislike for each option
class FashionQuestionnaireScreen extends ConsumerStatefulWidget {
  const FashionQuestionnaireScreen({super.key});

  @override
  ConsumerState<FashionQuestionnaireScreen> createState() => _FashionQuestionnaireScreenState();
}

class _FashionQuestionnaireScreenState extends ConsumerState<FashionQuestionnaireScreen> {
  final List<FashionQuestion> _questions = FashionQuestionnaire.getQuestions();
  int _currentQuestionIndex = 0;
  final Map<String, QuestionnaireAnswer> _answers = {};

  FashionQuestion get _currentQuestion => _questions[_currentQuestionIndex];

  void _selectOption(String optionId, bool liked) {
    setState(() {
      final questionId = _currentQuestion.id;
      if (_answers.containsKey(questionId)) {
        final existing = _answers[questionId]!;
        if (liked) {
          // Add to selected if not already there
          if (!existing.selectedOptionIds.contains(optionId)) {
            _answers[questionId] = QuestionnaireAnswer(
              questionId: questionId,
              selectedOptionIds: [...existing.selectedOptionIds, optionId],
              liked: liked,
            );
          }
        } else {
          // Remove from selected
          _answers[questionId] = QuestionnaireAnswer(
            questionId: questionId,
            selectedOptionIds: existing.selectedOptionIds.where((id) => id != optionId).toList(),
            liked: false,
          );
        }
      } else {
        _answers[questionId] = QuestionnaireAnswer(
          questionId: questionId,
          selectedOptionIds: liked ? [optionId] : [],
          liked: liked,
        );
      }
    });
  }

  Future<void> _handleNext() async {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      // Complete questionnaire
      await _completeQuestionnaire();
    }
  }

  void _handlePrevious() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Future<void> _completeQuestionnaire() async {
    try {
      final questionnaireService = ref.read(questionnaireServiceProvider);
      final userId = ref.read(questionnaireServiceProvider).userId;

      final response = QuestionnaireResponse(
        userId: userId,
        answers: _answers.values.toList(),
        completedAt: DateTime.now(),
      );

      await questionnaireService.saveQuestionnaireResponse(response);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: GrokDesignSystem.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: GrokDesignSystem.backgroundOffWhite,
      appBar: AppBar(
        backgroundColor: GrokDesignSystem.backgroundWhite,
        elevation: 0,
        title: Text(
          'Style Preferences',
          style: GrokDesignSystem.headlineSmall(isMobile: isMobile),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: GrokDesignSystem.backgroundLightGray,
            valueColor: const AlwaysStoppedAnimation<Color>(GrokDesignSystem.primaryCharcoal),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(GrokDesignSystem.spacingLG),
              child: Text(
                '${_currentQuestionIndex + 1} of ${_questions.length}',
                style: GrokDesignSystem.bodyMedium(isMobile: isMobile).copyWith(
                  color: GrokDesignSystem.textSecondary,
                ),
              ),
            ),

            // Question
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: GrokDesignSystem.spacingLG),
              child: Text(
                _currentQuestion.question,
                style: GrokDesignSystem.headlineMedium(isMobile: isMobile),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: GrokDesignSystem.spacingXL),

            // Options Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(GrokDesignSystem.spacingMD),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 2 : 4,
                  crossAxisSpacing: GrokDesignSystem.spacingMD,
                  mainAxisSpacing: GrokDesignSystem.spacingMD,
                  childAspectRatio: 0.75,
                ),
                itemCount: _currentQuestion.options.length,
                itemBuilder: (context, index) {
                  final option = _currentQuestion.options[index];
                  final isSelected = _answers[_currentQuestion.id]?.selectedOptionIds.contains(option.id) ?? false;
                  final isLiked = _answers[_currentQuestion.id]?.liked ?? false;

                  return _buildOptionCard(option, isSelected && isLiked, isMobile);
                },
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(GrokDesignSystem.spacingLG),
              child: Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _handlePrevious,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: GrokDesignSystem.spacingMD),
                          side: const BorderSide(color: GrokDesignSystem.borderLight),
                        ),
                        child: Text('Previous', style: GrokDesignSystem.buttonText()),
                      ),
                    ),
                  if (_currentQuestionIndex > 0) const SizedBox(width: GrokDesignSystem.spacingMD),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GrokDesignSystem.primaryCharcoal,
                        padding: const EdgeInsets.symmetric(vertical: GrokDesignSystem.spacingMD),
                      ),
                      child: Text(
                        _currentQuestionIndex < _questions.length - 1 ? 'Next' : 'Complete',
                        style: GrokDesignSystem.buttonText(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(FashionOption option, bool isSelected, bool isMobile) {
    return GestureDetector(
      onTap: () => _selectOption(option.id, !isSelected),
      child: Container(
        decoration: BoxDecoration(
          color: GrokDesignSystem.backgroundWhite,
          borderRadius: BorderRadius.circular(GrokDesignSystem.radiusLG),
          border: Border.all(
            color: isSelected ? GrokDesignSystem.accentBlue : GrokDesignSystem.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? GrokDesignSystem.cardShadow : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(GrokDesignSystem.radiusLG)),
                child: CachedNetworkImage(
                  imageUrl: option.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: GrokDesignSystem.backgroundLightGray,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: GrokDesignSystem.backgroundLightGray,
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            ),

            // Label and Like/Dislike buttons
            Padding(
              padding: const EdgeInsets.all(GrokDesignSystem.spacingSM),
              child: Column(
                children: [
                  Text(
                    option.label,
                    style: GrokDesignSystem.bodyMedium(isMobile: isMobile).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: GrokDesignSystem.spacingXS),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLikeButton(option.id, true, isSelected),
                      const SizedBox(width: GrokDesignSystem.spacingSM),
                      _buildLikeButton(option.id, false, false),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikeButton(String optionId, bool liked, bool isSelected) {
    final isActive = isSelected && liked;
    return GestureDetector(
      onTap: () => _selectOption(optionId, liked),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GrokDesignSystem.spacingSM,
          vertical: GrokDesignSystem.spacingXS,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? (liked ? GrokDesignSystem.success : GrokDesignSystem.error)
              : GrokDesignSystem.backgroundLightGray,
          borderRadius: BorderRadius.circular(GrokDesignSystem.radiusSM),
        ),
        child: Icon(
          liked ? Icons.thumb_up : Icons.thumb_down,
          size: 16,
          color: isActive ? GrokDesignSystem.textInverse : GrokDesignSystem.textSecondary,
        ),
      ),
    );
  }
}


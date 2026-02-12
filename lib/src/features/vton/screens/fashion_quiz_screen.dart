import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/quiz_model.dart';
import '../../../routes.dart';
import '../providers/quiz_provider.dart';

/// 10-question fashion style preference quiz
class FashionQuizScreen extends ConsumerStatefulWidget {
  const FashionQuizScreen({super.key});

  @override
  ConsumerState<FashionQuizScreen> createState() => _FashionQuizScreenState();
}

class _FashionQuizScreenState extends ConsumerState<FashionQuizScreen> {
  int _currentQuestionIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Questions load automatically via quizQuestionsProvider
  }

  Future<void> _handleAnswer(String choice) async {
    final questions = ref.read(quizQuestionsProvider).value ?? [];
    if (_currentQuestionIndex >= questions.length) return;

    final question = questions[_currentQuestionIndex];
    setState(() => _isLoading = true);

    try {
      await ref.read(quizProvider.notifier).submitAnswer(
            questionId: question.id,
            imageId: question.imageId,
            choice: choice,
          );

      if (mounted) {
        if (_currentQuestionIndex < questions.length - 1) {
          setState(() {
            _currentQuestionIndex++;
            _isLoading = false;
          });
        } else {
          // Quiz complete - compute style profile
          await ref.read(quizProvider.notifier).completeQuiz();
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(Routes.photoCapture);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(quizQuestionsProvider);
    final answers = ref.watch(quizProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: questionsAsync.when(
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_currentQuestionIndex >= questions.length) {
            return const Center(child: Text('Quiz complete!'));
          }

          final question = questions[_currentQuestionIndex];
          final progress = (_currentQuestionIndex + 1) / questions.length;

          return SafeArea(
            child: Column(
              children: [
                // Progress bar
                _ProgressBar(progress: progress),
                
                // Question card
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _QuestionCard(
                        question: question,
                        questionNumber: _currentQuestionIndex + 1,
                        totalQuestions: questions.length,
                        isLoading: _isLoading,
                        onLike: () => _handleAnswer('like'),
                        onDislike: () => _handleAnswer('dislike'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading quiz: $error'),
        ),
      ),
    );
  }
}

/// Progress bar at top
class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8C7AE6), Color(0xFF2DC6A7)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

/// Question card with image and buttons
class _QuestionCard extends StatefulWidget {
  final QuizQuestion question;
  final int questionNumber;
  final int totalQuestions;
  final bool isLoading;
  final VoidCallback onLike;
  final VoidCallback onDislike;

  const _QuestionCard({
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.isLoading,
    required this.onLike,
    required this.onDislike,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  final bool _imageLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image section
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.question.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.error),
                    ),
                  ),
                  // Overlay with question info
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question ${widget.questionNumber}/${widget.totalQuestions}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (widget.question.occasion != null)
                            Text(
                              widget.question.occasion!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          if (widget.question.tags.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: widget.question.tags
                                  .take(3)
                                  .map((tag) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          tag,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.close_rounded,
                      label: 'Dislike',
                      color: Colors.red,
                      onTap: widget.isLoading ? null : widget.onDislike,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.check_rounded,
                      label: 'Like',
                      color: const Color(0xFF2DC6A7),
                      onTap: widget.isLoading ? null : widget.onLike,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOut);
  }
}

/// Action button (Like/Dislike)
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


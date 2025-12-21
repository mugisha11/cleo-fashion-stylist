import 'package:equatable/equatable.dart';

/// Quiz question model
class QuizQuestion extends Equatable {
  final String id;
  final int questionNumber;
  final String imageUrl;
  final String imageId;
  final String? occasion;
  final List<String> tags;
  final String? styleCategory;

  const QuizQuestion({
    required this.id,
    required this.questionNumber,
    required this.imageUrl,
    required this.imageId,
    this.occasion,
    this.tags = const [],
    this.styleCategory,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      questionNumber: json['question_number'] as int,
      imageUrl: json['image_url'] as String,
      imageId: json['image_id'] as String,
      occasion: json['occasion'] as String?,
      tags: List<String>.from(json['tags'] as List? ?? []),
      styleCategory: json['style_category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_number': questionNumber,
      'image_url': imageUrl,
      'image_id': imageId,
      'occasion': occasion,
      'tags': tags,
      'style_category': styleCategory,
    };
  }

  @override
  List<Object?> get props => [id, questionNumber, imageUrl, imageId];
}

/// Quiz answer model
class QuizAnswer extends Equatable {
  final String questionId;
  final String imageId;
  final String choice; // 'like' or 'dislike'
  final DateTime answeredAt;

  const QuizAnswer({
    required this.questionId,
    required this.imageId,
    required this.choice,
    required this.answeredAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'image_id': imageId,
      'choice': choice,
      'answered_at': answeredAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [questionId, imageId, choice];
}


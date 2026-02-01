import 'package:equatable/equatable.dart';

/// Fashion Questionnaire Question Model
class FashionQuestion extends Equatable {
  final String id;
  final String question;
  final String category;
  final List<FashionOption> options;
  final int questionNumber;

  const FashionQuestion({
    required this.id,
    required this.question,
    required this.category,
    required this.options,
    required this.questionNumber,
  });

  @override
  List<Object?> get props => [id, question, category, options, questionNumber];
}

/// Fashion Option (Image-based)
class FashionOption extends Equatable {
  final String id;
  final String label;
  final String imageUrl;
  final Map<String, dynamic> metadata;

  const FashionOption({
    required this.id,
    required this.label,
    required this.imageUrl,
    required this.metadata,
  });

  @override
  List<Object?> get props => [id, label, imageUrl, metadata];
}

/// Questionnaire Answer
class QuestionnaireAnswer extends Equatable {
  final String questionId;
  final List<String> selectedOptionIds; // Can select multiple
  final bool liked; // true = like, false = dislike

  const QuestionnaireAnswer({
    required this.questionId,
    required this.selectedOptionIds,
    required this.liked,
  });

  Map<String, dynamic> toMap() {
    return {
      'question_id': questionId,
      'selected_option_ids': selectedOptionIds,
      'liked': liked,
    };
  }

  @override
  List<Object?> get props => [questionId, selectedOptionIds, liked];
}

/// Complete Questionnaire Response
class QuestionnaireResponse extends Equatable {
  final String userId;
  final List<QuestionnaireAnswer> answers;
  final DateTime completedAt;

  const QuestionnaireResponse({
    required this.userId,
    required this.answers,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'answers': answers.map((a) => a.toMap()).toList(),
      'completed_at': completedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [userId, answers, completedAt];
}

/// Predefined Fashion Questions (10 questions)
class FashionQuestionnaire {
  static List<FashionQuestion> getQuestions() {
    return [
      const FashionQuestion(
        id: 'q1',
        questionNumber: 1,
        question: 'What\'s your go-to fashion style?',
        category: 'style',
        options: [
          FashionOption(
            id: 'o1_1',
            label: 'Minimalist',
            imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
            metadata: {'style': 'minimalist'},
          ),
          FashionOption(
            id: 'o1_2',
            label: 'Streetwear',
            imageUrl: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400',
            metadata: {'style': 'streetwear'},
          ),
          FashionOption(
            id: 'o1_3',
            label: 'Classic',
            imageUrl: 'https://images.unsplash.com/photo-1490578474895-699cd4e2cf59?w=400',
            metadata: {'style': 'classic'},
          ),
          FashionOption(
            id: 'o1_4',
            label: 'Bohemian',
            imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
            metadata: {'style': 'bohemian'},
          ),
        ],
      ),
      const FashionQuestion(
        id: 'q2',
        questionNumber: 2,
        question: 'Which color palette do you prefer?',
        category: 'colors',
        options: [
          FashionOption(
            id: 'o2_1',
            label: 'Neutrals',
            imageUrl: 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=400',
            metadata: {'colors': ['black', 'white', 'gray', 'beige']},
          ),
          FashionOption(
            id: 'o2_2',
            label: 'Bold & Bright',
            imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
            metadata: {'colors': ['red', 'yellow', 'blue', 'green']},
          ),
          FashionOption(
            id: 'o2_3',
            label: 'Pastels',
            imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
            metadata: {'colors': ['pink', 'lavender', 'mint', 'peach']},
          ),
          FashionOption(
            id: 'o2_4',
            label: 'Earth Tones',
            imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
            metadata: {'colors': ['brown', 'olive', 'rust', 'tan']},
          ),
        ],
      ),
      const FashionQuestion(
        id: 'q3',
        questionNumber: 3,
        question: 'What occasions do you dress for most?',
        category: 'occasion',
        options: [
          FashionOption(
            id: 'o3_1',
            label: 'Work/Office',
            imageUrl: 'https://images.unsplash.com/photo-1490578474895-699cd4e2cf59?w=400',
            metadata: {'occasion': 'work'},
          ),
          FashionOption(
            id: 'o3_2',
            label: 'Casual/Everyday',
            imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
            metadata: {'occasion': 'casual'},
          ),
          FashionOption(
            id: 'o3_3',
            label: 'Formal Events',
            imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
            metadata: {'occasion': 'formal'},
          ),
          FashionOption(
            id: 'o3_4',
            label: 'Nightlife',
            imageUrl: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400',
            metadata: {'occasion': 'nightlife'},
          ),
        ],
      ),
      const FashionQuestion(
        id: 'q4',
        questionNumber: 4,
        question: 'How do you prefer your fits?',
        category: 'fit',
        options: [
          FashionOption(
            id: 'o4_1',
            label: 'Fitted',
            imageUrl: 'https://images.unsplash.com/photo-1490578474895-699cd4e2cf59?w=400',
            metadata: {'fit': 'fitted'},
          ),
          FashionOption(
            id: 'o4_2',
            label: 'Relaxed',
            imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
            metadata: {'fit': 'relaxed'},
          ),
          FashionOption(
            id: 'o4_3',
            label: 'Oversized',
            imageUrl: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400',
            metadata: {'fit': 'oversized'},
          ),
          FashionOption(
            id: 'o4_4',
            label: 'Tailored',
            imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
            metadata: {'fit': 'tailored'},
          ),
        ],
      ),
      const FashionQuestion(
        id: 'q5',
        questionNumber: 5,
        question: 'What patterns do you like?',
        category: 'patterns',
        options: [
          FashionOption(
            id: 'o5_1',
            label: 'Solid Colors',
            imageUrl: 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=400',
            metadata: {'pattern': 'solid'},
          ),
          FashionOption(
            id: 'o5_2',
            label: 'Stripes',
            imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
            metadata: {'pattern': 'stripes'},
          ),
          FashionOption(
            id: 'o5_3',
            label: 'Floral',
            imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
            metadata: {'pattern': 'floral'},
          ),
          FashionOption(
            id: 'o5_4',
            label: 'Geometric',
            imageUrl: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400',
            metadata: {'pattern': 'geometric'},
          ),
        ],
      ),
      const FashionQuestion(
        id: 'q6',
        questionNumber: 6,
        question: 'Preferred season style?',
        category: 'season',
        options: [
          FashionOption(
            id: 'o6_1',
            label: 'Spring',
            imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
            metadata: {'season': 'spring'},
          ),
          FashionOption(
            id: 'o6_2',
            label: 'Summer',
            imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
            metadata: {'season': 'summer'},
          ),
          FashionOption(
            id: 'o6_3',
            label: 'Fall',
            imageUrl: 'https://images.unsplash.com/photo-1490578474895-699cd4e2cf59?w=400',
            metadata: {'season': 'fall'},
          ),
          FashionOption(
            id: 'o6_4',
            label: 'Winter',
            imageUrl: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400',
            metadata: {'season': 'winter'},
          ),
        ],
      ),
      const FashionQuestion(
        id: 'q7',
        questionNumber: 7,
        question: 'What accessories do you prefer?',
        category: 'accessories',
        options: [
          FashionOption(
            id: 'o7_1',
            label: 'Minimal',
            imageUrl: 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=400',
            metadata: {'accessories': 'minimal'},
          ),
          FashionOption(
            id: 'o7_2',
            label: 'Statement Pieces',
            imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
            metadata: {'accessories': 'statement'},
          ),
          FashionOption(
            id: 'o7_3',
            label: 'Layered',
            imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
            metadata: {'accessories': 'layered'},
          ),
          FashionOption(
            id: 'o7_4',
            label: 'Classic',
            imageUrl: 'https://images.unsplash.com/photo-1490578474895-699cd4e2cf59?w=400',
            metadata: {'accessories': 'classic'},
          ),
        ],
      ),
      const FashionQuestion(
        id: 'q8',
        questionNumber: 8,
        question: 'How do you feel about trends?',
        category: 'trends',
        options: [
          FashionOption(
            id: 'o8_1',
            label: 'Early Adopter',
            imageUrl: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400',
            metadata: {'trends': 'early'},
          ),
          FashionOption(
            id: 'o8_2',
            label: 'Timeless',
            imageUrl: 'https://images.unsplash.com/photo-1490578474895-699cd4e2cf59?w=400',
            metadata: {'trends': 'timeless'},
          ),
          FashionOption(
            id: 'o8_3',
            label: 'Selective',
            imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
            metadata: {'trends': 'selective'},
          ),
          FashionOption(
            id: 'o8_4',
            label: 'Mix of Both',
            imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
            metadata: {'trends': 'mixed'},
          ),
        ],
      ),
      const FashionQuestion(
        id: 'q9',
        questionNumber: 9,
        question: 'What\'s your budget range?',
        category: 'budget',
        options: [
          FashionOption(
            id: 'o9_1',
            label: 'Budget-Friendly',
            imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
            metadata: {'budget': 'budget'},
          ),
          FashionOption(
            id: 'o9_2',
            label: 'Mid-Range',
            imageUrl: 'https://images.unsplash.com/photo-1490578474895-699cd4e2cf59?w=400',
            metadata: {'budget': 'mid'},
          ),
          FashionOption(
            id: 'o9_3',
            label: 'Premium',
            imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
            metadata: {'budget': 'premium'},
          ),
          FashionOption(
            id: 'o9_4',
            label: 'Luxury',
            imageUrl: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400',
            metadata: {'budget': 'luxury'},
          ),
        ],
      ),
      const FashionQuestion(
        id: 'q10',
        questionNumber: 10,
        question: 'How do you want to feel in your clothes?',
        category: 'mood',
        options: [
          FashionOption(
            id: 'o10_1',
            label: 'Confident',
            imageUrl: 'https://images.unsplash.com/photo-1490578474895-699cd4e2cf59?w=400',
            metadata: {'mood': 'confident'},
          ),
          FashionOption(
            id: 'o10_2',
            label: 'Comfortable',
            imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
            metadata: {'mood': 'comfortable'},
          ),
          FashionOption(
            id: 'o10_3',
            label: 'Elegant',
            imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
            metadata: {'mood': 'elegant'},
          ),
          FashionOption(
            id: 'o10_4',
            label: 'Bold',
            imageUrl: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400',
            metadata: {'mood': 'bold'},
          ),
        ],
      ),
    ];
  }
}


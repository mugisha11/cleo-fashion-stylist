import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wardrobe_item_model.dart';
import '../models/user_model.dart';

class RecommendationsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get AI-powered outfit recommendations
  Future<List<RecommendedOutfit>> getRecommendations({
    required OnboardingData onboardingData,
    required List<WardrobeItemModel> wardrobeItems,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Prepare input data
      final inputData = {
        'userId': userId,
        'onboardingData': onboardingData.toMap(),
        'wardrobeItems': wardrobeItems.map((item) => {
          'id': item.id,
          'category': item.category,
          'colorTags': item.colorTags,
          'brand': item.brand,
        }).toList(),
      };

      // Call Cloud Function
      final callable = _functions.httpsCallable('generateOutfitRecommendations');
      final result = await callable.call(inputData);
      final data = result.data as Map<String, dynamic>;

      // Parse recommendations
      final recommendations = (data['recommendations'] as List)
          .map((item) => RecommendedOutfit.fromMap(item as Map<String, dynamic>))
          .toList();

      return recommendations;
    } catch (e) {
      // Fallback: return mock recommendations
      return _getMockRecommendations(wardrobeItems);
    }
  }

  /// Fallback mock recommendations
  List<RecommendedOutfit> _getMockRecommendations(List<WardrobeItemModel> wardrobeItems) {
    if (wardrobeItems.isEmpty) {
      return [];
    }

    // Group items by category
    final tops = wardrobeItems.where((item) => item.category.toLowerCase().contains('top')).toList();
    final bottoms = wardrobeItems.where((item) => item.category.toLowerCase().contains('bottom')).toList();
    final shoes = wardrobeItems.where((item) => item.category.toLowerCase().contains('shoe')).toList();

    final recommendations = <RecommendedOutfit>[];

    // Create simple combinations
    if (tops.isNotEmpty && bottoms.isNotEmpty) {
      recommendations.add(RecommendedOutfit(
        name: 'Casual Look',
        itemIds: [tops.first.id, bottoms.first.id],
        confidence: 0.85,
        reasoning: 'A classic combination that works for everyday wear.',
      ));
    }

    if (tops.isNotEmpty && bottoms.isNotEmpty && shoes.isNotEmpty) {
      recommendations.add(RecommendedOutfit(
        name: 'Complete Outfit',
        itemIds: [tops.first.id, bottoms.first.id, shoes.first.id],
        confidence: 0.90,
        reasoning: 'A well-balanced outfit with all elements.',
      ));
    }

    return recommendations;
  }
}

class RecommendedOutfit {
  final String name;
  final List<String> itemIds;
  final double confidence;
  final String reasoning;

  RecommendedOutfit({
    required this.name,
    required this.itemIds,
    required this.confidence,
    required this.reasoning,
  });

  factory RecommendedOutfit.fromMap(Map<String, dynamic> map) {
    return RecommendedOutfit(
      name: map['name'] as String,
      itemIds: List<String>.from(map['itemIds'] as List),
      confidence: (map['confidence'] as num).toDouble(),
      reasoning: map['reasoning'] as String,
    );
  }
}


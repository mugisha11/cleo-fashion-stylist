import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/recommendations_service.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../../auth/providers/auth_provider.dart';

final recommendationsServiceProvider = Provider<RecommendationsService>((ref) {
  return RecommendationsService();
});

final recommendationsProvider = FutureProvider<List<RecommendedOutfit>>((ref) async {
  final recommendationsService = ref.read(recommendationsServiceProvider);
  final currentUser = await ref.read(currentUserProvider.future);
  final wardrobe = await ref.read(wardrobeItemsProvider.future);

  if (currentUser == null || currentUser.onboardingData == null) {
    return [];
  }

  return await recommendationsService.getRecommendations(
    onboardingData: currentUser.onboardingData!,
    wardrobeItems: wardrobe,
  );
});


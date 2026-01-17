import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/wardrobe_service.dart';
import '../../../core/models/wardrobe_item_model.dart';

final wardrobeServiceProvider = Provider<WardrobeService>((ref) {
  return WardrobeService();
});

/// Wardrobe items provider
/// Automatically refreshes when invalidated or refreshed
final wardrobeItemsProvider = FutureProvider<List<WardrobeItemModel>>((ref) async {
  final service = ref.read(wardrobeServiceProvider);
  return await service.getUserWardrobe();
});


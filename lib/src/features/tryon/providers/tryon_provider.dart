import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/tryon_service.dart';
import '../../../core/models/outfit_model.dart';

final tryOnServiceProvider = Provider<TryOnService>((ref) {
  return TryOnService();
});

final savedOutfitsProvider = FutureProvider<List<OutfitModel>>((ref) async {
  final service = ref.read(tryOnServiceProvider);
  return await service.getUserOutfits();
});


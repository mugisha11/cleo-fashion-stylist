/// Production VTON State Provider
/// Manages state for the 7-stage production virtual try-on pipeline
library;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/production_vton_state.dart';
import '../services/production_vton_service.dart';

class ProductionVTONNotifier extends StateNotifier<ProductionVTONState> {
  final ProductionVTONService _service;

  ProductionVTONNotifier(this._service) : super(const ProductionVTONState());

  /// Execute try-on
  Future<void> executeTryOn({
    required String userImageUrl,
    required List<String> garmentImageUrls,
    String? userImageBase64,
    List<String>? garmentImageBase64s,
  }) async {
    try {
      // Reset state
      state = const ProductionVTONState(stage: ProductionVTONStage.stage0_validation);

      // Call backend
      final result = await _service.executeTryOn(
        userImageUrl: userImageUrl,
        garmentImageUrls: garmentImageUrls,
        userImageBase64: userImageBase64,
        garmentImageBase64s: garmentImageBase64s,
      );

      // Update state based on result
      final status = result['status'] as String;
      final backendStage = result['stage'] as String?;

      if (status == 'success') {
        // Backend returns result_image_url (data URL) or image (base64)
        final String? resultUrl = result['result_image_url'] as String? ??
            (result['image'] != null ? 'data:image/jpeg;base64,${result['image']}' : null);
        state = ProductionVTONState(
          stage: ProductionVTONStage.success,
          resultImageUrl: resultUrl,
          metadata: result['metadata'] as Map<String, dynamic>?,
          qualityMetrics: result['quality_metrics'] as Map<String, dynamic>?,
        );
      } else if (status == 'rejected') {
        state = ProductionVTONState(
          stage: ProductionVTONStage.rejected,
          error: result['error'] as String?,
          errorStage: backendStage,
        );
      } else {
        state = ProductionVTONState(
          stage: ProductionVTONStage.failed,
          error: result['error'] as String?,
          errorStage: backendStage,
        );
      }
    } catch (e) {
      print('[ProductionVTON] executeTryOn error: $e');
      // Provide user-friendly error messages
      String errorMessage = e.toString();
      
      if (errorMessage.contains('Failed to connect') || 
          errorMessage.contains('Failed to fetch') ||
          errorMessage.contains('NetworkError')) {
        errorMessage = 'Cannot connect to backend server. Please ensure the backend is running on localhost:8001 or configure the correct URL in settings.';
      } else if (errorMessage.contains('timeout')) {
        errorMessage = 'Request timed out. The backend may be processing or unavailable.';
      }
      
      state = ProductionVTONState(
        stage: ProductionVTONStage.failed,
        error: errorMessage,
      );
    }
  }

  /// Reset state
  void reset() {
    state = const ProductionVTONState();
  }

  /// Update stage (for real-time updates if backend supports streaming)
  void updateStage(ProductionVTONStage stage) {
    state = state.copyWith(stage: stage);
  }
}

final productionVTONServiceProvider = Provider<ProductionVTONService>((ref) {
  return ProductionVTONService();
});

final productionVTONProvider = StateNotifierProvider<ProductionVTONNotifier, ProductionVTONState>((ref) {
  final service = ref.read(productionVTONServiceProvider);
  return ProductionVTONNotifier(service);
});

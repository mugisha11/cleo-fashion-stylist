import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tryon_state.dart';
import '../services/sora_vton_service.dart';

/// Sora VTON Service Provider
final soraVTONServiceProvider = Provider<SoraVTONService>((ref) {
  return SoraVTONService();
});

/// Try-On State with Result
class TryOnStateWithResult {
  final TryOnState state;
  final TryOnResult? result;

  TryOnStateWithResult(this.state, this.result);
}

/// Try-On State Notifier
class TryOnStateNotifier extends StateNotifier<TryOnStateWithResult> {
  final SoraVTONService _service;

  TryOnStateNotifier(this._service) : super(TryOnStateWithResult(TryOnState.idle, null));

  /// Reset state to idle
  void reset() {
    state = TryOnStateWithResult(TryOnState.idle, null);
  }

  /// Execute try-on with state transitions:
  /// idle → uploading → reasoning → diffusing → success/failed
  Future<void> executeTryOn({
    required String userImageUrl,
    required String clothingImageUrl,
  }) async {
    try {
      // Uploading state
      state = TryOnStateWithResult(TryOnState.uploading, null);
      
      // Start try-on (backend handles reasoning and diffusion)
      // For UI purposes, we transition through states
      state = TryOnStateWithResult(TryOnState.reasoning, null);
      
      // Execute the try-on
      final result = await _service.executeTryOn(
        userImageUrl: userImageUrl,
        clothingImageUrl: clothingImageUrl,
      );

      // Transition to diffusing (backend is processing)
      state = TryOnStateWithResult(TryOnState.diffusing, result);

      // Final state
      if (result.isSuccess) {
        state = TryOnStateWithResult(TryOnState.success, result);
      } else {
        state = TryOnStateWithResult(TryOnState.failed, result);
      }
    } catch (e) {
      final errorResult = TryOnResult(
        errorStage: 'unknown',
        errorReason: 'exception',
        errorMessage: 'Unexpected error: $e',
      );
      state = TryOnStateWithResult(TryOnState.failed, errorResult);
    }
  }
}

/// Try-On State Provider
final tryOnStateProvider = StateNotifierProvider<TryOnStateNotifier, TryOnStateWithResult>((ref) {
  final service = ref.read(soraVTONServiceProvider);
  return TryOnStateNotifier(service);
});

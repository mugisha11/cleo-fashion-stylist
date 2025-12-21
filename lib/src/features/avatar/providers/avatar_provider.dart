import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/avatar_service.dart';

final avatarServiceProvider = Provider<AvatarService>((ref) {
  return AvatarService();
});

final avatarGenerationProvider = StateNotifierProvider<AvatarGenerationNotifier, AvatarGenerationState>((ref) {
  return AvatarGenerationNotifier(ref.read(avatarServiceProvider));
});

class AvatarGenerationNotifier extends StateNotifier<AvatarGenerationState> {
  final AvatarService _avatarService;

  AvatarGenerationNotifier(this._avatarService) : super(AvatarGenerationState.initial());

  Future<void> generateAvatar(dynamic imageFile) async {
    // Accept both File (mobile) and Uint8List (web)
    state = AvatarGenerationState.loading();
    
    try {
      final result = await _avatarService.generateAvatar(imageFile);
      
      if (result.isSuccess) {
        state = AvatarGenerationState.success(
          modelUrl: result.modelUrl,
          previewUrl: result.previewUrl ?? '',
          isFallback: result.isFallback,
        );
      } else {
        state = AvatarGenerationState.error(result.errorMessage ?? 'Failed to generate avatar');
      }
    } catch (e) {
      state = AvatarGenerationState.error(e.toString());
    }
  }

  void reset() {
    state = AvatarGenerationState.initial();
  }
}

class AvatarGenerationState {
  final bool isLoading;
  final String? modelUrl;
  final String? previewUrl;
  final bool isFallback;
  final String? error;

  AvatarGenerationState({
    required this.isLoading,
    this.modelUrl,
    this.previewUrl,
    this.isFallback = false,
    this.error,
  });

  factory AvatarGenerationState.initial() {
    return AvatarGenerationState(isLoading: false);
  }

  factory AvatarGenerationState.loading() {
    return AvatarGenerationState(isLoading: true);
  }

  factory AvatarGenerationState.success({
    required String? modelUrl,
    required String previewUrl,
    bool isFallback = false,
  }) {
    return AvatarGenerationState(
      isLoading: false,
      modelUrl: modelUrl,
      previewUrl: previewUrl,
      isFallback: isFallback,
    );
  }

  factory AvatarGenerationState.error(String error) {
    return AvatarGenerationState(
      isLoading: false,
      error: error,
    );
  }
}


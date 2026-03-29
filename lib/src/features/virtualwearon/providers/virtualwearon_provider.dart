import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ready_player_me_service.dart';
import '../services/mediapipe_service.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../../core/services/wardrobe_service.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';

/// Ready Player Me service provider
final readyPlayerMeServiceProvider = Provider<ReadyPlayerMeService>((ref) {
  return ReadyPlayerMeService();
});

/// MediaPipe service provider
final mediaPipeServiceProvider = Provider<MediaPipeService>((ref) {
  return MediaPipeService();
});

/// VirtualWearOn state notifier
final virtualWearOnProvider = StateNotifierProvider<VirtualWearOnNotifier, VirtualWearOnState>((ref) {
  return VirtualWearOnNotifier(
    ref.read(readyPlayerMeServiceProvider),
    ref.read(mediaPipeServiceProvider),
    ref.read(wardrobeServiceProvider),
  );
});

class VirtualWearOnNotifier extends StateNotifier<VirtualWearOnState> {
  void _log(String location, String message,
      {Map<String, dynamic>? data,
      String runId = 'run1',
      String hypothesisId = 'H3'}) {
    final payload = jsonEncode({
      'location': location,
      'message': message,
      'data': data ?? {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'sessionId': 'debug-session',
      'runId': runId,
      'hypothesisId': hypothesisId,
    });
    if (kIsWeb) {
      // ignore: avoid_print
      print(payload);
    } else {
      debugPrint(payload);
    }
  }

  final ReadyPlayerMeService _avatarService;
  final MediaPipeService _mediaPipeService;
  final WardrobeService _wardrobeService;

  VirtualWearOnNotifier(
    this._avatarService,
    this._mediaPipeService,
    this._wardrobeService,
  ) : super(VirtualWearOnState.initial());

  /// Generate avatar from selfie and measurements
  Future<void> generateAvatar({
    required dynamic selfieFile, // io.File? on mobile, Uint8List? on web
    required BodyMeasurements measurements,
  }) async {
    state = state.copyWith(isGenerating: true, error: null);

    try {
      // Try to get cached avatar first
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final cached = await _avatarService.getCachedAvatar(userId);
        if (cached != null && cached.isSuccess) {
          state = state.copyWith(
            isGenerating: false,
            avatarUrl: cached.avatarUrl,
            modelUrl: cached.modelUrl,
            previewUrl: cached.previewUrl,
            isFromAPI: cached.isFromAPI,
          );
          return;
        }
      }

      // Generate new avatar
      final result = await _avatarService.generateAvatar(
        selfieFile: selfieFile,
        measurements: measurements,
      );

      if (result.isSuccess) {
        state = state.copyWith(
          isGenerating: false,
          avatarUrl: result.avatarUrl,
          modelUrl: result.modelUrl,
          previewUrl: result.previewUrl,
          isFromAPI: result.isFromAPI,
        );
      } else {
        state = state.copyWith(
          isGenerating: false,
          error: result.errorMessage ?? 'Failed to generate avatar',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: e.toString(),
      );
    }
  }

  /// Load user wardrobe
  Future<void> loadWardrobe() async {
    _log('virtualwearon_provider.dart:92',
        'loadWardrobe called, about to modify state',
        hypothesisId: 'H3');
    state = state.copyWith(isLoadingWardrobe: true);
    _log('virtualwearon_provider.dart:93', 'state modified (isLoadingWardrobe=true)',
        hypothesisId: 'H3');

    try {
      final items = await _wardrobeService.getUserWardrobe();
      state = state.copyWith(
        isLoadingWardrobe: false,
        wardrobeItems: items,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingWardrobe: false,
        error: 'Failed to load wardrobe: $e',
      );
    }
  }

  /// Apply wardrobe item to avatar
  void applyWardrobeItem(WardrobeItemModel item) {
    final currentItems = List<String>.from(state.appliedItems);
    
    // Remove items of the same category
    final categoryItems = state.wardrobeItems
        .where((i) => i.category.toLowerCase() == item.category.toLowerCase())
        .map((i) => i.id)
        .toList();
    
    currentItems.removeWhere((id) => categoryItems.contains(id));
    
    // Add new item
    if (!currentItems.contains(item.id)) {
      currentItems.add(item.id);
    }

    state = state.copyWith(appliedItems: currentItems);
  }

  /// Remove wardrobe item
  void removeWardrobeItem(String itemId) {
    final currentItems = List<String>.from(state.appliedItems);
    currentItems.remove(itemId);
    state = state.copyWith(appliedItems: currentItems);
  }

  /// Update 3D view controls
  void updateRotation(double rotationX, double rotationY) {
    state = state.copyWith(
      rotationX: rotationX,
      rotationY: rotationY,
    );
  }

  void updateZoom(double zoom) {
    state = state.copyWith(zoom: zoom.clamp(0.5, 2.0));
  }

  void updateLighting(double intensity) {
    state = state.copyWith(lightingIntensity: intensity.clamp(0.0, 1.0));
  }

  void resetView() {
    state = state.copyWith(
      rotationX: 0.0,
      rotationY: 0.0,
      zoom: 1.0,
      lightingIntensity: 0.7,
    );
  }
}

/// VirtualWearOn state
class VirtualWearOnState {
  final bool isGenerating;
  final bool isLoadingWardrobe;
  final String? avatarUrl;
  final String? modelUrl;
  final String? previewUrl; // Preview/thumbnail image URL
  final bool isFromAPI;
  final String? error;
  final List<WardrobeItemModel> wardrobeItems;
  final List<String> appliedItems; // Item IDs currently applied
  final double rotationX;
  final double rotationY;
  final double zoom;
  final double lightingIntensity;

  VirtualWearOnState({
    required this.isGenerating,
    required this.isLoadingWardrobe,
    this.avatarUrl,
    this.modelUrl,
    this.previewUrl,
    this.isFromAPI = false,
    this.error,
    required this.wardrobeItems,
    required this.appliedItems,
    this.rotationX = 0.0,
    this.rotationY = 0.0,
    this.zoom = 1.0,
    this.lightingIntensity = 0.7,
  });

  factory VirtualWearOnState.initial() {
    return VirtualWearOnState(
      isGenerating: false,
      isLoadingWardrobe: false,
      wardrobeItems: [],
      appliedItems: [],
    );
  }

  VirtualWearOnState copyWith({
    bool? isGenerating,
    bool? isLoadingWardrobe,
    String? avatarUrl,
    String? modelUrl,
    String? previewUrl,
    bool? isFromAPI,
    String? error,
    List<WardrobeItemModel>? wardrobeItems,
    List<String>? appliedItems,
    double? rotationX,
    double? rotationY,
    double? zoom,
    double? lightingIntensity,
  }) {
    return VirtualWearOnState(
      isGenerating: isGenerating ?? this.isGenerating,
      isLoadingWardrobe: isLoadingWardrobe ?? this.isLoadingWardrobe,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      modelUrl: modelUrl ?? this.modelUrl,
      previewUrl: previewUrl ?? this.previewUrl,
      isFromAPI: isFromAPI ?? this.isFromAPI,
      error: error ?? this.error,
      wardrobeItems: wardrobeItems ?? this.wardrobeItems,
      appliedItems: appliedItems ?? this.appliedItems,
      rotationX: rotationX ?? this.rotationX,
      rotationY: rotationY ?? this.rotationY,
      zoom: zoom ?? this.zoom,
      lightingIntensity: lightingIntensity ?? this.lightingIntensity,
    );
  }
}


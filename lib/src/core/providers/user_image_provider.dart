import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;

/// State for user try-on image
class UserImageState {
  final String? base64Image; // Full Base64 string: "data:image/png;base64,..."
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const UserImageState({
    this.base64Image,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  UserImageState copyWith({
    String? base64Image,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return UserImageState(
      base64Image: base64Image ?? this.base64Image,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Notifier for managing user try-on image with local persistence
class UserImageNotifier extends StateNotifier<UserImageState> {
  final SupabaseClient _supabase;
  final FirebaseAuth _auth;
  static const String _imageLocalKey = 'user_tryon_image_base64';
  static const String _imageTimestampKey = 'user_tryon_image_timestamp';

  UserImageNotifier(this._supabase, this._auth)
      : super(const UserImageState()) {
    _initializeImage();
  }

  String get _userId => _auth.currentUser?.uid ?? '';

  /// Initialize: Load from local storage first, then sync with Supabase
  Future<void> _initializeImage() async {
    try {
      // Load from local cache first (faster)
      await _loadFromLocalStorage();

      // Then sync with Supabase if userId is available
      if (_userId.isNotEmpty) {
        await _syncWithSupabase();
      }
    } catch (e) {
      debugPrint('❌ Error initializing user image: $e');
    }
  }

  /// Load user image from local storage (shared_preferences)
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedImage = prefs.getString(_imageLocalKey);

      if (cachedImage != null) {
        state = state.copyWith(
          base64Image: cachedImage,
          lastUpdated: DateTime.fromMillisecondsSinceEpoch(
            prefs.getInt(_imageTimestampKey) ?? 0,
          ),
        );
        debugPrint('✅ User image loaded from local storage');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading from local storage: $e');
    }
  }

  /// Sync image with Supabase (updates if newer version exists online)
  Future<void> _syncWithSupabase() async {
    if (_userId.isEmpty) return;

    try {
      final response = await _supabase
          .from('user_preferences')
          .select('preferences, updated_at')
          .eq('user_id', _userId)
          .maybeSingle();

      if (response != null) {
        final prefs = response['preferences'] as Map<String, dynamic>?;
        final base64Image = prefs?['tryon_base64_image'] as String?;
        final updatedAt = response['updated_at'] as String?;

        if (base64Image != null && base64Image != state.base64Image) {
          state = state.copyWith(
            base64Image: base64Image,
            lastUpdated:
                updatedAt != null ? DateTime.parse(updatedAt) : DateTime.now(),
          );

          // Update local cache
          await _saveToLocalStorage(base64Image);
          debugPrint('✅ User image synced from Supabase');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error syncing with Supabase: $e');
      // Don't show error if local image exists
      if (state.base64Image == null) {
        state = state.copyWith(error: 'Failed to sync image');
      }
    }
  }

  /// Save image to local storage
  Future<void> _saveToLocalStorage(String base64Image) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_imageLocalKey, base64Image);
      await prefs.setInt(
          _imageTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('⚠️ Error saving to local storage: $e');
    }
  }

  /// Load user image from database
  Future<void> _loadUserImage() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _supabase
          .from('user_preferences')
          .select('preferences')
          .eq('user_id', _userId)
          .maybeSingle();

      if (response != null) {
        final prefs = response['preferences'] as Map<String, dynamic>?;
        final base64Image = prefs?['tryon_base64_image'] as String?;

        state = state.copyWith(
          base64Image: base64Image,
          isLoading: false,
          lastUpdated: DateTime.now(),
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load user image: $e',
      );
    }
  }

  /// Upload and save user image at original quality to Supabase + local storage.
  /// Dimensions and quality are preserved for try-on and AI chat.
  /// Input: imageBytes (raw image data), mimeType (e.g., 'image/jpeg')
  /// Output: Full Base64 string with data URI prefix
  Future<bool> uploadUserImage(Uint8List imageBytes, String mimeType) async {
    if (_userId.isEmpty) {
      state = state.copyWith(error: 'User not authenticated');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      // Keep original quality and dimensions (no resize/compress)
      debugPrint('📦 Saving user image at original quality: ${imageBytes.length} bytes');

      // Convert to Base64 with data URI prefix
      final base64String = base64Encode(imageBytes);
      final dataUri = 'data:$mimeType;base64,$base64String';

      // Get current preferences
      final response = await _supabase
          .from('user_preferences')
          .select('preferences')
          .eq('user_id', _userId)
          .maybeSingle();

      final currentPrefs =
          (response?['preferences'] as Map<String, dynamic>?) ?? {};

      // Update with new image
      final updatedPrefs = {
        ...currentPrefs,
        'tryon_base64_image': dataUri,
      };

      // Save to Supabase
      await _supabase.from('user_preferences').upsert({
        'user_id': _userId,
        'preferences': updatedPrefs,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      // Save to local storage immediately
      await _saveToLocalStorage(dataUri);

      state = state.copyWith(
        base64Image: dataUri,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      debugPrint('✅ User image uploaded and cached successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to upload image: $e',
      );
      return false;
    }
  }

  /// Delete user image from Supabase and local storage
  Future<bool> deleteUserImage() async {
    if (_userId.isEmpty) {
      state = state.copyWith(error: 'User not authenticated');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      // Get current preferences
      final response = await _supabase
          .from('user_preferences')
          .select('preferences')
          .eq('user_id', _userId)
          .maybeSingle();

      final currentPrefs =
          (response?['preferences'] as Map<String, dynamic>?) ?? {};

      // Remove image from preferences
      final updatedPrefs = {...currentPrefs};
      updatedPrefs.remove('tryon_base64_image');

      // Update Supabase
      await _supabase.from('user_preferences').upsert({
        'user_id': _userId,
        'preferences': updatedPrefs,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      // Remove from local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_imageLocalKey);
      await prefs.remove(_imageTimestampKey);

      state = state.copyWith(
        base64Image: null,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      debugPrint('✅ User image deleted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting image: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete image: $e',
      );
      return false;
    }
  }

  /// Optional: encode to JPEG at high quality only when needed (e.g. PNG input).
  /// Prefer keeping original bytes for full quality; this is unused by default.
  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      final img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return imageBytes;
      // Preserve dimensions; encode at high quality (95) only for size cap
      final encoded = img.encodeJpg(image, quality: 95);
      return Uint8List.fromList(encoded);
    } catch (e) {
      debugPrint('⚠️ Encode failed, using original: $e');
      return imageBytes;
    }
  }

  /// Refresh user image from database
  Future<void> refreshImage() async {
    await _loadUserImage();
  }
}

/// Provider for user image state
final userImageProvider =
    StateNotifierProvider<UserImageNotifier, UserImageState>((ref) {
  final supabase = Supabase.instance.client;
  final auth = FirebaseAuth.instance;
  return UserImageNotifier(supabase, auth);
});

/// Helper provider to get decoded image bytes from Base64
final userImageBytesProvider = FutureProvider<Uint8List?>((ref) async {
  final userImage = ref.watch(userImageProvider);

  if (userImage.base64Image == null) return null;

  try {
    // Remove data URI prefix if present
    String base64String = userImage.base64Image!;
    if (base64String.contains(',')) {
      base64String = base64String.split(',').last;
    }

    return base64Decode(base64String);
  } catch (e) {
    return null;
  }
});

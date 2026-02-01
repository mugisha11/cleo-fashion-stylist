// Stub for web: no file write; caller should use base64 data URL for imagePath.
import 'dart:typed_data';

/// Saves post image bytes to local storage.
/// Returns null on web (use data URL in post instead).
Future<String?> savePostImage(Uint8List bytes, String postId) async => null;

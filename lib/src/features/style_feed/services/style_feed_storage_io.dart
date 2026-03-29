// Mobile/desktop: save post image to app documents directory.
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

const String _subdir = 'style_feed_images';

/// Saves [bytes] (e.g. JPEG) to app documents directory under [_subdir].
/// Returns the file path, or null on failure.
Future<String?> savePostImage(Uint8List bytes, String postId) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final sub = Directory('${dir.path}/$_subdir');
    if (!await sub.exists()) await sub.create(recursive: true);
    const ext = 'jpg';
    final path = '${sub.path}/$postId.$ext';
    final file = File(path);
    await file.writeAsBytes(bytes);
    return path;
  } catch (_) {
    return null;
  }
}

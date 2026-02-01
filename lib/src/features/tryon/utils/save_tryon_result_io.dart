// VM / mobile / desktop: save try-on result to app documents directory.
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Saves [bytes] (JPEG) to app documents directory.
/// Returns the file path on success, or null on failure.
Future<String?> saveTryOnResultToDevice(Uint8List bytes) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final name = 'cleo-tryon-${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    return file.path;
  } catch (_) {
    return null;
  }
}

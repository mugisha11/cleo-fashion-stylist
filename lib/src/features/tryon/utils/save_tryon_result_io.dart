// VM / mobile / desktop: save try-on result to device gallery (and app documents as fallback).
import 'dart:io';
import 'dart:typed_data';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// Saves [bytes] (JPEG) to device storage:
/// - On Android/iOS: saves to the device photo gallery (Photos app) so the user can see it.
/// - Also writes to app documents directory as fallback.
/// Returns a non-null path string on success (documents path; gallery path not exposed by gal), or null on failure.
Future<String?> saveTryOnResultToDevice(Uint8List bytes) async {
  final name = 'nikonyx-tryon-${DateTime.now().millisecondsSinceEpoch}.jpg';
  String? savedPath;

  // 1) Try to save to device gallery (Photos app) on mobile
  try {
    await Gal.putImageBytes(bytes, name: name);
  } catch (_) {}

  // 2) Always save to app documents directory (guaranteed save + fallback if gallery failed)
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    savedPath = file.path;
  } catch (_) {}

  return savedPath;
}

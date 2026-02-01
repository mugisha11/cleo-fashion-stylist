// Web: trigger browser download of try-on result image.
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Triggers download of [bytes] as a JPEG file in the browser.
/// Returns a short message on success, or null on failure.
Future<String?> saveTryOnResultToDevice(Uint8List bytes) async {
  try {
    final blob = html.Blob([bytes], 'image/jpeg');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement()
      ..href = url
      ..download = 'cleo-tryon-${DateTime.now().millisecondsSinceEpoch}.jpg'
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    return 'Download started';
  } catch (_) {
    return null;
  }
}

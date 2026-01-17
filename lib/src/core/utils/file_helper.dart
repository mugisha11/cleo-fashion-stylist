import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import - uses native implementation on mobile/desktop, stub on web
import 'file_helper_stub.dart' if (dart.library.io) 'file_helper_native.dart' as file_helper;

/// Helper to create a File object that works on both web and mobile
/// On web, returns null (use bytes instead)
/// On mobile, returns dart:io.File
dynamic createPlatformFile(String path) {
  if (kIsWeb) {
    return null; // File not supported on web
  }
  return file_helper.createPlatformFile(path);
}

import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import - uses native implementation on mobile/desktop, stub on web
import 'platform_helper_stub.dart' if (dart.library.io) 'platform_helper_native.dart' as platform;

bool get isApplePlatform {
  if (kIsWeb) return false;
  return platform.isApplePlatform;
}

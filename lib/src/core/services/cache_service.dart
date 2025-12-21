import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String wardrobeBoxName = 'wardrobe';
  static const String avatarBoxName = 'avatar';
  static const String tryOnBoxName = 'tryon';
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (kIsWeb) {
      // Hive doesn't work on web - use in-memory cache or skip
      _initialized = true;
      return;
    }
    
    try {
      await Hive.openBox(wardrobeBoxName);
      await Hive.openBox(avatarBoxName);
      await Hive.openBox(tryOnBoxName);
      _initialized = true;
    } catch (e) {
      // If Hive fails, continue without caching
      _initialized = false;
    }
  }

  static Box? get wardrobeBox => kIsWeb || !_initialized ? null : Hive.box(wardrobeBoxName);
  static Box? get avatarBox => kIsWeb || !_initialized ? null : Hive.box(avatarBoxName);
  static Box? get tryOnBox => kIsWeb || !_initialized ? null : Hive.box(tryOnBoxName);

  // Wardrobe caching
  static Future<void> cacheWardrobeItem(String id, Map<String, dynamic> data) async {
    if (kIsWeb || wardrobeBox == null) return;
    await wardrobeBox!.put(id, data);
  }

  static Map<String, dynamic>? getCachedWardrobeItem(String id) {
    if (kIsWeb || wardrobeBox == null) return null;
    return wardrobeBox!.get(id) as Map<String, dynamic>?;
  }

  static Future<void> clearWardrobeCache() async {
    if (kIsWeb || wardrobeBox == null) return;
    await wardrobeBox!.clear();
  }

  // Avatar caching
  static Future<void> cacheAvatarData(String userId, Map<String, dynamic> data) async {
    if (kIsWeb || avatarBox == null) return;
    await avatarBox!.put(userId, data);
  }

  static Map<String, dynamic>? getCachedAvatarData(String userId) {
    if (kIsWeb || avatarBox == null) return null;
    return avatarBox!.get(userId) as Map<String, dynamic>?;
  }

  // Try-on preview caching
  static Future<void> cacheTryOnPreview(String key, String imageUrl) async {
    if (kIsWeb || tryOnBox == null) return;
    await tryOnBox!.put(key, imageUrl);
  }

  static String? getCachedTryOnPreview(String key) {
    if (kIsWeb || tryOnBox == null) return null;
    return tryOnBox!.get(key) as String?;
  }
}


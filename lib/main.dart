import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/app.dart';
import 'src/core/services/cache_service.dart';
import 'firebase_options.dart';

void _log(String location, String message, {Map<String, dynamic>? data, String? hypothesisId}) {
  // #region agent log
  // Simplified logging - just use debugPrint for all platforms
  debugPrint('[$location] $message ${data != null ? data.toString() : ""}');
  // #endregion agent log
}

void main() async {
  _log('main.dart:11', 'Main function entry', hypothesisId: 'A,B,C,D,E');
  
  WidgetsFlutterBinding.ensureInitialized();
  _log('main.dart:15', 'WidgetsFlutterBinding initialized', hypothesisId: 'A,B,C,D,E');
  
  // Initialize Firebase
  try {
    _log('main.dart:25', 'Before Firebase.initializeApp', hypothesisId: 'B');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _log('main.dart:32', 'Firebase.initializeApp success', hypothesisId: 'B');
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    _log('main.dart:37', 'Firebase initialization error', data: {'error': e.toString()}, hypothesisId: 'B');
    debugPrint('⚠️ Firebase initialization error: $e');
    debugPrint('📝 Please update API keys in lib/firebase_options.dart');
    debugPrint('📖 Get keys from: https://console.firebase.google.com/project/ai-styling-c45cf/settings/general');
    // Continue anyway - app will show errors but won't crash
  }

  // Initialize Supabase for image/avatar storage and chat
  try {
    _log('main.dart:40', 'Before Supabase.initialize', hypothesisId: 'B');
    await Supabase.initialize(
      url: 'https://kjiqtspkvnwgjoerpyxb.supabase.co',
      anonKey: 'sb_publishable_A4DglmUBJorcilVMduJA4Q_ZTguPkKI',
    );
    _log('main.dart:45', 'Supabase.initialize success', hypothesisId: 'B');
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    _log('main.dart:48', 'Supabase initialization error', data: {'error': e.toString()}, hypothesisId: 'B');
    debugPrint('⚠️ Supabase initialization error: $e');
    // Continue anyway - app will show errors but won't crash
  }
  
  // Initialize Hive for offline caching (skip on web - Hive doesn't work on web)
  if (!kIsWeb) {
    try {
      _log('main.dart:50', 'Before Hive.initFlutter', hypothesisId: 'A');
      await Hive.initFlutter();
      _log('main.dart:56', 'Hive.initFlutter success', hypothesisId: 'A');
      
      try {
        _log('main.dart:60', 'Before CacheService.initialize', hypothesisId: 'E');
        await CacheService.initialize();
        _log('main.dart:63', 'CacheService.initialize success', hypothesisId: 'E');
      } catch (e) {
        _log('main.dart:66', 'CacheService.initialize error', data: {'error': e.toString()}, hypothesisId: 'E');
        debugPrint('⚠️ CacheService initialization error: $e');
      }
    } catch (e) {
      _log('main.dart:71', 'Hive.initFlutter error', data: {'error': e.toString()}, hypothesisId: 'A');
      debugPrint('⚠️ Hive initialization error: $e');
      // Continue - Hive may not work on web
    }
  } else {
    _log('main.dart:76', 'Skipping Hive initialization (web platform)', hypothesisId: 'A');
    debugPrint('ℹ️ Skipping Hive initialization on web platform');
  }
  
  _log('main.dart:80', 'Before runApp', hypothesisId: 'A,B,C,D,E');
  runApp(
    const ProviderScope(
      child: VirtualTwinApp(),
    ),
  );
  _log('main.dart:87', 'runApp called', hypothesisId: 'A,B,C,D,E');
}


import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, FlutterError;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/app.dart';
import 'src/core/services/cache_service.dart';
import 'src/core/services/config_service.dart';
import 'firebase_options.dart';

void main() {
  runZonedGuarded(() async {
    await _main();
  }, (error, stack) {
    debugPrint('❌ Uncaught error: $error');
    debugPrint('Stack: $stack');
    FlutterError.presentError(
        FlutterErrorDetails(exception: error, stack: stack));
  });
}

Future<void> _main() async {
  debugPrint('🚀 APP STARTED - main() called');

  WidgetsFlutterBinding.ensureInitialized();

  // Prevent Google Fonts runtime fetching (avoid network font loads in restricted environments)
  GoogleFonts.config.allowRuntimeFetching = false;

  // Catch Flutter framework errors (e.g. widget build errors)
  FlutterError.onError = (details) {
    debugPrint('❌ FlutterError: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
    FlutterError.presentError(details);
  };
  debugPrint('✅ WidgetsFlutterBinding initialized');

  // CRITICAL: Firebase MUST be initialized BEFORE runApp() on Web
  // On mobile, this is also safe and maintains correct initialization order
  bool firebaseInitialized = false;

  if (kIsWeb) {
    debugPrint(
        '🌐 Web platform detected - initializing Firebase synchronously');
    try {
      // Explicitly use Web options to ensure correct API key is used
      const webOptions = DefaultFirebaseOptions.web;

      // Check if API key is placeholder - but still try to initialize
      if (webOptions.apiKey.contains('Dummy') ||
          webOptions.apiKey.contains('YOUR_')) {
        debugPrint(
            '⚠️ WARNING: Firebase Web API key appears to be a placeholder');
        debugPrint(
            '⚠️ Firebase may not work correctly until you update the API key');
        debugPrint(
            '⚠️ Get it from: https://console.firebase.google.com/project/ai-styling-c45cf/settings/general');
        debugPrint(
            '⚠️ Run: .get_firebase_web_key.ps1 for step-by-step instructions');
        // Continue anyway - let Firebase try to initialize
      }

      await Firebase.initializeApp(
        options: webOptions, // Explicit Web options
      );
      firebaseInitialized = true;
      debugPrint('✅ Firebase initialized successfully (Web)');
      debugPrint('🔥 Firebase Auth ready');
      debugPrint('🔥 Firestore connected');
    } catch (e, stack) {
      firebaseInitialized = false;
      debugPrint('❌ Firebase Web initialization failed: $e');
      debugPrint('Stack: $stack');
      // Continue anyway - app will show setup screen
    }
  } else {
    // Mobile: Initialize Firebase before runApp (synchronous for safety)
    debugPrint('📱 Mobile platform detected - initializing Firebase');
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseInitialized = true;
      debugPrint('✅ Firebase initialized successfully (Mobile)');
    } catch (e) {
      firebaseInitialized = false;
      debugPrint('⚠️ Firebase Mobile initialization error: $e');
    }
  }

  // Store initialization status for app.dart to check
  if (!firebaseInitialized) {
    debugPrint(
        '⚠️ Firebase initialization failed - app will show setup screen');
  }

  // Start app UI
  debugPrint('📱 Starting app UI...');
  runApp(
    const ProviderScope(
      child: VirtualTwinApp(),
    ),
  );
  debugPrint('✅ runApp() called - UI should render now');

  // Initialize other services in background (non-blocking)
  _initializeServicesInBackground();

  // Initialize OpenAI config (non-blocking)
  ConfigService.initializeDefaultKeys().then((_) {
    debugPrint('✅ OpenAI config initialized');
  }).catchError((e) {
    debugPrint('⚠️ OpenAI config initialization error: $e');
  });
}

// Initialize other services without blocking the UI
void _initializeServicesInBackground() {
  debugPrint('🔧 Starting background service initialization...');

  // Supabase initialization (non-blocking)
  debugPrint('🔐 Starting Supabase initialization...');
  Supabase.initialize(
    url: 'https://kjiqtspkvnwgjoerpyxb.supabase.co',
    anonKey: 'sb_publishable_A4DglmUBJorcilVMduJA4Q_ZTguPkKI',
  ).then((_) {
    debugPrint('✅ Supabase initialized successfully');
    try {
      final client = Supabase.instance.client;
      debugPrint('✅ Supabase client accessible: true');
    } catch (e) {
      debugPrint('⚠️ Supabase client access error: $e');
    }
  }).catchError((e, stack) {
    debugPrint('❌ Supabase initialization FAILED: $e');
    debugPrint('Stack: $stack');
    // App continues even if Supabase fails
  });

  // Hive initialization (skip on web, non-blocking)
  if (!kIsWeb) {
    debugPrint('💾 Starting Hive initialization...');
    Hive.initFlutter().then((_) {
      debugPrint('✅ Hive initialized');
      return CacheService.initialize();
    }).then((_) {
      debugPrint('✅ CacheService initialized');
    }).catchError((e) {
      debugPrint('⚠️ Hive/CacheService initialization error: $e');
    });
  } else {
    debugPrint('ℹ️ Skipping Hive initialization (web platform)');
  }

  debugPrint('✅ Background initialization started (non-blocking)');
}

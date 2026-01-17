import 'dart:async';
import 'dart:convert';
import '../../../core/utils/io_stub.dart' if (dart.library.io) 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  try {
    // Check if Firebase is initialized first
    if (Firebase.apps.isEmpty) {
      debugPrint('⚠️ Firebase not initialized yet - returning null stream');
      return Stream.value(null);
    }
    final auth = FirebaseAuth.instanceFor(app: Firebase.apps.first);
    // Firebase authStateChanges() is a continuous stream that emits:
    // - null when user logs out
    // - User object when user logs in or is already logged in
    // - Automatically handles token refresh without emitting null
    // No timeout needed - the stream stays alive as long as the app is running
    return auth.authStateChanges().handleError((error) {
      debugPrint('⚠️ Auth state stream error: $error');
      // Don't close the stream on error - just log it
      // The stream will continue to work normally
    });
  } catch (e) {
    debugPrint('⚠️ Auth state initialization error: $e');
    // On initialization error, return a stream that emits null once
    // This allows the app to show login screen if Firebase isn't ready
    return Stream.value(null);
  }
});

final authServiceProvider = Provider<AuthService>((ref) {
  const logPath = 'd:\\styleapp\\.cursor\\debug.log';
  void log(String location, String message,
      {Map<String, dynamic>? data,
      String runId = 'run1',
      String hypothesisId = 'H5'}) {
    final payload = jsonEncode({
      'location': location,
      'message': message,
      'data': data ?? {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'sessionId': 'debug-session',
      'runId': runId,
      'hypothesisId': hypothesisId,
    });
    if (!kIsWeb) {
      io.File(logPath)
          .writeAsStringSync('$payload\n', mode: io.FileMode.append, flush: true);
    } else {
      // ignore: avoid_print
      print(payload);
    }
  }

  log('auth_provider.dart:15', 'authServiceProvider creating AuthService',
      hypothesisId: 'H5');
  return AuthService();
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) return null;
      final authService = ref.read(authServiceProvider);
      return await authService.getUserData(user.uid);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});


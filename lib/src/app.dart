import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';

class VirtualTwinApp extends ConsumerWidget {
  const VirtualTwinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if Firebase is initialized
    bool firebaseInitialized = true;
    try {
      FirebaseAuth.instance; // This will throw if Firebase not initialized
    } catch (e) {
      firebaseInitialized = false;
      debugPrint('Firebase not initialized: $e');
    }
    
    if (!firebaseInitialized) {
      // Show setup screen if Firebase not configured
      return MaterialApp(
        title: 'Virtual Twin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: _buildFirebaseSetupScreen(context),
      );
    }
    
    // Watch auth state with error handling
    return ref.watch(authStateProvider).when(
      data: (user) {
        final route = user == null ? Routes.signup : Routes.dashboard;
        debugPrint('User state: ${user != null ? "logged in" : "not logged in"}, route: $route');
        return _buildMaterialApp(route);
      },
      loading: () {
        debugPrint('Auth state loading, showing splash');
        return _buildMaterialApp(Routes.splash);
      },
      error: (error, stack) {
        debugPrint('Auth state error: $error');
        debugPrint('Stack: $stack');
        // Show signup screen on error
        return _buildMaterialApp(Routes.signup);
      },
    );
  }
  
  Widget _buildMaterialApp(String initialRoute) {
    return MaterialApp(
      title: 'Virtual Twin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      onGenerateRoute: Routes.generateRoute,
      builder: (context, child) {
        // Always ensure we have a widget to display
        return MediaQuery(
          data: MediaQuery.of(context),
          child: child ?? const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFirebaseSetupScreen(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Firebase Not Configured',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'To run this app, you need to configure Firebase first.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Setup:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _buildStep(context, '1', 'Login to Firebase:', 'firebase login'),
                      _buildStep(context, '2', 'Configure FlutterFire:', 'flutterfire configure --project=ai-styling-c45cf'),
                      _buildStep(context, '3', 'Enable services in Firebase Console', ''),
                      const SizedBox(height: 16),
                      Text(
                        'See FIREBASE_READY.md for detailed instructions.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String label, String command) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (command.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      command,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations.dart';
import 'routes.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/theme_wrapper.dart';
import 'core/widgets/app_launch_loader.dart';
import 'core/providers/language_provider.dart';
import 'core/localization/language_service.dart';
import 'features/auth/providers/auth_provider.dart';

class VirtualTwinApp extends ConsumerWidget {
  const VirtualTwinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if Firebase is initialized - improved check
    bool firebaseInitialized = false;
    try {
      // Check if any Firebase apps exist
      final apps = Firebase.apps;
      if (apps.isNotEmpty) {
        // Try to access FirebaseAuth
        try {
          FirebaseAuth.instanceFor(app: apps.first);
          firebaseInitialized = true;
          debugPrint('✅ Firebase is initialized and accessible');
        } catch (e) {
          debugPrint('⚠️ Firebase app exists but Auth not accessible: $e');
          // Still consider it initialized if app exists
          firebaseInitialized = true;
        }
      } else {
        debugPrint('⚠️ No Firebase apps found');
      }
    } catch (e) {
      firebaseInitialized = false;
      debugPrint('⚠️ Firebase check failed: $e');
    }

    if (!firebaseInitialized) {
      // Show setup screen if Firebase not configured
      debugPrint('⚠️ Showing Firebase setup screen');
      return MaterialApp(
        title: 'Nikonyx',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.giovanniTheme,
        home: _buildFirebaseSetupScreen(context),
      );
    }

    // Watch auth state with error handling and timeout
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        final route = user == null ? Routes.signup : Routes.dashboard;
        debugPrint(
            '✅ User state: ${user != null ? "logged in" : "not logged in"}, route: $route');
        debugPrint('✅ First frame ready - UI rendering');
        return _buildMaterialApp(route);
      },
      loading: () {
        debugPrint(
            '⏳ Auth state loading, showing signup (app launch loader handles initial loading)');
        // Don't show splash - app launch loader handles initial loading
        // Show signup immediately, auth will redirect if needed
        return _buildMaterialApp(Routes.signup);
      },
      error: (error, stack) {
        debugPrint('⚠️ Auth state error: $error');
        debugPrint('Stack: $stack');
        // Show signup screen on error - don't block
        return _buildMaterialApp(Routes.signup);
      },
    );
  }

  Widget _buildMaterialApp(String initialRoute) {
    return ThemeWrapper(
      child: Builder(
        builder: (context) {
          // Theme is provided by ThemeWrapper, just use it
          return Consumer(
            builder: (context, ref, _) {
              final languageCode = ref.watch(currentLanguageProvider);
              final textDirection =
                  LanguageService.getTextDirection(languageCode);

              return Directionality(
                textDirection: textDirection,
                child: MaterialApp(
                  title: 'Nikonyx',
                  debugShowCheckedModeBanner: false,
                  theme: Theme.of(context),
                  initialRoute: initialRoute,
                  onGenerateRoute: Routes.generateRoute,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: [Locale(languageCode)],
                  locale: Locale(languageCode),
                  builder: (context, child) {
                    // Always ensure we have a widget to display
                    return Stack(
                      children: [
                        MediaQuery(
                          data: MediaQuery.of(context),
                          child: child ??
                              const Scaffold(
                                body: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                        ),
                        const AppLaunchLoader(),
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
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
                'Firebase Not Configured', // firebase_notConfigured
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'To run this app, you need to configure Firebase first.', // firebase_setupMessage
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
                        'Quick Setup:', // firebase_quickSetup
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      _buildStep(
                          context, '1', 'Login to Firebase:', 'firebase login'),
                      _buildStep(context, '2', 'Configure FlutterFire:',
                          'flutterfire configure --project=ai-styling-c45cf'),
                      _buildStep(context, '3',
                          'Enable services in Firebase Console', ''),
                      const SizedBox(height: 16),
                      Text(
                        'See FIREBASE_READY.md for detailed instructions.', // firebase_detailedInstructions
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

  Widget _buildStep(
      BuildContext context, String number, String label, String command) {
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

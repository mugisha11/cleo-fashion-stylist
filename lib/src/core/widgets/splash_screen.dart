import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../routes.dart';
import 'cleo_logo.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    authState.whenData((user) {
      Future.delayed(const Duration(seconds: 2), () {
        final navigator = Navigator.of(context);
        if (!navigator.mounted) return;
        if (user == null) {
          navigator.pushReplacementNamed(Routes.signup);
        } else {
          navigator.pushReplacementNamed(Routes.dashboard);
        }
      });
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            const CleoLogo.large(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOut),
            const SizedBox(height: 24),
            Text(
              'Virtual Twin',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              'AI Fashion Try-On',
              style: Theme.of(context).textTheme.bodyLarge,
            ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}


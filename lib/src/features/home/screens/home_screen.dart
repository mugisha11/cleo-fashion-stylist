import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../routes.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Twin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
            },
          ),
        ],
      ),
      body: currentUser.when(
        data: (userModel) => _buildContent(context, userModel),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, userModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Ready to try on some outfits?',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Quick actions grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildActionCard(
                context,
                icon: Icons.checkroom,
                title: 'My Wardrobe',
                subtitle: 'View your clothes',
                color: Theme.of(context).colorScheme.primary,
                onTap: () {
                  Navigator.of(context).pushNamed(Routes.wardrobe);
                },
              ).animate().fadeIn(duration: 300.ms, delay: 200.ms).scale(
                    duration: 200.ms,
                    begin: const Offset(0.9, 0.9),
                  ),
              _buildActionCard(
                context,
                icon: Icons.person_outline,
                title: 'Virtual Twin',
                subtitle: 'View your avatar',
                color: Theme.of(context).colorScheme.secondary,
                onTap: () {
                  Navigator.of(context).pushNamed(Routes.avatarCreation);
                },
              ).animate().fadeIn(duration: 300.ms, delay: 300.ms).scale(
                    duration: 200.ms,
                    begin: const Offset(0.9, 0.9),
                  ),
              _buildActionCard(
                context,
                icon: Icons.view_in_ar,
                title: 'Virtual Wear-On',
                subtitle: '3D try-on experience',
                color: Theme.of(context).colorScheme.primary,
                onTap: () {
                  Navigator.of(context).pushNamed(Routes.virtualwearon);
                },
              ).animate().fadeIn(duration: 300.ms, delay: 400.ms).scale(
                    duration: 200.ms,
                    begin: const Offset(0.9, 0.9),
                  ),
              _buildActionCard(
                context,
                icon: Icons.try_sms_star,
                title: 'Try On',
                subtitle: 'Virtual try-on',
                color: Theme.of(context).colorScheme.primary,
                onTap: () {
                  Navigator.of(context).pushNamed(Routes.mobileVton);
                },
              ).animate().fadeIn(duration: 300.ms, delay: 400.ms).scale(
                    duration: 200.ms,
                    begin: const Offset(0.9, 0.9),
                  ),
              _buildActionCard(
                context,
                icon: Icons.lightbulb_outline,
                title: 'AI Recommendations',
                subtitle: 'Get outfit ideas',
                color: Theme.of(context).colorScheme.secondary,
                onTap: () {
                  Navigator.of(context).pushNamed(Routes.recommendations);
                },
              ).animate().fadeIn(duration: 300.ms, delay: 500.ms).scale(
                    duration: 200.ms,
                    begin: const Offset(0.9, 0.9),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


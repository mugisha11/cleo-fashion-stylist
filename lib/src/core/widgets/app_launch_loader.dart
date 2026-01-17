import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'cleo_logo.dart';

/// App Launch Loader
/// 
/// World-class loading experience that appears only at app cold start.
/// Shows logo with subtle breathing animation, theme-aware, auto-dismisses on first frame.
class AppLaunchLoader extends StatefulWidget {
  const AppLaunchLoader({super.key});

  @override
  State<AppLaunchLoader> createState() => _AppLaunchLoaderState();
}

class _AppLaunchLoaderState extends State<AppLaunchLoader>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _fadeController;
  bool _isDismissing = false;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    
    // Breathing animation controller
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Fade out controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Start breathing animation immediately
    _breathingController.repeat(reverse: true);

    // Auto-dismiss after first frame is painted and app is ready
    // Wait for first frame, then ensure minimum display time (800ms) for premium feel
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Wait for first frame + minimum display time
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !_isDismissing && !_isDismissed) {
          _dismissLoader();
        }
      });
    });
  }

  void _dismissLoader() {
    if (_isDismissing || _isDismissed || !mounted) return;
    _isDismissing = true;

    // Stop breathing and fade out
    _breathingController.stop();
    _fadeController.forward().then((_) {
      if (mounted) {
        setState(() {
          _isDismissed = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
      ),
      child: AnimatedBuilder(
        animation: _breathingController,
        builder: (context, child) {
          // Breathing animation: scale 0.96 → 1.0, opacity 0.85 → 1.0
          final scale = 0.96 + (_breathingController.value * 0.04);
          final opacity = 0.85 + (_breathingController.value * 0.15);

          return Container(
            color: theme.scaffoldBackgroundColor,
            child: Center(
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: const CleoLogo.large(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

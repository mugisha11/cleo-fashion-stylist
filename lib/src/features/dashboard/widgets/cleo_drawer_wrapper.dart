import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'grok_drawer.dart';
import '../../../core/theme/grok_design_system.dart';
import '../../auth/providers/auth_provider.dart';

/// Wrapper widget that provides drawer functionality to any screen
/// Automatically detects mobile vs desktop and shows drawer only on mobile
class CleoDrawerWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final String activeRoute;
  final ValueChanged<String> onNavigate;
  final PreferredSizeWidget? appBar;

  const CleoDrawerWrapper({
    super.key,
    required this.child,
    required this.activeRoute,
    required this.onNavigate,
    this.appBar,
  });

  @override
  ConsumerState<CleoDrawerWrapper> createState() => _CleoDrawerWrapperState();
}

class _CleoDrawerWrapperState extends ConsumerState<CleoDrawerWrapper>
    with SingleTickerProviderStateMixin {
  bool _isDrawerOpen = false;
  late AnimationController _drawerController;
  late Animation<double> _drawerAnimation;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: GrokDesignSystem.animationMedium,
    );
    _drawerAnimation = CurvedAnimation(
      parent: _drawerController,
      curve: GrokDesignSystem.defaultCurve,
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  void _openDrawer() {
    setState(() => _isDrawerOpen = true);
    _drawerController.forward();
  }

  void _closeDrawer() {
    _drawerController.reverse().then((_) {
      if (mounted) {
        setState(() => _isDrawerOpen = false);
      }
    });
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 900;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: widget.appBar ??
          (isMobile
              ? AppBar(
                  elevation: 0,
                  backgroundColor: GrokDesignSystem.backgroundWhite,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.menu,
                      color: GrokDesignSystem.textPrimary,
                      size: GrokDesignSystem.iconSize,
                    ),
                    onPressed: _openDrawer,
                  ),
                  title: Text(
                    'StyleApp',
                    style: GrokDesignSystem.headlineSmall(),
                  ),
                  centerTitle: false,
                )
              : null),
      body: Stack(
        children: [
          widget.child,
          if (_isDrawerOpen && isMobile)
            FadeTransition(
              opacity: _drawerAnimation,
              child: GrokDrawer(
                activeRoute: widget.activeRoute,
                onNavigate: widget.onNavigate,
                onClose: _closeDrawer,
                currentUser: currentUser,
              ),
            ),
        ],
      ),
    );
  }
}


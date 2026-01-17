/// Minimal Intelligent Sidebar
/// Ultra-thin, expands on hover, ChatGPT-level minimalism
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/executive_blue_theme.dart';
import '../../../routes.dart';

final sidebarExpandedProvider = StateProvider<bool>((ref) => false);

class MinimalSidebar extends ConsumerStatefulWidget {
  final String? currentRoute;
  final VoidCallback? onNavigate;

  const MinimalSidebar({
    super.key,
    this.currentRoute,
    this.onNavigate,
  });

  @override
  ConsumerState<MinimalSidebar> createState() => _MinimalSidebarState();
}

class _MinimalSidebarState extends ConsumerState<MinimalSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _widthAnimation;

  static const double _collapsedWidth = 64.0;
  static const double _expandedWidth = 240.0;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: ExecutiveBlueTheme.animationMedium,
    );
    _widthAnimation = Tween<double>(
      begin: _collapsedWidth,
      end: _expandedWidth,
    ).animate(
      CurvedAnimation(
        parent: _expandController,
        curve: ExecutiveBlueTheme.smoothCurve,
      ),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _handleHover(bool hover) {
    if (hover) {
      _expandController.forward();
    } else {
      final isManuallyExpanded = ref.read(sidebarExpandedProvider);
      if (!isManuallyExpanded) {
        _expandController.reverse();
      }
    }
  }

  void _handleTap(String route) {
    HapticFeedback.lightImpact();
    if (widget.onNavigate != null) {
      widget.onNavigate!();
    } else {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: AnimatedBuilder(
        animation: _widthAnimation,
        builder: (context, child) {
          return Container(
            width: _widthAnimation.value,
            decoration: BoxDecoration(
              color: ExecutiveBlueTheme.backgroundPrimary,
              border: Border(
                right: BorderSide(
                  color: ExecutiveBlueTheme.borderLight,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: ExecutiveBlueTheme.spacingLG),
                _buildNavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Dashboard',
                  route: Routes.dashboard,
                ),
                _buildNavItem(
                  icon: Icons.checkroom_outlined,
                  activeIcon: Icons.checkroom,
                  label: 'Wardrobe',
                  route: Routes.wardrobe,
                ),
                _buildNavItem(
                  icon: Icons.auto_awesome_outlined,
                  activeIcon: Icons.auto_awesome,
                  label: 'Try-On',
                  route: Routes.tryon,
                ),
                _buildNavItem(
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today,
                  label: 'Calendar',
                  route: Routes.calendar,
                ),
                _buildNavItem(
                  icon: Icons.notifications_outlined,
                  activeIcon: Icons.notifications,
                  label: 'Notifications',
                  route: Routes.dashboard,
                ),
                const Spacer(),
                _buildNavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                  route: Routes.settings,
                ),
                const SizedBox(height: ExecutiveBlueTheme.spacingLG),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
  }) {
    final isActive = widget.currentRoute == route;
    final isExpanded = _widthAnimation.value > _collapsedWidth + 20;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(route),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: ExecutiveBlueTheme.spacingSM,
            vertical: ExecutiveBlueTheme.spacingXS,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: ExecutiveBlueTheme.spacingMD,
            vertical: ExecutiveBlueTheme.spacingMD,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? ExecutiveBlueTheme.primaryBlue.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 20,
                color: isActive
                    ? ExecutiveBlueTheme.primaryBlue
                    : ExecutiveBlueTheme.textSecondary,
              ),
              if (isExpanded) ...[
                const SizedBox(width: ExecutiveBlueTheme.spacingMD),
                Expanded(
                  child: Text(
                    label,
                    style: ExecutiveBlueTheme.bodyMedium(
                      color: isActive
                          ? ExecutiveBlueTheme.primaryBlue
                          : ExecutiveBlueTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

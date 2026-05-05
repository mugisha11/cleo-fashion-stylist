/// Intelligent Sidebar
/// Tiny, elegant, minimal navigation - "Less UI, more intelligence"
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_wrapper.dart';
import 'nikonyx_logo.dart';
import '../../routes.dart';
import '../../features/dashboard/widgets/notification_panel.dart';
import '../../features/dashboard/providers/notification_provider.dart';

/// Sidebar state provider
final sidebarExpandedProvider = StateProvider<bool>((ref) => false);
final sidebarHoveredProvider = StateProvider<bool>((ref) => false);

/// Intelligent Sidebar Widget
class IntelligentSidebar extends ConsumerStatefulWidget {
  final String? currentRoute;
  final String? userName;
  final String? userEmail;
  final String? profileImageUrl;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogout;

  const IntelligentSidebar({
    super.key,
    this.currentRoute,
    this.userName,
    this.userEmail,
    this.profileImageUrl,
    this.onProfileTap,
    this.onLogout,
  });

  @override
  ConsumerState<IntelligentSidebar> createState() => _IntelligentSidebarState();
}

class _IntelligentSidebarState extends ConsumerState<IntelligentSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _widthAnimation;
  late Animation<double> _opacityAnimation;

  static const double _collapsedWidth = 64.0;
  static const double _expandedWidth = 240.0;

  @override
  void initState() {
    super.initState();

    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _widthAnimation = Tween<double>(
      begin: _collapsedWidth,
      end: _expandedWidth,
    ).animate(
      CurvedAnimation(
        parent: _expandController,
        curve: Curves.easeOutCubic,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _expandController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    ref.read(sidebarHoveredProvider.notifier).state = isHovered;
    final isManuallyExpanded = ref.read(sidebarExpandedProvider);

    if (isHovered) {
      _expandController.forward();
    } else {
      // Only collapse if not manually expanded (click-locked)
      if (!isManuallyExpanded) {
        _expandController.reverse();
      }
    }
  }

  void _handleSidebarTap() {
    // Click to toggle lock state
    _toggleExpanded();
  }

  void _toggleExpanded() {
    final isExpanded = ref.read(sidebarExpandedProvider);
    ref.read(sidebarExpandedProvider.notifier).state = !isExpanded;

    if (!isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isExpanded = ref.watch(sidebarExpandedProvider);
    final isHovered = ref.watch(sidebarHoveredProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    // Mobile: Use bottom navigation instead
    if (isMobile) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _handleSidebarTap,
      child: MouseRegion(
        onEnter: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _handleHover(true);
          });
        },
        onExit: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _handleHover(false);
          });
        },
        child: AnimatedBuilder(
          animation: _expandController,
          builder: (context, child) {
            return Container(
              width: _widthAnimation.value,
              decoration: BoxDecoration(
                color: theme.surface,
                boxShadow: theme.cardGlow != null
                    ? [theme.cardGlow!]
                    : [
                        BoxShadow(
                          color: theme.backgroundPrimary.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(2, 0),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  // Logo at top
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    child: Opacity(
                      opacity: isExpanded || isHovered ? 1.0 : 0.0,
                      child: AnimatedOpacity(
                        opacity: _opacityAnimation.value,
                        duration: const Duration(milliseconds: 200),
                        child: const NikonyxLogo.small(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                  // Top Section - Primary Navigation
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      children: [
                        // Lock indicator (when expanded)
                        if (isExpanded || isHovered)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Opacity(
                              opacity: _opacityAnimation.value,
                              child: Row(
                                children: [
                                  Icon(
                                    isExpanded ? Icons.lock : Icons.lock_open,
                                    size: 14,
                                    color: theme.textTertiary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isExpanded
                                        ? 'Pinned open'
                                        : 'Tap to expand',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        _buildNavItem(
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home,
                          label: 'Dashboard',
                          route: Routes.dashboard,
                          isActive: widget.currentRoute == Routes.dashboard,
                        ),
                        _buildNavItem(
                          icon: Icons.auto_awesome_outlined,
                          activeIcon: Icons.auto_awesome,
                          label: 'Virtual Try-On',
                          route: Routes.tryon,
                          isActive: widget.currentRoute == Routes.tryon,
                        ),
                        _buildNavItem(
                          icon: Icons.checkroom_outlined,
                          activeIcon: Icons.checkroom,
                          label: 'Wardrobe',
                          route: Routes.wardrobe,
                          isActive: widget.currentRoute == Routes.wardrobe,
                        ),
                        _buildNavItem(
                          icon: Icons.people_outline,
                          activeIcon: Icons.people,
                          label: 'Friends Space',
                          route: Routes.styleFeed,
                          isActive: widget.currentRoute == Routes.styleFeed,
                        ),
                        _buildNavItem(
                          icon: Icons.calendar_today_outlined,
                          activeIcon: Icons.calendar_today,
                          label: 'Calendar',
                          route: Routes.calendar,
                          isActive: widget.currentRoute == Routes.calendar,
                          showBadge: false,
                        ),
                        _buildNavItem(
                          icon: Icons.grid_view_rounded,
                          activeIcon: Icons.grid_view_rounded,
                          label: 'Fashion Feed',
                          route: Routes.styleFeed,
                          isActive: widget.currentRoute == Routes.styleFeed,
                        ),
                        _buildNavItem(
                          icon: Icons.shopping_bag_outlined,
                          activeIcon: Icons.shopping_bag,
                          label: 'Shopping',
                          route: Routes.generatedOutfits,
                          isActive:
                              widget.currentRoute == Routes.generatedOutfits,
                        ),
                        _buildNavItem(
                          icon: Icons.notifications_outlined,
                          activeIcon: Icons.notifications,
                          label: 'Notifications',
                          route: null, // Opens panel instead
                          isActive: false,
                          onTap: () => _showNotificationPanel(),
                          showBadge: true,
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Divider(
                    height: 1,
                    color: theme.borderLight,
                    indent: 12,
                    endIndent: 12,
                  ),

                  // Bottom Section - Secondary Navigation
                  Column(
                    children: [
                      _buildNavItem(
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'Profile',
                        route: Routes.settings,
                        isActive: widget.currentRoute == Routes.settings,
                        onTap: widget.onProfileTap,
                      ),
                      _buildNavItem(
                        icon: Icons.settings_outlined,
                        activeIcon: Icons.settings,
                        label: 'Settings',
                        route: Routes.settings,
                        isActive: widget.currentRoute == Routes.settings,
                      ),
                      _buildNavItem(
                        icon: Icons.help_outline,
                        activeIcon: Icons.help,
                        label: 'Help & Support',
                        route: null,
                        isActive: false,
                      ),
                      if (widget.onLogout != null)
                        _buildNavItem(
                          icon: Icons.logout,
                          activeIcon: Icons.logout,
                          label: 'Logout',
                          route: null,
                          isActive: false,
                          onTap: widget.onLogout,
                          isDestructive: true,
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    String? route,
    required bool isActive,
    VoidCallback? onTap,
    bool showBadge = false,
    bool isDestructive = false,
  }) {
    final theme = context.appTheme;
    final isExpanded =
        ref.watch(sidebarExpandedProvider) || ref.watch(sidebarHoveredProvider);
    // Don't block on notification provider - use try-catch to avoid hangs
    int? unreadCount;
    if (showBadge) {
      try {
        final unreadCountAsync = ref.watch(unreadCountProvider);
        unreadCount = unreadCountAsync.valueOrNull;
      } catch (e) {
        // Provider not ready yet - ignore badge
        unreadCount = null;
      }
    }

    return Tooltip(
      message: label,
      preferBelow: false,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap();
          } else if (route != null) {
            Navigator.of(context).pushReplacementNamed(route);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? theme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(theme.borderRadius),
            border: isActive
                ? Border.all(
                    color: theme.primary.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              // Icon with active indicator
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isActive ? activeIcon : icon,
                    size: 22,
                    color: isActive
                        ? theme.primary
                        : (isDestructive
                            ? theme.accentError
                            : theme.textSecondary),
                  ),

                  // Active indicator bar
                  if (isActive)
                    Positioned(
                      left: -12,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 3,
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                  // Badge (non-blocking)
                  if (showBadge && unreadCount != null && unreadCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.surface,
                            width: 2,
                          ),
                          boxShadow: theme.primaryGlow != null
                              ? [theme.primaryGlow!]
                              : null,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),

              // Label (only when expanded)
              if (isExpanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? theme.primary
                            : (isDestructive
                                ? theme.accentError
                                : theme.textPrimary),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  void _showNotificationPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationPanel(),
    );
  }
}

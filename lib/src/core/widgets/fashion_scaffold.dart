import 'package:flutter/material.dart';
import '../theme/fashion_design_system.dart';
import 'theme_wrapper.dart';
import 'fashion_header.dart';
import 'fashion_drawer.dart';
import 'intelligent_sidebar.dart';
import 'quora_bottom_navigation.dart';
import '../../routes.dart';
import '../../features/dashboard/widgets/notification_panel.dart';

/// Global Fashion Scaffold Wrapper
/// Ensures consistent header, drawer, and footer across ALL pages
class FashionScaffold extends StatefulWidget {
  final Widget body;
  final String? title;
  final String? greeting;
  final int? notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final String? profileImageUrl;
  final int currentBottomNavIndex;
  final ValueChanged<int>? onBottomNavTap;
  final bool showBottomNav;
  final bool showDrawer;
  final String? currentRoute;
  final Function(String route)? onNavigate;
  final VoidCallback? onLogout;
  final String? userName;
  final String? userEmail;
  final Color? backgroundColor;

  const FashionScaffold({
    super.key,
    required this.body,
    this.title,
    this.greeting,
    this.notificationCount,
    this.onNotificationTap,
    this.onProfileTap,
    this.profileImageUrl,
    this.currentBottomNavIndex = 0,
    this.onBottomNavTap,
    this.showBottomNav = true,
    this.showDrawer = true,
    this.currentRoute,
    this.onNavigate,
    this.onLogout,
    this.userName,
    this.userEmail,
    this.backgroundColor,
  });

  @override
  State<FashionScaffold> createState() => _FashionScaffoldState();
}

class _FashionScaffoldState extends State<FashionScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _handleBottomNavTap(BuildContext context, int index) {
    if (widget.onBottomNavTap != null) {
      widget.onBottomNavTap!(index);
      return;
    }

    // Default navigation
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(Routes.dashboard);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(Routes.wardrobe);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(Routes.tryon);
        break;
      case 3:
        // Show notification panel
        _showNotificationPanel(context);
        break;
      case 4:
        // Profile - navigate to settings
        Navigator.of(context).pushNamed(Routes.settings);
        break;
    }
  }

  void _showNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationPanel(),
    );
  }

  void _handleDrawerNavigate(BuildContext context, String route) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(route);
    } else {
      // Default navigation mapping
      if (route == Routes.dashboard) {
        Navigator.of(context).pushReplacementNamed(Routes.dashboard);
      } else if (route == Routes.wardrobe) {
        Navigator.of(context).pushReplacementNamed(Routes.wardrobe);
      } else if (route == Routes.tryon) {
        Navigator.of(context).pushReplacementNamed(Routes.tryon);
      } else if (route == Routes.recommendations) {
        Navigator.of(context).pushReplacementNamed(Routes.recommendations);
      } else if (route == Routes.calendar) {
        Navigator.of(context).pushReplacementNamed(Routes.calendar);
      } else if (route == Routes.settings || route == '/profile') {
        Navigator.of(context).pushNamed(Routes.settings);
      } else {
        // Fallback for any hardcoded strings
        switch (route) {
          case '/dashboard':
            Navigator.of(context).pushReplacementNamed(Routes.dashboard);
            break;
          case '/wardrobe':
            Navigator.of(context).pushReplacementNamed(Routes.wardrobe);
            break;
          case '/tryon':
            Navigator.of(context).pushReplacementNamed(Routes.tryon);
            break;
          case '/recommendations':
            Navigator.of(context).pushReplacementNamed(Routes.recommendations);
            break;
          case '/calendar':
            Navigator.of(context).pushReplacementNamed(Routes.calendar);
            break;
          case '/settings':
            Navigator.of(context).pushNamed(Routes.settings);
            break;
          case '/logout':
            if (widget.onLogout != null) {
              widget.onLogout!();
            }
            break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final backgroundColor = widget.backgroundColor ?? 
        (theme.backgroundGradient != null 
            ? null 
            : theme.backgroundPrimary);
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: widget.showDrawer
          ? Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isMobile = screenWidth < 768;
                
                // Mobile: Use drawer, Desktop: Use intelligent sidebar
                if (isMobile) {
                  return FashionDrawer(
                    userName: widget.userName,
                    userEmail: widget.userEmail,
                    profileImageUrl: widget.profileImageUrl,
                    currentRoute: widget.currentRoute ?? ModalRoute.of(context)?.settings.name,
                    onNavigate: (route) => _handleDrawerNavigate(context, route),
                    onProfileTap: widget.onProfileTap,
                    onLogout: widget.onLogout,
                  );
                }
                // Desktop: Return empty drawer (sidebar handles navigation)
                return const Drawer(child: SizedBox.shrink());
              },
            )
          : null,
      body: Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 768;
          final currentRoute = widget.currentRoute ?? ModalRoute.of(context)?.settings.name;
          final theme = context.appTheme;

          return Container(
            decoration: theme.backgroundGradient != null
                ? BoxDecoration(gradient: theme.backgroundGradient)
                : null,
            child: SafeArea(
              child: Row(
                children: [
                  // Intelligent Sidebar (Desktop/Web only)
                  if (widget.showDrawer && !isMobile)
                    IntelligentSidebar(
                      currentRoute: currentRoute,
                      userName: widget.userName,
                      userEmail: widget.userEmail,
                      profileImageUrl: widget.profileImageUrl,
                      onProfileTap: widget.onProfileTap,
                      onLogout: widget.onLogout,
                    ),
                  
                  // Main Content Area
                  Expanded(
                    child: Column(
                      children: [
                        // Global Header
                        FashionHeader(
                          title: widget.title,
                          greeting: widget.greeting,
                          notificationCount: widget.notificationCount,
                          onNotificationTap: widget.onNotificationTap ?? () {
                            _showNotificationPanel(context);
                          },
                          onProfileTap: widget.onProfileTap,
                          profileImageUrl: widget.profileImageUrl,
                          showMenuIcon: widget.showDrawer && isMobile,
                          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                        
                        // Body Content
                        Expanded(child: widget.body),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: widget.showBottomNav
          ? QuoraBottomNavigation(
              currentIndex: widget.currentBottomNavIndex,
              onTap: (index) => _handleBottomNavTap(context, index),
            )
          : null,
    );
  }
}

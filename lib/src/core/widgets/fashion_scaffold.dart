import 'package:flutter/material.dart';
import '../theme/fashion_design_system.dart';
import 'fashion_header.dart';
import 'fashion_drawer.dart';
import 'quora_bottom_navigation.dart';
import '../../routes.dart';

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
        // Notifications - implement route if needed
        break;
      case 4:
        // Profile - implement route if needed
        break;
    }
  }

  void _handleDrawerNavigate(BuildContext context, String route) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(route);
    } else {
      // Default navigation mapping
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
          // Implement settings route if needed
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: widget.backgroundColor ?? FashionDesignSystem.backgroundIvory,
      drawer: widget.showDrawer
          ? FashionDrawer(
              userName: widget.userName,
              userEmail: widget.userEmail,
              profileImageUrl: widget.profileImageUrl,
              currentRoute: widget.currentRoute ?? ModalRoute.of(context)?.settings.name,
              onNavigate: (route) => _handleDrawerNavigate(context, route),
              onProfileTap: widget.onProfileTap,
              onLogout: widget.onLogout,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Global Header
            FashionHeader(
              title: widget.title,
              greeting: widget.greeting,
              notificationCount: widget.notificationCount,
              onNotificationTap: widget.onNotificationTap,
              onProfileTap: widget.onProfileTap,
              profileImageUrl: widget.profileImageUrl,
              showMenuIcon: widget.showDrawer,
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            
            // Body Content
            Expanded(child: widget.body),
          ],
        ),
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

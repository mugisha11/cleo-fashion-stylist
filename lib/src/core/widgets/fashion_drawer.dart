import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../routes.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Sidebar design: light blue-white palette matching homepage style.
class _DrawerColors {
  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0B1B3A);
  static const Color textSecondary = Color(0xFF3D4B66);
  static const Color border = Color(0xFFCAD6EA);
  static const Color blueDark = Color(0xFF1AACCF);
  static const Color blueMedium = Color(0xFF1178B4);
  static const Color blueLight = Color(0xFF0A4E8F);
  static const Color accent = Color(0xFF2A58C8);
}

/// Single shared sidebar for the app. Match reference: X, profile, 5 items + arrow, Nikonyx.
class FashionDrawer extends StatelessWidget {
  final String? userName;
  final String? userEmail;
  final String? profileImageUrl;
  final String? currentRoute;
  final Function(String route)? onNavigate;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogout;

  const FashionDrawer({
    super.key,
    this.userName,
    this.userEmail,
    this.profileImageUrl,
    this.currentRoute,
    this.onNavigate,
    this.onProfileTap,
    this.onLogout,
  });

  static const double drawerWidth = 280;

  static final List<_DrawerNavItem> items = [
    const _DrawerNavItem(
        icon: Icons.home_outlined, label: 'Dashboard', route: Routes.dashboard),
    const _DrawerNavItem(
        icon: Icons.checkroom_outlined,
        label: 'Wardrobe',
        route: Routes.wardrobe),
    const _DrawerNavItem(
        icon: Icons.shopping_bag_outlined,
        label: 'Shopping',
        route: Routes.generatedOutfits),
    const _DrawerNavItem(
        icon: Icons.dynamic_feed_outlined,
        label: 'Fashion Feed',
        route: Routes.styleFeed),
    const _DrawerNavItem(
        icon: Icons.calendar_today_outlined,
        label: 'Calendar',
        route: Routes.calendar),
    const _DrawerNavItem(
        icon: Icons.people_outline,
        label: 'Friends Space',
        route: Routes.styleFeed),
    const _DrawerNavItem(
        icon: Icons.history_rounded, label: 'Messages', route: Routes.chats),
    const _DrawerNavItem(
        icon: Icons.person_outline,
        label: 'Profile & Settings',
        route: Routes.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final logoutWidget = onLogout != null
        ? Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onLogout!();
              },
              child: const Text(
                'Sign out',
                style: TextStyle(
                  fontFamily: 'system-ui',
                  fontSize: 14,
                  color: _DrawerColors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    return Drawer(
      width: drawerWidth,
      backgroundColor: _DrawerColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _DrawerColors.blueDark,
                    _DrawerColors.blueMedium,
                    _DrawerColors.blueLight
                  ],
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  const Text(
                    'Menu',
                    style: TextStyle(
                      fontFamily: 'system-ui',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Container(
              color: _DrawerColors.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    onProfileTap?.call();
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _DrawerColors.border, width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: profileImageUrl != null &&
                                profileImageUrl!.isNotEmpty
                            ? Image.network(
                                profileImageUrl!,
                                fit: BoxFit.cover,
                                width: 56,
                                height: 56,
                                errorBuilder: (_, __, ___) =>
                                    _avatarPlaceholder(context),
                              )
                            : _avatarPlaceholder(context),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName ?? 'Style Lover',
                              style: const TextStyle(
                                fontFamily: 'system-ui',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _DrawerColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (userEmail != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                userEmail!,
                                style: const TextStyle(
                                  fontFamily: 'system-ui',
                                  fontSize: 13,
                                  color: _DrawerColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: _DrawerColors.border),
            Expanded(
              child: Container(
                color: _DrawerColors.surface,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: items.map((item) {
                    final isActive = currentRoute == item.route;
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: Icon(
                          item.icon,
                          size: 22,
                          color: isActive
                              ? _DrawerColors.accent
                              : _DrawerColors.textSecondary,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            fontFamily: 'system-ui',
                            fontSize: 15,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive
                                ? _DrawerColors.accent
                                : _DrawerColors.textPrimary,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: _DrawerColors.textSecondary,
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          onNavigate?.call(item.route);
                        },
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(height: 1, color: _DrawerColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        _DrawerColors.blueLight,
                        _DrawerColors.blueMedium
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'Nikonyx',
                      style: TextStyle(
                        fontFamily: 'system-ui',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Personal AI stylish',
                    style: TextStyle(
                      fontFamily: 'system-ui',
                      fontSize: 13,
                      color: _DrawerColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            logoutWidget,
          ],
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(BuildContext context) {
    final initial = (userName ?? '?').isNotEmpty
        ? (userName!.substring(0, 1).toUpperCase())
        : '?';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontFamily: 'system-ui',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: _DrawerColors.textSecondary,
        ),
      ),
    );
  }
}

class _DrawerNavItem {
  final IconData icon;
  final String label;
  final String route;
  const _DrawerNavItem(
      {required this.icon, required this.label, required this.route});
}

/// Shared app drawer: reads auth and builds FashionDrawer. Use as drawer: AppDrawer(currentRoute: Routes.xxx).
class AppDrawer extends ConsumerWidget {
  final String? currentRoute;

  const AppDrawer({super.key, this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    return FashionDrawer(
      userName: user?.displayName,
      userEmail: user?.email,
      profileImageUrl: user?.photoURL,
      currentRoute: currentRoute ?? ModalRoute.of(context)?.settings.name,
      onNavigate: (route) {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed(route);
      },
      onProfileTap: () {
        Navigator.of(context).pushNamed(Routes.settings);
      },
      onLogout: () async {
        try {
          await FirebaseAuth.instanceFor(app: Firebase.apps.first).signOut();
          if (context.mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil(Routes.login, (r) => false);
          }
        } catch (_) {}
      },
    );
  }
}

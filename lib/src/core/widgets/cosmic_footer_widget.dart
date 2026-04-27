// ══════════════════════════════════════════════════════════════════════════════
//  cosmic_footer_widget.dart
//  Universal reusable footer component for all main pages
//  Extracted from wardrobe_screen.dart for consistency across app
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import 'nikonyx_logo.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  CONSTANTS (from wardrobe_screen.dart)
// ──────────────────────────────────────────────────────────────────────────────
const _navTextColor = Color(0xFF1A3060);

// ──────────────────────────────────────────────────────────────────────────────
//  NAV SEPARATOR
// ──────────────────────────────────────────────────────────────────────────────
class _NavSep extends StatelessWidget {
  const _NavSep();
  @override
  Widget build(BuildContext ctx) => Container(
        width: 1.5,
        height: 32,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Color(0xFF3C78DC),
              Color(0xFF5096FF),
              Color(0xFF3C78DC),
              Colors.transparent,
            ],
            stops: [0.0, 0.30, 0.50, 0.70, 1.0],
          ),
        ),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
//  NAV ITEM
// ──────────────────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final Widget icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext ctx) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            icon,
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: active
                    ? _navTextColor
                    : const Color.fromRGBO(26, 48, 96, 0.7),
                letterSpacing: 0.1,
                shadows: const [
                  Shadow(
                      color: Colors.white, blurRadius: 1, offset: Offset(0, 1))
                ],
              ),
            ),
          ]),
        ),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
//  NAV ICON
// ──────────────────────────────────────────────────────────────────────────────
class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.data, this.size = 24.0});
  final IconData data;
  final double size;
  @override
  Widget build(BuildContext ctx) => ShaderMask(
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A4A8A), Color(0xFF1E3060)],
        ).createShader(r),
        child: Icon(data, size: size, color: Colors.white),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
//  HOME LOGO RING (from wardrobe_screen.dart)
// ──────────────────────────────────────────────────────────────────────────────
class _HomeLogoRing extends StatelessWidget {
  const _HomeLogoRing({this.size = 36.0});
  final double size;
  @override
  Widget build(BuildContext ctx) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            startAngle: 0.26,
            colors: [
              Color.fromARGB(255, 19, 52, 143),
              Color(0xFF5080B0),
              Color(0xFF90B8D8),
              Color(0xFFC8DCF0),
              Color(0xFFE8F4FF),
              Color(0xFFFFFFFF),
              Color(0xFFFFFFFF),
              Color(0xFFE8F4FF),
              Color(0xFFC8DCF0),
              Color(0xFF90B8D8),
              Color(0xFF5080B0),
              Color(0xFF1E3060),
            ],
          ),
          boxShadow: [
            BoxShadow(
                color: Color.fromRGBO(130, 180, 255, 0.45),
                blurRadius: 0,
                spreadRadius: 1.5),
            BoxShadow(
                color: Color.fromRGBO(50, 120, 220, 0.50), blurRadius: 10),
            BoxShadow(color: Color.fromRGBO(30, 90, 200, 0.28), blurRadius: 18),
          ],
        ),
        child: Center(
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: size * 0.83,
              height: size * 0.83,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment(-0.2, -0.35),
                  colors: [
                    Color(0xFF1A3A7A),
                    Color.fromARGB(255, 29, 64, 170),
                    Color.fromARGB(255, 28, 65, 165),
                  ],
                ),
              ),
            ),
            Container(
              width: size * 0.69,
              height: size * 0.69,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color.fromRGBO(160, 208, 255, 0.28), width: 1),
              ),
            ),
            SizedBox(
              width: size * 0.72,
              height: size * 0.72,
              child: const NikonyxLogo.small(),
            ),
          ]),
        ),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
//  MAIN COSMIC FOOTER WIDGET
// ──────────────────────────────────────────────────────────────────────────────
class CosmicFooter extends StatelessWidget {
  const CosmicFooter({
    super.key,
    this.bottomPadding = 0.0,
    this.activeIndex = 2, // Home active by default
    required this.onTryOn,
    required this.onWardrobe,
    required this.onHome,
    required this.onFriends,
    required this.onOutfits,
  });
  final double bottomPadding;
  final int activeIndex;
  final VoidCallback onTryOn;
  final VoidCallback onWardrobe;
  final VoidCallback onHome;
  final VoidCallback onFriends;
  final VoidCallback onOutfits;

  @override
  Widget build(BuildContext ctx) {
    final h = 52.0 + bottomPadding;
    return Container(
      height: h,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFB8C8E0), // nav top silver
            Color(0xFFD4E0F0), // 8%
            Color(0xFFE8F0F8), // 25%
            Color(0xFFF2F6FC), // 40%
            Color(0xFFE0EAF6), // 60%
            Color(0xFFC8D8EC), // 80%
            Color(0xFFB0C4DC), // bottom
          ],
          stops: [0.0, 0.08, 0.25, 0.40, 0.60, 0.80, 1.0],
        ),
        border: Border(
          top: BorderSide(color: Colors.white, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x1F143278), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Try-On
            _NavItem(
              icon: const _NavIcon(data: Icons.camera_alt_outlined, size: 20),
              label: 'Try-On',
              active: activeIndex == 0,
              onTap: onTryOn,
            ),
            const _NavSep(),
            // Wardrobe
            _NavItem(
              icon: const _NavIcon(data: Icons.checkroom_outlined, size: 20),
              label: 'Wardrobe',
              active: activeIndex == 1,
              onTap: onWardrobe,
            ),
            const _NavSep(),
            // Home (centre — larger)
            Expanded(
              child: GestureDetector(
                onTap: onHome,
                behavior: HitTestBehavior.opaque,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _HomeLogoRing(size: 36),
                      const SizedBox(height: 2),
                      Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: activeIndex == 2
                              ? _navTextColor
                              : const Color.fromRGBO(26, 48, 96, 0.8),
                          shadows: const [
                            Shadow(
                                color: Colors.white,
                                blurRadius: 1,
                                offset: Offset(0, 1))
                          ],
                        ),
                      ),
                    ]),
              ),
            ),
            const _NavSep(),
            // Friends Space
            _NavItem(
              icon: const _NavIcon(data: Icons.people_outline, size: 20),
              label: 'Friends Space',
              active: activeIndex == 3,
              onTap: onFriends,
            ),
            const _NavSep(),
            // Outfits
            _NavItem(
              icon: const _NavIcon(data: Icons.style_outlined, size: 20),
              label: 'Outfits',
              active: activeIndex == 4,
              onTap: onOutfits,
            ),
          ],
        ),
      ),
    );
  }
}

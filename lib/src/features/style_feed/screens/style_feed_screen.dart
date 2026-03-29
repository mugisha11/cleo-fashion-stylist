// ══════════════════════════════════════════════════════════════════════════════
//  friends_space_screen.dart
//  100% pixel-perfect clone of Friends Space mockup
//  Background: light silver-white frosted glass — clean professional look
//  Professional clean layout — Instagram/Facebook style
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/providers/social_provider.dart';
import '../providers/style_feed_provider.dart';
import '../widgets/discover_people_strip.dart';
import '../widgets/look_post_card.dart';
import '../widgets/style_feed_story_strip.dart';
import '../widgets/style_feed_skeleton.dart';
import '../models/look_post_model.dart';

// ─── Route shims ──────────────────────────────────────────────────────────────
const _rWardrobe = Routes.wardrobe;
const _rChat = Routes.chat;
const _rPostLook = Routes.postLook;
const _rTryon = Routes.tryon;
const _rProfile = '/profile';
const _rShopping = '/shopping';
const _rStyleFeed = Routes.styleFeed;

// ══════════════════════════════════════════════════════════════════════════════
//  PALETTE
//  Page body  → light silver-blue-white (like the image)
//  Header     → same light silver, NX logo on top
//  Cards      → frosted white glass with subtle border
//  Section bars / tabs → dark navy (same as wardrobe)
//  Nav bar    → dark navy (bottom of image is dark)
// ══════════════════════════════════════════════════════════════════════════════

// Page body background — light silvery-white (from image)
const _pageBg = Color(0xFFD4DCF0); // main body tint
const _pageMid = Color(0xFFBFC9E2);
const _pageBot = Color(0xFFAAB8D8);

// Header background — slightly lighter
const _headerBg = Color(0xFFDDE5F5);

// Section header bars — dark navy (matches wardrobe exactly)
const _secBg = Color(0xFF0B1D4C);
const _secBdr = Color(0xFF1D3268);

// Tab pills
const _tabSel = Color(0xFF0B1D4C); // selected = dark navy
const _tabUnsel = Color(0xFFFFFFFF); // unselected = white

// Filter pills
const _filtSel = Color(0xFF0B1D4C);
const _filtUnsel = Color(0xFFFFFFFF);

// Post cards — frosted white with subtle border
const _cardBg = Color(0xCCFFFFFF);
const _cardBdr = Color(0xFFCCDAF0);

// Chrome / silver (same as wardrobe)
const _chr0 = Color(0xFF3A5A8A);
const _chr1 = Color(0xFFBBD0EE);
const _slv = Color(0xFFCCDDFF);

// Accent
const _blue = Color(0xFF2050C8);
const _blueGlow = Color(0xFF4488FF);

// Nav bar — dark navy (bottom of image)
const _navBg = Color(0xFF08102A);
const _navBdr = Color(0xFF1A2850);

// Text
const _darkText = Color(0xFF0A1830);
const _midText = Color(0xFF3A5A8A);
const _lightText = Color(0xFF7A9ABB);
const _whiteText = Colors.white;

// Stats colours
const _heartRed = Color(0xFFE84040);
const _commentBl = Color(0xFF2255CC);

// ══════════════════════════════════════════════════════════════════════════════
//  BACKGROUND PAINTER — clean gradient, no stars or sparkles
// ══════════════════════════════════════════════════════════════════════════════
class _PageBgPainter extends CustomPainter {
  const _PageBgPainter();

  @override
  void paint(Canvas c, Size s) {
    // Clean silver-blue gradient — no stars, professional look
    c.drawRect(
        Rect.fromLTWH(0, 0, s.width, s.height),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_headerBg, _pageBg, _pageMid, _pageBot],
            stops: [0.0, 0.25, 0.6, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, s.width, s.height)));

    // Subtle white glow behind logo area only
    final p = Paint()
      ..shader = RadialGradient(colors: [
        Colors.white.withOpacity(0.4),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(
          center: Offset(s.width / 2, s.height * 0.09),
          radius: s.width * 0.42));
    c.drawCircle(Offset(s.width / 2, s.height * 0.09), s.width * 0.42, p);

    // Chrome rail separator at header/body boundary
    final railY = s.height * 0.21 - 5;
    c.drawRect(
        Rect.fromLTWH(0, railY, s.width, 9),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.05),
              const Color(0xFFCCDDFF).withOpacity(0.5),
              Colors.white.withOpacity(0.9),
              const Color(0xFFAABBDD).withOpacity(0.5),
              Colors.white.withOpacity(0.05),
            ],
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
          ).createShader(Rect.fromLTWH(0, railY, s.width, 9)));
  }

  @override
  bool shouldRepaint(_) => false;
}

//  NX METALLIC LOGO (same as wardrobe + tryon)
// ══════════════════════════════════════════════════════════════════════════════
class _NxLogo extends StatelessWidget {
  const _NxLogo({this.d = 86.0});
  final double d;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: d * 1.28,
        height: d * 1.28,
        child: Stack(alignment: Alignment.center, children: [
          // outer bloom
          Container(
              width: d * 1.28,
              height: d * 1.28,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Color(0x884499FF),
                    Color(0x224499FF),
                    Colors.transparent,
                  ], stops: [
                    0.0,
                    0.4,
                    1.0
                  ]))),
          // chrome ring
          Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(colors: [
                    Color(0xFF2A4A7A),
                    Color(0xFFAABBDD),
                    Color(0xFFEEF5FF),
                    Color(0xFFCCDDFF),
                    Color(0xFF6688BB),
                    Color(0xFFDDEEFF),
                    Color(0xFF4466AA),
                    Color(0xFF2A4A7A),
                  ]),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1),
                    BoxShadow(
                        color: const Color(0xFF4488FF).withOpacity(0.3),
                        blurRadius: 22,
                        spreadRadius: 3),
                  ])),
          // inner dark disc
          Container(
              width: d * 0.85,
              height: d * 0.85,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                      center: Alignment(-0.4, -0.4),
                      colors: [
                        Color(0xFF2255BB),
                        Color(0xFF0E1F55),
                        Color(0xFF060F28)
                      ],
                      stops: [
                        0.0,
                        0.45,
                        1.0
                      ]),
                  border: Border.all(
                      color: const Color(0xFF3355AA).withOpacity(0.5),
                      width: 1))),
          // NX text
          ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFCCDDFF),
                      Color(0xFF8899CC)
                    ],
                  ).createShader(r),
              child: Text('NX',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: d * 0.26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: d * 0.04,
                      shadows: const [
                        Shadow(color: Color(0xFF99BBFF), blurRadius: 14)
                      ]))),
          // top arc highlight
          Positioned(
              top: d * 0.12,
              child: Container(
                  width: d * 0.42,
                  height: d * 0.034,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.75),
                        Colors.transparent,
                      ])))),
          // lens flare dots
          Positioned(left: -d * 0.04, top: d * 0.44, child: _Spark(d * 0.06)),
          Positioned(right: -d * 0.04, top: d * 0.44, child: _Spark(d * 0.06)),
        ]),
      );
}

class _Spark extends StatelessWidget {
  const _Spark(this.r);
  final double r;
  @override
  Widget build(BuildContext _) => Container(
      width: r,
      height: r,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFAADDFF).withOpacity(0.9),
                blurRadius: r * 2.5,
                spreadRadius: r * 0.4)
          ]));
}

// ══════════════════════════════════════════════════════════════════════════════
//  ICON BUTTON (glass on light bg — dark icons)
// ══════════════════════════════════════════════════════════════════════════════
class _IBtn extends StatelessWidget {
  const _IBtn({required this.icon, required this.onTap, this.badge = 0});
  final IconData icon;
  final VoidCallback onTap;
  final int badge;
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.55),
                border: Border.all(
                    color: Colors.white.withOpacity(0.8), width: 1.2),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]),
            child: Icon(icon, color: _darkText, size: 18)),
        if (badge > 0)
          Positioned(
              right: -2,
              top: -2,
              child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: Center(
                      child: Text('$badge',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold))))),
      ]));
}

// ══════════════════════════════════════════════════════════════════════════════
//  NX BOTTOM NAV CENTRE BUTTON (same as wardrobe)
// ══════════════════════════════════════════════════════════════════════════════
class _NxNavBtn extends StatelessWidget {
  const _NxNavBtn({this.active = false});
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient:
              RadialGradient(center: const Alignment(-0.3, -0.3), colors: [
            active ? const Color(0xFF2E66CC) : const Color(0xFF1A3A88),
            const Color(0xFF080F28),
          ]),
          border: Border.all(color: const Color(0xFF4477CC), width: 2.2),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF2255CC).withOpacity(0.6),
                blurRadius: 18,
                spreadRadius: 2),
            BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ]),
      child: Center(
          child: ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFFFFF), Color(0xFFAABBDD)])
                  .createShader(r),
              child: const Text('NX',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2)))));
}

// ══════════════════════════════════════════════════════════════════════════════
//  SECTION HEADER BAR (dark navy pill — same as wardrobe screen)
// ══════════════════════════════════════════════════════════════════════════════
class _SecBar extends StatelessWidget {
  const _SecBar({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: _secBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _secBdr, width: 1)),
      child: Row(children: [
        Icon(icon, size: 16, color: _slv),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: _chr0.withOpacity(0.5))),
      ]));
}

// ══════════════════════════════════════════════════════════════════════════════
//  TAB PILL  (dark when selected, white glass when not)
// ══════════════════════════════════════════════════════════════════════════════
class _TabPill extends StatelessWidget {
  const _TabPill(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
              color: selected ? _tabSel : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: selected ? _secBdr : Colors.white.withOpacity(0.9),
                  width: 1),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(selected ? 0.0 : 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: selected ? Colors.white : _darkText),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : _darkText,
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          ])));
}

// ══════════════════════════════════════════════════════════════════════════════
//  FILTER PILL  (for trends sub-categories)
// ══════════════════════════════════════════════════════════════════════════════
class _FilterPill extends StatelessWidget {
  const _FilterPill(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: selected ? _filtSel : Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected ? _secBdr : Colors.white.withOpacity(0.85),
                  width: 1),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2))
              ]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: selected ? Colors.white : _darkText),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : _darkText,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          ])));
}

// ══════════════════════════════════════════════════════════════════════════════
//  POST CARD  (photo card with avatar, label, stats)
// ══════════════════════════════════════════════════════════════════════════════
class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.imageUrl,
    required this.label,
    required this.likes,
    required this.comments,
    required this.timeAgo,
    this.avatarUrl,
    this.userName,
    this.isLiked = false,
    required this.onTap,
  });
  final String imageUrl, label, likes, comments, timeAgo;
  final String? avatarUrl, userName;
  final bool isLiked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _cardBg,
              border: Border.all(color: _cardBdr, width: 1),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(children: [
              // Photo
              Positioned.fill(
                  child: Image.network(imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFD8E4F4),
                          child: const Icon(Icons.person,
                              size: 52, color: Color(0xFF8AAACF))))),

              // Gradient overlay bottom
              Positioned.fill(
                  child: Container(
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x00000000), Color(0xBB000000)],
                              stops: [0.45, 1.0])))),

              // Top: avatar + username (only for Public Outfits)
              if (userName != null)
                Positioned(
                    top: 8,
                    left: 8,
                    child: Row(children: [
                      Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                              color: const Color(0xFFD8E4F4)),
                          child: avatarUrl != null
                              ? ClipOval(
                                  child: Image.network(avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.person,
                                          size: 14,
                                          color: _midText)))
                              : const Icon(Icons.person,
                                  size: 14, color: _midText)),
                      const SizedBox(width: 5),
                      Text(userName!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 4)
                              ])),
                    ])),

              // Bottom: label + stats
              Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  shadows: [
                                    Shadow(color: Colors.black45, blurRadius: 3)
                                  ])),
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(Icons.favorite,
                                size: 11,
                                color: isLiked ? _heartRed : Colors.white70),
                            const SizedBox(width: 3),
                            Text(likes,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(width: 7),
                            Icon(Icons.chat_bubble_outline,
                                size: 11, color: Colors.white.withOpacity(0.9)),
                            const SizedBox(width: 3),
                            Text(comments,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10)),
                            const SizedBox(width: 7),
                            Icon(Icons.access_time_outlined,
                                size: 11, color: Colors.white.withOpacity(0.7)),
                            const SizedBox(width: 3),
                            Text(timeAgo,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 10)),
                          ]),
                        ]),
                  )),
            ]),
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
//  VIEW ALL BUTTON
// ══════════════════════════════════════════════════════════════════════════════
class _ViewAllBtn extends StatelessWidget {
  const _ViewAllBtn({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withOpacity(0.85), width: 1),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 5,
                    offset: const Offset(0, 2))
              ]),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Text('View All',
                style: TextStyle(
                    color: _darkText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            SizedBox(width: 4),
            Icon(Icons.chevron_right, color: _midText, size: 16),
          ])));
}

// ══════════════════════════════════════════════════════════════════════════════
//  NX CHAT MINIMIZED BAR (bottom nav left side)
// ══════════════════════════════════════════════════════════════════════════════
class _NxChatBar extends StatelessWidget {
  const _NxChatBar({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
              color: const Color(0xFF0A1430),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1D3268), width: 1),
              boxShadow: [
                BoxShadow(color: _blue.withOpacity(0.3), blurRadius: 10)
              ]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                        colors: [Color(0xFF2255BB), Color(0xFF060F28)]),
                    border: Border.all(color: _chr0.withOpacity(0.6), width: 1),
                    boxShadow: [
                      BoxShadow(color: _blue.withOpacity(0.45), blurRadius: 6)
                    ]),
                child: const Icon(Icons.smart_toy_outlined,
                    color: _slv, size: 16)),
            const SizedBox(width: 7),
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('NX Chat',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  Text('Minimize',
                      style: TextStyle(
                          color: _blue.withOpacity(0.85), fontSize: 10.5)),
                ]),
          ])));
}

// ══════════════════════════════════════════════════════════════════════════════
//  MAIN SCREEN — fully wired to real providers
// ══════════════════════════════════════════════════════════════════════════════
class FriendsSpaceScreen extends ConsumerStatefulWidget {
  const FriendsSpaceScreen({super.key});
  @override
  ConsumerState<FriendsSpaceScreen> createState() => _FriendsSpaceScreenState();
}

class _FriendsSpaceScreenState extends ConsumerState<FriendsSpaceScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollCtrl = ScrollController();

  int _navIndex = 3; // Friends Space active
  int _tabIndex = 1; // default: Public Outfits
  int _trendFilt = 0;

  static const _tabs = [
    (Icons.person_add_outlined, 'Invite Friends'),
    (Icons.group_outlined, 'Public Outfits'),
    (Icons.trending_up_outlined, 'Trends'),
    (Icons.mail_outline, 'Friends'),
  ];

  static const _trendFilters = [
    (Icons.business_center_outlined, 'Smart Business'),
    (Icons.dry_cleaning_outlined, 'Spring Streetwear'),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ─── Navigation helpers ────────────────────────────────────────────────────
  void _goToPostLook() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushNamed(_rPostLook);
  }

  void _goToTryOn(String? imagePath) {
    if (imagePath == null) return;
    ref.read(lastTryOnImageForPostProvider.notifier).state = imagePath;
    Navigator.of(context).pushNamed(_rTryon);
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final unread = ref.watch(socialUnreadCountProvider) ?? 0;
    final user = ref.watch(authStateProvider).valueOrNull;
    final userName = user?.displayName ?? 'Style Lover';
    final photoUrl = user?.photoURL;
    final feedAsync = ref.watch(styleFeedProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _pageBg,
        extendBody: true,
        body: Stack(children: [
          // Clean gradient background
          const Positioned.fill(child: CustomPaint(painter: _PageBgPainter())),

          // Main scrollable content — driven by real feed provider
          feedAsync.when(
            data: (state) => _buildFeed(context, state, mq, unread, photoUrl),
            loading: () => _buildLoading(mq, unread),
            error: (e, _) => _buildError(mq, unread, e),
          ),
        ]),
        bottomNavigationBar: _navBar(mq, unread),
      ),
    );
  }

  // ─── FEED (loaded) ─────────────────────────────────────────────────────────
  Widget _buildFeed(BuildContext context, StyleFeedState state,
      MediaQueryData mq, int unread, String? photoUrl) {
    final posts = state.posts;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(styleFeedProvider),
      color: _blue,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────────────────────────────
          SliverToBoxAdapter(child: _header(mq, unread, photoUrl)),

          // ── Story strip (reuses existing widget) ────────────────────
          SliverToBoxAdapter(
            child: StyleFeedStoryStrip(
              recentPosts: posts.take(10).toList(),
              onAddLook: _goToPostLook,
              onTryThisLook: (post) => _goToTryOn(post.imagePath),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Discover people strip ────────────────────────────────────
          const SliverToBoxAdapter(child: DiscoverPeopleStrip()),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Tab row ─────────────────────────────────────────────────
          SliverToBoxAdapter(child: _tabRow()),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // ── PUBLIC OUTFITS section ───────────────────────────────────
          const SliverToBoxAdapter(
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: _SecBar(
                      icon: Icons.group_add_outlined,
                      title: 'Public Outfits'))),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          if (posts.isEmpty)
            SliverToBoxAdapter(child: _emptyOutfits())
          else
            SliverToBoxAdapter(child: _outfitGrid(posts, state)),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── TRENDS section ───────────────────────────────────────────
          const SliverToBoxAdapter(
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: _SecBar(
                      icon: Icons.trending_up_outlined, title: 'Trends'))),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverToBoxAdapter(child: _filterRow()),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverToBoxAdapter(child: _trendsGrid(posts, state)),

          // ── Post Look FAB space ──────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 160)),
        ],
      ),
    );
  }

  // ─── LOADING STATE ─────────────────────────────────────────────────────────
  Widget _buildLoading(MediaQueryData mq, int unread) => Column(children: [
        _header(mq, unread, null),
        StyleFeedStoryStrip(recentPosts: const [], onAddLook: _goToPostLook),
        const Expanded(child: StyleFeedSkeleton(itemCount: 4)),
      ]);

  // ─── ERROR STATE ───────────────────────────────────────────────────────────
  Widget _buildError(MediaQueryData mq, int unread, Object error) =>
      Column(children: [
        _header(mq, unread, null),
        Expanded(
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
              const Icon(Icons.error_outline_rounded,
                  size: 52, color: _midText),
              const SizedBox(height: 16),
              const Text(
                "Couldn't load the feed",
                style: TextStyle(
                    color: _darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text('$error',
                  style: const TextStyle(color: _midText, fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                  onPressed: () => ref.invalidate(styleFeedProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)))),
            ]))),
      ]);

  // ─── HEADER ────────────────────────────────────────────────────────────────
  Widget _header(MediaQueryData mq, int unread, String? photoUrl) => Padding(
        padding: EdgeInsets.only(top: mq.padding.top + 8, bottom: 6),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              _IBtn(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.maybePop(context)),
              const Spacer(),
              const _NxLogo(d: 80).animate().scale(
                  begin: const Offset(0.75, 0.75),
                  end: const Offset(1.0, 1.0),
                  duration: 700.ms,
                  curve: Curves.elasticOut),
              const Spacer(),
              // Profile avatar (real user photo if available)
              GestureDetector(
                  onTap: () => Navigator.pushNamed(context, _rProfile),
                  child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFBBD0EE), width: 1.5),
                          color: const Color(0xFFE8F0FA)),
                      child: photoUrl != null
                          ? ClipOval(
                              child: Image.network(photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person,
                                      size: 18,
                                      color: _midText)))
                          : const Icon(Icons.person,
                              size: 18, color: _midText))),
              const SizedBox(width: 8),
              _IBtn(icon: Icons.mail_outline, badge: unread, onTap: () {}),
            ]),
          ),
          const SizedBox(height: 8),
          const Text('Friends Space',
                  style: TextStyle(
                      color: _darkText,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.15))
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.1),
          const SizedBox(height: 10),
        ]),
      );

  // ─── TAB ROW ───────────────────────────────────────────────────────────────
  Widget _tabRow() => SizedBox(
      height: 46,
      child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: _tabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final (icon, label) = _tabs[i];
            return _TabPill(
                icon: icon,
                label: label,
                selected: _tabIndex == i,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _tabIndex = i);
                });
          }));

  // ─── OUTFIT GRID (real posts — first 3 shown as cards) ─────────────────────
  Widget _outfitGrid(List<LookPost> posts, StyleFeedState state) {
    final display = posts.take(3).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: SizedBox(
          height: 228,
          child: Row(
              children: display.asMap().entries.map((e) {
            final i = e.key;
            final post = e.value;
            final isLiked = state.likedIds.contains(post.id);
            return Expanded(
                child: Padding(
                    padding:
                        EdgeInsets.only(right: i < display.length - 1 ? 8 : 0),
                    child: _PostCard(
                      imageUrl: post.imagePath ?? '',
                      label: post.caption ?? '',
                      likes: _fmt(post.likeCount),
                      comments: _fmt(post.commentCount),
                      timeAgo: _timeAgo(post.createdAt),
                      userName: post.userName,
                      avatarUrl: post.userAvatarUrl,
                      isLiked: isLiked,
                      onTap: () => _goToTryOn(post.imagePath),
                    ).animate().fadeIn(
                        duration: 300.ms,
                        delay: Duration(milliseconds: i * 70))));
          }).toList()),
        ),
      ),
      const SizedBox(height: 8),
      Align(
          alignment: Alignment.centerRight,
          child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: _ViewAllBtn(
                  onTap: () => Navigator.of(context).pushNamed(_rStyleFeed)))),
    ]);
  }

  // ─── TRENDS GRID (trending posts by like count — top 3) ────────────────────
  Widget _trendsGrid(List<LookPost> posts, StyleFeedState state) {
    // Sort by likes descending for trending
    final sorted = [...posts]
      ..sort((a, b) => b.likeCount.compareTo(a.likeCount));
    final display = sorted.take(3).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: SizedBox(
          height: 228,
          child: Row(
              children: display.asMap().entries.map((e) {
            final i = e.key;
            final post = e.value;
            return Expanded(
                child: Padding(
                    padding:
                        EdgeInsets.only(right: i < display.length - 1 ? 8 : 0),
                    child: _PostCard(
                      imageUrl: post.imagePath ?? '',
                      label: post.caption ?? '',
                      likes: _fmt(post.likeCount),
                      comments: _fmt(post.commentCount),
                      timeAgo: _timeAgo(post.createdAt),
                      onTap: () => _goToTryOn(post.imagePath),
                    ).animate().fadeIn(
                        duration: 300.ms,
                        delay: Duration(milliseconds: i * 70))));
          }).toList()),
        ),
      ),
      const SizedBox(height: 8),
      Align(
          alignment: Alignment.centerRight,
          child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: _ViewAllBtn(
                  onTap: () => Navigator.of(context).pushNamed(_rStyleFeed)))),
    ]);
  }

  // ─── FILTER ROW ────────────────────────────────────────────────────────────
  Widget _filterRow() => SizedBox(
      height: 38,
      child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: _trendFilters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final (icon, label) = _trendFilters[i];
            return _FilterPill(
                icon: icon,
                label: label,
                selected: _trendFilt == i,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _trendFilt = i);
                });
          }));

  // ─── EMPTY OUTFITS ─────────────────────────────────────────────────────────
  Widget _emptyOutfits() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      child: Center(
          child: Column(children: [
        Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: _blue.withOpacity(0.1)),
            child: Icon(Icons.photo_camera_rounded,
                size: 32, color: _blue.withOpacity(0.7))),
        const SizedBox(height: 16),
        const Text('No outfits yet',
            style: TextStyle(
                color: _darkText, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Be the first to post a look!',
            style: TextStyle(color: _midText, fontSize: 12)),
        const SizedBox(height: 16),
        GestureDetector(
            onTap: _goToPostLook,
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                decoration: BoxDecoration(
                    color: _blue, borderRadius: BorderRadius.circular(10)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text('Post a Look',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ]))),
      ])));

  // ─── BOTTOM NAV ────────────────────────────────────────────────────────────
  Widget _navBar(MediaQueryData mq, int unread) {
    return Container(
        height: 84.0 + mq.padding.bottom,
        decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
                top: BorderSide(color: Color(0xFFCCDDEE), width: 1)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 14,
                  offset: const Offset(0, -3))
            ]),
        child: SafeArea(
            top: false,
            child: Stack(alignment: Alignment.center, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                // NX Chat minimized pill
                _NxChatBar(onTap: () => Navigator.pushNamed(context, _rChat)),

                // Centre spacer
                const SizedBox(width: 62),

                // Messages / Friends Space (active tab)
                GestureDetector(
                    onTap: () => setState(() => _navIndex = 3),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(clipBehavior: Clip.none, children: [
                            Icon(Icons.people_outline,
                                size: 26,
                                color: _navIndex == 3
                                    ? const Color(0xFF0B1D4C)
                                    : const Color(0xFF7A9ABB)),
                            if (unread > 0)
                              Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                      width: 17,
                                      height: 17,
                                      decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle),
                                      child: Center(
                                          child: Text('$unread',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight:
                                                      FontWeight.bold))))),
                          ]),
                          const SizedBox(height: 3),
                          Text('Messages',
                              style: TextStyle(
                                  color: _navIndex == 3
                                      ? const Color(0xFF0B1D4C)
                                      : const Color(0xFF7A9ABB),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ])),

                // Shopping
                GestureDetector(
                    onTap: () {
                      setState(() => _navIndex = 4);
                      Navigator.pushNamed(context, _rShopping);
                    },
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined,
                              size: 26,
                              color: _navIndex == 4
                                  ? const Color(0xFF0B1D4C)
                                  : const Color(0xFF7A9ABB)),
                          const SizedBox(height: 3),
                          Text('Shopping',
                              style: TextStyle(
                                  color: _navIndex == 4
                                      ? const Color(0xFF0B1D4C)
                                      : const Color(0xFF7A9ABB),
                                  fontSize: 10)),
                        ])),
              ]),

              // Floating NX centre button
              Positioned(
                  top: -20,
                  child: GestureDetector(
                      onTap: () {
                        setState(() => _navIndex = 2);
                        Navigator.pushNamed(context, _rWardrobe);
                      },
                      child: _NxNavBtn(active: _navIndex == 2))),
            ])));
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────
  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return '$n';
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours} hr';
    if (diff.inMinutes >= 1) return '${diff.inMinutes} min';
    return 'now';
  }
}

// Backward-compat alias for routes.dart
typedef StyleFeedScreen = FriendsSpaceScreen;

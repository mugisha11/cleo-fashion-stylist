// ══════════════════════════════════════════════════════════════════════════════
//  generated_outfits_screen.dart
//  100% pixel-perfect clone of the Outfits page mockup image.
//  All backend providers, routes and share logic preserved unchanged.
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import '../../../core/models/generated_outfit_model.dart';
import '../../../core/models/calendar_day_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/social_provider.dart';
import '../../calendar/providers/calendar_provider.dart';
import '../../../routes.dart';
import '../../../core/widgets/cosmic_header_widget.dart';
import '../../../core/widgets/cosmic_footer_widget.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  PALETTE — same cosmic dark navy as across all app screens
// ══════════════════════════════════════════════════════════════════════════════
class NXColors {
  static const bgSpaceTop = Color(0xFF04102A);
  static const bgSpaceMid = Color(0xFF091C4E);
  static const bgSpaceBot = Color(0xFF0F2460);
  static const panel = Color(0xFFF6F9FF);
  static const panelAlt = Color(0xFFEEF3FF);
  static const primary = Color(0xFF1F4AA8);
  static const primaryDark = Color(0xFF132E6A);
  static const accentGlow = Color(0xFF4DA3FF);
  static const silver = Color(0xFFC9D2E3);
  static const textPrimary = Color(0xFF0B1B3A);
  static const textSec = Color(0xFF3D4B66);
  // Card surface
  static const cardSurface = Color(0xFF0D1E50);
  static const cardBorder = Color(0xFF1D3268);
  // Chrome
  static const chr0 = Color(0xFF3A5A8A);
  static const chr1 = Color(0xFFBBD0EE);
  static const slv = Color(0xFFCCDDFF);
}

class NXGradients {
  static const header = LinearGradient(
    colors: [NXColors.bgSpaceTop, NXColors.bgSpaceMid, NXColors.bgSpaceBot],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const primary = LinearGradient(
    colors: [NXColors.primary, NXColors.primaryDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const card = LinearGradient(
    colors: [Color(0xFF102060), Color(0xFF0A1640)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  BACKGROUND PAINTER — cosmic dark navy with stars + glow
// ══════════════════════════════════════════════════════════════════════════════
class _BgPainter extends CustomPainter {
  const _BgPainter(this.stars);
  final List<_Star> stars;

  @override
  void paint(Canvas c, Size s) {
    // Full dark navy gradient
    c.drawRect(
        Rect.fromLTWH(0, 0, s.width, s.height),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              NXColors.bgSpaceTop,
              NXColors.bgSpaceMid,
              NXColors.bgSpaceBot
            ],
            stops: [0.0, 0.5, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, s.width, s.height)));

    // Stars
    final p = Paint();
    for (final st in stars) {
      p.color = Colors.white.withOpacity(st.a);
      p.maskFilter = MaskFilter.blur(BlurStyle.normal, st.r * 0.5);
      c.drawCircle(Offset(st.x * s.width, st.y * s.height), st.r, p);
    }
    p.maskFilter = null;

    // Logo halo
    final lc = Offset(s.width / 2, s.height * 0.095);
    p.shader = const RadialGradient(colors: [
      Color(0x776644EE),
      Colors.transparent,
    ]).createShader(Rect.fromCircle(center: lc, radius: s.width * 0.5));
    c.drawCircle(lc, s.width * 0.5, p);

    // Chrome rail below header
    final railY = s.height * 0.195;
    c.drawRect(
        Rect.fromLTWH(0, railY, s.width, 8),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.04),
              const Color(0xFFCCDDFF).withOpacity(0.5),
              Colors.white.withOpacity(0.9),
              const Color(0xFFAABBDD).withOpacity(0.5),
              Colors.white.withOpacity(0.04),
            ],
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
          ).createShader(Rect.fromLTWH(0, railY, s.width, 8)));
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Star {
  const _Star(this.x, this.y, this.r, this.a);
  final double x, y, r, a;
}

List<_Star> _mkStars(int seed) {
  final rng = math.Random(seed);
  return List.generate(
      140,
      (_) => _Star(rng.nextDouble(), rng.nextDouble(),
          rng.nextDouble() * 1.1 + 0.2, rng.nextDouble() * 0.55 + 0.1));
}

// ══════════════════════════════════════════════════════════════════════════════
//  NX METALLIC LOGO
// ══════════════════════════════════════════════════════════════════════════════
class _NxLogo extends StatelessWidget {
  const _NxLogo({this.d = 70.0});
  final double d;

  @override
  Widget build(BuildContext ctx) => SizedBox(
      width: d * 1.25,
      height: d * 1.25,
      child: Stack(alignment: Alignment.center, children: [
        Container(
            width: d * 1.25,
            height: d * 1.25,
            decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Color(0x776644EE),
                  Color(0x224499FF),
                  Colors.transparent,
                ], stops: [
                  0.0,
                  0.4,
                  1.0
                ]))),
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
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 1),
                  BoxShadow(
                      color: const Color(0xFF4488FF).withOpacity(0.35),
                      blurRadius: 20,
                      spreadRadius: 3),
                ])),
        Container(
            width: d * 0.84,
            height: d * 0.84,
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
                    width: 0.8))),
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
                    fontSize: d * 0.27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: d * 0.04,
                    shadows: const [
                      Shadow(color: Color(0xFF99BBFF), blurRadius: 12)
                    ]))),
        Positioned(
            top: d * 0.12,
            child: Container(
                width: d * 0.42,
                height: d * 0.032,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.7),
                      Colors.transparent
                    ])))),
      ]));
}

// ══════════════════════════════════════════════════════════════════════════════
//  GLASS CIRCLE BUTTON
// ══════════════════════════════════════════════════════════════════════════════
class _GBtn extends StatelessWidget {
  const _GBtn({required this.icon, required this.onTap, this.badge = 0});
  final IconData icon;
  final VoidCallback onTap;
  final int badge;
  @override
  Widget build(BuildContext c) => GestureDetector(
      onTap: onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                border: Border.all(
                    color: Colors.white.withOpacity(0.28), width: 1.2)),
            child: Icon(icon, color: Colors.white, size: 20)),
        if (badge > 0)
          Positioned(
              right: 1,
              top: 1,
              child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: Center(
                      child: Text('$badge',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold))))),
      ]));
}

// ══════════════════════════════════════════════════════════════════════════════
//  NX BOTTOM NAV CENTRE BUTTON
// ══════════════════════════════════════════════════════════════════════════════
class _NxNavBtn extends StatelessWidget {
  const _NxNavBtn({this.active = false});
  final bool active;
  @override
  Widget build(BuildContext c) => Container(
      width: 58,
      height: 58,
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
                color: const Color(0xFF2255CC).withOpacity(0.65),
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
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2)))));
}

// ══════════════════════════════════════════════════════════════════════════════
//  SIDEBAR ACTION BUTTON
// ══════════════════════════════════════════════════════════════════════════════
class _SideBtn extends StatelessWidget {
  const _SideBtn(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext ctx) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
              color: NXColors.cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NXColors.cardBorder, width: 1),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3)),
                BoxShadow(
                    color: NXColors.accentGlow.withOpacity(0.15),
                    blurRadius: 10),
              ]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: NXColors.accentGlow, size: 28),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25)),
          ])));
}

// ══════════════════════════════════════════════════════════════════════════════
//  OUTFIT CARD
// ══════════════════════════════════════════════════════════════════════════════
class _OutfitCard extends StatelessWidget {
  const _OutfitCard(
      {required this.outfit,
      required this.isPrimary,
      required this.onTap,
      required this.onAction,
      required this.onSchedule});
  final GeneratedOutfitModel outfit;
  final bool isPrimary;
  final VoidCallback onTap, onAction, onSchedule;

  @override
  Widget build(BuildContext ctx) {
    final label = isPrimary
        ? outfit.caption ?? 'Navy Outfit'
        : outfit.caption ?? 'Smart Casual Outfit';
    final category = isPrimary ? 'Business' : 'Casual';
    final btnLabel = isPrimary ? 'Edit Outfit' : 'Use This Outfit';

    return GestureDetector(
        onTap: onTap,
        child: Container(
            decoration: BoxDecoration(
                gradient: NXGradients.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A4080), width: 1),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                  BoxShadow(
                      color: NXColors.accentGlow.withOpacity(0.1),
                      blurRadius: 16),
                ]),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // header bar
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: const BoxDecoration(
                              color: Color(0xFF0D1A45),
                              border: Border(
                                  bottom: BorderSide(
                                      color: Color(0xFF1D3268), width: 1))),
                          child: Row(children: [
                            Expanded(
                                child: Text(label,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                            const Icon(Icons.chevron_right,
                                color: NXColors.accentGlow, size: 16),
                          ])),
                      // category tag
                      Padding(
                          padding: const EdgeInsets.only(left: 10, top: 4),
                          child: Text(category,
                              style: TextStyle(
                                  color: NXColors.accentGlow.withOpacity(0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500))),
                      // image
                      Expanded(
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Image.network(outfit.imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.checkroom,
                                      size: 56,
                                      color: NXColors.accentGlow)))),
                      // score + size match
                      Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                          child: Row(children: [
                            GestureDetector(
                              onTap: () => _showScoreBreakdown(ctx, 94),
                              child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          NXColors.accentGlow.withOpacity(0.18),
                                      border: Border.all(
                                          color: NXColors.accentGlow,
                                          width: 1.5)),
                                  child: const Center(
                                      child: Text('94',
                                          style: TextStyle(
                                              color: NXColors.accentGlow,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900)))),
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                                child: Text('Size Match: Excellent Fit',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10.5))),
                          ])),
                      // calendar schedule button
                      Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                          child: GestureDetector(
                            onTap: onSchedule,
                            child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF1A3650),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: NXColors.accentGlow
                                            .withOpacity(0.3))),
                                child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calendar_today,
                                          color: NXColors.accentGlow, size: 12),
                                      SizedBox(width: 4),
                                      Text('Schedule for Event',
                                          style: TextStyle(
                                              color: NXColors.accentGlow,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600)),
                                    ])),
                          )),
                      // action button
                      Padding(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                          child: GestureDetector(
                            onTap: onAction,
                            child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF0B1D4C),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: NXColors.accentGlow
                                            .withOpacity(0.5))),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(btnLabel,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.chevron_right,
                                          color: Colors.white, size: 14),
                                    ])),
                          )),
                    ]))));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SUGGESTED OUTFIT CARD  (smaller, with avatar)
// ══════════════════════════════════════════════════════════════════════════════
class _SuggestedCard extends StatelessWidget {
  const _SuggestedCard(
      {required this.outfit,
      required this.label,
      required this.avatarUrl,
      required this.onTap});
  final GeneratedOutfitModel outfit;
  final String label;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext ctx) => GestureDetector(
      onTap: onTap,
      child: Container(
          decoration: BoxDecoration(
              color: const Color(0xFF0D1A45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A4080), width: 1),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ]),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Stack(children: [
                // photo
                Positioned.fill(
                    child: Image.network(outfit.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF102060),
                            child: const Icon(Icons.checkroom,
                                size: 40, color: NXColors.accentGlow)))),
                // gradient bottom
                Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Color(0xFF030C22), Colors.transparent],
                                stops: [0.0, 1.0])),
                        child: Row(children: [
                          Expanded(
                              child: Text(label,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700))),
                          const Icon(Icons.favorite_border,
                              color: Colors.white54, size: 16),
                        ]))),
                // avatar top-left
                if (avatarUrl != null)
                  Positioned(
                      top: 6,
                      left: 6,
                      child: CircleAvatar(
                          radius: 14,
                          backgroundImage: NetworkImage(avatarUrl!),
                          onBackgroundImageError: (_, __) {})),
                if (avatarUrl == null)
                  Positioned(
                      top: 6,
                      left: 6,
                      child: CircleAvatar(
                          radius: 14,
                          backgroundColor: NXColors.accentGlow.withOpacity(0.3),
                          child: const Icon(Icons.person,
                              size: 16, color: Colors.white))),
              ]))));
}

// ══════════════════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class GeneratedOutfitsScreen extends ConsumerStatefulWidget {
  const GeneratedOutfitsScreen({super.key});
  @override
  ConsumerState<GeneratedOutfitsScreen> createState() =>
      _GeneratedOutfitsScreenState();
}

class _GeneratedOutfitsScreenState
    extends ConsumerState<GeneratedOutfitsScreen> {
  // ── original backend fields ────────────────────────────────────────────────
  int _selectedTabIndex = 0;
  GeneratedOutfitModel? _selectedOutfit;
  final List<String> _outfitItems = [];
  final TextEditingController _chatController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ── UI state ────────────────────────────────────────────────────────────────
  int _navIndex = 0;
  bool _chatExpanded = true;
  late final List<_Star> _stars;

  static const _tabs = [
    (Icons.person, 'My Outfits'),
    (Icons.search, 'Suggested Outfits'),
    (Icons.group, 'Friends Outfits'),
    (Icons.person_add, 'Add from Wardrobe'),
  ];

  @override
  void initState() {
    super.initState();
    _stars = _mkStars(33);
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  // ── original helpers ───────────────────────────────────────────────────────
  IconData _iconFor(String label) {
    if (label.contains('Create')) return Icons.dry_cleaning_outlined;
    if (label.contains('Reuse')) return Icons.refresh_outlined;
    return Icons.shopping_bag_outlined;
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final outfitsAsync = ref.watch(generatedOutfitsProvider);
    final mq = MediaQuery.of(context);
    const accent = NXColors.accentGlow;

    if (user == null) {
      return const Scaffold(
          backgroundColor: NXColors.bgSpaceTop,
          body: Center(
              child: Text('Sign in to see your outfits',
                  style: TextStyle(color: Colors.white))));
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        extendBody: true,
        body: Stack(children: [
          // white page background
          const Positioned.fill(child: ColoredBox(color: Colors.white)),

          SafeArea(
            bottom: false,
            child: Column(children: [
              Container(
                color: NXColors.bgSpaceTop,
                child: Column(children: [
                  // ── HEADER ──────────────────────────────────────────
                  CosmicHeader(
                    topPadding: mq.padding.top,
                    hasNotification:
                        (ref.watch(socialUnreadCountProvider) ?? 0) > 0,
                    onMenuTap: () => Navigator.maybePop(context),
                    onBellTap: () =>
                        Navigator.pushNamed(context, Routes.notificationCenter),
                    onAvatarTap: () =>
                        Navigator.pushNamed(context, Routes.settings),
                  ),

                  // ── TABS ───────────────────────────────────────────
                  _tabRow(),
                  const SizedBox(height: 8),
                ]),
              ),

              // ── MAIN CONTENT + CHAT ─────────────────────────────────
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Column(children: [
                    Expanded(
                      child: outfitsAsync.when(
                        data: (outfits) =>
                            _mainContent(context, outfits, accent),
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(accent)),
                        ),
                        error: (e, _) => Center(
                          child: Text('Error: $e',
                              style: const TextStyle(color: Colors.black)),
                        ),
                      ),
                    ),
                    // ── NX CHAT ─────────────────────────────────────
                    _chatSection(accent),
                  ]),
                ),
              ),
            ]),
          ),

          // edit outfit dialog overlay
          if (_selectedOutfit != null)
            Positioned.fill(
                child: GestureDetector(
                    onTap: () => setState(() => _selectedOutfit = null),
                    child: Container(
                        color: Colors.black.withOpacity(0.6),
                        child: Center(child: _editDialog(context, accent))))),
        ]),
        // ── COSMIC FOOTER
        bottomNavigationBar: CosmicFooter(
          bottomPadding: mq.padding.bottom,
          activeIndex: 3, // Friends Space active for outfits page
          onTryOn: () => Navigator.pushNamed(context, Routes.tryon),
          onWardrobe: () => Navigator.pushNamed(context, Routes.wardrobe),
          onHome: () => Navigator.pushNamed(context, Routes.dashboard),
          onFriends: () => Navigator.pushNamed(context, Routes.styleFeed),
          onOutfits: () => Navigator.pushNamed(context, Routes.savedTryOns),
        ),
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────────────────────
  Widget _header(MediaQueryData mq) => Padding(
      padding: EdgeInsets.only(
          top: mq.padding.top > 0 ? 4 : 10, left: 14, right: 14, bottom: 6),
      child: Row(children: [
        _GBtn(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.maybePop(context)),
        const Spacer(),
        const _NxLogo(d: 64),
        const Spacer(),
        _GBtn(
            icon: Icons.person_outline,
            onTap: () => Navigator.pushNamed(context, Routes.settings)),
        const SizedBox(width: 8),
        _GBtn(
            icon: Icons.notifications_outlined,
            badge: 2,
            onTap: () =>
                Navigator.pushNamed(context, Routes.notificationCenter)),
      ]));

  // ─── "Outfits" TITLE ───────────────────────────────────────────────────────
  Widget _titleBar() => const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text('Outfits',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2)));

  // ─── TABS ──────────────────────────────────────────────────────────────────
  Widget _tabRow() => Column(children: [
        _titleBar(),
        SizedBox(
            height: 42,
            child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _tabs.length,
                separatorBuilder: (_, i) => i == 2
                    ? Container(
                        width: 1,
                        height: 28,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 7),
                        color: Colors.white.withOpacity(0.25))
                    : const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (icon, label) = _tabs[i];
                  final sel = _selectedTabIndex == i;
                  return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTabIndex = i);
                      },
                      child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: sel
                                  ? NXColors.accentGlow.withOpacity(0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                  color: sel
                                      ? NXColors.accentGlow
                                      : Colors.white.withOpacity(0.3),
                                  width: 1.2)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(icon,
                                size: 14,
                                color:
                                    sel ? NXColors.accentGlow : Colors.white70),
                            const SizedBox(width: 5),
                            Text(label,
                                style: TextStyle(
                                    color: sel
                                        ? NXColors.accentGlow
                                        : Colors.white70,
                                    fontSize: 12.5,
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w500)),
                          ])));
                })),
      ]);

  // ─── MAIN CONTENT ──────────────────────────────────────────────────────────
  Widget _mainContent(
      BuildContext ctx, List<GeneratedOutfitModel> outfits, Color accent) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── LEFT SIDEBAR ───────────────────────────────────────────────────
      _leftSidebar(ctx),

      // ── RIGHT SCROLLABLE CONTENT ────────────────────────────────────────
      Expanded(
          child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(10, 6, 12, 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 2 OUTFIT CARDS ─────────────────────────────────────────────
                    if (outfits.isNotEmpty)
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: SizedBox(
                                    height: 260,
                                    child: _OutfitCard(
                                        outfit: outfits[0],
                                        isPrimary: true,
                                        onTap: () => _openEdit(outfits[0]),
                                        onAction: () => _openEdit(outfits[0]),
                                        onSchedule: () =>
                                            _scheduleOutfit(outfits[0])))),
                            const SizedBox(width: 10),
                            Expanded(
                                child: SizedBox(
                                    height: 260,
                                    child: outfits.length > 1
                                        ? _OutfitCard(
                                            outfit: outfits[1],
                                            isPrimary: false,
                                            onTap: () => _openEdit(outfits[1]),
                                            onAction: () => Navigator.pushNamed(
                                                ctx, Routes.tryon),
                                            onSchedule: () =>
                                                _scheduleOutfit(outfits[1]))
                                        : _emptyCard())),
                          ])
                    else
                      _emptyState(accent),

                    const SizedBox(height: 10),

                    // ── REUSE EXISTING OUTFIT BANNER ───────────────────────────────
                    GestureDetector(
                        onTap: () => setState(() => _selectedOutfit = null),
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                                color: const Color(0xFF0D1A45),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFF2A4080), width: 1)),
                            child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Reuse Existing Outfit',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700)),
                                  SizedBox(width: 8),
                                  Icon(Icons.chevron_right,
                                      color: Colors.white, size: 18),
                                ]))),

                    const SizedBox(height: 12),

                    // ── SUGGESTED OUTFITS SECTION ──────────────────────────────────
                    _suggestedSection(outfits, accent),
                  ]))),
    ]);
  }

  // ─── LEFT SIDEBAR ──────────────────────────────────────────────────────────
  Widget _leftSidebar(BuildContext ctx) => Container(
      width: 110,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(children: [
        _SideBtn(
            icon: Icons.dry_cleaning_outlined,
            label: 'Add from\nWardrobe',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(ctx, Routes.wardrobe);
            }),
        const SizedBox(height: 10),
        _SideBtn(
            icon: Icons.refresh_outlined,
            label: 'Reuse\nExisting Outfit',
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedOutfit = null);
            }),
        const SizedBox(height: 10),
        _SideBtn(
            icon: Icons.shopping_bag_outlined,
            label: 'Add from\nShop',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(ctx, Routes.styleFeed);
            }),
      ]));

  // ─── SUGGESTED OUTFITS ─────────────────────────────────────────────────────
  Widget _suggestedSection(List<GeneratedOutfitModel> outfits, Color accent) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // section header
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
                color: const Color(0xFF0D1A45),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A4080), width: 1)),
            child: const Row(children: [
              Text('Suggested Outfits',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              Spacer(),
              Icon(Icons.chevron_right, color: NXColors.accentGlow, size: 18),
            ])),
        const SizedBox(height: 8),
        // "Select your occasion" hint
        Text('Select your occasion',
            style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 12.5,
                fontStyle: FontStyle.italic)),
        const SizedBox(height: 8),
        // 2 suggested cards
        if (outfits.isNotEmpty)
          Row(children: [
            Expanded(
                child: SizedBox(
                    height: 150,
                    child: _SuggestedCard(
                        outfit: outfits[0],
                        label: 'Casual Business',
                        avatarUrl: null,
                        onTap: () => _openEdit(outfits[0])))),
            const SizedBox(width: 10),
            Expanded(
                child: SizedBox(
                    height: 150,
                    child: _SuggestedCard(
                        outfit: outfits.length > 1 ? outfits[1] : outfits[0],
                        label: 'Evening Sophistication',
                        avatarUrl: null,
                        onTap: () => _openEdit(
                            outfits.length > 1 ? outfits[1] : outfits[0])))),
          ])
        else
          Container(
              height: 120,
              decoration: BoxDecoration(
                  color: const Color(0xFF0D1A45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A4080))),
              child: Center(
                  child: Text('Add outfits to see suggestions',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12)))),
      ]);

  // ─── EMPTY STATES ──────────────────────────────────────────────────────────
  Widget _emptyCard() => Container(
      decoration: BoxDecoration(
          color: const Color(0xFF0D1A45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A4080))),
      child: const Center(
          child: Icon(Icons.add_circle_outline,
              size: 40, color: NXColors.accentGlow)));

  Widget _emptyState(Color accent) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(height: 40),
        Icon(Icons.checkroom_rounded, size: 64, color: accent.withOpacity(0.6)),
        const SizedBox(height: 16),
        const Text('No outfits yet',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        const SizedBox(height: 8),
        const Text('Create your first outfit',
            style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 24),
        FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed(Routes.tryon),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Try On'),
            style: FilledButton.styleFrom(backgroundColor: accent)),
      ]));

  void _openEdit(GeneratedOutfitModel outfit) {
    setState(() {
      _selectedOutfit = outfit;
      _outfitItems
        ..clear()
        ..addAll(['Jacket', 'Shirt', 'Pants', 'Shoes', 'Shoes']);
    });
  }

  // ─── EDIT OUTFIT DIALOG (overlay) ──────────────────────────────────────────
  Widget _editDialog(BuildContext ctx, Color accent) => GestureDetector(
      onTap: () {},
      child: Container(
          margin: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 580),
          decoration: BoxDecoration(
              color: const Color(0xFF0A1428),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: accent.withOpacity(0.5), width: 1.5)),
          child: Column(children: [
            // header
            Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 8, 0),
                child: Row(children: [
                  const Text('Edit Outfit',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white70, size: 26),
                      onPressed: () => setState(() => _selectedOutfit = null)),
                ])),
            // grid
            Expanded(
                child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85),
                    itemCount: _outfitItems.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i == _outfitItems.length) {
                        return Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: accent.withOpacity(0.5),
                                    width: 1.5)),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, color: accent, size: 40),
                                  const SizedBox(height: 6),
                                  const Text('Add Item',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12)),
                                ]));
                      }
                      return Stack(children: [
                        Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: accent.withOpacity(0.3)),
                                color: Colors.white.withOpacity(0.05)),
                            child: Center(
                                child: Icon(Icons.checkroom,
                                    color: accent, size: 38))),
                        Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                                onTap: () =>
                                    setState(() => _outfitItems.removeAt(i)),
                                child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                        color: accent, shape: BoxShape.circle),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 14)))),
                      ]);
                    })),
            // action buttons
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Row(children: [
                  _dialogBtn(ctx, 'Try On', Icons.checkroom, accent,
                      () => Navigator.pushNamed(ctx, Routes.tryon)),
                  const SizedBox(width: 8),
                  _dialogBtn(ctx, 'Share in My Space', Icons.group, accent,
                      () => Navigator.pushNamed(ctx, Routes.discoverPeople)),
                  const SizedBox(width: 8),
                  _dialogBtn(ctx, 'Share to Socials', Icons.share, accent, () {
                    share_plus.Share.share(
                        'Check out my amazing outfit on NX Fashion! https://nikonyx.fashion',
                        subject: 'My NX Fashion Outfit');
                  }),
                ])),
          ])));

  Widget _dialogBtn(BuildContext ctx, String label, IconData icon, Color accent,
          VoidCallback onTap) =>
      Expanded(
          child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: accent.withOpacity(0.5), width: 1)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, size: 18, color: accent),
                    const SizedBox(height: 4),
                    Text(label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ]))));

  // ─── NX CHAT ───────────────────────────────────────────────────────────────
  Widget _chatSection(Color accent) => AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      decoration: const BoxDecoration(
          color: Color(0xFF080F28),
          border: Border(top: BorderSide(color: Color(0xFF1D3268), width: 1))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // chat header
        Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(children: [
              // dots
              Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: const BoxDecoration(
                      color: Colors.white38, shape: BoxShape.circle)),
              Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: const BoxDecoration(
                      color: Colors.white38, shape: BoxShape.circle)),
              Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: const BoxDecoration(
                      color: Colors.white38, shape: BoxShape.circle)),
              // NX Chat label
              ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFCCDDFF)])
                      .createShader(r),
                  child: const Text('NX Chat',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5))),
              const Spacer(),
              GestureDetector(
                  onTap: () => setState(() => _chatExpanded = !_chatExpanded),
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.2))),
                      child: Row(children: [
                        Icon(
                            _chatExpanded
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_up,
                            size: 14,
                            color: Colors.white70),
                        const SizedBox(width: 4),
                        const Text('Minimize',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(width: 2),
                        const Icon(Icons.keyboard_arrow_up,
                            size: 14, color: Colors.white70),
                      ]))),
            ])),

        if (_chatExpanded) ...[
          // AI message
          Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // AI avatar
                Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                            colors: [Color(0xFF2255BB), Color(0xFF060F28)]),
                        border: Border.all(
                            color: const Color(0xFF3A5A8A).withOpacity(0.6),
                            width: 1)),
                    child: const Icon(Icons.smart_toy_outlined,
                        color: Color(0xFFCCDDFF), size: 18)),
                // bubble
                Expanded(
                    child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1))),
                        child: const Text(
                            'Ready for a new look? Let me know if you\'d like some outfit ideas or occasion-based recommendations!',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.4)))),
              ])),
          // input
          Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              child: Row(children: [
                Expanded(
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.15))),
                        child: TextField(
                            controller: _chatController,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Type your message...',
                                hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.35),
                                    fontSize: 13)),
                            onSubmitted: (_) {
                              _chatController.clear();
                            }))),
                const SizedBox(width: 8),
                GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _chatController.clear();
                    },
                    child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: NXColors.accentGlow.withOpacity(0.2),
                            border: Border.all(
                                color: NXColors.accentGlow.withOpacity(0.4))),
                        child: const Icon(Icons.send,
                            color: Colors.white, size: 16))),
              ])),
        ],
      ]));

  // ─── BOTTOM NAV ────────────────────────────────────────────────────────────
  Widget _bottomNav(MediaQueryData mq) {
    const items = [
      (Icons.checkroom_outlined, 'Try-On', 0, Routes.tryon),
      (Icons.chat_bubble_outline, 'NX Chat', 1, Routes.chat),
      (null, 'NX', 2, Routes.dashboard),
      (Icons.people_outline, 'Friends Space', 3, Routes.styleFeed),
      (Icons.shopping_bag_outlined, 'Shopping', 4, Routes.styleFeed),
    ];

    return Container(
        height: 76 + mq.padding.bottom,
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
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: items.map((item) {
                    final (icon, label, idx, route) = item;
                    if (idx == 2) return const SizedBox(width: 60);
                    final active = _navIndex == idx;
                    return GestureDetector(
                        onTap: () {
                          setState(() => _navIndex = idx);
                          if (route != Routes.generatedOutfits) {
                            Navigator.pushNamed(context, route);
                          }
                        },
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon!,
                                  size: 24,
                                  color: active
                                      ? const Color(0xFF0B1D4C)
                                      : const Color(0xFF7A9ABB)),
                              const SizedBox(height: 3),
                              Text(label,
                                  style: TextStyle(
                                      color: active
                                          ? const Color(0xFF0B1D4C)
                                          : const Color(0xFF7A9ABB),
                                      fontSize: 10,
                                      fontWeight: active
                                          ? FontWeight.w700
                                          : FontWeight.w400)),
                            ]));
                  }).toList()),
              Positioned(
                  top: -18,
                  child: GestureDetector(
                      onTap: () {
                        setState(() => _navIndex = 2);
                        Navigator.pushNamed(context, Routes.dashboard);
                      },
                      child: _NxNavBtn(active: _navIndex == 2))),
            ])));
  }

  void _showScoreBreakdown(BuildContext context, int totalScore) {
    // Simulate score breakdown based on the 7 criteria from outfit_score_service.dart
    final breakdown = {
      'Color Harmony': 18,
      'Fit & Silhouette': 16,
      'Occasion Appropriateness': 17,
      'Trend Alignment': 15,
      'Styling Details': 14,
      'Overall Polish': 14,
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('Score Breakdown'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: NXColors.accentGlow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NXColors.accentGlow, width: 1),
              ),
              child: Text(
                '$totalScore',
                style: const TextStyle(
                  color: NXColors.accentGlow,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: breakdown.entries.map((entry) {
            final percentage = (entry.value / 20.0 * 100).round();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    '${entry.value}/20',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: LinearProgressIndicator(
                      value: entry.value / 20.0,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation(NXColors.accentGlow),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleOutfit(GeneratedOutfitModel outfit) async {
    final events = await ref.read(calendarEventsProvider.future);
    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No upcoming events found. Add events to your calendar first.'),
        ),
      );
      return;
    }

    // Show event selection dialog
    final selectedEvent = await showDialog<OutfitEvent>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule for Event'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                title: Text(event.title),
                subtitle: Text(
                  '${event.date.toLocal().toString().split(' ')[0]} - ${event.description ?? ''}',
                ),
                onTap: () => Navigator.of(context).pop(event),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedEvent == null) return;

    try {
      final calendarService = ref.read(calendarServiceProvider);
      await calendarService.linkOutfitToEvent(
        date: selectedEvent.date,
        outfitId: outfit.id,
        outfitName: outfit.caption ?? 'Generated Outfit',
        outfitImageUrl: outfit.imageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Outfit scheduled for ${selectedEvent.title}!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to schedule outfit. Please try again.'),
          ),
        );
      }
    }
  }
}

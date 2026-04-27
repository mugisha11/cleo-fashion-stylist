// ══════════════════════════════════════════════════════════════════════════════
//  modern_home_screen.dart
//  UI: 100% pixel-perfect clone of the Nikonyx dashboard mockup image.
//  Backend: ALL original providers, routes and speech logic preserved.
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/fashion_drawer.dart';
import '../../../routes.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  PALETTE — exact match to the image
// ══════════════════════════════════════════════════════════════════════════════
class _C {
  // Hero dark navy
  static const heroTop   = Color(0xFF04102A);
  static const heroMid   = Color(0xFF091C4E);
  static const heroBot   = Color(0xFF0F2460);
  // Body light silver-blue
  static const bodyBg    = Color(0xFFD8E4F4);
  static const bodyMid   = Color(0xFFC4D4EC);
  // Dark navy cards / bars
  static const cardBg    = Color(0xFF0B1D4C);
  static const cardBdr   = Color(0xFF1D3268);
  // Chrome / silver
  static const chr0      = Color(0xFF3A5A8A);
  static const chr1      = Color(0xFFBBD0EE);
  static const slv       = Color(0xFFCCDDFF);
  // Accent
  static const blue      = Color(0xFF2050C8);
  static const blueGlow  = Color(0xFF4488FF);
  // Text on light bg
  static const dark      = Color(0xFF0A1830);
  static const mid       = Color(0xFF3A5A8A);
  static const light     = Color(0xFF7A9ABB);
  // Nav bar
  static const navBg     = Colors.white;
  static const navBdr    = Color(0xFFCCDDEE);
}

// ══════════════════════════════════════════════════════════════════════════════
//  BACKGROUND PAINTER  —  hero (top 40%) dark navy + body light + chrome rail
// ══════════════════════════════════════════════════════════════════════════════
class _BgPainter extends CustomPainter {
  const _BgPainter();
  static const double _hFrac = 0.40;

  @override
  void paint(Canvas c, Size s) {
    final heroH = s.height * _hFrac;

    // Dark navy hero
    c.drawRect(Rect.fromLTWH(0, 0, s.width, heroH),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [_C.heroTop, _C.heroMid, _C.heroBot],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, s.width, heroH)));

    // Light body
    c.drawRect(Rect.fromLTWH(0, heroH, s.width, s.height - heroH),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFD8E4F4), Color(0xFFC0D0E8)],
      ).createShader(Rect.fromLTWH(0, heroH, s.width, s.height - heroH)));

    // Logo glow halo
    final lc = Offset(s.width / 2, heroH * 0.28);
    c.drawCircle(lc, s.width * 0.52,
      Paint()..shader = const RadialGradient(colors: [
        Color(0x886699EE), Colors.transparent,
      ]).createShader(Rect.fromCircle(center: lc, radius: s.width * 0.52)));

    // Light rays
    final ray = Paint()..shader = const RadialGradient(colors: [
      Color(0x44AABBFF), Colors.transparent,
    ]).createShader(Rect.fromCircle(center: lc, radius: s.width * 0.9));
    for (int i = 0; i < 14; i++) {
      final a = i * math.pi / 7;
      final path = Path()
        ..moveTo(lc.dx, lc.dy)
        ..lineTo(lc.dx + math.cos(a) * s.width * 0.9,
                 lc.dy + math.sin(a) * s.width * 0.9)
        ..lineTo(lc.dx + math.cos(a + 0.03) * s.width * 0.9,
                 lc.dy + math.sin(a + 0.03) * s.width * 0.9);
      c.drawPath(path, ray);
    }

    // Chrome rail at hero/body boundary
    final railY = heroH - 5;
    c.drawRect(Rect.fromLTWH(0, railY, s.width, 10),
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.04),
          const Color(0xFFCCDDFF).withOpacity(0.6),
          Colors.white.withOpacity(0.95),
          const Color(0xFFAABBDD).withOpacity(0.6),
          Colors.white.withOpacity(0.04),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, railY, s.width, 10)));
  }

  @override bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
//  NX METALLIC LOGO
// ══════════════════════════════════════════════════════════════════════════════
class _NxLogo extends StatelessWidget {
  const _NxLogo({this.d = 90.0});
  final double d;

  @override
  Widget build(BuildContext ctx) => SizedBox(
    width: d * 1.3, height: d * 1.3,
    child: Stack(alignment: Alignment.center, children: [
      // bloom
      Container(width: d * 1.3, height: d * 1.3,
        decoration: const BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            Color(0x886699EE), Color(0x224499FF), Colors.transparent,
          ], stops: [0.0, 0.4, 1.0]))),
      // chrome ring
      Container(width: d, height: d,
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: const SweepGradient(colors: [
            Color(0xFF2A4A7A), Color(0xFFAABBDD), Color(0xFFEEF5FF),
            Color(0xFFCCDDFF), Color(0xFF6688BB), Color(0xFFDDEEFF),
            Color(0xFF4466AA), Color(0xFF2A4A7A),
          ]),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.55), blurRadius: 14, spreadRadius: 2),
            BoxShadow(color: const Color(0xFF4488FF).withOpacity(0.4), blurRadius: 28, spreadRadius: 4),
          ])),
      // inner disc
      Container(width: d * 0.84, height: d * 0.84,
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: const RadialGradient(center: Alignment(-0.4, -0.4),
            colors: [Color(0xFF2255BB), Color(0xFF0E1F55), Color(0xFF060F28)],
            stops: [0.0, 0.45, 1.0]),
          border: Border.all(color: const Color(0xFF3355AA).withOpacity(0.5), width: 1))),
      // NX text
      ShaderMask(
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFCCDDFF), Color(0xFF8899CC)],
        ).createShader(r),
        child: Text('NX', style: TextStyle(
          color: Colors.white, fontSize: d * 0.26, fontWeight: FontWeight.w900,
          letterSpacing: d * 0.04,
          shadows: const [Shadow(color: Color(0xFF99BBFF), blurRadius: 16)]))),
      // top arc
      Positioned(top: d * 0.12, child: Container(
        width: d * 0.42, height: d * 0.034,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(99),
          gradient: LinearGradient(colors: [
            Colors.transparent, Colors.white.withOpacity(0.75), Colors.transparent])))),
      // sparks
      Positioned(left: -d * 0.05, top: d * 0.43, child: _Spark(d * 0.065)),
      Positioned(right: -d * 0.05, top: d * 0.43, child: _Spark(d * 0.065)),
    ]));
}

class _Spark extends StatelessWidget {
  const _Spark(this.r);
  final double r;
  @override Widget build(BuildContext c) => Container(width: r, height: r,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white,
      boxShadow: [BoxShadow(color: const Color(0xFFBBDDFF).withOpacity(0.9),
        blurRadius: r * 2.5, spreadRadius: r * 0.4)]));
}

// ══════════════════════════════════════════════════════════════════════════════
//  GLASS CIRCLE BUTTON  (top bar — on dark hero bg)
// ══════════════════════════════════════════════════════════════════════════════
class _GlassBtn extends StatelessWidget {
  const _GlassBtn({required this.icon, required this.onTap, this.badge = 0});
  final IconData icon; final VoidCallback onTap; final int badge;
  @override
  Widget build(BuildContext c) => GestureDetector(
    onTap: onTap,
    child: Stack(clipBehavior: Clip.none, children: [
      Container(width: 44, height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.12),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.2)),
        child: Icon(icon, color: Colors.white, size: 22)),
      if (badge > 0) Positioned(right: 2, top: 2,
        child: Container(width: 16, height: 16,
          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          child: Center(child: Text('$badge', style: const TextStyle(
            color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold))))),
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
    width: 62, height: 62,
    decoration: BoxDecoration(shape: BoxShape.circle,
      gradient: RadialGradient(center: const Alignment(-0.3, -0.3), colors: [
        active ? const Color(0xFF2E66CC) : const Color(0xFF1A3A88),
        const Color(0xFF080F28),
      ]),
      border: Border.all(color: const Color(0xFF4477CC), width: 2.5),
      boxShadow: [
        BoxShadow(color: const Color(0xFF2255CC).withOpacity(0.65), blurRadius: 20, spreadRadius: 3),
        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 3)),
      ]),
    child: Center(child: ShaderMask(
      shaderCallback: (r) => const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFAABBDD)]).createShader(r),
      child: const Text('NX', style: TextStyle(
        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2.5)))));
}

// ══════════════════════════════════════════════════════════════════════════════
//  ACTION CARD  (Create Outfits / Saved Outfits / Shopping)
// ══════════════════════════════════════════════════════════════════════════════
class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;

  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 8, 10),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.cardBdr, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3)),
          BoxShadow(color: const Color(0xFF2255CC).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4)),
        ]),
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(width: 42, height: 42,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(color: Colors.white.withOpacity(0.2))),
              child: Icon(icon, color: Colors.white, size: 22)),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, height: 1.25)),
          ]),
        Positioned(right: 0, bottom: 0,
          child: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5), size: 20)),
        // blue glow line at bottom
        Positioned(bottom: 0, left: 0, right: 0,
          child: Container(height: 2,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
              gradient: LinearGradient(colors: [
                Color(0xFF2255CC), Color(0xFF4488FF), Color(0xFF2255CC)])))),
      ])));
}

// ══════════════════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class ModernHomeScreen extends ConsumerStatefulWidget {
  const ModernHomeScreen({super.key});
  @override
  ConsumerState<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends ConsumerState<ModernHomeScreen>
    with SingleTickerProviderStateMixin {

  // ── Original backend fields (unchanged) ────────────────────────────────────
  late PageController _carouselController;
  final int _currentCarouselIndex = 0;
  int _selectedTabIndex = 0;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _searchQuery = '';
  late AnimationController _logoRotationController;

  // ── UI state ────────────────────────────────────────────────────────────────
  int _navIndex = 2;   // Home active
  final _inspirationCtrl = PageController();
  final _fitsCtrl        = PageController();
  int _inspirationPage = 0;
  int _fitsPage        = 0;

  static const _tabs    = ['Date', 'Wedding', 'Dining Out', 'Daily', 'Interview'];
  static const _actions = ['Create\nOutfits', 'Saved\nOutfits', 'Shopping'];

  static const _inspirationUrls = [
    ('https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400&h=500&fit=crop',
     'Elevated Formal Confidence'),
    ('https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=400&h=500&fit=crop',
     'Smart Navy Authority'),
    ('https://images.unsplash.com/photo-1515575227652-8d992ee8c5d1?w=400&h=500&fit=crop',
     'Classic Elegance'),
  ];

  static const _fitsUrls = [
    ('https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=400&h=500&fit=crop',
     'Smart Casual Made Effortless'),
    ('https://images.unsplash.com/photo-1578932750294-f5075e85f44a?w=400&h=500&fit=crop',
     'Weekend Comfort Chic'),
    ('https://images.unsplash.com/photo-1520975916090-3105956dac38?w=400&h=500&fit=crop',
     'Business Casual Mastery'),
  ];

  // ── Original action icons ──────────────────────────────────────────────────
  IconData _iconFor(String label) {
    if (label.contains('Create')) return Icons.person_outline;
    if (label.contains('Saved'))  return Icons.dry_cleaning_outlined;
    return Icons.shopping_bag_outlined;
  }

  // ── Original route mapping ─────────────────────────────────────────────────
  void _onActionTap(String label) {
    if (label.contains('Create')) {
      Navigator.of(context).pushNamed(Routes.generatedOutfits);
    } else if (label.contains('Saved')) {
      Navigator.of(context).pushNamed(Routes.generatedOutfits);
    } else {
      Navigator.of(context).pushNamed(Routes.styleFeed);
    }
  }

  @override
  void initState() {
    super.initState();
    _carouselController = PageController(viewportFraction: 0.88);
    _speech = stt.SpeechToText();
    _logoRotationController = AnimationController(
      duration: const Duration(seconds: 20), vsync: this)..repeat();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async => _speech.initialize();

  // Original voice logic — unchanged
  void _startListening() async {
    if (!_isListening && _speech.isAvailable) {
      final available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        HapticFeedback.mediumImpact();
        _speech.listen(onResult: (result) {
          setState(() {
            _searchQuery = result.recognizedWords;
            if (result.finalResult) _isListening = false;
          });
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _carouselController.dispose();
    _speech.cancel();
    _logoRotationController.dispose();
    _inspirationCtrl.dispose();
    _fitsCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        drawer: const AppDrawer(currentRoute: Routes.home),
        backgroundColor: _C.heroTop,
        extendBody: true,
        body: Stack(children: [
          // Background
          const Positioned.fill(child: CustomPaint(painter: _BgPainter())),
          // Content
          SafeArea(
            bottom: false,
            child: Column(children: [
              Expanded(child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(children: [
                  const SizedBox(height: 6),
                  _topBar(mq),
                  _logoSection(),
                  _profileSection(),
                  _portraitSection(),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(children: [
                      _searchBar(),
                      const SizedBox(height: 14),
                      _occasionTabs(),
                      const SizedBox(height: 16),
                      _actionCards(),
                      const SizedBox(height: 18),
                      _inspirationSection(),
                      const SizedBox(height: 120),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
        ]),
        bottomNavigationBar: _bottomNav(mq),
      ),
    );
  }

  // ─── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _topBar(MediaQueryData mq) {
    const unread = 0; // replace with real provider if needed
    return Padding(
      padding: EdgeInsets.only(
        top: mq.padding.top > 0 ? 4 : 10,
        left: 16, right: 16, bottom: 4),
      child: Row(children: [
        _GlassBtn(icon: Icons.menu_rounded, onTap: () {
          try { Scaffold.of(context).openDrawer(); } catch (_) {}
        }),
        const Spacer(),
        _GlassBtn(icon: Icons.notifications_none_rounded,
          badge: unread,
          onTap: () => Navigator.of(context).pushNamed(Routes.notificationCenter)),
      ]).animate().fadeIn(duration: 400.ms));
  }

  // ─── LOGO ──────────────────────────────────────────────────────────────────
  Widget _logoSection() => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 6),
    child: const _NxLogo(d: 88)
        .animate()
        .scale(begin: const Offset(0.75, 0.75), end: const Offset(1, 1),
            duration: 700.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 600.ms));

  // ─── PROFILE NAME + SUBTITLE ───────────────────────────────────────────────
  Widget _profileSection() {
    final firebaseUser = ref.watch(authStateProvider).valueOrNull;
    final userModel    = ref.watch(currentUserProvider).valueOrNull;
    final displayName  = userModel?.displayName ?? firebaseUser?.displayName ?? 'Guest';

    return Column(children: [
      Text(displayName, style: const TextStyle(
        color: Colors.white, fontSize: 28,
        fontWeight: FontWeight.w800, letterSpacing: 0.2))
          .animate().fadeIn(duration: 500.ms),
      const SizedBox(height: 5),
      // subtitle with decorative dashes
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 20, height: 1.2, color: Colors.white.withOpacity(0.45)),
        const SizedBox(width: 8),
        Text('Your Personal AI Style Consultant',
          style: TextStyle(color: Colors.white.withOpacity(0.75),
            fontSize: 13.5, fontStyle: FontStyle.italic)),
        const SizedBox(width: 8),
        Container(width: 20, height: 1.2, color: Colors.white.withOpacity(0.45)),
      ]).animate().fadeIn(duration: 550.ms, delay: 80.ms),
      const SizedBox(height: 6),
    ]);
  }

  // ─── PORTRAIT PLACEHOLDER / AVATAR ────────────────────────────────────────
  Widget _portraitSection() {
    final firebaseUser = ref.watch(authStateProvider).valueOrNull;
    final userModel    = ref.watch(currentUserProvider).valueOrNull;
    final photoUrl     = userModel?.avatarUrl ?? firebaseUser?.photoURL;
    final gender       = userModel?.onboardingData?.bodyInputs.gender;

    Widget avatar;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      avatar = Container(
        width: 148, height: 172,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(photoUrl, fit: BoxFit.cover,
            errorBuilder: (_,__,___) => _avatarPlaceholder(gender))));
    } else {
      avatar = _avatarPlaceholder(gender);
    }

    return SizedBox(
      height: 172,
      child: avatar,
    ).animate().fadeIn(duration: 650.ms, delay: 100.ms)
        .slideY(begin: 0.15, duration: 650.ms);
  }

  Widget _avatarPlaceholder(String? gender) {
    final icon = gender?.toLowerCase() == 'female'
        ? Icons.person_2 : Icons.person_outline;
    return Container(
      width: 148, height: 172,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF1A3580), Color(0xFF0A1A40)]),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2)),
      child: Icon(icon, size: 72, color: Colors.white.withOpacity(0.35)));
  }

  // ─── SEARCH / ASK BAR ─────────────────────────────────────────────────────
  Widget _searchBar() => GestureDetector(
    onTap: () => Navigator.of(context).pushNamed(Routes.dashboard),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF08142E),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF2A4070), width: 1),
        boxShadow: [BoxShadow(
          color: const Color(0xFF2255CC).withOpacity(0.3), blurRadius: 12)]),
      child: Row(children: [
        // mini NX logo in search bar
        Container(width: 32, height: 32,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: const RadialGradient(colors: [Color(0xFF2255BB), Color(0xFF060F28)]),
            border: Border.all(color: _C.chr0.withOpacity(0.6), width: 1)),
          child: Center(child: ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFAABBDD)]).createShader(r),
            child: const Text('NX', style: TextStyle(
              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900))))),
        const SizedBox(width: 10),
        Container(width: 1, height: 20, color: Colors.white.withOpacity(0.2)),
        const SizedBox(width: 10),
        Expanded(child: Text(
          _searchQuery.isNotEmpty ? _searchQuery : 'Ask NX for Outfit Suggestions',
          style: TextStyle(
            color: _searchQuery.isNotEmpty ? Colors.white : Colors.white70,
            fontSize: 15, fontWeight: FontWeight.w600),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
        GestureDetector(
          onTap: _startListening,
          child: Icon(Icons.mic_outlined,
            color: _isListening ? Colors.redAccent : Colors.white70, size: 22)),
      ])),
  ).animate().fadeIn(duration: 700.ms).slideY(begin: 0.15, duration: 700.ms);

  // ─── OCCASION TABS ─────────────────────────────────────────────────────────
  Widget _occasionTabs() => SizedBox(
    height: 44,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _tabs.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final sel = _selectedTabIndex == i;
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedTabIndex = i); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: sel ? Colors.white : Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: sel ? Colors.white : Colors.white.withOpacity(0.35),
                width: 1)),
            child: Text(_tabs[i], style: TextStyle(
              color: sel ? _C.dark : Colors.white,
              fontSize: 13,
              fontWeight: sel ? FontWeight.w800 : FontWeight.w500))));
      }),
  ).animate().fadeIn(duration: 650.ms).slideY(begin: 0.15, duration: 650.ms);

  // ─── 3 ACTION CARDS ────────────────────────────────────────────────────────
  Widget _actionCards() => Row(
    children: _actions.asMap().entries.map((e) {
      final i = e.key; final label = e.value;
      return Expanded(child: Padding(
        padding: EdgeInsets.only(right: i < _actions.length - 1 ? 10 : 0),
        child: SizedBox(
          height: 100,
          child: _ActionCard(
            icon: _iconFor(label),
            label: label,
            onTap: () => _onActionTap(label)))));
    }).toList(),
  ).animate().fadeIn(duration: 700.ms).slideX(begin: -0.1, duration: 700.ms);

  // ─── INSPIRATION + FITS YOUR WARDROBE ─────────────────────────────────────
  Widget _inspirationSection() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: _carouselCol(
        title: 'Inspiration',
        items: _inspirationUrls,
        ctrl: _inspirationCtrl,
        page: _inspirationPage,
        onPage: (p) => setState(() => _inspirationPage = p))),
      const SizedBox(width: 10),
      Expanded(child: _carouselCol(
        title: 'Fits Your\nWardrobe',
        items: _fitsUrls,
        ctrl: _fitsCtrl,
        page: _fitsPage,
        onPage: (p) => setState(() => _fitsPage = p))),
    ]);

  Widget _carouselCol({
    required String title,
    required List<(String, String)> items,
    required PageController ctrl,
    required int page,
    required ValueChanged<int> onPage,
  }) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    // Section title with dashes
    Row(children: [
      Container(width: 10, height: 1.2, color: _C.dark.withOpacity(0.35)),
      const SizedBox(width: 5),
      Flexible(child: Text(title, style: const TextStyle(
        color: _C.dark, fontSize: 13.5, fontWeight: FontWeight.w800, height: 1.2),
        maxLines: 2, overflow: TextOverflow.ellipsis)),
      const SizedBox(width: 5),
      Container(width: 10, height: 1.2, color: _C.dark.withOpacity(0.35)),
    ]),
    const SizedBox(height: 8),
    // Carousel
    Stack(children: [
      SizedBox(
        height: 190,
        child: PageView.builder(
          controller: ctrl,
          onPageChanged: onPage,
          itemCount: items.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _InspCard(imageUrl: items[i].$1, label: items[i].$2)))),
      // left arrow
      Positioned(left: 0, top: 0, bottom: 0,
        child: GestureDetector(
          onTap: () => ctrl.previousPage(duration: 280.ms, curve: Curves.easeOut),
          child: Container(width: 22, alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8))),
            child: const Icon(Icons.chevron_left, size: 18, color: _C.dark)))),
      // right arrow
      Positioned(right: 0, top: 0, bottom: 0,
        child: GestureDetector(
          onTap: () => ctrl.nextPage(duration: 280.ms, curve: Curves.easeOut),
          child: Container(width: 22, alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(8))),
            child: const Icon(Icons.chevron_right, size: 18, color: _C.dark)))),
    ]),
    const SizedBox(height: 7),
    // dot indicators
    Row(mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(items.length, (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: i == page ? 16 : 6, height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: i == page ? _C.dark : _C.dark.withOpacity(0.22))))),
  ]).animate().fadeIn(duration: 800.ms).slideY(begin: 0.15, duration: 800.ms);

  // ─── BOTTOM NAV ────────────────────────────────────────────────────────────
  Widget _bottomNav(MediaQueryData mq) {
    const items = [
      (Icons.checkroom_outlined,     'Try-On',        0, Routes.tryon),
      (Icons.dry_cleaning_outlined,  'Wardrobe',      1, Routes.wardrobe),
      (null,                         'Home',          2, Routes.dashboard),
      (Icons.people_outline,         'Friends Space', 3, Routes.styleFeed),
      (Icons.person_outline,         'Profile',       4, Routes.settings),
    ];

    return Container(
      height: 78 + mq.padding.bottom,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: _C.navBdr, width: 1)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 14, offset: const Offset(0, -3))]),
      child: SafeArea(top: false, child: Stack(alignment: Alignment.center, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            final (icon, label, idx, route) = item;
            if (idx == 2) return const SizedBox(width: 62);
            final active = _navIndex == idx;
            return GestureDetector(
              onTap: () {
                setState(() => _navIndex = idx);
                if (route != Routes.dashboard) Navigator.of(context).pushNamed(route);
              },
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon!, size: 24,
                  color: active ? const Color(0xFF0B1D4C) : const Color(0xFF7A9ABB)),
                const SizedBox(height: 3),
                Text(label, textAlign: TextAlign.center, style: TextStyle(
                  color: active ? const Color(0xFF0B1D4C) : const Color(0xFF7A9ABB),
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
              ]));
          }).toList()),
        // floating NX centre
        Positioned(top: -20, child: GestureDetector(
          onTap: () => setState(() => _navIndex = 2),
          child: _NxNavBtn(active: _navIndex == 2))),
      ])));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  INSPIRATION CARD
// ══════════════════════════════════════════════════════════════════════════════
class _InspCard extends StatelessWidget {
  const _InspCard({required this.imageUrl, required this.label});
  final String imageUrl, label;

  @override
  Widget build(BuildContext ctx) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      border: Border.all(color: const Color(0xFFCCDAF0), width: 1),
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))]),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Stack(children: [
        Positioned.fill(child: Image.network(imageUrl, fit: BoxFit.cover,
          errorBuilder: (_,__,___) => Container(
            color: const Color(0xFFD0DCF0),
            child: const Icon(Icons.checkroom, size: 44, color: Color(0xFF8AAACF))))),
        Positioned(bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                colors: [Color(0xEE000022), Colors.transparent],
                stops: [0.0, 1.0])),
            child: Text(label, style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700,
              shadows: [Shadow(color: Colors.black54, blurRadius: 3)]),
              textAlign: TextAlign.center, maxLines: 2))),
      ])));
}
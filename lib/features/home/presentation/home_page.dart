// lib/features/home/presentation/home_page.dart
//
// Visual design: 100% clone of NX Home v14 HTML mockup
// Backend / providers / routes / imports: unchanged from original Dart file

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../src/features/auth/providers/auth_provider.dart';
import '../../../src/core/widgets/fashion_drawer.dart';
import '../../../src/core/widgets/nikonyx_logo.dart';
import '../../../src/routes.dart';
import '../../../src/features/home/providers/inspiration_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  PALETTE  — exact HTML colour values
// ═══════════════════════════════════════════════════════════════════════════

// .cosmic radial gradient
const _cBg0 = Color(0xFF4880E0);
const _cBg1 = Color(0xFF1848C0);
const _cBg2 = Color(0xFF0A1E58);
const _cBg3 = Color(0xFF050F2A);
const _cBg4 = Color(0xFF020810);

// body bg
const _bodyBg = Color(0xFFFFFFFF);

// text
const _nameTxt = Color(0xFF0C1E48);
const _subTxt = Color(0xFF606880);

// .occ (occasion chip)
const _occBg = Color(0xFFF0F5FF);
const _occBg2 = Color(0xFFE4EDF8);
const _occBdr = Color(0xFFB4CDF0);
const _occTxt = Color(0xFF1A2A50);
const _occActBg = Color(0xFF2A58C8);
const _occActBg2 = Color(0xFF1A3A9A);

// .act-card (action card — dark navy)
const _actBg0 = Color(0xFF0A1E58);
const _actBg1 = Color(0xFF060F2E);
const _actBg2 = Color(0xFF0D1E50);
const _actBdr = Color(0xFF7AB4FF);
const _actTxt = Color(0xFFD7EBFF);

// .insp-card silver triple-ring
const _rng1 = Color(0xFF8AA8CC);
const _rng2 = Color(0xFFD4E8F8);
const _rng3 = Color(0xFF7898B8);

// footer nav
const _navTxt = Color(0xFF1A3060);
const _navSepHi = Color(0xFF5096FF);
const _navSepLo = Color(0xFF3C78DC);

// ═══════════════════════════════════════════════════════════════════════════
//  PAGE
// ═══════════════════════════════════════════════════════════════════════════

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int bottomIndex = 2;
  String _selectedOcc = 'Date';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final mq = MediaQuery.of(context);

    return Scaffold(
      drawer: const AppDrawer(currentRoute: Routes.dashboard),
      backgroundColor: _bodyBg,
      body: Column(children: [
        // ── cosmic header (not in scroll — sits at top) ─────────────────
        _CosmicHeader(
          topPadding: mq.padding.top,
          name: user?.displayName ?? 'Arjün Petel',
        ),
        // ── scrollable body ─────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _PromptBar(),
                const SizedBox(height: 6),
                _OccasionRow(
                  selected: _selectedOcc,
                  onSelect: (v) => setState(() => _selectedOcc = v),
                ),
                _MDivider(),
                _ActionRow(),
                _MDivider(),
                _InspirationRow(),
                SizedBox(height: mq.padding.bottom + 8),
              ],
            ),
          ),
        ),
      ]),
      bottomNavigationBar: _NxNavBar(
        currentIndex: bottomIndex,
        onTap: (i) {
          setState(() => bottomIndex = i);
          switch (i) {
            case 0:
              Navigator.of(context).pushNamed(Routes.tryon);
              break;
            case 1:
              Navigator.of(context).pushNamed(Routes.wardrobe);
              break;
            case 2:
              break; // already home
            case 3:
              Navigator.of(context).pushNamed(Routes.discoverPeople);
              break;
            case 4:
              Navigator.of(context).pushNamed(Routes.settings);
              break;
          }
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  COSMIC HEADER  (.cosmic + .tbar + arc-svg)
// ═══════════════════════════════════════════════════════════════════════════

class _CosmicHeader extends StatelessWidget {
  const _CosmicHeader({required this.topPadding, required this.name});
  final double topPadding;
  final String name;

  @override
  Widget build(BuildContext ctx) {
    return SizedBox(
      height: 99 + topPadding,
      child: Stack(children: [
        // ── radial gradient background ──────────────────────────────────
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.90),
                radius: 1.45,
                colors: [_cBg0, _cBg1, _cBg2, _cBg3, _cBg4],
                stops: [0.0, 0.16, 0.36, 0.62, 1.0],
              ),
            ),
          ),
        ),

        // ── top radial glow blob ────────────────────────────────────────
        Positioned(
          top: topPadding - 20,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 180,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF3C82FF).withOpacity(0.42),
                  const Color(0xFF1446C8).withOpacity(0.14),
                  Colors.transparent,
                ], stops: const [
                  0.0,
                  0.42,
                  0.70
                ]),
              ),
            ),
          ),
        ),

        // ── .rays overlay ───────────────────────────────────────────────
        Positioned.fill(child: CustomPaint(painter: _RaysPainter())),

        // ── stars ───────────────────────────────────────────────────────
        Positioned.fill(child: _StarField()),

        // ── silver rim stripe (.srim) ───────────────────────────────────
        const Positioned(top: 0, left: 0, right: 0, child: _SilverRim()),

        // ── top-bar row (.tbar) ─────────────────────────────────────────
        Positioned(
          top: topPadding + 8,
          left: 16,
          right: 16,
          height: 34,
          child: Row(children: [
            // hamburger
            _IBtn(child: _HamburgerIcon()),
            const Spacer(),

            // centred logo + flares
            Stack(alignment: Alignment.center, children: [
              // halo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    const Color(0xFF50A0FF).withOpacity(0.48),
                    const Color(0xFF2864DC).withOpacity(0.18),
                    Colors.transparent,
                  ], stops: const [
                    0.0,
                    0.36,
                    0.65
                  ]),
                ),
              ),
              const _LogoRing(size: 50),
              // top 4-line flare
              const Positioned(top: 0, child: _Flare4(size: 11)),
              // right small flare
              const Positioned(
                  right: 0, child: _Flare2(size: 7, opacity: 0.68)),
              // left small flare
              const Positioned(left: 0, child: _Flare2(size: 7, opacity: 0.68)),
            ]),

            const Spacer(),

            // bell + avatar
            Row(mainAxisSize: MainAxisSize.min, children: [
              _IBtn(
                  badge: true,
                  child: const Icon(Icons.notifications_outlined,
                      color: Color(0xFFC8DCF4), size: 14)),
              const SizedBox(width: 5),
              _IBtn(
                  child: const Icon(Icons.person_outline,
                      color: Color(0xFFC8DCF4), size: 14)),
            ]),
          ]),
        ),

        // ── double-arc chrome separator ─────────────────────────────────
        Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 30,
            child: CustomPaint(painter: _ArcPainter())),
      ]),
    );
  }
}

// ── .srim ────────────────────────────────────────────────────────────────────
class _SilverRim extends StatelessWidget {
  const _SilverRim();
  @override
  Widget build(BuildContext ctx) => Container(
        height: 5,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
            Color(0xFF1E2E50),
            Color(0xFF4868A8),
            Color(0xFF90B4D8),
            Color(0xFFC8DFF0),
            Color(0xFFE8F4FF),
            Color(0xFFFFFFFF),
            Color(0xFFE8F4FF),
            Color(0xFFC8DFF0),
            Color(0xFF90B4D8),
            Color(0xFF4868A8),
            Color(0xFF1E2E50),
          ], stops: [
            0.0,
            0.07,
            0.16,
            0.26,
            0.36,
            0.50,
            0.64,
            0.74,
            0.84,
            0.93,
            1.0
          ]),
        ),
      );
}

// ── .rays painter ─────────────────────────────────────────────────────────────
class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    // soft radial ellipse glow
    c.drawRect(
        Rect.fromLTWH(0, 0, s.width, s.height),
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, -0.30),
            radius: 0.65,
            colors: [
              const Color(0xFF78BEFF).withOpacity(0.22),
              Colors.transparent
            ],
          ).createShader(Rect.fromLTWH(0, 0, s.width, s.height)));

    // centre light shaft (::before clip-path polygon)
    final shaft = Path()
      ..moveTo(s.width * .38, 0)
      ..lineTo(s.width * .62, 0)
      ..lineTo(s.width * .78, s.height)
      ..lineTo(s.width * .22, s.height)
      ..close();
    c.drawPath(
        shaft,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x2464B4FF), Colors.transparent],
            stops: [0.0, 0.70],
          ).createShader(Rect.fromLTWH(0, 0, s.width, s.height)));

    // repeating conic rays
    final cx = s.width / 2;
    final cy = s.height * .35;
    final rp = Paint()
      ..color = const Color(0xFFB4DCFF).withOpacity(0.055)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 24; i++) {
      final a = (i * 15.0 - 180) * math.pi / 180;
      c.drawLine(
          Offset(cx, cy),
          Offset(cx + math.cos(a) * s.width, cy + math.sin(a) * s.height * 2),
          rp);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── star field ────────────────────────────────────────────────────────────────
class _StarField extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => LayoutBuilder(
        builder: (_, c) => Stack(children: [
          _s(c, 0.12, 0.06, 2.0, 0.75, glow: true),
          _s(c, 0.05, 0.46, 1.5, 0.50),
          _s(c, 0.16, 0.87, 2.0, 0.70, glow: true),
          _s(c, 0.04, 0.93, 2.5, 0.28, glow: true),
          _s(c, 0.08, 0.30, 1.5, 0.40),
          _s(c, 0.03, 0.14, 1.5, 0.50),
          _s(c, 0.18, 0.68, 1.0, 0.45),
        ]),
      );
  Widget _s(BoxConstraints c, double top, double left, double sz, double op,
          {bool glow = false}) =>
      Positioned(
        top: c.maxHeight * top,
        left: c.maxWidth * left,
        child: Container(
          width: sz,
          height: sz,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(op),
            shape: BoxShape.circle,
            boxShadow: glow
                ? [
                    BoxShadow(
                        color: const Color(0xFFC8E6FF).withOpacity(0.8),
                        blurRadius: 3)
                  ]
                : null,
          ),
        ),
      );
}

// ── logo ring ─────────────────────────────────────────────────────────────────
class _LogoRing extends StatelessWidget {
  const _LogoRing({this.size = 50.0});
  final double size;
  @override
  Widget build(BuildContext ctx) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(startAngle: 0.26, colors: [
            Color(0xFF1E3060),
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
          ]),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF96CDFF).withOpacity(0.48),
                blurRadius: 0,
                spreadRadius: 2),
            BoxShadow(
                color: const Color(0xFF50A0FF).withOpacity(0.62),
                blurRadius: 14),
            BoxShadow(
                color: const Color(0xFF2878E6).withOpacity(0.35),
                blurRadius: 30),
          ],
        ),
        child: Center(
          child: Stack(alignment: Alignment.center, children: [
            // ::before — inner dark circle
            Container(
              width: size * .86,
              height: size * .86,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment(-0.2, -0.35),
                  colors: [
                    Color(0xFF1A3A7A),
                    Color(0xFF0D1E50),
                    Color(0xFF08122E)
                  ],
                ),
              ),
            ),
            // ::after — inner ring border
            Container(
              width: size * .72,
              height: size * .72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFB4DCFF).withOpacity(0.30), width: 1),
              ),
            ),
            // logo-in SVG
            SizedBox(
                width: size * .72,
                height: size * .72,
                child: CustomPaint(painter: _LogoIconPainter())),
          ]),
        ),
      );
}

class _LogoIconPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    // dashed rect
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTRB(
                s.width * .09, s.height * .09, s.width * .91, s.height * .91),
            const Radius.circular(3.5)),
        Paint()
          ..color = const Color(0xFFA0C8FF).withOpacity(0.42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1);
    // checkmark
    final path = Path()
      ..moveTo(s.width * .31, s.height * .50)
      ..lineTo(s.width * .44, s.height * .63)
      ..lineTo(s.width * .69, s.height * .38);
    c.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFA0C8FF).withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── flares ────────────────────────────────────────────────────────────────────
/// 4-line flare (top of logo: + and ×) — HTML uses both + and × lines
class _Flare4 extends StatelessWidget {
  const _Flare4({this.size = 11.0});
  final double size;
  @override
  Widget build(BuildContext ctx) => SizedBox(
      width: size, height: size, child: CustomPaint(painter: _Flare4Painter()));
}

class _Flare4Painter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p1 = Paint()
      ..color = const Color(0xFFDCF0FF).withOpacity(0.9)
      ..strokeWidth = 1.0;
    final p2 = Paint()
      ..color = const Color(0xFFC8E6FF).withOpacity(0.30)
      ..strokeWidth = 0.6;
    c.drawLine(Offset(s.width / 2, 0), Offset(s.width / 2, s.height), p1);
    c.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), p1);
    c.drawLine(Offset.zero, Offset(s.width, s.height), p2);
    c.drawLine(Offset(s.width, 0), Offset(0, s.height), p2);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// 2-line flare (sides of logo)
class _Flare2 extends StatelessWidget {
  const _Flare2({this.size = 7.0, this.opacity = 0.68});
  final double size;
  final double opacity;
  @override
  Widget build(BuildContext ctx) => SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _Flare2Painter(opacity: opacity)));
}

class _Flare2Painter extends CustomPainter {
  const _Flare2Painter({required this.opacity});
  final double opacity;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0xFFC8E6FF).withOpacity(opacity)
      ..strokeWidth = 0.8;
    c.drawLine(Offset(s.width / 2, 0), Offset(s.width / 2, s.height), p);
    c.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── glass icon button (.ibtn) ─────────────────────────────────────────────────
class _IBtn extends StatelessWidget {
  const _IBtn({required this.child, this.badge = false});
  final Widget child;
  final bool badge;
  @override
  Widget build(BuildContext ctx) => Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
                begin: Alignment(-0.6, -0.8),
                end: Alignment(0.6, 0.8),
                colors: [Color(0x29FFFFFF), Color(0x0FFFFFFF)]),
            border: Border.all(color: Colors.white.withOpacity(0.26), width: 1),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF00001E).withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
              BoxShadow(
                  color: Colors.white.withOpacity(0.18),
                  blurRadius: 0,
                  spreadRadius: 0,
                  offset: const Offset(0, 1)),
            ],
          ),
          child: Center(child: child),
        ),
        if (badge)
          Positioned(
              top: -1,
              right: -1,
              child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE85A4F),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF060E28), width: 1.5)))),
      ]);
}

// ── hamburger ─────────────────────────────────────────────────────────────────
class _HamburgerIcon extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(12),
          const SizedBox(height: 2.5),
          _line(12),
          const SizedBox(height: 2.5),
          _line(9),
        ],
      );
  Widget _line(double w) => Container(
      width: w,
      height: 1.5,
      decoration: BoxDecoration(
          color: const Color(0xFFC8DCF4),
          borderRadius: BorderRadius.circular(1)));
}

// ── arc painter ───────────────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    void arc(Paint p, double sag, {double startY = 6}) {
      final path = Path()
        ..moveTo(0, startY)
        ..quadraticBezierTo(w / 2, sag, w, startY);
      c.drawPath(path, p);
    }

    // glow
    arc(
        Paint()
          ..shader = LinearGradient(colors: [
            const Color(0xFF3060C0).withOpacity(0),
            const Color(0xFF4878D8).withOpacity(0.22),
            const Color(0xFF6AA4FF).withOpacity(0.44),
            const Color(0xFF4878D8).withOpacity(0.22),
            const Color(0xFF3060C0).withOpacity(0),
          ]).createShader(Rect.fromLTWH(0, 0, w, s.height))
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke,
        30);
    // main silver arc
    arc(
        Paint()
          ..shader = LinearGradient(colors: const [
            Color(0x591A2E50),
            Color(0xE04868A8),
            Color(0xFF90B4D8),
            Color(0xFFC8DFF2),
            Color(0xFFEEF6FF),
            Color(0xFFFFFFFF),
            Color(0xFFEEF6FF),
            Color(0xFFC8DFF2),
            Color(0xFF90B4D8),
            Color(0xE04868A8),
            Color(0x591A2E50),
          ], stops: const [
            0.0,
            0.06,
            0.16,
            0.28,
            0.42,
            0.50,
            0.58,
            0.72,
            0.84,
            0.94,
            1.0
          ]).createShader(Rect.fromLTWH(0, 0, w, s.height))
          ..strokeWidth = 4.5
          ..style = PaintingStyle.stroke,
        29);
    // bright highlight
    arc(
        Paint()
          ..color = Colors.white.withOpacity(0.55)
          ..strokeWidth = 1.1
          ..style = PaintingStyle.stroke,
        27.5,
        startY: 5.3);
    // secondary silver
    arc(
        Paint()
          ..shader = LinearGradient(colors: const [
            Color(0x261A2E50),
            Color(0xA66888B8),
            Color(0xD9B0CCE4),
            Color(0xFFDEEEFF),
            Color(0xD9B0CCE4),
            Color(0xA66888B8),
            Color(0x261A2E50),
          ], stops: const [
            0.0,
            0.10,
            0.28,
            0.50,
            0.72,
            0.90,
            1.0
          ]).createShader(Rect.fromLTWH(0, 0, w, s.height))
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke,
        18,
        startY: 2.5);
    // faint top
    arc(
        Paint()
          ..color = Colors.white.withOpacity(0.38)
          ..strokeWidth = 0.6
          ..style = PaintingStyle.stroke,
        16.5,
        startY: 2.2);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
//  BODY: .name-sec  (user name + subtitle — now below header in body)
// ═══════════════════════════════════════════════════════════════════════════
// NOTE: In the HTML the name is in .body below .cosmic.
// We render it here as a widget placed after the header.

class _NameSection extends StatelessWidget {
  const _NameSection({required this.name});
  final String name;
  @override
  Widget build(BuildContext ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Column(children: [
          Text(name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _nameTxt,
                  letterSpacing: -0.2)),
          const SizedBox(height: 3),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
                width: 14,
                height: 1,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.transparent, Color(0xFFB0BCD0)]))),
            const SizedBox(width: 5),
            const Text('· Your NX Style Assistant ·',
                style: TextStyle(
                    fontSize: 10, color: _subTxt, letterSpacing: 0.3)),
            const SizedBox(width: 5),
            Container(
                width: 14,
                height: 1,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFFB0BCD0), Colors.transparent]))),
          ]),
        ]),
      );
}

// ── thin sep ──────────────────────────────────────────────────────────────────
class _Sep extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
        Colors.transparent,
        Color(0x80B4CDEB),
        Color(0xBFD2E4FA),
        Color(0x80B4CDEB),
        Colors.transparent,
      ], stops: [
        0.0,
        0.20,
        0.50,
        0.80,
        1.0
      ])));
}

// ── .mdiv ─────────────────────────────────────────────────────────────────────
class _MDivider extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => Container(
      height: 3,
      margin: const EdgeInsets.fromLTRB(14, 5, 14, 0),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          gradient: const LinearGradient(colors: [
            Colors.transparent,
            Color(0x4D96B9E6),
            Color(0xCCC8E1F8),
            Color(0xFFFFFFFF),
            Color(0xCCC8E1F8),
            Color(0x4D96B9E6),
            Colors.transparent,
          ], stops: [
            0.0,
            0.15,
            0.40,
            0.50,
            0.60,
            0.85,
            1.0
          ])));
}

// ═══════════════════════════════════════════════════════════════════════════
//  .portrait — user portrait placeholder
// ═══════════════════════════════════════════════════════════════════════════
class _Portrait extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => Container(
        height: 118,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    begin: Alignment(-0.6, -0.8),
                    end: Alignment(0.6, 0.8),
                    colors: [Color(0xFFE8F0FF), Color(0xFFD4E2F8)]),
                border: Border.all(
                    color: const Color(0xFFA0BEEB).withOpacity(0.4),
                    width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF1E3C78).withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
              ),
              child: const Icon(Icons.person_outline,
                  color: Color(0xFF8090B8), size: 28),
            ),
            const SizedBox(height: 6),
            const Text('User Portrait',
                style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFFA0AAC0),
                    letterSpacing: 0.3)),
          ]),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  .prompt — NX ask bar
// ═══════════════════════════════════════════════════════════════════════════
class _PromptBar extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) {
    // Build the full visible section: name + sep + portrait + prompt
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _NameSection(name: 'Arjün Petel'), // static; parent passes via hero
      _Sep(),
      const SizedBox(height: 8),
      _Portrait(),
      Container(
        margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        padding: const EdgeInsets.fromLTRB(14, 7, 7, 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: const LinearGradient(colors: [
            Color(0xFF05102A),
            Color(0xFF091636),
            Color(0xFF05102A)
          ]),
          border: Border.all(
              color: const Color(0xFF508CFF).withOpacity(0.35), width: 1),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF1E50C8).withOpacity(0.18),
                blurRadius: 10),
          ],
        ),
        child: Row(children: [
          // .plogo mini conic ring
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [
                Color(0xFF4070C0),
                Color(0xFF98C0E8),
                Color(0xFFDCEEFF),
                Color(0xFF6090C8),
                Color(0xFF4070C0),
              ]),
            ),
            child: Center(
                child: Text('NX',
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0A1840)))),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: RichText(
                  text: const TextSpan(
            children: [
              TextSpan(
                  text: 'Ask NX for ',
                  style: TextStyle(fontSize: 11, color: Color(0x99BED7FF))),
              TextSpan(
                  text: 'Outfit Suggestions',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ],
          ))),
          const SizedBox(width: 8),
          // .mic button
          _MicButton(),
        ]),
      ),
    ]);
  }
}

// ── .mic ──────────────────────────────────────────────────────────────────────
class _MicButton extends StatefulWidget {
  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  bool _active = false;
  late final AnimationController _ac = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  void _tap() {
    setState(() => _active = true);
    _ac.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _active = false);
    });
  }

  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: _tap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                begin: const Alignment(-0.6, -0.8),
                end: const Alignment(0.6, 0.8),
                colors: _active
                    ? const [Color(0xFF1060E0), Color(0xFF0840B0)]
                    : const [Color(0xFF1A44B8), Color(0xFF0F2880)]),
            border: Border.all(
                color: const Color(0xFF64B4FF).withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF3C8CFF)
                      .withOpacity(_active ? 0.90 : 0.50),
                  blurRadius: _active ? 22 : 9,
                  spreadRadius: _active ? 3 : 0),
            ],
          ),
          child: const Center(
              child: Icon(Icons.mic, color: Colors.white, size: 15)),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  .occ-row — occasion chips
// ═══════════════════════════════════════════════════════════════════════════
class _OccasionRow extends StatelessWidget {
  const _OccasionRow({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;

  static const _occs = [
    'Date',
    'Wedding',
    'Dining Out',
    'Daily',
    'Working',
    'Interview',
    'Business'
  ];

  @override
  Widget build(BuildContext ctx) => SizedBox(
        height: 36,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
          scrollDirection: Axis.horizontal,
          itemCount: _occs.length,
          itemBuilder: (_, i) {
            final occ = _occs[i];
            final act = occ == selected;
            return GestureDetector(
              onTap: () => onSelect(occ),
              child: Container(
                margin: const EdgeInsets.only(right: 5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: act
                      ? const LinearGradient(
                          begin: Alignment(-0.6, -0.8),
                          end: Alignment(0.6, 0.8),
                          colors: [_occActBg, _occActBg2])
                      : const LinearGradient(
                          begin: Alignment(-0.6, -0.8),
                          end: Alignment(0.6, 0.8),
                          colors: [_occBg, _occBg2]),
                  border: Border.all(
                      color: act
                          ? const Color(0xFF64A0FF).withOpacity(0.5)
                          : _occBdr.withOpacity(0.55),
                      width: 1),
                  boxShadow: act
                      ? [
                          BoxShadow(
                              color: const Color(0xFF143CC8).withOpacity(0.26),
                              blurRadius: 8,
                              offset: const Offset(0, 3)),
                          BoxShadow(
                              color: Colors.white.withOpacity(0.22),
                              blurRadius: 0,
                              offset: const Offset(0, 1))
                        ]
                      : [
                          BoxShadow(
                              color: const Color(0xFF143278).withOpacity(0.07),
                              blurRadius: 5,
                              offset: const Offset(0, 2)),
                          BoxShadow(
                              color: Colors.white.withOpacity(0.9),
                              blurRadius: 0,
                              offset: const Offset(0, 1))
                        ],
                ),
                child: Text(occ,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: act ? FontWeight.w700 : FontWeight.w600,
                        color: act ? Colors.white : _occTxt)),
              ),
            );
          },
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  .act-row — 5 action cards
// ═══════════════════════════════════════════════════════════════════════════
class _ActionRow extends ConsumerWidget {
  @override
  Widget build(BuildContext ctx, WidgetRef ref) => SizedBox(
        height: 40,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
          scrollDirection: Axis.horizontal,
          children: [
            _ActCard(
                label: 'Create\nOutfits',
                icon: Icons.person_outline,
                onTap: () => Navigator.of(ctx).pushNamed('/fashion-quiz')),
            const SizedBox(width: 8),
            _ActCard(
                label: 'Saved\nOutfits',
                icon: Icons.bookmark_border,
                onTap: () => Navigator.of(ctx).pushNamed('/my-outfits')),
            const SizedBox(width: 8),
            _ActCard(
                label: 'Shopping',
                icon: Icons.shopping_bag_outlined,
                onTap: () => Navigator.of(ctx).pushNamed('/recommendations')),
            const SizedBox(width: 8),
            _ActCard(
                label: 'Try-On',
                icon: Icons.camera_alt_outlined,
                onTap: () => Navigator.of(ctx).pushNamed('/tryon')),
            const SizedBox(width: 8),
            _ActCard(
                label: 'Friends\nSpace',
                icon: Icons.people_outline,
                onTap: () => Navigator.of(ctx).pushNamed('/discover-people')),
          ],
        ),
      );
}

class _ActCard extends StatelessWidget {
  const _ActCard(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 109,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
                begin: Alignment(-0.8, -0.8),
                end: Alignment(0.8, 0.8),
                colors: [_actBg0, _actBg1, _actBg2],
                stops: [0.0, 0.45, 1.0]),
            border: Border.all(color: _actBdr.withOpacity(0.36), width: 1),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF030828).withOpacity(0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 5)),
              BoxShadow(
                  color: const Color(0xFFA0D2FF).withOpacity(0.30),
                  blurRadius: 0,
                  offset: const Offset(0, 1)),
              BoxShadow(
                  color: const Color(0xFF00003C).withOpacity(0.50),
                  blurRadius: 0,
                  offset: const Offset(0, -1)),
            ],
          ),
          child: Row(children: [
            // .act-icon
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      begin: Alignment(-0.6, -0.8),
                      end: Alignment(0.6, 0.8),
                      colors: [Color(0x2EFFFFFF), Color(0x0FFFFFFF)]),
                  border: Border.all(
                      color: const Color(0xFFA0D2FF).withOpacity(0.28),
                      width: 1)),
              child: Center(
                  child: Icon(icon,
                      size: 12,
                      color: const Color(0xFFB4D7FF).withOpacity(0.92))),
            ),
            const SizedBox(width: 8),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _actTxt,
                        height: 1.25,
                        letterSpacing: 0.1))),
            const Icon(Icons.chevron_right, size: 7, color: Color(0x808CC3FF)),
          ]),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  .insp-row — inspiration cards (uses backend InspirationOutfit)
// ═══════════════════════════════════════════════════════════════════════════
class _InspirationRow extends ConsumerWidget {
  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final async = ref.watch(inspirationOutfitsProvider);

    const titles = [
      ('Inspiration', 'Elevated Formal\nConfidence', 'Navy suit · Sharp fit'),
      (
        'Fits Wardrobe',
        'Smart Casual\nMade Effortless',
        'Layers · Relaxed fit'
      ),
      ('Trends', 'Evening\nSophistication', 'Charcoal · Slim cut'),
      ('Friends Space', 'Spring\nGarden Party', 'Green · Fresh look'),
    ];
    const imgBgs = [
      [Color(0xFFBCD0EA), Color(0xFFD4E4F4)],
      [Color(0xFFC8DAF0), Color(0xFFD8E8F4)],
      [Color(0xFFCCD4E8), Color(0xFFC0CCE0)],
      [Color(0xFFD4E4F0), Color(0xFFDCEEF8)],
    ];

    return SizedBox(
      height: 178,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 5, 14, 12),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: 4,
        itemBuilder: (_, i) {
          final (sec, fallbackTitle, sub) = titles[i];
          final bgs = imgBgs[i];

          return async.when(
            data: (outfits) {
              final outfit = i < outfits.length ? outfits[i] : null;
              return _InspCard(
                sectionLabel: sec,
                title: outfit?.title ?? fallbackTitle,
                sub: outfit?.occasion ?? sub,
                dotActive: [1, 2, 0, 2][i],
                dotCount: [3, 4, 3, 3][i],
                bgColors: bgs,
                imageUrl: outfit?.imageUrl,
                dotIndex: i,
              );
            },
            loading: () => _InspCard(
                sectionLabel: sec,
                title: fallbackTitle,
                sub: sub,
                dotActive: [1, 2, 0, 2][i],
                dotCount: [3, 4, 3, 3][i],
                bgColors: bgs,
                dotIndex: i),
            error: (_, __) => _InspCard(
                sectionLabel: sec,
                title: fallbackTitle,
                sub: sub,
                dotActive: [1, 2, 0, 2][i],
                dotCount: [3, 4, 3, 3][i],
                bgColors: bgs,
                dotIndex: i),
          );
        },
      ),
    );
  }
}

class _InspCard extends StatelessWidget {
  const _InspCard({
    required this.sectionLabel,
    required this.title,
    required this.sub,
    required this.dotActive,
    required this.dotCount,
    required this.bgColors,
    required this.dotIndex,
    this.imageUrl,
  });
  final String sectionLabel, title, sub;
  final int dotActive, dotCount, dotIndex;
  final List<Color> bgColors;
  final String? imageUrl;

  @override
  Widget build(BuildContext ctx) {
    Uint8List? imgBytes;
    if (imageUrl != null) {
      try {
        final clean =
            imageUrl!.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '');
        imgBytes = base64Decode(clean);
      } catch (_) {}
    }

    return SizedBox(
      width: 148,
      child: Column(children: [
        // .insp-title
        Row(children: [
          Expanded(
              child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.transparent, Color(0x66648CC8)])))),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(sectionLabel,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A2A50),
                      letterSpacing: 0.3))),
          Expanded(
              child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0x66648CC8), Colors.transparent])))),
        ]),
        const SizedBox(height: 5),
        // .insp-card — triple silver ring shadow
        Container(
          width: 148,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(color: _rng1, blurRadius: 0, spreadRadius: 1.5),
              BoxShadow(color: _rng2, blurRadius: 0, spreadRadius: 3.0),
              BoxShadow(color: _rng3, blurRadius: 0, spreadRadius: 4.5),
              BoxShadow(
                  color: Color(0x21143278),
                  blurRadius: 16,
                  offset: Offset(0, 6)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(children: [
              // .iimg
              SizedBox(
                height: 90,
                width: 148,
                child: Stack(children: [
                  // gradient bg
                  Positioned.fill(
                      child: Container(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: const Alignment(-0.6, -0.8),
                                  end: const Alignment(0.6, 0.8),
                                  colors: bgColors)))),
                  // actual image if available
                  if (imgBytes != null)
                    Positioned.fill(
                        child: Image.memory(imgBytes!, fit: BoxFit.cover)),
                  // .img-ph placeholder
                  if (imgBytes == null)
                    Center(
                        child: Container(
                      width: 72,
                      height: 64,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF5A8CC8).withOpacity(0.45),
                              width: 1.5,
                              style: BorderStyle.solid),
                          color: Colors.white.withOpacity(0.25)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined,
                              color: const Color(0xFF5082C8).withOpacity(0.50),
                              size: 20),
                          const SizedBox(height: 3),
                          Text('Add Image',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 7.5,
                                  color:
                                      const Color(0xFF5082C8).withOpacity(0.48),
                                  height: 1.3)),
                        ],
                      ),
                    )),
                ]),
              ),
              // .icard-label
              Container(
                padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        top: BorderSide(color: Color(0x4DB4D2F0), width: 1))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0C1E48),
                            height: 1.35)),
                    const SizedBox(height: 2),
                    Text(sub,
                        style: const TextStyle(
                            fontSize: 8.5,
                            color: Color(0xFF6070A0),
                            height: 1.3)),
                    // .idots
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                          children: List.generate(
                              dotCount,
                              (d) => Container(
                                  width: d == dotActive ? 9 : 4,
                                  height: 4,
                                  margin: const EdgeInsets.only(right: 3),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      color: d == dotActive
                                          ? const Color(0xFF2A58C8)
                                          : const Color(0xFF6490C8)
                                              .withOpacity(0.28))))),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  FOOTER NAV (.nav)  — silver metallic HTML clone
// ═══════════════════════════════════════════════════════════════════════════

class _NxNavBar extends StatelessWidget {
  const _NxNavBar({required this.currentIndex, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext ctx) {
    final mq = MediaQuery.of(ctx);
    return Container(
      height: 52 + mq.padding.bottom,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB8C8E0),
              Color(0xFFD4E0F0),
              Color(0xFFE8F0F8),
              Color(0xFFF2F6FC),
              Color(0xFFE0EAF6),
              Color(0xFFC8D8EC),
              Color(0xFFB0C4DC),
            ],
            stops: [
              0.0,
              0.08,
              0.25,
              0.40,
              0.60,
              0.80,
              1.0
            ]),
        border: Border(top: BorderSide(color: Colors.white, width: 1)),
        boxShadow: [
          BoxShadow(
              color: Color(0x1F143278), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: mq.padding.bottom),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NI(
                icon: _NavSvg.tryOn,
                label: 'Try-On',
                active: currentIndex == 0,
                onTap: () => onTap(0)),
            _NavSep(),
            _NI(
                icon: _NavSvg.wardrobe,
                label: 'Wardrobe',
                active: currentIndex == 1,
                onTap: () => onTap(1)),
            _NavSep(),
            // centre home logo
            Expanded(
                child: GestureDetector(
              onTap: () => onTap(2),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _HomeLogo(),
                    const SizedBox(height: 2),
                    Text('Home',
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: currentIndex == 2
                                ? _navTxt
                                : _navTxt.withOpacity(0.8),
                            letterSpacing: 0.1,
                            shadows: const [
                              Shadow(
                                  color: Colors.white,
                                  blurRadius: 1,
                                  offset: Offset(0, 1))
                            ])),
                  ]),
            )),
            _NavSep(),
            _NI(
                icon: _NavSvg.friends,
                label: 'Friends Space',
                active: currentIndex == 3,
                onTap: () => onTap(3)),
            _NavSep(),
            _NI(
                icon: _NavSvg.profile,
                label: 'Profile',
                active: currentIndex == 4,
                onTap: () => onTap(4)),
          ],
        ),
      ),
    );
  }
}

// ── .ni ───────────────────────────────────────────────────────────────────────
class _NI extends StatelessWidget {
  const _NI(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap});
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
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: active ? _navTxt : _navTxt.withOpacity(0.75),
                    letterSpacing: 0.1,
                    shadows: const [
                      Shadow(
                          color: Colors.white,
                          blurRadius: 1,
                          offset: Offset(0, 1))
                    ])),
          ]),
        ),
      );
}

// ── .nav-sep ─────────────────────────────────────────────────────────────────
class _NavSep extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => Container(
      width: 1.5,
      height: 32,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
            Colors.transparent,
            Color(0x8C3C78DC),
            Color(0xB35096FF),
            Color(0x8C3C78DC),
            Colors.transparent,
          ],
              stops: [
            0.0,
            0.30,
            0.50,
            0.70,
            1.0
          ])));
}

// ── home logo ring ────────────────────────────────────────────────────────────
class _HomeLogo extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(startAngle: 0.26, colors: [
            Color(0xFF1E3060),
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
          ]),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF82B4FF).withOpacity(0.45),
                blurRadius: 0,
                spreadRadius: 1.5),
            BoxShadow(
                color: const Color(0xFF3278DC).withOpacity(0.50),
                blurRadius: 10),
            BoxShadow(
                color: const Color(0xFF1E5AC8).withOpacity(0.28),
                blurRadius: 18),
          ],
        ),
        child: Stack(alignment: Alignment.center, children: [
          Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                      center: Alignment(-0.2, -0.35),
                      colors: [
                        Color(0xFF1A3A7A),
                        Color(0xFF0D1E50),
                        Color(0xFF08122E)
                      ]))),
          Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFA0D0FF).withOpacity(0.28),
                      width: 1))),
          SizedBox(
              width: 26,
              height: 26,
              child: CustomPaint(painter: _LogoIconPainter())),
        ]),
      );
}

// ── nav SVG icons ─────────────────────────────────────────────────────────────
class _NavSvg {
  static const tryOn = _NavIcon(path: _NavPaths.tryOn);
  static const wardrobe = _NavIcon(path: _NavPaths.wardrobe);
  static const friends = _NavIcon(path: _NavPaths.friends);
  static const profile = _NavIcon(path: _NavPaths.profile);
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.path});
  final String path;
  @override
  Widget build(BuildContext ctx) => SizedBox(
      width: 18, height: 18, child: CustomPaint(painter: _PathPainter(path)));
}

class _PathPainter extends CustomPainter {
  const _PathPainter(this.svgPath);
  final String svgPath;
  @override
  void paint(Canvas c, Size s) {
    // scale 24→18
    c.scale(s.width / 24, s.height / 24);
    final p = Paint()
      ..color = const Color(0xFF1E3878)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _draw(c, svgPath, p);
  }

  void _draw(Canvas c, String key, Paint p) {
    switch (key) {
      case 'tryOn':
        // camera
        c.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTRB(1, 8, 23, 21), const Radius.circular(2)),
            p);
        c.drawCircle(const Offset(12, 14), 4, p);
        final cam = Path()
          ..moveTo(8, 8)
          ..lineTo(6, 5)
          ..lineTo(10, 5)
          ..moveTo(10, 5)
          ..lineTo(12, 2)
          ..moveTo(12, 2)
          ..lineTo(14, 5)
          ..lineTo(18, 5)
          ..lineTo(16, 8);
        c.drawPath(cam, p);
        break;
      case 'wardrobe':
        // hanger
        final hang = Path()
          ..moveTo(20.38, 3.46)
          ..lineTo(16, 2)
          ..moveTo(16, 2)
          ..cubicTo(16, 4, 8, 4, 8, 2)
          ..lineTo(3.62, 3.46)
          ..cubicTo(3, 3.9, 2.7, 4.7, 2.96, 5.69)
          ..lineTo(3.54, 9.26)
          ..cubicTo(3.7, 9.66, 4.08, 9.84, 4.53, 10)
          ..lineTo(5, 10)
          ..lineTo(5, 20)
          ..cubicTo(5, 20.55, 5.45, 21, 6, 21)
          ..lineTo(18, 21)
          ..cubicTo(18.55, 21, 19, 20.55, 19, 20)
          ..lineTo(19, 10)
          ..lineTo(19.47, 10)
          ..cubicTo(19.92, 9.84, 20.3, 9.46, 20.46, 9.06)
          ..lineTo(21.04, 5.49)
          ..cubicTo(21.3, 4.5, 21, 3.7, 20.38, 3.46);
        c.drawPath(hang, p);
        break;
      case 'friends':
        c.drawCircle(const Offset(8, 7), 3, p);
        final fr = Path()
          ..moveTo(2, 18)
          ..cubicTo(2, 13, 8, 13, 8, 18)
          ..moveTo(8, 18)
          ..cubicTo(8, 13, 14, 13, 14, 18)
          ..moveTo(14, 4)
          ..cubicTo(16, 4, 16.5, 5.5, 16, 7)
          ..cubicTo(15.5, 8.5, 15, 8.5, 14.5, 8.5)
          ..moveTo(17.5, 10)
          ..cubicTo(19.5, 11, 19.5, 14, 19.5, 14);
        c.drawPath(fr, p);
        break;
      case 'profile':
        c.drawCircle(const Offset(12, 8), 4, p);
        final pr = Path()
          ..moveTo(4, 20)
          ..cubicTo(4, 15, 8, 15, 12, 15)
          ..cubicTo(16, 15, 20, 15, 20, 20);
        c.drawPath(pr, p);
        break;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _NavPaths {
  static const tryOn = 'tryOn';
  static const wardrobe = 'wardrobe';
  static const friends = 'friends';
  static const profile = 'profile';
}

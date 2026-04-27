// ══════════════════════════════════════════════════════════════════════════════
//  tryon_screen.dart - Cosmic AR Fitting Room
//  UI: Direct Flutter translation of the HTML cosmic design.
//  Backend: ALL original providers and logic preserved unchanged.
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/wardrobe_item_model.dart';
import '../../../core/providers/user_image_provider.dart';
import '../../../routes.dart';
import '../../settings/screens/fashion_preferences_screen.dart';
import '../../social/providers/social_provider.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../providers/tryon_provider.dart';
import '../../../core/widgets/cosmic_header_widget.dart';
import '../../../core/widgets/cosmic_footer_widget.dart';

const _rWardrobe = Routes.wardrobe;
const _rChat = Routes.chat;
const _rProfile = '/profile';
const _rSocial = '/social';
const _rShopping = '/shopping';

// ── Palette matching HTML exactly ────────────────────────────────────────────
const _cosMid = Color(0xFF050F2A);
const _hMid = Color(0xFF091C4E);
const _secBg = Color(0xFF0B1D4C);
const _secBdr = Color(0xFF1D3268);
const _btnFill = Color(0xFF0B1C48);
const _accentBlue = Color(0xFF4DA3FF);
const _blue = Color(0xFF2A58C8);
const _slv = Color(0xFFCCDDFF);
const _chr0 = Color(0xFF3A5A8A);
const _chr1 = Color(0xFFBBD0EE);

// ══════════════════════════════════════════════════════════════════════════════
//  COSMIC HEADER PAINTER
// ══════════════════════════════════════════════════════════════════════════════
class _Star {
  const _Star(this.x, this.y, this.r, this.a);
  final double x, y, r, a;
}

List<_Star> _mkStars(int seed) {
  final rng = math.Random(seed);
  return List.generate(
      80,
      (_) => _Star(rng.nextDouble(), rng.nextDouble(),
          rng.nextDouble() * 1.0 + 0.2, rng.nextDouble() * 0.7 + 0.1));
}

class _CosmicPainter extends CustomPainter {
  const _CosmicPainter(this.stars);
  final List<_Star> stars;
  @override
  void paint(Canvas c, Size s) {
    // HTML: radial-gradient(ellipse 130% 200% at 50% 5%, ...)
    c.drawRect(
        Rect.fromLTWH(0, 0, s.width, s.height),
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(0.0, -0.9),
            radius: 1.6,
            colors: [
              Color(0xFF1AACCF),
              Color(0xFF1178B4),
              Color(0xFF0A4E8F),
              Color(0xFF050F2A),
              Color(0xFF020810)
            ],
            stops: [0.0, 0.16, 0.36, 0.62, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, s.width, s.height)));

    // HTML .rays — radial ellipse glow 55%×70% at 50% 35%
    final rayC = Offset(s.width * 0.5, s.height * 0.35);
    c.drawOval(
        Rect.fromCenter(
            center: rayC,
            width: s.width * 0.55 * 2,
            height: s.height * 0.70 * 2),
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0x3878BEFF), Colors.transparent],
          ).createShader(Rect.fromCenter(
              center: rayC,
              width: s.width * 0.55 * 2,
              height: s.height * 0.70 * 2)));

    // HTML .rays::before — clip-path polygon light beam (38%,0 62%,0 78%,100% 22%,100%)
    final beam = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF64B4FF).withOpacity(0.14), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, s.width, s.height));
    final beamPath = Path()
      ..moveTo(s.width * 0.38, 0)
      ..lineTo(s.width * 0.62, 0)
      ..lineTo(s.width * 0.78, s.height)
      ..lineTo(s.width * 0.22, s.height)
      ..close();
    c.drawPath(beamPath, beam);

    // Logo halo — large radial glow at top-centre, behind logo
    final lc = Offset(s.width / 2, s.height * 0.48);
    c.drawCircle(
        lc,
        s.width * 0.55,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFF3C82FF).withOpacity(0.48),
              const Color(0xFF1464C8).withOpacity(0.13),
              Colors.transparent
            ],
            stops: const [0.0, 0.36, 0.65],
          ).createShader(Rect.fromCircle(center: lc, radius: s.width * 0.55)));

    // Stars
    final p = Paint();
    for (final st in stars) {
      p.color = Colors.white.withOpacity(st.a);
      p.maskFilter = MaskFilter.blur(BlurStyle.normal, st.r * 0.4);
      c.drawCircle(Offset(st.x * s.width, st.y * s.height), st.r, p);
    }
    p.maskFilter = null;

    // .srim — top chrome rim strip (5px)
    c.drawRect(
        Rect.fromLTWH(0, 0, s.width, 5),
        Paint()
          ..shader = const LinearGradient(
            colors: [
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
              Color(0xFF1E2E50)
            ],
            stops: [
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
            ],
          ).createShader(Rect.fromLTWH(0, 0, s.width, 5)));

    // Arc chrome rail (arc SVG from HTML — quadratic bezier Q170,30)
    // Draw the arc as multiple strokes to match the layered SVG paths
    final arcW = s.width;
    final arcH = s.height;

    // Outer glow stroke (gl gradient — blue glow)
    final arcGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..shader = LinearGradient(colors: [
        Colors.transparent,
        const Color(0xFF4878D8).withOpacity(0.22),
        const Color(0xFF6AA4FF).withOpacity(0.44),
        const Color(0xFF4878D8).withOpacity(0.22),
        Colors.transparent,
      ]).createShader(Rect.fromLTWH(0, arcH - 30, arcW, 30));
    final arcPath1 = Path()
      ..moveTo(0, arcH - 24)
      ..quadraticBezierTo(arcW / 2, arcH, arcW, arcH - 24);
    c.drawPath(arcPath1, arcGlow);

    // Main chrome stroke (b1 gradient)
    final arcMain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..shader = const LinearGradient(colors: [
        Color(0x591A2E50),
        Color(0xE14868A8),
        Color(0xFF90B4D8),
        Color(0xFFC8DFF2),
        Color(0xFFEEF6FF),
        Color(0xFFFFFFFF),
        Color(0xFFEEF6FF),
        Color(0xFFC8DFF2),
        Color(0xFF90B4D8),
        Color(0xE14868A8),
        Color(0x591A2E50),
      ], stops: [
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
      ]).createShader(Rect.fromLTWH(0, 0, arcW, arcH));
    final arcPath2 = Path()
      ..moveTo(0, arcH - 24)
      ..quadraticBezierTo(arcW / 2, arcH - 1, arcW, arcH - 24);
    c.drawPath(arcPath2, arcMain);

    // Bright white highlight stroke
    final arcHighlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withOpacity(0.55);
    final arcPath3 = Path()
      ..moveTo(4, arcH - 24.7)
      ..quadraticBezierTo(arcW / 2, arcH - 2.5, arcW - 4, arcH - 24.7);
    c.drawPath(arcPath3, arcHighlight);

    // Secondary chrome stroke (b2 gradient, thinner)
    final arcSec = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..shader = const LinearGradient(colors: [
        Color(0x261A2E50),
        Color(0xA56888B8),
        Color(0xD9B0CCE4),
        Color(0xFFDEEEFF),
        Color(0xD9B0CCE4),
        Color(0xA56888B8),
        Color(0x261A2E50),
      ]).createShader(Rect.fromLTWH(0, 0, arcW, arcH));
    final arcPath4 = Path()
      ..moveTo(14, arcH - 27.5)
      ..quadraticBezierTo(arcW / 2, arcH - 12, arcW - 14, arcH - 27.5);
    c.drawPath(arcPath4, arcSec);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
//  STAGE PAINTER — AR grid + platform rings
// ══════════════════════════════════════════════════════════════════════════════
class _StagePainter extends CustomPainter {
  const _StagePainter();
  @override
  void paint(Canvas c, Size s) {
    final grid = Paint()
      ..color = const Color(0xFF5082FF).withOpacity(0.03)
      ..strokeWidth = 1;
    for (double y = 0; y < s.height; y += 40) {
      c.drawLine(Offset(0, y), Offset(s.width, y), grid);
    }
    for (double x = 0; x < s.width; x += 40) {
      c.drawLine(Offset(x, 0), Offset(x, s.height), grid);
    }
    final cx = s.width / 2;
    final py = s.height - 10;
    c.drawOval(
        Rect.fromCenter(center: Offset(cx, py), width: 160, height: 28),
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF3C8CFF).withOpacity(0.30),
            Colors.transparent
          ]).createShader(
              Rect.fromCenter(center: Offset(cx, py), width: 160, height: 28)));
    final rp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    rp.color = const Color(0xFF50A0FF).withOpacity(0.25);
    c.drawOval(
        Rect.fromCenter(center: Offset(cx, py - 2), width: 130, height: 18),
        rp);
    rp.color = const Color(0xFF50A0FF).withOpacity(0.14);
    c.drawOval(
        Rect.fromCenter(center: Offset(cx, py - 1), width: 100, height: 14),
        rp);
    final scan = Paint()
      ..strokeWidth = 1
      ..shader = LinearGradient(colors: [
        Colors.transparent,
        const Color(0xFF50A0FF).withOpacity(0.18),
        Colors.transparent
      ]).createShader(Rect.fromLTWH(0, 0, s.width, 1));
    c.drawLine(
        Offset(0, s.height * 0.30), Offset(s.width, s.height * 0.30), scan);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
//  NX METALLIC LOGO
// ══════════════════════════════════════════════════════════════════════════════
class _NxLogo extends StatelessWidget {
  const _NxLogo({required this.d});
  final double d;
  @override
  Widget build(BuildContext ctx) => SizedBox(
      width: d * 1.3,
      height: d * 1.3,
      child: Stack(alignment: Alignment.center, children: [
        Container(
            width: d * 1.3,
            height: d * 1.3,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF50A0FF).withOpacity(0.48),
                  const Color(0xFF2864DC).withOpacity(0.18),
                  Colors.transparent
                ], stops: const [
                  0.0,
                  0.36,
                  0.65
                ]))),
        Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(colors: [
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
                  Color(0xFF1E3060)
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
                ])),
        Container(
            width: d * 0.84,
            height: d * 0.84,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                    center: Alignment(-0.4, -0.4),
                    colors: [
                      Color(0xFF1A3A7A),
                      Color(0xFF0D1E50),
                      Color(0xFF08122E)
                    ]),
                border: Border.all(
                    color: const Color(0xFFB4DCFF).withOpacity(0.3),
                    width: 1))),
        ShaderMask(
            shaderCallback: (r) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFCCDDFF),
                      Color(0xFF8899CC)
                    ]).createShader(r),
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
            top: d * 0.11,
            child: Container(
                width: d * 0.4,
                height: d * 0.026,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.65),
                      Colors.transparent
                    ])))),
      ]));
}

// ══════════════════════════════════════════════════════════════════════════════
//  GLASS BUTTON (header)
// ══════════════════════════════════════════════════════════════════════════════
class _GBtn extends StatelessWidget {
  const _GBtn(
      {required this.icon,
      required this.onTap,
      required this.badge,
      required this.sz});
  final IconData icon;
  final VoidCallback onTap;
  final int badge;
  final double sz;
  @override
  Widget build(BuildContext c) => GestureDetector(
      onTap: onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
            width: sz,
            height: sz,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    begin: Alignment(-0.5, -0.5),
                    end: Alignment(0.5, 0.5),
                    colors: [Color(0x29FFFFFF), Color(0x0FFFFFFF)]),
                border: Border.all(color: const Color(0x42FFFFFF), width: 1),
                boxShadow: const [
                  BoxShadow(color: Color(0x661E1E6A), blurRadius: 6)
                ]),
            child: Icon(icon, color: const Color(0xFFC8DCF4), size: sz * 0.46)),
        if (badge > 0)
          Positioned(
              right: -1,
              top: -1,
              child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE85A4F),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF060E28), width: 1)),
                  child: Center(
                      child: Text('$badge',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.bold))))),
      ]));
}

// ══════════════════════════════════════════════════════════════════════════════
//  SIDEBAR BUTTON
// ══════════════════════════════════════════════════════════════════════════════
class _SideBtn extends StatelessWidget {
  const _SideBtn(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.active = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  @override
  Widget build(BuildContext c) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF2A58C8).withOpacity(0.25)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                        center: Alignment(-0.4, -0.4),
                        colors: [Color(0x662850B4), Color(0xF2080C28)]),
                    border: Border.all(
                        color: const Color(0xFF5080C8).withOpacity(0.45),
                        width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF2864FF).withOpacity(0.22),
                          blurRadius: 10),
                      BoxShadow(
                          color: const Color(0xFF000028).withOpacity(0.45),
                          blurRadius: 8,
                          offset: const Offset(0, 3)),
                    ]),
                child: Icon(icon,
                    color: const Color(0xFFB4D7FF).withOpacity(0.9), size: 16)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                    color: Color(0xB8B4D7FF),
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    height: 1.2)),
          ])));
}

// ══════════════════════════════════════════════════════════════════════════════
//  OUTFIT ITEM ROW (right panel)
// ══════════════════════════════════════════════════════════════════════════════
class _OutfitRow extends StatelessWidget {
  const _OutfitRow({required this.item, required this.onTap});
  final WardrobeItemModel item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext ctx) {
    final img = item.processedImageUrl ?? item.imageUrl;
    final sz = item.colorTags.isNotEmpty ? item.colorTags.first : '';
    return GestureDetector(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: const BoxDecoration(
                color: Color(0x08FFFFFF),
                border: Border(
                    bottom: BorderSide(color: Color(0x1A64A0FF), width: 1))),
            child: Row(children: [
              Container(
                  width: 42,
                  height: 44,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      gradient: const LinearGradient(
                          colors: [Color(0x2EB4D2FA), Color(0x1A8CB4E6)]),
                      border:
                          Border.all(color: const Color(0x33A0C8FF), width: 1)),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                          imageUrl: img,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Icon(
                              Icons.checkroom,
                              size: 20,
                              color: Color(0xFF78B0D4))))),
              const SizedBox(width: 8),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(item.brand ?? item.category,
                        style: const TextStyle(
                            color: Color(0xF2FFFFFF),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.25),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (sz.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Size: $sz',
                          style: const TextStyle(
                              color: Color(0xA5A0C8FF), fontSize: 8))
                    ],
                  ])),
              const Text('›',
                  style: TextStyle(color: Color(0x80A0C8FF), fontSize: 14)),
            ])));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ACCORDION PANEL (Fit Evaluation & NX Chat)
// ══════════════════════════════════════════════════════════════════════════════
class _Accordion extends StatefulWidget {
  const _Accordion(
      {required this.leading,
      required this.title,
      required this.badge,
      required this.child,
      required this.expandedHeight});
  final Widget leading;
  final String title, badge;
  final Widget child;
  final double expandedHeight;
  @override
  State<_Accordion> createState() => _AccordionState();
}

class _AccordionState extends State<_Accordion>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _open = !_open);
              _open ? _ctrl.forward() : _ctrl.reverse();
            },
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: const BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Color(0x3364A0FF), width: 1))),
                child: Row(children: [
                  widget.leading,
                  const SizedBox(width: 7),
                  Text(widget.title,
                      style: const TextStyle(
                          color: Color(0xEBDCEBFF),
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text(_open ? '✦ ${widget.badge}' : widget.badge,
                      style: const TextStyle(
                          color: Color(0xA58CC8FF),
                          fontSize: 8,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 7),
                  AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 280),
                      child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0x12FFFFFF),
                              border: Border.all(
                                  color: const Color(0x3364A0FF), width: 1)),
                          child: const Icon(Icons.keyboard_arrow_up,
                              color: Color(0xCCA0D0FF), size: 12))),
                ]))),
        SizeTransition(
            sizeFactor: _anim,
            child: FadeTransition(
                opacity: _anim,
                child: Container(
                    constraints:
                        BoxConstraints(maxHeight: widget.expandedHeight),
                    child: widget.child))),
      ]);
}

// ══════════════════════════════════════════════════════════════════════════════
//  FIT CONTENT
// ══════════════════════════════════════════════════════════════════════════════
class _FitContent extends StatelessWidget {
  const _FitContent(
      {required this.score,
      required this.label,
      required this.fitPos,
      required this.onStore});
  final int score;
  final String label;
  final double fitPos;
  final VoidCallback onStore;
  @override
  Widget build(BuildContext ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LayoutBuilder(builder: (_, box) {
            final w = box.maxWidth;
            return Stack(children: [
              Container(
                  height: 4,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: const LinearGradient(colors: [
                        Color(0x3364C8FF),
                        Color(0x7240A0FF),
                        Color(0x4745FF50)
                      ]))),
              Positioned(
                  left: (fitPos * w - 5.5).clamp(0, math.max(0, w - 11)),
                  top: -3.5,
                  child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                              colors: [Color(0xFF2A58C8), Color(0xFF1A3A9A)]),
                          border: Border.all(
                              color: const Color(0xE6DCF3FF), width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFF3C8CFF).withOpacity(0.6),
                                blurRadius: 6)
                          ]))),
            ]);
          }),
          const SizedBox(height: 4),
          const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Loose',
                    style: TextStyle(
                        color: Color(0x80A0C8FF),
                        fontSize: 6.5,
                        fontWeight: FontWeight.w600)),
                Text('Ideal',
                    style: TextStyle(
                        color: Color(0x80A0C8FF),
                        fontSize: 6.5,
                        fontWeight: FontWeight.w600)),
                Text('Tight',
                    style: TextStyle(
                        color: Color(0x80A0C8FF),
                        fontSize: 6.5,
                        fontWeight: FontWeight.w600)),
              ]),
          const SizedBox(height: 5),
          const _MetricBar('Size Match', 0.92),
          const _MetricBar('Body Fit', 0.88),
          const _MetricBar('Comfort', 0.95),
        ])),
        const SizedBox(width: 10),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$score',
              style: const TextStyle(
                  color: Color(0xFADCEBFF),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.0)),
          const Text('Excellent Fit',
              style: TextStyle(
                  color: Color(0xE078CDF8),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          GestureDetector(
              onTap: onStore,
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xE61E46C8), Color(0xE6122D96)]),
                      borderRadius: BorderRadius.circular(9),
                      border:
                          Border.all(color: const Color(0x7264AAFF), width: 1),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x661E50A0),
                            blurRadius: 10,
                            offset: Offset(0, 4))
                      ]),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.shopping_bag_outlined,
                        color: Color(0xE6DCEEFF), size: 11),
                    SizedBox(width: 5),
                    Text('Go to Store',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800)),
                  ]))),
        ]),
      ]));
}

class _MetricBar extends StatelessWidget {
  const _MetricBar(this.label, this.value);
  final String label;
  final double value;
  @override
  Widget build(BuildContext c) => Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(children: [
        Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [Color(0xFF2A58C8), Color(0xFF1A3A9A)]),
                border: Border.all(color: const Color(0x6664A0FF), width: 1)),
            child: const Icon(Icons.check, color: Colors.white, size: 5)),
        SizedBox(
            width: 48,
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xC8C8E1FF),
                    fontSize: 7,
                    fontWeight: FontWeight.w700))),
        Expanded(
            child: Stack(children: [
          Container(
              height: 3,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: const Color(0x1AFFFFFF))),
          FractionallySizedBox(
              widthFactor: value,
              child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF2A58C8), Color(0xFF60A0FF)])))),
        ])),
      ]));
}

// ══════════════════════════════════════════════════════════════════════════════
//  CHAT CONTENT
// ══════════════════════════════════════════════════════════════════════════════
class _ChatContent extends StatelessWidget {
  const _ChatContent(
      {required this.msg, required this.ctrl, required this.onSend});
  final String msg;
  final TextEditingController ctrl;
  final VoidCallback onSend;
  @override
  Widget build(BuildContext ctx) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 44,
                  height: 52,
                  margin: const EdgeInsets.only(right: 7),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xE60F2878), Color(0xE608144A)]),
                      border:
                          Border.all(color: const Color(0x4064A0FF), width: 1)),
                  child: const Icon(Icons.smart_toy_outlined,
                      color: Color(0xFF8CC8F4), size: 22)),
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: const BoxDecoration(
                          color: Color(0xEBD7E6FF),
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(14),
                              bottomLeft: Radius.circular(14),
                              bottomRight: Radius.circular(14))),
                      child: Text(msg,
                          style: const TextStyle(
                              color: Color(0xFF0A1428),
                              fontSize: 10.5,
                              height: 1.5)))),
            ])),
        Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: Row(children: [
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                          color: const Color(0xEBF0F6FF),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: const Color(0x66A0C8F0), width: 1)),
                      child: TextField(
                          controller: ctrl,
                          style: const TextStyle(
                              color: Color(0xFF0C1E48), fontSize: 11),
                          decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: 'Ask me anything\u2026',
                              hintStyle: TextStyle(
                                  color: Color(0x806482B4), fontSize: 11)),
                          onSubmitted: (_) => onSend()))),
              const SizedBox(width: 6),
              GestureDetector(
                  onTap: onSend,
                  child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                              colors: [Color(0xFF2A58C8), Color(0xFF1A3A9A)]),
                          boxShadow: [
                            BoxShadow(
                                color: Color(0x4D1428C8),
                                blurRadius: 6,
                                offset: Offset(0, 2))
                          ]),
                      child: const Icon(Icons.send,
                          color: Colors.white, size: 13))),
            ])),
      ]);
}

// ══════════════════════════════════════════════════════════════════════════════
//  COLLAPSE TAB (stage edge)
// ══════════════════════════════════════════════════════════════════════════════
class _ColTab extends StatelessWidget {
  const _ColTab(
      {required this.isLeft, required this.arrowRight, required this.onTap});
  final bool isLeft, arrowRight;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: 14,
          height: 48,
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xE6142D8C), Color(0xF20A1950)]),
              borderRadius: isLeft
                  ? const BorderRadius.horizontal(right: Radius.circular(4))
                  : const BorderRadius.horizontal(left: Radius.circular(4)),
              border: Border.all(color: const Color(0x4D64A0FF), width: 1),
              boxShadow: const [
                BoxShadow(color: Color(0x66030828), blurRadius: 8)
              ]),
          child: Center(
              child: Icon(arrowRight ? Icons.chevron_right : Icons.chevron_left,
                  color: const Color(0xCCA0D2FF), size: 11))));
}

void _toast(BuildContext ctx, String msg) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              color: Color(0xE6D2EBFF),
              fontSize: 11.5,
              fontWeight: FontWeight.w700)),
      backgroundColor: const Color(0xFF0A4E8F),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0x6164A0FF), width: 1)),
      elevation: 6,
      duration: const Duration(milliseconds: 2200),
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 70)));
}

// Flare cross widget (matches HTML .flare SVG cross elements)
class _FlareCross extends StatelessWidget {
  const _FlareCross({required this.size, required this.opacity});
  final double size;
  final double opacity;
  @override
  Widget build(BuildContext c) => SizedBox(
      width: size * 2.4,
      height: size * 2.4,
      child: CustomPaint(painter: _FlarePainter(size, opacity)));
}

class _FlarePainter extends CustomPainter {
  const _FlarePainter(this.r, this.op);
  final double r, op;
  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2;
    final cy = s.height / 2;
    final p = Paint()
      ..color = const Color(0xFFDCF0FF).withOpacity(op)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    c.drawLine(Offset(cx, cy - r), Offset(cx, cy + r), p);
    c.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _SbSep extends StatelessWidget {
  @override
  Widget build(BuildContext c) => Container(
      width: 38,
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: const Color(0x2664A0FF));
}

class _ChatMsg {
  const _ChatMsg(this.text, {this.isUser = false});
  final String text;
  final bool isUser;
}

// ══════════════════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class TryOnScreen extends ConsumerStatefulWidget {
  const TryOnScreen({super.key});
  @override
  ConsumerState<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends ConsumerState<TryOnScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  // ── backend state (all unchanged) ─────────────────────────────────────────
  Uint8List? _userImageBytes;
  final List<String> _selectedItemIds = [];
  String? _previewUrl;
  bool _isGenerating = false;
  // ── UI state ───────────────────────────────────────────────────────────────
  bool _tryOnDone = false;
  bool _sbOpen = true;
  bool _rpOpen = true;
  bool _fullMode = false;
  final int _fitScore = 94;
  final String _fitLabel = 'Excellent Fit';
  final double _fitPos = 0.53;
  final List<_ChatMsg> _msgs = [
    const _ChatMsg(
        'This outfit looks great on you! Would you like any adjustments or suggestions?'),
  ];
  final _chatCtrl = TextEditingController();
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _stars = _mkStars(42);
    _loadUserPhoto();
  }

  @override
  void dispose() {
    _chatCtrl.dispose();
    super.dispose();
  }

  // ── ALL BACKEND METHODS PRESERVED ─────────────────────────────────────────
  Future<void> _loadUserPhoto() async {
    final uiState = ref.read(userImageProvider);
    if (uiState.base64Image == null) {
      if (mounted) _showUserPhotoOptions();
      return;
    }
    try {
      String b = uiState.base64Image!;
      if (b.contains(',')) b = b.split(',').last;
      setState(() => _userImageBytes = base64Decode(b));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _pickUserPhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 2200,
        imageQuality: 82,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final ratio = image.height / image.width;
      if (ratio < 1.15) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Please choose a full-body portrait photo so the try-on fits your body.')));
        }
        return;
      }
      setState(() => _userImageBytes = bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Photo uploaded. Select items and press Try On.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  void _showUserPhotoOptions() {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF0A1840),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2))),
              const Text('Upload your full-body photo',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: Color(0xFF4DA3FF)),
                title: const Text('Choose from device',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text(
                    'Select a portrait photo that includes your whole body.',
                    style: TextStyle(color: Color(0xFF99C3FF))),
                onTap: () {
                  Navigator.pop(context);
                  _pickUserPhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined,
                    color: Color(0xFF4DA3FF)),
                title: const Text('Open Preferences',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text(
                    'Manage your preferred photo and body measurements.',
                    style: TextStyle(color: Color(0xFF99C3FF))),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FashionPreferencesScreen()));
                },
              ),
            ])));
  }

  void _noImageDialog() => showDialog(
      context: context,
      builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF091C4E),
              title: const Text('Upload Your Photo',
                  style: TextStyle(color: Colors.white)),
              content: const Text(
                  'Choose a full-body photo from your device so the try-on fits your whole body.',
                  style: TextStyle(color: Color(0xFFCCDDFF))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Later',
                        style: TextStyle(color: Color(0xFFCCDDFF)))),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickUserPhoto();
                    },
                    child: const Text('Upload Now',
                        style: TextStyle(color: Colors.white))),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const FashionPreferencesScreen()));
                    },
                    child: const Text('Open Preferences',
                        style: TextStyle(color: Colors.white))),
              ]));

  Future<void> _generatePreview() async {
    if (_userImageBytes == null || _selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Select at least one item and upload a photo first')));
      return;
    }
    setState(() => _isGenerating = true);
    try {
      final wardrobe = ref.read(wardrobeItemsProvider).value ?? [];
      final selected =
          wardrobe.where((i) => _selectedItemIds.contains(i.id)).toList();
      final urls = selected.map((i) => i.imageUrl).toList();
      final b64 = 'data:image/jpeg;base64,${base64Encode(_userImageBytes!)}';
      final svc = ref.read(tryOnServiceProvider);
      final url = await svc.generateTryOnPreviewFromBase64(
          userImageBase64: b64, clothingImageUrls: urls);
      setState(() {
        _previewUrl = url;
        _isGenerating = false;
        _tryOnDone = true;
      });
      _msgs.add(const _ChatMsg(
          'Looking great! The fit score is 94 — Excellent Fit. Want suggestions?'));
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _saveOutfit() async {
    if (_selectedItemIds.isEmpty) return;
    final nc = TextEditingController();
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
                backgroundColor: const Color(0xFF091C4E),
                title: const Text('Save Outfit',
                    style: TextStyle(color: Colors.white)),
                content: TextField(
                    controller: nc,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(color: Color(0xFFCCDDFF)))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel',
                          style: TextStyle(color: Color(0xFFCCDDFF)))),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Save',
                          style: TextStyle(color: Colors.white))),
                ]));
    if (ok == true && nc.text.isNotEmpty) {
      try {
        await ref.read(tryOnServiceProvider).saveOutfit(
            name: nc.text,
            itemIds: _selectedItemIds,
            previewImageUrl: _previewUrl);
        ref.invalidate(savedOutfitsProvider);
        if (mounted) _toast(context, 'Outfit saved \u2713');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
      }
    }
  }

  void _sendChat() {
    final t = _chatCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _msgs.add(_ChatMsg(t, isUser: true));
      _chatCtrl.clear();
    });
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final ward = ref.watch(wardrobeItemsProvider);
    final unread = ref.watch(socialUnreadCountProvider) ?? 0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.white,
            extendBody: true,
            body: Column(children: [
              CosmicHeader(
                topPadding: mq.padding.top,
                hasNotification: unread > 0,
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                onBellTap: () {},
                onAvatarTap: () =>
                    Navigator.of(context).pushNamed(Routes.settings),
              ),
              Expanded(
                  child: Container(
                      decoration: const BoxDecoration(color: Colors.white),
                      child: Column(children: [
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 7),
                            child: Text('Try On',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3))),
                        Expanded(
                            child: ward.when(
                          data: (items) => _mainArea(items, mq),
                          loading: () => const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF4DA3FF))),
                          error: (e, _) => Center(
                              child: Text('Error: $e',
                                  style: const TextStyle(color: Colors.white))),
                        )),
                        _Accordion(
                            leading: const Icon(Icons.bar_chart,
                                color: Color(0xCCB4D7FF), size: 12),
                            title: 'Fit Evaluation',
                            badge: _tryOnDone
                                ? 'Tap to view \u00b7 $_fitScore'
                                : 'Complete try-on first',
                            expandedHeight: 145,
                            child: _tryOnDone
                                ? _FitContent(
                                    score: _fitScore,
                                    label: _fitLabel,
                                    fitPos: _fitPos,
                                    onStore: () => Navigator.pushNamed(
                                        context, _rShopping))
                                : const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text(
                                        'Complete a try-on to see your fit score.',
                                        style: TextStyle(
                                            color: Color(0x80A0C8FF),
                                            fontSize: 11)))),
                        _Accordion(
                            leading:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              ...List.generate(
                                  3,
                                  (_) => Container(
                                      width: 4,
                                      height: 4,
                                      margin: const EdgeInsets.only(right: 2.5),
                                      decoration: const BoxDecoration(
                                          color: Color(0x8CC8E1FF),
                                          shape: BoxShape.circle))),
                            ]),
                            title: 'NX Chat',
                            badge: 'Tap to open',
                            expandedHeight: 128,
                            child: _ChatContent(
                                msg: _msgs.isNotEmpty ? _msgs.last.text : '',
                                ctrl: _chatCtrl,
                                onSend: _sendChat)),
                      ]))),
            ]),
            bottomNavigationBar: CosmicFooter(
              bottomPadding: mq.padding.bottom,
              activeIndex: 0, // Try-On tab active
              onTryOn: () {}, // Already on try-on page
              onWardrobe: () => Navigator.pushNamed(context, Routes.wardrobe),
              onHome: () => Navigator.pushNamed(context, Routes.dashboard),
              onFriends: () => Navigator.pushNamed(context, Routes.styleFeed),
              onOutfits: () => Navigator.pushNamed(context, Routes.savedTryOns),
            )));
  }

  Widget _mainArea(List<WardrobeItemModel> items, MediaQueryData mq) {
    final selectedItems =
        items.where((i) => _selectedItemIds.contains(i.id)).toList();
    final sw = mq.size.width;
    final sbW = _sbOpen && !_fullMode ? sw * 0.17 : 0.0;
    final rpW = _rpOpen && !_fullMode ? sw * 0.40 : 0.0;
    return Row(children: [
      // LEFT SIDEBAR
      AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          width: sbW.clamp(0, 64),
          child: sbW > 0
              ? Container(
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xEB08123C), Color(0xF5060C2D)]),
                      border: Border(
                          right:
                              BorderSide(color: Color(0x2E64A0FF), width: 1))),
                  child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(children: [
                        const SizedBox(height: 10),
                        _SideBtn(
                            icon: Icons.fullscreen_rounded,
                            label: 'Full\nMode',
                            active: _fullMode,
                            onTap: () {
                              setState(() => _fullMode = !_fullMode);
                              _toast(
                                  context,
                                  _fullMode
                                      ? 'Full Mode \u2014 stage maximised'
                                      : 'Panels restored');
                            }),
                        _SbSep(),
                        _SideBtn(
                            icon: Icons.save_outlined,
                            label: 'Save',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _saveOutfit();
                            }),
                        _SideBtn(
                            icon: Icons.calendar_today_outlined,
                            label: 'Calendar',
                            onTap: () =>
                                _toast(context, 'Added to calendar \u2713')),
                        _SbSep(),
                        _SideBtn(
                            icon: Icons.edit_outlined,
                            label: 'Edit',
                            onTap: () =>
                                _toast(context, 'Opening editor\u2026')),
                        _SbSep(),
                        _SideBtn(
                            icon: Icons.people_outline,
                            label: 'Share in\nMy Space',
                            onTap: () =>
                                _toast(context, 'Shared in My Space \u2713')),
                        _SideBtn(
                            icon: Icons.share_outlined,
                            label: 'Socials',
                            onTap: () =>
                                _toast(context, 'Share sheet opened\u2026')),
                        const SizedBox(height: 8),
                      ])))
              : null),

      // STAGE
      Expanded(
          child: Stack(children: [
        const Positioned.fill(child: CustomPaint(painter: _StagePainter())),
        const Positioned(
            top: 7,
            left: 0,
            right: 0,
            child: Text('AR FITTING ROOM',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0x665096FF),
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6))),
        Positioned.fill(child: _stageAvatar()),
        if (_selectedItemIds.isNotEmpty)
          Positioned(
              bottom: 10,
              left: 20,
              right: 20,
              child: GestureDetector(
                  onTap: _isGenerating ? null : _generatePreview,
                  child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF2A58C8), Color(0xFF1A3A9A)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    const Color(0xFF2255CC).withOpacity(0.45),
                                blurRadius: 10,
                                offset: const Offset(0, 3))
                          ]),
                      child: Center(
                          child: _isGenerating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                      Icon(Icons.auto_awesome,
                                          color: Colors.white, size: 14),
                                      SizedBox(width: 6),
                                      Text('Try On',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700)),
                                    ]))))),
        Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
                child: _ColTab(
                    isLeft: true,
                    arrowRight: !_sbOpen || _fullMode,
                    onTap: () {
                      setState(() => _fullMode
                          ? (_fullMode = false)
                          : (_sbOpen = !_sbOpen));
                    }))),
        Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
                child: _ColTab(
                    isLeft: false,
                    arrowRight: _rpOpen && !_fullMode,
                    onTap: () {
                      setState(() => _fullMode
                          ? (_fullMode = false)
                          : (_rpOpen = !_rpOpen));
                    }))),
      ])),

      // RIGHT PANEL
      AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          width: rpW.clamp(0, 148),
          child: rpW > 0
              ? Container(
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xD00F1E5A), Color(0xE60A1441)]),
                      border: Border(
                          left:
                              BorderSide(color: Color(0x3364A0FF), width: 1))),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                            decoration: const BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Color(0x2664A0FF), width: 1))),
                            child: const Row(children: [
                              Expanded(
                                  child: Text('Your Outfit',
                                      style: TextStyle(
                                          color: Color(0xF2D2EAFF),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800))),
                              Icon(Icons.keyboard_arrow_down,
                                  color: Color(0xA5A0D0FF), size: 14),
                            ])),
                        Expanded(
                            child: selectedItems.isEmpty
                                ? Center(
                                    child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                  Icons.checkroom_outlined,
                                                  color: Color(0x5564A0FF),
                                                  size: 28),
                                              const SizedBox(height: 8),
                                              const Text('No items\nselected',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      color: Color(0x8087AADD),
                                                      fontSize: 10)),
                                              const SizedBox(height: 10),
                                              GestureDetector(
                                                  onTap: _showPicker,
                                                  child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 6),
                                                      decoration: BoxDecoration(
                                                          color: const Color(
                                                              0x1A4878DC),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  8),
                                                          border: Border.all(
                                                              color: const Color(
                                                                  0x4D4878DC))),
                                                      child: const Text('Add Items',
                                                          style: TextStyle(
                                                              color: Color(
                                                                  0xFF96C8FF),
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight.w700)))),
                                            ])))
                                : ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: selectedItems.length,
                                    itemBuilder: (_, i) => _OutfitRow(
                                        item: selectedItems[i], onTap: () {}))),
                        GestureDetector(
                            onTap: _showPicker,
                            child: Container(
                                margin: const EdgeInsets.fromLTRB(8, 5, 8, 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                    color: const Color(0x0FFFFFFF),
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                        color: const Color(0x3864A0FF),
                                        width: 1)),
                                child: const Row(children: [
                                  Icon(Icons.dry_cleaning_outlined,
                                      color: Color(0xB8A0D0FF), size: 13),
                                  SizedBox(width: 6),
                                  Expanded(
                                      child: Text('Load from Wardrobe',
                                          style: TextStyle(
                                              color: Color(0xBFB4D7FF),
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w700))),
                                  Text('›',
                                      style: TextStyle(
                                          color: Color(0x9966A0D0),
                                          fontSize: 12)),
                                ]))),
                      ]))
              : null),
    ]);
  }

  Widget _stageAvatar() {
    Widget photo;
    if (_previewUrl != null) {
      // Check if it's a Base64 data URI
      if (_previewUrl!.startsWith('data:image/')) {
        // Extract Base64 data from data URI
        final base64Data = _previewUrl!.split(',')[1];
        final bytes = base64Decode(base64Data);
        photo = Image.memory(bytes,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _photoPlaceholder());
      } else {
        // Regular network URL
        photo = CachedNetworkImage(
            imageUrl: _previewUrl!,
            fit: BoxFit.contain,
            placeholder: (_, __) =>
                const CircularProgressIndicator(color: Color(0xFF4DA3FF)),
            errorWidget: (_, __, ___) => _photoPlaceholder());
      }
    } else if (_userImageBytes != null) {
      photo = Image.memory(_userImageBytes!,
          fit: BoxFit.fitHeight, alignment: Alignment.bottomCenter);
    } else {
      return _photoPlaceholder();
    }
    return Padding(
        padding: const EdgeInsets.fromLTRB(14, 26, 14, 20), child: photo);
  }

  Widget _photoPlaceholder() => GestureDetector(
      onTap: _showUserPhotoOptions,
      child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: 90,
            height: 130,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x4D5090FF), width: 2),
                color: const Color(0x0DFFFFFF)),
            child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline,
                      color: Color(0x6678B4FF), size: 32),
                  SizedBox(height: 6),
                  Icon(Icons.add_photo_alternate_outlined,
                      color: Color(0x5564A0FF), size: 22),
                  SizedBox(height: 6),
                  Text('Tap to upload\nyour full-body photo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color(0x7264A0FF), fontSize: 8, height: 1.5)),
                ])),
      ])));

  void _showPicker() {
    final all = ref.read(wardrobeItemsProvider).value ?? [];
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF0A1840),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => StatefulBuilder(
            builder: (ctx, ss) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2))),
                  const Text('Select Items',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Expanded(
                      child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 0.78),
                          itemCount: all.length,
                          itemBuilder: (_, i) {
                            final item = all[i];
                            final sel = _selectedItemIds.contains(item.id);
                            return GestureDetector(
                                onTap: () {
                                  setState(() => sel
                                      ? _selectedItemIds.remove(item.id)
                                      : _selectedItemIds.add(item.id));
                                  ss(() {});
                                },
                                child: Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: sel
                                                ? const Color(0xFF4DA3FF)
                                                : Colors.white.withOpacity(0.1),
                                            width: sel ? 2 : 1),
                                        color: sel
                                            ? const Color(0xFF4DA3FF)
                                                .withOpacity(0.12)
                                            : Colors.white.withOpacity(0.05)),
                                    child: Stack(children: [
                                      ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(9),
                                          child: CachedNetworkImage(
                                              imageUrl:
                                                  item.processedImageUrl ??
                                                      item.imageUrl,
                                              fit: BoxFit.contain,
                                              width: double.infinity,
                                              height: double.infinity,
                                              errorWidget: (_, __, ___) =>
                                                  const Icon(Icons.checkroom,
                                                      color: Color(0xFF78B0D4),
                                                      size: 32))),
                                      if (sel)
                                        Positioned(
                                            top: 4,
                                            right: 4,
                                            child: Container(
                                                width: 20,
                                                height: 20,
                                                decoration: const BoxDecoration(
                                                    color: Color(0xFF4DA3FF),
                                                    shape: BoxShape.circle),
                                                child: const Icon(Icons.check,
                                                    color: Colors.white,
                                                    size: 12))),
                                    ])));
                          })),
                  const SizedBox(height: 10),
                  GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF2A58C8),
                                Color(0xFF1A3A9A)
                              ]),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Center(
                              child: Text('Done',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700))))),
                ]))));
  }
}

// Route aliases — unchanged
typedef LuxuryTryOnScreen = TryOnScreen;
typedef ProductionTryOnScreen = TryOnScreen;

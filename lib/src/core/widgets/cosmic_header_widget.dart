// ══════════════════════════════════════════════════════════════════════════════
//  cosmic_header_widget.dart
//  Universal reusable header component for all main pages
//  Extracted from wardrobe_screen.dart for consistency across app
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'nikonyx_logo.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  SILVER RIM
// ──────────────────────────────────────────────────────────────────────────────
class _SilverRim extends StatelessWidget {
  const _SilverRim();
  @override
  Widget build(BuildContext ctx) => Container(
        height: 5,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A4E8F),
              Color(0xFF4868A8),
              Color(0xFF90B4D8),
              Color(0xFFC8DFF0),
              Color(0xFFE8F4FF),
              Color(0xFFFFFFFF),
              Color(0xFFE8F4FF),
              Color(0xFFC8DFF0),
              Color(0xFF90B4D8),
              Color(0xFF4868A8),
              Color(0xFF0A4E8F),
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
          ),
        ),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
//  STARFIELD
// ──────────────────────────────────────────────────────────────────────────────
class _Stars extends StatelessWidget {
  const _Stars();
  @override
  Widget build(BuildContext ctx) => Stack(children: [
        _star(top: 0.12, left: 0.06, size: 2.0, opacity: 0.75, glow: true),
        _star(top: 0.05, left: 0.46, size: 1.5, opacity: 0.50),
        _star(top: 0.16, left: 0.87, size: 2.0, opacity: 0.70),
        _star(top: 0.04, left: 0.93, size: 2.5, opacity: 0.28, glow: true),
        _star(top: 0.08, left: 0.30, size: 1.5, opacity: 0.40),
        _star(top: 0.03, left: 0.14, size: 1.5, opacity: 0.50),
      ]);

  Widget _star(
          {required double top,
          required double left,
          required double size,
          required double opacity,
          bool glow = false}) =>
      Positioned(
        top: null,
        left: null,
        child: FractionallySizedBox(
          widthFactor: 1,
          heightFactor: 1,
          child: LayoutBuilder(
              builder: (_, c) => Stack(children: [
                    Positioned(
                      top: c.maxHeight * top,
                      left: c.maxWidth * left,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(opacity),
                          shape: BoxShape.circle,
                          boxShadow: glow
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFC8E6FF)
                                        .withOpacity(0.8),
                                    blurRadius: 3,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ])),
        ),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
class _Flare extends StatelessWidget {
  const _Flare({this.size = 11.0, this.opacity = 0.9});
  final double size;
  final double opacity;
  @override
  Widget build(BuildContext ctx) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _FlarePainter(opacity: opacity)),
      );
}

class _FlarePainter extends CustomPainter {
  const _FlarePainter({required this.opacity});
  final double opacity;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0xFFDCF0FF).withOpacity(opacity)
      ..strokeWidth = 1.0;
    c.drawLine(Offset(s.width / 2, 0), Offset(s.width / 2, s.height), p);
    c.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ──────────────────────────────────────────────────────────────────────────────
//  ICON BUTTON
// ──────────────────────────────────────────────────────────────────────────────
class _IBtn extends StatelessWidget {
  const _IBtn({required this.child, this.onTap, this.badge = false});
  final Widget child;
  final VoidCallback? onTap;
  final bool badge;
  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment(-0.6, -0.8),
                end: Alignment(0.6, 0.8),
                colors: [Color(0x29FFFFFF), Color(0x0FFFFFFF)],
              ),
              border: Border.all(
                  color: const Color(0xFFFFFFFF).withOpacity(0.26), width: 1),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2)),
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
                  border:
                      Border.all(color: const Color(0xFF060E28), width: 1.5),
                ),
              ),
            ),
        ]),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
//  HAMBURGER ICON
// ──────────────────────────────────────────────────────────────────────────────
class _HamburgerIcon extends StatelessWidget {
  const _HamburgerIcon();

  @override
  Widget build(BuildContext ctx) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hline(12),
          const SizedBox(height: 2.5),
          _hline(12),
          const SizedBox(height: 2.5),
          _hline(9),
        ],
      );

  Widget _hline(double w) => Container(
        width: w,
        height: 1.5,
        decoration: BoxDecoration(
          color: const Color(0xFFC8DCF4),
          borderRadius: BorderRadius.circular(1),
        ),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
//  ARC SEPARATOR
// ──────────────────────────────────────────────────────────────────────────────
class _ArcSeparator extends CustomPainter {
  const _ArcSeparator();

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;

    _drawArc(c, w, s.height,
        color: const Color(0xFF6AA4FF).withOpacity(0.44),
        strokeW: 12,
        sagy: 0.95);

    _drawArcGradient(c, w, s.height,
        colors: const [
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
        ],
        stops: const [
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
        ],
        strokeW: 4.5,
        sagy: 0.94);

    _drawArc(c, w, s.height,
        color: Colors.white.withOpacity(0.55), strokeW: 1.1, sagy: 0.925);

    _drawArcGradient(c, w, s.height,
        colors: const [
          Color(0x261A2E50),
          Color(0xA66888B8),
          Color(0xD9B0CCE4),
          Color(0xFFDEEEFF),
          Color(0xD9B0CCE4),
          Color(0xA66888B8),
          Color(0x261A2E50),
        ],
        stops: const [0.0, 0.10, 0.28, 0.50, 0.72, 0.90, 1.0],
        strokeW: 2.2,
        sagy: 0.82);

    _drawArc(c, w, s.height,
        color: Colors.white.withOpacity(0.38), strokeW: 0.6, sagy: 0.78);
  }

  void _drawArc(Canvas c, double w, double h,
      {required Color color, required double strokeW, required double sagy}) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;
    final path = Path()
      ..moveTo(0, h * 0.20)
      ..quadraticBezierTo(w / 2, h * sagy, w, h * 0.20);
    c.drawPath(path, p);
  }

  void _drawArcGradient(Canvas c, double w, double h,
      {required List<Color> colors,
      required List<double> stops,
      required double strokeW,
      required double sagy}) {
    final p = Paint()
      ..shader = LinearGradient(colors: colors, stops: stops)
          .createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;
    final path = Path()
      ..moveTo(0, h * 0.20)
      ..quadraticBezierTo(w / 2, h * sagy, w, h * 0.20);
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ──────────────────────────────────────────────────────────────────────────────
//  RAYS PAINTER
// ──────────────────────────────────────────────────────────────────────────────
class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final gPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.30),
        radius: 0.65,
        colors: [
          const Color(0xFF78BEFF).withOpacity(0.22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, s.width, s.height));
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), gPaint);

    final shaftP = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x2464B4FF), Colors.transparent],
        stops: [0.0, 0.70],
      ).createShader(Rect.fromLTWH(0, 0, s.width, s.height));
    final shaft = Path()
      ..moveTo(s.width * 0.38, 0)
      ..lineTo(s.width * 0.62, 0)
      ..lineTo(s.width * 0.78, s.height)
      ..lineTo(s.width * 0.22, s.height)
      ..close();
    c.drawPath(shaft, shaftP);

    final cx = s.width / 2;
    final cy = s.height * 0.35;
    final rayP = Paint()
      ..color = const Color(0xFFB4DCFF).withOpacity(0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 24; i++) {
      final angle = (i * 15.0 - 180) * math.pi / 180;
      c.drawLine(
        Offset(cx, cy),
        Offset(cx + math.cos(angle) * s.width,
            cy + math.sin(angle) * s.height * 2),
        rayP,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
//  COSMIC HEADER - Public Widget
// ══════════════════════════════════════════════════════════════════════════════
class CosmicHeader extends StatelessWidget {
  const CosmicHeader({
    super.key,
    this.onMenuTap,
    required this.onBellTap,
    required this.onAvatarTap,
    this.hasNotification = true,
    this.topPadding = 0.0,
  });
  final VoidCallback? onMenuTap;
  final VoidCallback onBellTap;
  final VoidCallback onAvatarTap;
  final bool hasNotification;
  final double topPadding;

  @override
  Widget build(BuildContext ctx) {
    return SizedBox(
      height: 99 + topPadding,
      child: Stack(children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.85),
                radius: 1.5,
                colors: [
                  Color(0xFF1AACCF),
                  Color(0xFF1178B4),
                  Color(0xFF0A4E8F),
                  Color(0xFF050F2A),
                  Color(0xFF020810),
                ],
                stops: [0.0, 0.16, 0.36, 0.62, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: topPadding - 18,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 180,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF3C82FF).withOpacity(0.40),
                  const Color(0xFF1446C8).withOpacity(0.13),
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
        Positioned.fill(child: CustomPaint(painter: _RaysPainter())),
        const Positioned.fill(child: _Stars()),
        const Positioned(top: 0, left: 0, right: 0, child: _SilverRim()),
        Positioned(
          top: topPadding + 8,
          left: 14,
          right: 14,
          height: 34,
          child: Row(children: [
            _IBtn(
              onTap: onMenuTap,
              child: const _HamburgerIcon(),
            ),
            const Spacer(),
            Center(
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: DecoratedBox(
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
                ),
                const NikonyxLogo.medium(),
                const Positioned(
                  top: 0,
                  child: _Flare(size: 11, opacity: 0.9),
                ),
                const Positioned(
                  right: 0,
                  child: _Flare(size: 7, opacity: 0.68),
                ),
                const Positioned(
                  left: 0,
                  child: _Flare(size: 7, opacity: 0.68),
                ),
              ]),
            ),
            const Spacer(),
            Row(mainAxisSize: MainAxisSize.min, children: [
              _IBtn(
                onTap: onBellTap,
                badge: hasNotification,
                child: const Icon(Icons.notifications_outlined,
                    color: Color(0xFFC8DCF4), size: 14),
              ),
              const SizedBox(width: 5),
              _IBtn(
                onTap: onAvatarTap,
                child: const Icon(Icons.person_outline,
                    color: Color(0xFFC8DCF4), size: 14),
              ),
            ]),
          ]),
        ),
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 30,
          child: CustomPaint(painter: _ArcSeparator()),
        ),
      ]),
    );
  }
}

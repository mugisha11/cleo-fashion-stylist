// ══════════════════════════════════════════════════════════════════════════════
//  dashboard_screen.dart
//  UI: 100% pixel-perfect clone of the NX Home v14 HTML mockup.
//  Backend: ALL original logic preserved exactly — no backend changes.
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:ui' show PlatformDispatcher;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/luxury_theme.dart';
import '../core/theme/dashboard_ui_colors.dart';
import '../core/widgets/luxury_components.dart';
import '../core/widgets/dashboard_components.dart';
import 'dart:convert';

import '../core/constants/trusted_retailers.dart';
import '../core/services/ai_chat_firestore_service.dart';
import '../core/services/backend_config_service.dart';
import '../core/services/open_router_service.dart';
import '../core/services/recommendations_service.dart';
import '../core/services/sound_service.dart';
import '../core/services/tryon_service.dart';
import '../core/models/wardrobe_item_model.dart';
import '../features/recommendations/providers/smart_outfit_suggestions_provider.dart';
import '../core/providers/user_image_provider.dart';
import '../core/providers/ai_recommendation_provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/settings/models/settings_state.dart';
import '../features/settings/providers/settings_provider.dart';
import '../features/wardrobe/providers/wardrobe_provider.dart'
    show wardrobeItemsProvider;
import '../features/social/providers/social_provider.dart';
import '../routes.dart';
import '../core/models/user_model.dart';
import '../core/widgets/fashion_drawer.dart';
import '../core/widgets/theme_wrapper.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  PALETTE — matches the HTML exactly
// ══════════════════════════════════════════════════════════════════════════════
// Cosmic header
const _cosmicTop    = Color(0xFF020810);
const _cosmicMid    = Color(0xFF050F2A);
const _cosmicDeep   = Color(0xFF0A1E58);
const _cosmicBright = Color(0xFF1848C0);
const _cosmicBlue   = Color(0xFF4880E0);
// Shimmer rim colours
const _rimL  = Color(0xFF1E2E50);
const _rimM  = Color(0xFF90B4D8);
const _rimW  = Color(0xFFFFFFFF);
const _rimC  = Color(0xFFC8DFF0);
const _rimE  = Color(0xFFE8F4FF);
// Body
const _bodyWhite    = Color(0xFFFFFFFF);
const _bodyBgLight  = Color(0xFFF6F9FF);
// Name / text
const _darkText  = Color(0xFF0C1E48);
const _midText   = Color(0xFF606880);
const _lightText = Color(0xFFA0AAC0);
// Separator
const _sepColor = Color(0xFFD4E8F8);
// Navy card
const _cardBg  = Color(0xFF0A1E58);
const _cardBg2 = Color(0xFF060F2E);
const _cardBg3 = Color(0xFF0D1E50);
const _cardBdr = Color(0x5C78B4FF);
// Occasion chips
const _occActiveBg  = Color(0xFF2A58C8);
const _occActiveBg2 = Color(0xFF1A3A9A);
const _occInactiveBg  = Color(0xFFF0F5FF);
const _occInactiveBg2 = Color(0xFFE4EDF8);
const _occBdr = Color(0xFF8AABC8); // inactive border tint
// Inspiration card
const _icardBdr1 = Color(0xFF8AA8CC);
const _icardBdr2 = Color(0xFFD4E8F8);
const _icardBdr3 = Color(0xFF7898B8);
// Footer
const _footerGradTop  = Color(0xFFB8C8E0);
const _footerGradBot  = Color(0xFFB0C4DC);
const _footerText     = Color(0xFF1A3060);
const _footerTextAct  = Color(0xFF0A1E58);
// Prompt bar
const _promptBg  = Color(0xFF05102A);
const _promptBg2 = Color(0xFF091636);
const _promptBdr = Color(0x596490FF);
// Mic button
const _micBg1 = Color(0xFF1A44B8);
const _micBg2 = Color(0xFF0F2880);
// Metallic divider
const _mdivBg1 = Color(0x4D96B9E6);
const _mdivBg2 = Color(0xCCC8E1F8);
// Chrome blue accent
const _blueAccent = Color(0xFF2255CC);
const _blueGlow   = Color(0xFF4488FF);

// ══════════════════════════════════════════════════════════════════════════════
//  COSMIC HEADER PAINTER — mirrors the CSS/SVG exactly
// ══════════════════════════════════════════════════════════════════════════════
class _CosmicPainter extends CustomPainter {
  const _CosmicPainter();

  @override
  void paint(Canvas c, Size s) {
    // Main radial background
    c.drawRect(
      Rect.fromLTWH(0, 0, s.width, s.height),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.9),
          radius: 1.4,
          colors: [
            _cosmicBlue, _cosmicBright, _cosmicDeep,
            _cosmicMid, _cosmicTop,
          ],
          stops: [0.0, 0.16, 0.36, 0.62, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, s.width, s.height)),
    );

    // Radial ellipse glow at top centre
    final glowC = Offset(s.width / 2, s.height * 0.35);
    c.drawOval(
      Rect.fromCenter(center: glowC, width: s.width * 1.1, height: s.height * 1.4),
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0x3878BEFF), Colors.transparent],
        ).createShader(Rect.fromCenter(center: glowC, width: s.width * 1.1, height: s.height * 1.4)),
    );

    // Ray cone upward
    final rayPath = Path()
      ..moveTo(s.width * 0.22, s.height * 1.3)
      ..lineTo(s.width * 0.38, -s.height * 0.2)
      ..lineTo(s.width * 0.62, -s.height * 0.2)
      ..lineTo(s.width * 0.78, s.height * 1.3)
      ..close();
    c.drawPath(rayPath, Paint()..color = const Color(0x2264B4FF));

    // Shimmer rim at very top
    c.drawRect(
      Rect.fromLTWH(0, 0, s.width, 5),
      Paint()
        ..shader = LinearGradient(
          colors: [_rimL, const Color(0xFF4868A8), _rimM, _rimC, _rimE, _rimW, _rimE, _rimC, _rimM, const Color(0xFF4868A8), _rimL],
          stops: const [0.0, 0.07, 0.16, 0.26, 0.36, 0.50, 0.64, 0.74, 0.84, 0.93, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, s.width, 5)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
//  ARC PAINTER — the curved chrome line at the bottom of the header
// ══════════════════════════════════════════════════════════════════════════════
class _ArcPainter extends CustomPainter {
  const _ArcPainter();

  @override
  void paint(Canvas c, Size s) {
    // Glow stroke
    final glow = Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, const Color(0x384878D8), const Color(0x706AA4FF), const Color(0x384878D8), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, s.width, s.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    // Main arc
    final main = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x591A2E50), const Color(0xE04868A8), const Color(0xFF90B4D8),
          const Color(0xFFC8DFF2), const Color(0xFFEEF6FF), const Color(0xFFFFFFFF),
          const Color(0xFFEEF6FF), const Color(0xFFC8DFF2), const Color(0xFF90B4D8),
          const Color(0xE04868A8), const Color(0x591A2E50),
        ],
        stops: const [0.0, 0.06, 0.16, 0.28, 0.42, 0.50, 0.58, 0.72, 0.84, 0.94, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, s.width, s.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;

    final inner = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x261A2E50), const Color(0xA46888B8), const Color(0xD9B0CCE4),
          const Color(0xFFDEEEFF), const Color(0xD9B0CCE4), const Color(0xA46888B8),
          const Color(0x261A2E50),
        ],
        stops: const [0.0, 0.10, 0.28, 0.50, 0.72, 0.90, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, s.width, s.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final path = Path()
      ..moveTo(0, 6)
      ..quadraticBezierTo(s.width / 2, 30, s.width, 6);

    final path2 = Path()
      ..moveTo(4, 5.3)
      ..quadraticBezierTo(s.width / 2, 27.5, s.width - 4, 5.3);

    final path3 = Path()
      ..moveTo(14, 2.5)
      ..quadraticBezierTo(s.width / 2, 18, s.width - 14, 2.5);

    c.drawPath(path, glow);
    c.drawPath(path, main);

    final highlight = Paint()
      ..color = const Color(0x8CFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    c.drawPath(path2, highlight);
    c.drawPath(path3, inner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
//  METALLIC DIVIDER — mirrors .mdiv
// ══════════════════════════════════════════════════════════════════════════════
class _MetallicDivider extends StatelessWidget {
  const _MetallicDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: const LinearGradient(
          colors: [
            Colors.transparent,
            Color(0x4D96B9E6),
            Color(0xCCC8E1F8),
            Color(0xFFFFFFFF),
            Color(0xCCC8E1F8),
            Color(0x4D96B9E6),
            Colors.transparent,
          ],
          stops: [0.0, 0.15, 0.40, 0.50, 0.60, 0.85, 1.0],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  THIN SEPARATOR — mirrors .sep
// ══════════════════════════════════════════════════════════════════════════════
class _ThinSep extends StatelessWidget {
  const _ThinSep();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Color(0x80B4CDE8),
            Color(0xBFD2E8FA),
            Color(0x80B4CDE8),
            Colors.transparent,
          ],
          stops: [0.0, 0.20, 0.50, 0.80, 1.0],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  GLASS ICON BUTTON (ibtn in HTML)
// ══════════════════════════════════════════════════════════════════════════════
class _IBtn extends StatelessWidget {
  const _IBtn({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0x29FFFFFF), Color(0x0FFFFFFF)],
          ),
          border: Border.all(color: const Color(0x42FFFFFF), width: 1),
          boxShadow: const [
            BoxShadow(color: Color(0x661E001E), blurRadius: 6),
            BoxShadow(color: Color(0x2EFFFFFF), blurRadius: 0, offset: Offset(0, 1)),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  LOGO RING — mirrors .logo-ring with halo, ring, inner, flares
// ══════════════════════════════════════════════════════════════════════════════
class _LogoRing extends StatelessWidget {
  const _LogoRing();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80, height: 80,
      child: Stack(alignment: Alignment.center, children: [
        // Halo
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              Color(0x7A50A0FF), Color(0x2D2864DC), Colors.transparent,
            ], stops: [0.0, 0.36, 0.65]),
          ),
        ),
        // Conic ring
        Container(
          width: 50, height: 50,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              startAngle: 0.26, // ~15 deg
              colors: [
                Color(0xFF1E3060), Color(0xFF5080B0), Color(0xFF90B8D8),
                Color(0xFFC8DCF0), Color(0xFFE8F4FF), Color(0xFFFFFFFF),
                Color(0xFFE8F4FF), Color(0xFFC8DCF0), Color(0xFF90B8D8),
                Color(0xFF5080B0), Color(0xFF1E3060),
              ],
            ),
            boxShadow: [
              BoxShadow(color: Color(0x7A96C8FF), blurRadius: 14),
              BoxShadow(color: Color(0x593078E6), blurRadius: 30),
              BoxShadow(color: Color(0x59000032), blurRadius: 6),
            ],
          ),
          // Inner dark circle
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.2, -0.3),
                colors: [Color(0xFF1A3A7A), Color(0xFF0D1E50), Color(0xFF08122E)],
              ),
              border: Border.all(color: const Color(0x4DB4DCFF), width: 1),
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x4DB4DCFF), width: 1),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // SVG-equivalent: dashed rect + checkmark
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3.5),
                        border: Border.all(color: const Color(0x6896C8FF), width: 1.1),
                      ),
                      child: const Icon(Icons.check, color: Color(0x8C96C8FF), size: 12),
                    ),
                    const SizedBox(height: 1),
                    const Text('logo', style: TextStyle(fontSize: 6.5, color: Color(0x6696C8FF))),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Top flare (cross)
        Positioned(
          top: 2,
          child: _FlareCross(size: 11, color: const Color(0xE6DCF0FF)),
        ),
        // Right flare
        Positioned(
          right: 3,
          child: _FlareSmall(color: const Color(0xADC8E6FF)),
        ),
        // Left flare
        Positioned(
          left: 3,
          child: _FlareSmall(color: const Color(0xADC8E6FF)),
        ),
      ]),
    );
  }
}

class _FlareCross extends StatelessWidget {
  const _FlareCross({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _FlarePainter(color: color),
    );
  }
}

class _FlarePainter extends CustomPainter {
  final Color color;
  const _FlarePainter({required this.color});

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = color..strokeWidth = 1..style = PaintingStyle.stroke;
    final p2 = Paint()..color = color.withOpacity(0.3)..strokeWidth = 0.6..style = PaintingStyle.stroke;
    c.drawLine(Offset(s.width / 2, 0), Offset(s.width / 2, s.height), p);
    c.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), p);
    c.drawLine(Offset(s.width * .14, s.height * .14), Offset(s.width * .86, s.height * .86), p2);
    c.drawLine(Offset(s.width * .86, s.height * .14), Offset(s.width * .14, s.height * .86), p2);
  }

  @override
  bool shouldRepaint(covariant _FlarePainter old) => old.color != color;
}

class _FlareSmall extends StatelessWidget {
  const _FlareSmall({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(7, 7),
      painter: _SmallFlarePainter(color: color),
    );
  }
}

class _SmallFlarePainter extends CustomPainter {
  final Color color;
  const _SmallFlarePainter({required this.color});

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = color..strokeWidth = .8..style = PaintingStyle.stroke;
    c.drawLine(Offset(s.width / 2, 0), Offset(s.width / 2, s.height), p);
    c.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
//  HOME LOGO (footer) — mirrors .home-logo
// ══════════════════════════════════════════════════════════════════════════════
class _HomeLogo extends StatelessWidget {
  const _HomeLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          startAngle: 0.26,
          colors: [
            Color(0xFF1E3060), Color(0xFF5080B0), Color(0xFF90B8D8),
            Color(0xFFC8DCF0), Color(0xFFE8F4FF), Color(0xFFFFFFFF),
            Color(0xFFE8F4FF), Color(0xFFC8DCF0), Color(0xFF90B8D8),
            Color(0xFF5080B0), Color(0xFF1E3060),
          ],
        ),
        boxShadow: [
          BoxShadow(color: Color(0x7382B4FF), blurRadius: 10),
          BoxShadow(color: Color(0x473278DC), blurRadius: 18),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment(-0.2, -0.3),
            colors: [Color(0xFF1A3A7A), Color(0xFF0D1E50), Color(0xFF08122E)],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x478AB4FF), width: 1),
          ),
          child: const Icon(Icons.check, color: Color(0x6696C8FF), size: 14),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  OCCASION CHIP
// ══════════════════════════════════════════════════════════════════════════════
class _OccChip extends StatelessWidget {
  const _OccChip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: active
              ? const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [_occActiveBg, _occActiveBg2],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [_occInactiveBg, _occInactiveBg2],
                ),
          border: Border.all(
            color: active ? const Color(0x806490FF) : const Color(0x8CB4CDFA),
            width: 1,
          ),
          boxShadow: active
              ? [
                  const BoxShadow(color: Color(0x421440C8), blurRadius: 8, offset: Offset(0, 3)),
                  const BoxShadow(color: Color(0x2EFFFFFF), blurRadius: 0, offset: Offset(0, 1)),
                ]
              : [
                  const BoxShadow(color: Color(0x121432780), blurRadius: 5, offset: Offset(0, 2)),
                  const BoxShadow(color: Color(0xE6FFFFFF), blurRadius: 0, offset: Offset(0, 1)),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            color: active ? Colors.white : _darkText,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ACTION CARD — mirrors .act-card (navy pill with icon + label + chevron)
// ══════════════════════════════════════════════════════════════════════════════
class _ActCard extends StatelessWidget {
  const _ActCard({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 109, height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [_cardBg, _cardBg2, _cardBg3],
            stops: [0.0, 0.45, 1.0],
          ),
          border: Border.all(color: _cardBdr, width: 1),
          boxShadow: const [
            BoxShadow(color: Color(0x730308280), blurRadius: 16, offset: Offset(0, 5)),
            BoxShadow(color: Color(0x4DA0D2FF), blurRadius: 0, offset: Offset(0, 1)),
          ],
        ),
        child: Stack(children: [
          // Sheen sweep
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1, -1), end: Alignment(0.3, 1),
                    colors: [Colors.transparent, Color(0x0EA0D2FF), Colors.transparent],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Bottom glow bar (::after)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 1.5,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                gradient: LinearGradient(colors: [Colors.transparent, Color(0x8C50A0FF), Colors.transparent]),
              ),
            ),
          ),
          // Content row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                // Icon circle
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0x2EFFFFFF), Color(0x0FFFFFFF)],
                    ),
                    border: Border.all(color: const Color(0x47A0D2FF), width: 1),
                  ),
                  child: Icon(icon, color: const Color(0xEEB4D7FF), size: 12),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xF2D7EBFF),
                      letterSpacing: 0.1,
                      height: 1.25,
                    ),
                  ),
                ),
                // Mini chevron
                const Icon(Icons.chevron_right, color: Color(0x808CC3FF), size: 12),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  INSPIRATION CARD — mirrors .insp-card with triple-border shadow
// ══════════════════════════════════════════════════════════════════════════════
class _InspCard extends StatelessWidget {
  const _InspCard({
    required this.title,
    required this.sectionLabel,
    required this.sub,
    required this.bgColor,
    required this.dotActive,
    required this.totalDots,
    required this.imageUrl,
    required this.onTap,
  });
  final String title, sectionLabel, sub, imageUrl;
  final Color bgColor;
  final int dotActive, totalDots;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 148,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section title with lines
            Row(children: [
              Expanded(child: Container(height: 1, decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, Color(0x666488C8)]),
              ))),
              const SizedBox(width: 4),
              Text(sectionLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _darkText, letterSpacing: .3)),
              const SizedBox(width: 4),
              Expanded(child: Container(height: 1, decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0x666488C8), Colors.transparent]),
              ))),
            ]),
            const SizedBox(height: 5),
            // Card with triple shadow border
            Container(
              width: 148,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(color: Color(0xFF8AA8CC), blurRadius: 0, spreadRadius: 1.5),
                  BoxShadow(color: Color(0xFFD4E8F8), blurRadius: 0, spreadRadius: 3),
                  BoxShadow(color: Color(0xFF7898B8), blurRadius: 0, spreadRadius: 4.5),
                  BoxShadow(color: Color(0x211432780), blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(children: [
                  // Image area
                  Container(
                    height: 90, width: double.infinity,
                    color: bgColor,
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imagePlaceholder())
                        : _imagePlaceholder(),
                  ),
                  // Label area
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: _darkText, height: 1.35)),
                      const SizedBox(height: 2),
                      Text(sub, style: const TextStyle(fontSize: 8.5, color: Color(0xFF6070A0), height: 1.3)),
                      const SizedBox(height: 5),
                      // Dot indicators
                      Row(children: List.generate(totalDots, (i) {
                        final on = i == dotActive;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: on ? 9 : 4, height: 4,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: on ? const Color(0xFF2A58C8) : const Color(0x476488C8),
                          ),
                        );
                      })),
                    ]),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: bgColor,
      child: Center(
        child: Container(
          width: 72, height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x725A8CC8), width: 1.5, style: BorderStyle.solid),
            color: Colors.white.withOpacity(0.25),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.image_outlined, color: Color(0x7A5A8CC8), size: 20),
            const SizedBox(height: 3),
            const Text('Add Image', style: TextStyle(fontSize: 7.5, color: Color(0x7A5A8CC8)), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  FOOTER NAV ITEM
// ══════════════════════════════════════════════════════════════════════════════
class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? _footerTextAct : _footerText;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 18,
              shadows: const [Shadow(color: Color(0x261432780), blurRadius: 1, offset: Offset(0, 1))]),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color, letterSpacing: .1,
                  shadows: const [Shadow(color: Color(0xCCFFFFFF), blurRadius: 0, offset: Offset(0, 1))]),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _NavSep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.5, height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0x8C3C78DC), Color(0xB35096FF), Color(0x8C3C78DC), Colors.transparent],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  NX CHAT COMPONENTS (from original — unchanged)
// ══════════════════════════════════════════════════════════════════════════════
class _NxLogo extends StatelessWidget {
  const _NxLogo({this.d = 92.0});
  final double d;
  @override
  Widget build(BuildContext ctx) => SizedBox(
      width: d * 1.32, height: d * 1.32,
      child: Stack(alignment: Alignment.center, children: [
        Container(
            width: d * 1.32, height: d * 1.32,
            decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Color(0x886699EE), Color(0x224499FF), Colors.transparent,
                ], stops: [0.0, 0.4, 1.0]))),
        Container(
            width: d, height: d,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(colors: [
                  Color(0xFF2A4A7A), Color(0xFFAABBDD), Color(0xFFEEF5FF),
                  Color(0xFFCCDDFF), Color(0xFF6688BB), Color(0xFFDDEEFF),
                  Color(0xFF4466AA), Color(0xFF2A4A7A),
                ]),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.55), blurRadius: 14, spreadRadius: 2),
                  BoxShadow(color: const Color(0xFF4488FF).withOpacity(0.4), blurRadius: 28, spreadRadius: 4),
                ])),
        Container(
            width: d * 0.84, height: d * 0.84,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                    center: Alignment(-0.4, -0.4),
                    colors: [Color(0xFF2255BB), Color(0xFF0E1F55), Color(0xFF060F28)],
                    stops: [0.0, 0.45, 1.0]),
                border: Border.all(color: const Color(0xFF3355AA).withOpacity(0.5), width: 1))),
        ShaderMask(
            shaderCallback: (r) => const LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFFFFF), Color(0xFFCCDDFF), Color(0xFF8899CC)],
                ).createShader(r),
            child: Text('NX',
                style: TextStyle(
                    color: Colors.white, fontSize: d * 0.26,
                    fontWeight: FontWeight.w900, letterSpacing: d * 0.04,
                    shadows: const [Shadow(color: Color(0xFF99BBFF), blurRadius: 16)]))),
        Positioned(
            top: d * 0.12,
            child: Container(
                width: d * 0.42, height: d * 0.034,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: LinearGradient(colors: [
                      Colors.transparent, Colors.white.withOpacity(0.75), Colors.transparent,
                    ])))),
      ]));
}

// ══════════════════════════════════════════════════════════════════════════════
//  DATA MODELS (preserved from original — no changes)
// ══════════════════════════════════════════════════════════════════════════════
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imageUrl;
  final bool isError;
  final Uint8List? tryOnResultImageBytes;
  final List<WardrobeItemModel>? wardrobeItems;
  final bool isTryOnInProgress;
  final String? buyLinkUrl;
  final String? externalImageUrl;
  final String? externalDisplayImageUrl;
  final String? externalProductPageUrl;
  final List<SearchedProduct>? searchedProducts;

  ChatMessage({
    required this.id, required this.text, required this.isUser, required this.timestamp,
    this.imageUrl, this.isError = false, this.tryOnResultImageBytes, this.wardrobeItems,
    this.isTryOnInProgress = false, this.buyLinkUrl, this.externalImageUrl,
    this.externalDisplayImageUrl, this.externalProductPageUrl, this.searchedProducts,
  });
}

class SearchedProduct {
  final String title, imageUrl, link;
  final String? displayImageUrl;
  SearchedProduct({required this.title, required this.imageUrl, required this.link, this.displayImageUrl});
}

// ══════════════════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ── ALL ORIGINAL BACKEND FIELDS ──────────────────────────────────────────
  late TextEditingController _messageController;
  late ScrollController _chatScrollController;
  late AnimationController _wardrobeSlideController;
  final OpenRouterService _openRouter = OpenRouterService();
  final TryOnService _tryOnService = TryOnService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ImagePicker _imagePicker = ImagePicker();
  final AiChatFirestoreService _aiChatService = AiChatFirestoreService();

  List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      text: 'Hello! I\'m Nikonyx, your AI fashion assistant. How can I help you today?',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  bool _showWardrobePanel = false;
  bool _showChatView = false;
  bool _isAITyping = false;
  bool _isListening = false;
  String _lastWords = '';
  Uint8List? _attachedImageBytes;

  // ── UI STATE ─────────────────────────────────────────────────────────────
  int _navIndex = 2;
  int _occasionIdx = 0; // "Date" active by default (matches HTML)
  bool _micPulsing = false;

  static const _occasions = [
    'Date', 'Wedding', 'Dining Out', 'Daily', 'Working', 'Interview', 'Business',
  ];

  // 4 cards: Inspiration / Fits Wardrobe / Trends / Friends Space  — matches HTML
  static const _inspCards = [
    (
      sectionLabel: 'Inspiration',
      title: 'Elevated Formal\nConfidence',
      sub: 'Navy suit · Sharp fit',
      dotActive: 1,
      totalDots: 3,
      bg: Color(0xFFBCD0EA),
      url: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=300&h=200&fit=crop',
    ),
    (
      sectionLabel: 'Fits Wardrobe',
      title: 'Smart Casual\nMade Effortless',
      sub: 'Layers · Relaxed fit',
      dotActive: 2,
      totalDots: 4,
      bg: Color(0xFFC8DAF0),
      url: 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=300&h=200&fit=crop',
    ),
    (
      sectionLabel: 'Trends',
      title: 'Evening\nSophistication',
      sub: 'Charcoal · Slim cut',
      dotActive: 0,
      totalDots: 3,
      bg: Color(0xFFCCD4E8),
      url: 'https://images.unsplash.com/photo-1515575227652-8d992ee8c5d1?w=300&h=200&fit=crop',
    ),
    (
      sectionLabel: 'Friends Space',
      title: 'Spring\nGarden Party',
      sub: 'Green · Fresh look',
      dotActive: 2,
      totalDots: 3,
      bg: Color(0xFFD4E4F0),
      url: 'https://images.unsplash.com/photo-1520975916090-3105956dac38?w=300&h=200&fit=crop',
    ),
  ];

  // Action cards — 5 items matching HTML exactly
  static const _actCards = [
    (icon: Icons.person_outline,            label: 'Create\nOutfits',   route: Routes.tryon),
    (icon: Icons.bookmark_outline,          label: 'Saved\nOutfits',    route: Routes.wardrobe),
    (icon: Icons.shopping_bag_outlined,     label: 'Shopping',          route: Routes.recommendations),
    (icon: Icons.camera_alt_outlined,       label: 'Try-On',            route: Routes.tryon),
    (icon: Icons.people_outline,            label: 'Friends\nSpace',    route: Routes.styleFeed),
  ];

  // ── LIFECYCLE ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _chatScrollController = ScrollController();
    _wardrobeSlideController =
        AnimationController(duration: DesignTokens.durationMedium, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadChatFromDb());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    _wardrobeSlideController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ALL ORIGINAL BACKEND METHODS — PRESERVED EXACTLY (no changes)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _loadChatFromDb() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null || uid.isEmpty || !mounted) return;
    try {
      final dtos = await _aiChatService.getMessages(uid);
      if (!mounted) return;
      if (dtos.isNotEmpty) setState(() { _messages = dtos.map(_chatMessageFromDto).toList(); });
    } catch (_) {}
  }

  void _persistMessage(ChatMessage m) {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null || uid.isEmpty) return;
    _aiChatService.saveMessage(uid, _dtoFromChatMessage(m));
  }

  AiChatMessageDto _dtoFromChatMessage(ChatMessage m) => AiChatMessageDto(
      id: m.id, text: m.text, isUser: m.isUser, timestamp: m.timestamp,
      imageUrl: m.imageUrl, isError: m.isError, buyLinkUrl: m.buyLinkUrl,
      externalImageUrl: m.externalImageUrl, externalDisplayImageUrl: m.externalDisplayImageUrl,
      externalProductPageUrl: m.externalProductPageUrl,
      searchedProducts: m.searchedProducts?.map((p) => {
        'title': p.title, 'imageUrl': p.imageUrl, 'link': p.link, 'displayImageUrl': p.displayImageUrl,
      }).toList());

  ChatMessage _chatMessageFromDto(AiChatMessageDto d) => ChatMessage(
      id: d.id, text: d.text, isUser: d.isUser, timestamp: d.timestamp,
      imageUrl: d.imageUrl, isError: d.isError, buyLinkUrl: d.buyLinkUrl,
      externalImageUrl: d.externalImageUrl, externalDisplayImageUrl: d.externalDisplayImageUrl,
      externalProductPageUrl: d.externalProductPageUrl,
      searchedProducts: d.searchedProducts?.map((map) => SearchedProduct(
          title: map['title'] ?? '', imageUrl: map['imageUrl'] ?? '',
          link: map['link'] ?? '', displayImageUrl: map['displayImageUrl'])).toList());

  void _toggleWardrobePanel() {
    if (_showWardrobePanel) _wardrobeSlideController.reverse();
    else _wardrobeSlideController.forward();
    setState(() => _showWardrobePanel = !_showWardrobePanel);
  }

  Future<void> _pickImage() async {
    if (_isListening) return;
    final result = await showModalBottomSheet<Object>(
        context: context,
        builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Photo from gallery'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
          if (!kIsWeb) ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Take photo'), onTap: () => Navigator.pop(context, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.checkroom_outlined), title: const Text('From wardrobe'), onTap: () => Navigator.pop(context, 'wardrobe')),
          const SizedBox(height: 8),
        ])));
    if (result == null || !mounted) return;
    if (result == 'wardrobe') { await _pickImageFromWardrobe(); return; }
    final source = result as ImageSource;
    try {
      final XFile? picked = await _imagePicker.pickImage(source: source, imageQuality: 85, maxWidth: 1200);
      if (picked != null && mounted) {
        final bytes = await picked.readAsBytes();
        if (mounted) setState(() => _attachedImageBytes = bytes);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not pick image: $e'), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _pickImageFromWardrobe() async {
    ref.invalidate(wardrobeItemsProvider);
    List<WardrobeItemModel> items;
    try { items = await ref.read(wardrobeItemsProvider.future); } catch (_) { items = []; }
    if (!mounted) return;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your wardrobe is empty. Add items at Wardrobe.'), behavior: SnackBarBehavior.floating));
      return;
    }
    final isDark = context.isDarkMode;
    await showModalBottomSheet<void>(
        context: context, isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.85, expand: false,
            builder: (context, scrollController) => Container(
                decoration: BoxDecoration(
                    color: isDark ? DesignTokens.darkBackground : DesignTokens.lightBackground,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                child: Column(children: [
                  Padding(padding: const EdgeInsets.all(16), child: Row(children: [
                    Text('Choose from wardrobe', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ])),
                  Expanded(child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final imageUrl = item.processedImageUrl ?? item.imageUrl;
                        return GestureDetector(
                            onTap: () async {
                              try {
                                final response = await http.get(Uri.parse(imageUrl));
                                if (response.statusCode == 200 && context.mounted) {
                                  Navigator.pop(context);
                                  if (mounted) setState(() => _attachedImageBytes = response.bodyBytes);
                                }
                              } catch (e) {
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load image: $e'), behavior: SnackBarBehavior.floating));
                              }
                            },
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                                child: Stack(fit: StackFit.expand, children: [
                                  Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard, child: Icon(Icons.checkroom, color: context.textSecondaryColor))),
                                  Positioned(left: 4, right: 4, bottom: 4, child: Text(item.category, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, shadows: const [Shadow(color: Colors.black54, blurRadius: 4)]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ])));
                      })),
                ]))));
  }

  void _clearAttachedImage() => setState(() => _attachedImageBytes = null);

  String _buildUserPreferencesSummary(UserModel? user, SettingsState settings) {
    final parts = <String>[];
    final body = user?.onboardingData?.bodyInputs;
    final onboarding = user?.onboardingData;
    if (body?.gender != null && body!.gender.isNotEmpty) parts.add('Gender: ${body.gender}');
    else parts.add('Gender: not specified (ask if relevant)');
    final bodyType = body?.bodyType ?? settings.bodyType;
    if (bodyType != null && bodyType.toString().isNotEmpty) parts.add('Body type: $bodyType');
    final height = body?.height ?? settings.height;
    if (height != null) parts.add('Height: ${height.toStringAsFixed(0)} cm');
    if (settings.preferredStyles.isNotEmpty) parts.add('Preferred styles: ${settings.preferredStyles.join(', ')}');
    if (settings.colorPreferences.isNotEmpty) parts.add('Color preferences: ${settings.colorPreferences.join(', ')}');
    if (settings.eventPreferences.isNotEmpty) parts.add('Occasions/events: ${settings.eventPreferences.join(', ')}');
    if (onboarding != null) {
      if (onboarding.fashionStyle.isNotEmpty) parts.add('Fashion style (go-to): ${onboarding.fashionStyle}');
      if (onboarding.favoriteColors.isNotEmpty) parts.add('Favorite colors: ${onboarding.favoriteColors}');
      if (onboarding.occasion.isNotEmpty) parts.add('Typical occasion: ${onboarding.occasion}');
      if (onboarding.budget.isNotEmpty) parts.add('Budget: ${onboarding.budget}');
      if (onboarding.styleInspiration.isNotEmpty) parts.add('Style inspiration: ${onboarding.styleInspiration}');
    }
    if (parts.isEmpty) return 'No preferences set yet; ask the user if gender or style matters.';
    return parts.join('\n');
  }

  void _onQuickActionTap(String action) {
    String prompt;
    switch (action) {
      case 'tips': prompt = 'Give me styling tips for my wardrobe and how to put outfits together.'; break;
      case 'favorites': prompt = 'Show my wardrobe and help me pick my favorite looks.'; break;
      case 'trending': prompt = "What's trending in fashion right now? Show me some options I can try on."; break;
      case 'style': prompt = 'Help me with my personal style — what suits me and what pieces am I missing?'; break;
      default: return;
    }
    _messageController.text = prompt;
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _attachedImageBytes == null) return;
    _messageController.clear();
    HapticFeedback.mediumImpact();
    SoundService.play(AppSound.messageSent);
    final hadImage = _attachedImageBytes != null;
    if (mounted) setState(() => _attachedImageBytes = null);
    final displayText = text.isEmpty && hadImage ? '[Attached an image]' : text;
    final userMessage = ChatMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), text: displayText, isUser: true, timestamp: DateTime.now(), imageUrl: hadImage ? 'attached' : null);
    setState(() { _messages.add(userMessage); _isAITyping = true; });
    _persistMessage(userMessage);
    _scrollToBottom();
    try {
      final apiKey = await OpenRouterService.getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        if (mounted) {
          final errMsg = ChatMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), text: 'Add your OpenRouter API key in Settings → AI & Try-On Settings → Nikonyx Chat API Key to chat. Get a key at openrouter.ai.', isUser: false, timestamp: DateTime.now(), isError: true);
          setState(() { _messages.add(errMsg); _isAITyping = false; });
          _persistMessage(errMsg); _scrollToBottom();
        }
        return;
      }
      final currentUser = ref.read(currentUserProvider).value;
      final settings = ref.read(settingsProvider);
      final wardrobeAsync = ref.read(wardrobeItemsProvider);
      final wardrobeSummary = wardrobeAsync.valueOrNull?.map((WardrobeItemModel item) => {'id': item.id, 'name': '${item.category}${item.colorTags.isNotEmpty ? ' (${item.colorTags.join(', ')})' : ''}', 'category': item.category}).toList().cast<Map<String, String>>();
      final userPreferencesSummary = _buildUserPreferencesSummary(currentUser, settings);
      final userCountryCode = PlatformDispatcher.instance.locale.countryCode;
      final systemPrompt = OpenRouterService.buildFashionSystemPrompt(userName: currentUser?.displayName ?? 'User', wardrobeSummary: wardrobeSummary ?? [], savedPhotoHint: 'User can try on outfits; their photo is saved in Settings.', userCountryCode: (userCountryCode != null && userCountryCode.isNotEmpty) ? userCountryCode : null, userPreferencesSummary: userPreferencesSummary);
      final history = _messages.where((m) => !m.isError).map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text}).toList().cast<Map<String, String>>();
      final response = await _openRouter.chatWithFallback(messages: history, systemPrompt: systemPrompt, temperature: 0.7, maxTokens: 1024);
      if (mounted) {
        final (displayText2, tryOnId, showWardrobe, scheduleDate, buyLinkUrl, searchQuery) = _parseAssistantResponse(response);
        final userAskedForWardrobe = _userAskedForWardrobe(text);
        final showWardrobeGrid = showWardrobe || (userAskedForWardrobe && tryOnId == null && scheduleDate == null);
        final aiMessage = ChatMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), text: displayText2, isUser: false, timestamp: DateTime.now(), buyLinkUrl: buyLinkUrl);
        setState(() { _messages.add(aiMessage); _isAITyping = false; });
        _scrollToBottom(); SoundService.play(AppSound.messageReceived);
        if (tryOnId != null) _runTryOnInChat(tryOnId);
        else if (showWardrobeGrid) _showWardrobeInChat();
        else if (scheduleDate != null) _openScheduleForDate(scheduleDate);
        else if (searchQuery != null && searchQuery.isNotEmpty) _fetchAndShowSearchedProducts(searchQuery);
        final imageUrl = _extractDirectImageUrl(text);
        if (imageUrl != null) _runTryOnWithGarmentUrl(imageUrl);
        else { final productPageUrl = _extractProductPageUrl(text); if (productPageUrl != null) _fetchAndShowExternalProduct(productPageUrl); }
      }
    } catch (e) {
      if (mounted) {
        final errStr = e is OpenRouterException ? e.message : e.toString();
        final errorChatMsg = ChatMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), text: 'Sorry, something went wrong: $errStr', isUser: false, timestamp: DateTime.now(), isError: true);
        setState(() { _messages.add(errorChatMsg); _isAITyping = false; });
        _persistMessage(errorChatMsg); _scrollToBottom();
      }
    }
  }

  String? _extractDirectImageUrl(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return null;
    if (isDirectImageUrl(trimmed)) return trimmed;
    final words = trimmed.split(RegExp(r'\s+'));
    for (final w in words) { final clean = w.replaceAll(RegExp(r'[.,!?)]+$'), ''); if (isDirectImageUrl(clean)) return clean; }
    return null;
  }

  String? _extractProductPageUrl(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return null;
    final urlPattern = RegExp(r'https?://[^\s<>"{}|\\^`\[\]]+', caseSensitive: false);
    final match = urlPattern.firstMatch(trimmed);
    if (match == null) return null;
    var url = (match.group(0) ?? '').replaceAll(RegExp(r'[.,!?)]+$'), '');
    if (url.isEmpty || isDirectImageUrl(url)) return null;
    return url;
  }

  Future<void> _fetchAndShowExternalProduct(String pageUrl) async {
    String baseUrl;
    try { baseUrl = await BackendConfigService.getBackendUrl(); } catch (_) { baseUrl = 'http://localhost:8001'; }
    final uri = Uri.parse('$baseUrl/link-preview').replace(queryParameters: {'url': pageUrl});
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200 || resp.body.isEmpty) return;
      final data = jsonDecode(resp.body) as Map<String, dynamic>?;
      if (data == null) return;
      final imageUrl = data['image_url'] as String?;
      final title = data['title'] as String?;
      final pageUrlReturned = data['page_url'] as String? ?? pageUrl;
      if (imageUrl == null || imageUrl.isEmpty) return;
      if (!mounted) return;
      final displayImageUrl = '$baseUrl/proxy-image?url=${Uri.encodeComponent(imageUrl)}';
      final previewMsg = ChatMessage(id: 'preview-${DateTime.now().millisecondsSinceEpoch}', text: title?.isNotEmpty == true ? title! : 'From your link — try it on or buy below.', isUser: false, timestamp: DateTime.now(), externalImageUrl: imageUrl, externalDisplayImageUrl: displayImageUrl, externalProductPageUrl: pageUrlReturned);
      setState(() { _messages.add(previewMsg); });
      _persistMessage(previewMsg); _scrollToBottom();
    } catch (_) {}
  }

  Future<void> _fetchAndShowSearchedProducts(String query) async {
    String baseUrl;
    try { baseUrl = await BackendConfigService.getBackendUrl(); } catch (_) { baseUrl = 'http://localhost:8001'; }
    final uri = Uri.parse('$baseUrl/product-search').replace(queryParameters: {'q': query, 'limit': '8'});
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200 || resp.body.isEmpty) return;
      final data = jsonDecode(resp.body) as Map<String, dynamic>?;
      if (data == null) return;
      final list = data['products'] as List<dynamic>?;
      if (list == null || list.isEmpty) return;
      final products = <SearchedProduct>[];
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        final title = e['title'] as String? ?? '';
        final imageUrl = e['image_url'] as String? ?? '';
        final link = e['link'] as String? ?? '';
        if (title.isEmpty && imageUrl.isEmpty) continue;
        final displayImageUrl = imageUrl.isNotEmpty ? '$baseUrl/proxy-image?url=${Uri.encodeComponent(imageUrl)}' : null;
        products.add(SearchedProduct(title: title, imageUrl: imageUrl, link: link, displayImageUrl: displayImageUrl));
      }
      if (products.isEmpty) return;
      if (!mounted) return;
      final searchMsg = ChatMessage(id: 'search-${DateTime.now().millisecondsSinceEpoch}', text: 'Here are some options for "$query". Try on any image or tap Buy.', isUser: false, timestamp: DateTime.now(), searchedProducts: products);
      setState(() { _messages.add(searchMsg); });
      _persistMessage(searchMsg); _scrollToBottom();
    } catch (_) {}
  }

  bool _userAskedForWardrobe(String userMessage) {
    final lower = userMessage.trim().toLowerCase();
    if (!lower.contains('wardrobe')) return false;
    return lower.contains('show') || lower.contains('see') || lower.contains('list') || lower.contains('my ') || lower.contains('what') || lower.contains('browse');
  }

  (String, String?, bool, String?, String?, String?) _parseAssistantResponse(String raw) {
    String display = raw;
    String? tryOnId; bool showWardrobe = false; String? scheduleDate; String? buyLinkUrl; String? searchQuery;
    final lines = raw.split('\n'); final keep = <String>[];
    for (final line in lines) {
      final t = line.trim();
      if (t.startsWith('TRY_ON_ITEM_ID=')) tryOnId = t.substring('TRY_ON_ITEM_ID='.length).trim();
      else if (t == 'SHOW_WARDROBE') showWardrobe = true;
      else if (t.startsWith('SCHEDULE_FOR=')) scheduleDate = t.substring('SCHEDULE_FOR='.length).trim();
      else if (t.startsWith('BUY_LINK=')) { buyLinkUrl = t.substring('BUY_LINK='.length).trim(); if (!buyLinkUrl.startsWith('http')) buyLinkUrl = 'https://$buyLinkUrl'; }
      else if (t.startsWith('SEARCH_PRODUCTS=')) searchQuery = t.substring('SEARCH_PRODUCTS='.length).trim();
      else keep.add(line);
    }
    display = keep.join('\n').trim();
    if (display.isEmpty) display = raw;
    return (display, tryOnId, showWardrobe, scheduleDate, buyLinkUrl, searchQuery);
  }

  Future<void> _runTryOnInChat(String itemId) async {
    final items = ref.read(wardrobeItemsProvider).valueOrNull ?? [];
    final item = items.where((e) => e.id == itemId).firstOrNull;
    if (item == null) return;
    final garmentUrl = item.processedImageUrl ?? item.imageUrl;
    ref.invalidate(userImageBytesProvider);
    Uint8List? userBytes;
    try { userBytes = await ref.read(userImageBytesProvider.future); } catch (_) {}
    if (userBytes == null || userBytes.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add your try-on photo in Settings → Fashion Preferences, then try again.'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 4)));
      return;
    }
    final progressId = 'tryon-${DateTime.now().millisecondsSinceEpoch}';
    final progressMsg = ChatMessage(id: progressId, text: 'Try-on in progress...', isUser: false, timestamp: DateTime.now(), isTryOnInProgress: true);
    setState(() { _messages.add(progressMsg); _isAITyping = false; });
    _persistMessage(progressMsg); _scrollToBottom();
    try {
      final userBase64 = 'data:image/jpeg;base64,${base64Encode(userBytes)}';
      final result = await _tryOnService.generateTryOnPreviewFromBase64(userImageBase64: userBase64, clothingImageUrls: [garmentUrl]);
      Uint8List? resultBytes;
      if (result.startsWith('http')) { final res = await http.get(Uri.parse(result)); if (res.statusCode == 200) resultBytes = res.bodyBytes; }
      else if (result.startsWith('data:') && result.contains(',')) resultBytes = base64Decode(result.split(',').last);
      else if (result.length > 100 && !result.startsWith('http')) resultBytes = base64Decode(result);
      if (!mounted) return;
      final idx = _messages.indexWhere((m) => m.id == progressId);
      if (idx >= 0) { final doneMsg = ChatMessage(id: progressId, text: "Here's your try-on!", isUser: false, timestamp: DateTime.now(), tryOnResultImageBytes: resultBytes); setState(() { _messages[idx] = doneMsg; }); _persistMessage(doneMsg); }
      _scrollToBottom(); SoundService.play(AppSound.messageReceived);
    } catch (e) {
      if (!mounted) return;
      final idx = _messages.indexWhere((m) => m.id == progressId);
      if (idx >= 0) { final tryOnErrMsg = ChatMessage(id: progressId, text: 'Try-on failed: ${e is TryOnException ? e.getUserMessage() : e}', isUser: false, timestamp: DateTime.now(), isError: true); setState(() => _messages[idx] = tryOnErrMsg); _persistMessage(tryOnErrMsg); }
      _scrollToBottom();
    }
  }

  Future<void> _runTryOnWithGarmentUrl(String garmentUrl) async {
    ref.invalidate(userImageBytesProvider);
    Uint8List? userBytes;
    try { userBytes = await ref.read(userImageBytesProvider.future); } catch (_) {}
    if (userBytes == null || userBytes.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add your try-on photo in Settings → Fashion Preferences, then try again.'), behavior: SnackBarBehavior.floating));
      return;
    }
    final progressId = 'tryon-url-${DateTime.now().millisecondsSinceEpoch}';
    final progressMsg = ChatMessage(id: progressId, text: 'Try-on in progress (from link)...', isUser: false, timestamp: DateTime.now(), isTryOnInProgress: true);
    setState(() { _messages.add(progressMsg); });
    _persistMessage(progressMsg); _scrollToBottom();
    try {
      final userBase64 = 'data:image/jpeg;base64,${base64Encode(userBytes)}';
      final result = await _tryOnService.generateTryOnPreviewFromBase64(userImageBase64: userBase64, clothingImageUrls: [garmentUrl]);
      Uint8List? resultBytes;
      if (result.startsWith('http')) { final res = await http.get(Uri.parse(result)); if (res.statusCode == 200) resultBytes = res.bodyBytes; }
      else if (result.startsWith('data:') && result.contains(',')) resultBytes = base64Decode(result.split(',').last);
      else if (result.length > 100 && !result.startsWith('http')) resultBytes = base64Decode(result);
      if (!mounted) return;
      final idx = _messages.indexWhere((m) => m.id == progressId);
      if (idx >= 0) { final doneMsg = ChatMessage(id: progressId, text: "Here's your try-on from the link!", isUser: false, timestamp: DateTime.now(), tryOnResultImageBytes: resultBytes); setState(() => _messages[idx] = doneMsg); _persistMessage(doneMsg); }
      _scrollToBottom(); SoundService.play(AppSound.messageReceived);
    } catch (e) {
      if (!mounted) return;
      final idx = _messages.indexWhere((m) => m.id == progressId);
      if (idx >= 0) { final tryOnErrMsg = ChatMessage(id: progressId, text: 'Try-on failed: ${e is TryOnException ? e.getUserMessage() : e}', isUser: false, timestamp: DateTime.now(), isError: true); setState(() => _messages[idx] = tryOnErrMsg); _persistMessage(tryOnErrMsg); }
      _scrollToBottom();
    }
  }

  void _openScheduleForDate(String dateIso) {
    Navigator.of(context).pushNamed(Routes.calendar);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calendar opened — add an outfit for $dateIso'), behavior: SnackBarBehavior.floating));
  }

  Future<void> _showWardrobeInChat() async {
    ref.invalidate(wardrobeItemsProvider);
    List<WardrobeItemModel> list;
    try { list = await ref.read(wardrobeItemsProvider.future); } catch (_) { list = []; }
    if (!mounted) return;
    final msg = ChatMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), text: list.isEmpty ? 'Your wardrobe is empty. Add items in Wardrobe.' : "Here's your wardrobe. Tap Try on on any item.", isUser: false, timestamp: DateTime.now(), wardrobeItems: list.isEmpty ? null : list);
    setState(() { _messages.add(msg); _isAITyping = false; });
    _persistMessage(msg); _scrollToBottom();
  }

  Future<void> _startVoiceInput() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() { _isListening = false; _micPulsing = false; });
      if (_lastWords.trim().isNotEmpty && mounted) _messageController.text = _lastWords.trim();
      return;
    }
    final available = await _speech.initialize(
        onStatus: (status) { if (mounted && (status == 'done' || status == 'notListening')) { setState(() { _isListening = false; _micPulsing = false; }); if (_lastWords.trim().isNotEmpty) _messageController.text = _lastWords.trim(); } },
        onError: (error) { if (mounted) { setState(() { _isListening = false; _micPulsing = false; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.errorMsg), behavior: SnackBarBehavior.floating)); } });
    if (!mounted) return;
    if (!available) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice input is not available on this device.'), behavior: SnackBarBehavior.floating)); return; }
    _lastWords = '';
    setState(() { _isListening = true; _micPulsing = true; });
    HapticFeedback.mediumImpact();
    await _speech.listen(
        onResult: (result) { _lastWords = result.recognizedWords; if (mounted) { _messageController.text = _lastWords; _messageController.selection = TextSelection.fromPosition(TextPosition(offset: _lastWords.length)); setState(() {}); } },
        listenFor: const Duration(seconds: 30), pauseFor: const Duration(seconds: 3), partialResults: true, localeId: null);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) _chatScrollController.animateTo(_chatScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    ref.listen(socialUnreadCountProvider, (prev, next) {
      if (prev != null && next > prev && next > 0) SoundService.play(AppSound.notification);
    });
    if (_showChatView) return _buildAIChatScreen(context);
    return _buildHomeScreen(context);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HOME SCREEN — pixel-perfect clone of NX Home v14 HTML
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHomeScreen(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final firebaseUser = ref.watch(authStateProvider).value;
    final displayName = user?.displayName ?? firebaseUser?.displayName ?? 'there';
    final photoUrl = user?.avatarUrl ?? firebaseUser?.photoURL;
    final unreadCount = ref.watch(socialUnreadCountProvider) ?? 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _cosmicTop,
        drawer: const AppDrawer(currentRoute: Routes.dashboard),
        body: Column(children: [
          // ① COSMIC HEADER (99px)
          _buildCosmicHeader(unreadCount, photoUrl),

          // ② BODY (white)
          Expanded(
            child: Container(
              color: _bodyWhite,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(children: [
                  // Name + subtitle
                  _buildNameSection(displayName),
                  // Separator
                  const _ThinSep(),
                  // Portrait placeholder
                  _buildPortrait(photoUrl),
                  // Prompt bar
                  _buildPromptBar(),
                  // Occasion chips
                  _buildOccasionRow(),
                  // Metallic divider
                  const _MetallicDivider(),
                  // Action cards (horizontal)
                  _buildActionRow(context),
                  // Metallic divider
                  const _MetallicDivider(),
                  // Inspiration cards (horizontal)
                  _buildInspirationRow(context),
                  const SizedBox(height: 8),
                ]),
              ),
            ),
          ),

          // ③ FOOTER NAV
          _buildFooterNav(context),
        ]),
      ),
    );
  }

  // ── ① COSMIC HEADER ───────────────────────────────────────────────────────
  Widget _buildCosmicHeader(int unreadCount, String? photoUrl) {
    return SizedBox(
      height: 99,
      child: Stack(clipBehavior: Clip.none, children: [
        // Background
        Positioned.fill(child: const CustomPaint(painter: _CosmicPainter())),

        // Stars
        ..._stars(),

        // Top bar content
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(children: [
                  // Hamburger
                  _IBtn(
                    onTap: () { try { _scaffoldKey.currentState?.openDrawer(); } catch (_) {} },
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _hLine(12), const SizedBox(height: 3), _hLine(12), const SizedBox(height: 3), _hLine(9),
                    ]),
                  ),
                  const Spacer(),
                  // Logo ring centred
                  const _LogoRing(),
                  const Spacer(),
                  // Bell with badge
                  Stack(clipBehavior: Clip.none, children: [
                    _IBtn(
                      onTap: () {},
                      child: const Icon(Icons.notifications_outlined, color: Color(0xFFC8DCF4), size: 14),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: -1, right: -1,
                        child: Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE85A4F),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF060E28), width: 1.5),
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(width: 5),
                  // Profile
                  _IBtn(
                    onTap: () => Navigator.of(context).pushNamed(Routes.settings),
                    child: (photoUrl != null && photoUrl.isNotEmpty)
                        ? ClipOval(child: Image.network(photoUrl, width: 34, height: 34, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person_outline, color: Color(0xFFC8DCF4), size: 14)))
                        : const Icon(Icons.person_outline, color: Color(0xFFC8DCF4), size: 14),
                  ),
                ]),
              ),
            ),
          ),
        ),

        // Arc at bottom
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: CustomPaint(
            size: const Size(double.infinity, 30),
            painter: const _ArcPainter(),
          ),
        ),
      ]),
    );
  }

  Widget _hLine(double width) => Container(
    width: width, height: 1.5,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(1), color: const Color(0xFFC8DCF4)),
  );

  List<Widget> _stars() => [
    _star(top: .12, left: .06, size: 2.0, opacity: .75),
    _star(top: .05, left: .46, size: 1.5, opacity: .50),
    _star(top: .16, left: .87, size: 2.0, opacity: .70),
    _star(top: .04, left: .93, size: 2.5, opacity: .28),
    _star(top: .08, left: .30, size: 1.5, opacity: .40),
    _star(top: .03, left: .14, size: 1.5, opacity: .50),
    _star(top: .18, left: .68, size: 1.0, opacity: .45),
  ];

  Widget _star({required double top, required double left, required double size, required double opacity}) {
    return Positioned(
      top: 99 * top, left: MediaQuery.of(context).size.width * left,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(opacity),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: const Color(0xCCC8E6FF), blurRadius: size * 2)],
        ),
      ),
    );
  }

  // ── NAME + SUBTITLE ────────────────────────────────────────────────────────
  Widget _buildNameSection(String displayName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(children: [
        Text(displayName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _darkText, letterSpacing: -.2))
            .animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 3),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 14, height: 1, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Color(0xFFB0BCD0)]))),
          const SizedBox(width: 5),
          const Text('· Your NX Style Assistant ·', style: TextStyle(fontSize: 10, color: _midText, letterSpacing: .3)),
          const SizedBox(width: 5),
          Container(width: 14, height: 1, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFB0BCD0), Colors.transparent]))),
        ]).animate().fadeIn(duration: 500.ms, delay: 100.ms),
      ]),
    );
  }

  // ── PORTRAIT PLACEHOLDER ──────────────────────────────────────────────────
  Widget _buildPortrait(String? photoUrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Container(
        height: 118,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        child: Center(
          child: (photoUrl != null && photoUrl.isNotEmpty)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(photoUrl, height: 118, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _portraitPlaceholder()))
              : _portraitPlaceholder(),
        ),
      ).animate().fadeIn(duration: 500.ms, delay: 150.ms),
    );
  }

  Widget _portraitPlaceholder() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE8F0FF), Color(0xFFD4E2F8)]),
          border: Border.all(color: const Color(0x668090B8), width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x141E3C78), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: const Icon(Icons.person_outline, color: Color(0xFF8090B8), size: 28),
      ),
      const SizedBox(height: 6),
      const Text('User Portrait', style: TextStyle(fontSize: 10, color: _lightText, letterSpacing: .3)),
    ]);
  }

  // ── PROMPT BAR ────────────────────────────────────────────────────────────
  Widget _buildPromptBar() {
    return GestureDetector(
      onTap: () => setState(() => _showChatView = true),
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 8, 14, 6),
        padding: const EdgeInsets.fromLTRB(14, 7, 7, 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: const LinearGradient(
            colors: [_promptBg, _promptBg2, _promptBg],
            stops: [0.0, 0.5, 1.0],
          ),
          border: Border.all(color: _promptBdr, width: 1),
          boxShadow: const [
            BoxShadow(color: Color(0x2E1E50C8), blurRadius: 10),
            BoxShadow(color: Color(0x0FFFFFFF), blurRadius: 0, offset: Offset(0, 1)),
          ],
        ),
        child: Row(children: [
          // Mini NX logo pill
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(colors: [Color(0xFF4070C0), Color(0xFF98C0E8), Color(0xFFDCEEFF), Color(0xFF6090C8), Color(0xFF4070C0)]),
            ),
            child: const Center(child: Text('NX', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF0A1840)))),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 20, color: const Color(0x33FFFFFF)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(text: const TextSpan(style: TextStyle(fontSize: 11), children: [
              TextSpan(text: 'Ask NX for ', style: TextStyle(color: Color(0x99BED7FF))),
              TextSpan(text: 'Outfit Suggestions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ])),
          ),
          // Mic button
          GestureDetector(
            onTap: _startVoiceInput,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: _micPulsing
                      ? [const Color(0xFF1060E0), const Color(0xFF0840B0)]
                      : [_micBg1, _micBg2],
                ),
                border: Border.all(color: const Color(0x806490FF), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _micPulsing ? const Color(0xE66690FF) : const Color(0x803C8CFF),
                    blurRadius: _micPulsing ? 22 : 9,
                  ),
                  const BoxShadow(color: Color(0x33FFFFFF), blurRadius: 0, offset: Offset(0, 1)),
                ],
              ),
              child: const Icon(Icons.mic_outlined, color: Colors.white, size: 15),
            ),
          ),
        ]),
      ),
    );
  }

  // ── OCCASION CHIPS ────────────────────────────────────────────────────────
  Widget _buildOccasionRow() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        separatorBuilder: (_, __) => const SizedBox(width: 5),
        itemCount: _occasions.length,
        itemBuilder: (_, i) => _OccChip(
          label: _occasions[i],
          active: _occasionIdx == i,
          onTap: () { HapticFeedback.selectionClick(); setState(() => _occasionIdx = i); },
        ),
      ),
    );
  }

  // ── ACTION CARDS ROW (5 horizontal scrolling cards) ───────────────────────
  Widget _buildActionRow(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _actCards.length,
        itemBuilder: (_, i) {
          final card = _actCards[i];
          return _ActCard(
            icon: card.icon,
            label: card.label,
            onTap: () {
              if (card.route == Routes.dashboard) {
                setState(() => _showChatView = true);
              } else {
                Navigator.of(context).pushNamed(card.route);
              }
            },
          );
        },
      ),
    );
  }

  // ── INSPIRATION CARDS (4 horizontal) ─────────────────────────────────────
  Widget _buildInspirationRow(BuildContext context) {
    return SizedBox(
      height: 185,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 5, 14, 12),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: _inspCards.length,
        itemBuilder: (_, i) {
          final c = _inspCards[i];
          return _InspCard(
            sectionLabel: c.sectionLabel,
            title: c.title,
            sub: c.sub,
            bgColor: c.bg,
            dotActive: c.dotActive,
            totalDots: c.totalDots,
            imageUrl: c.url,
            onTap: () {},
          );
        },
      ),
    );
  }

  // ── FOOTER NAV ────────────────────────────────────────────────────────────
  Widget _buildFooterNav(BuildContext context) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [_footerGradTop, Color(0xFFD4E0F0), Color(0xFFE8F0F8), Color(0xFFF2F6FC), Color(0xFFE0EAF6), Color(0xFFC8D8EC), _footerGradBot],
          stops: [0.0, 0.08, 0.25, 0.40, 0.60, 0.80, 1.0],
        ),
        border: Border(top: BorderSide(color: Color(0xB3FFFFFF), width: 1)),
        boxShadow: [
          BoxShadow(color: Color(0x0F143278), blurRadius: 8, offset: Offset(0, -2)),
          BoxShadow(color: Color(0xD9FFFFFF), blurRadius: 0, offset: Offset(0, 1)),
        ],
      ),
      child: Row(children: [
        _NavItem(icon: Icons.camera_alt_outlined,  label: 'Try-On',       active: _navIndex == 0, onTap: () { setState(() => _navIndex = 0); Navigator.of(context).pushNamed(Routes.tryon); }),
        _NavSep(),
        _NavItem(icon: Icons.checkroom_outlined,   label: 'Wardrobe',     active: _navIndex == 1, onTap: () { setState(() => _navIndex = 1); Navigator.of(context).pushNamed(Routes.wardrobe); }),
        _NavSep(),
        // Home logo button
        Expanded(child: GestureDetector(
          onTap: () => setState(() => _navIndex = 2),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const _HomeLogo(),
            const SizedBox(height: 2),
            Text('Home', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: _navIndex == 2 ? _footerTextAct : _footerText, letterSpacing: .1,
                shadows: const [Shadow(color: Color(0xCCFFFFFF), blurRadius: 0, offset: Offset(0, 1))])),
          ]),
        )),
        _NavSep(),
        _NavItem(icon: Icons.people_outline,       label: 'Friends Space', active: _navIndex == 3, onTap: () { setState(() => _navIndex = 3); Navigator.of(context).pushNamed(Routes.styleFeed); }),
        _NavSep(),
        _NavItem(icon: Icons.person_outline,       label: 'Profile',      active: _navIndex == 4, onTap: () { setState(() => _navIndex = 4); Navigator.of(context).pushNamed(Routes.settings); }),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  AI CHAT SCREEN — preserved exactly from original
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAIChatScreen(BuildContext context) {
    final isDark = context.isDarkMode;
    final theme = context.appTheme;
    final useThemeGradient = isDark && theme.radialGradientBackground != null;
    return Scaffold(
        body: Container(
            width: double.infinity, height: double.infinity,
            decoration: useThemeGradient ? null : const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [DashboardUIColors.chatGradientTopLeft, DashboardUIColors.chatGradientBottomRight])),
            child: SafeArea(child: Column(children: [
              _buildChatAppBar(context),
              Expanded(child: _buildAIChatArea(context)),
              _buildAIChatInput(context),
            ]))));
  }

  Widget _buildChatAppBar(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        _chatCircleButton(icon: Icons.arrow_back, onPressed: () => setState(() => _showChatView = false)),
        const Expanded(child: Center(child: Text('AI stylist', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: DashboardUIColors.chatTitle)))),
        _chatCircleButton(icon: Icons.redo, onPressed: () {}),
      ]));

  Widget _chatCircleButton({required IconData icon, VoidCallback? onPressed}) =>
      Material(
          color: DashboardUIColors.chatHeaderBg, shape: const CircleBorder(),
          child: InkWell(onTap: onPressed, customBorder: const CircleBorder(),
              child: Container(padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: DashboardUIColors.chatHeaderBg, shape: BoxShape.circle, border: Border.all(color: DashboardUIColors.chatTopBarButtonBorder, width: 1)),
                  child: Icon(icon, size: 22, color: DashboardUIColors.chatTitle))));

  Widget _buildAIChatArea(BuildContext context) {
    final isDark = context.isDarkMode;
    return ListView.builder(
        controller: _chatScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _messages.length + (_isAITyping ? 1 : 0),
        itemBuilder: (context, index) {
          Widget child; bool isUserBubble;
          if (_isAITyping && index == _messages.length) { child = _buildAIStylistBubble('...', isUser: false); isUserBubble = false; }
          else {
            final message = _messages[index];
            if (message.wardrobeItems != null && message.wardrobeItems!.isNotEmpty) { child = _buildWardrobeMessageBubble(message, isDark, context); isUserBubble = false; }
            else if (message.externalImageUrl != null && message.externalImageUrl!.isNotEmpty) { child = _buildExternalProductBubble(message, isDark, context); isUserBubble = false; }
            else if (message.searchedProducts != null && message.searchedProducts!.isNotEmpty) { child = _buildSearchedProductsBubble(message, isDark, context); isUserBubble = false; }
            else { child = _buildAIStylistBubble(message.text, isUser: message.isUser, imageBytes: message.tryOnResultImageBytes); isUserBubble = message.isUser; }
          }
          return child.animate(delay: (index * 50).ms).fadeIn(duration: 300.ms, curve: Curves.easeOut).slideX(begin: isUserBubble ? 0.06 : -0.06, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
        });
  }

  Widget _buildAIStylistBubble(String text, {required bool isUser, Uint8List? imageBytes}) {
    final user = ref.watch(currentUserProvider).value;
    final firebaseUser = ref.watch(authStateProvider).value;
    final photoUrl = user?.avatarUrl ?? firebaseUser?.photoURL;
    final bubbleColor = isUser ? DashboardUIColors.chatUserBubble : DashboardUIColors.chatAIBubble;
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (!isUser) _buildAIAvatar(),
          if (!isUser) const SizedBox(width: 8),
          Flexible(child: Stack(clipBehavior: Clip.none, children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: bubbleColor, borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(isUser ? 18 : 6), bottomRight: Radius.circular(isUser ? 6 : 18))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(text, style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4)),
                  if (imageBytes != null) ...[const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(imageBytes, width: 200, height: 240, fit: BoxFit.cover))],
                ])),
            Positioned(bottom: 8, left: isUser ? null : -6, right: isUser ? -6 : null, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: bubbleColor, shape: BoxShape.circle))),
          ])),
          if (isUser) const SizedBox(width: 8),
          if (isUser) CircleAvatar(radius: 18, backgroundColor: DashboardUIColors.chatQuickReplyBg, backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null, child: photoUrl == null || photoUrl.isEmpty ? const Icon(Icons.person, size: 20, color: DashboardUIColors.chatQuickReplyText) : null),
        ]));
  }

  Widget _buildAIAvatar() => Container(
      width: 36, height: 36, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [_dot(DashboardUIColors.chatAIAvatarDots), const SizedBox(width: 3), _dot(DashboardUIColors.chatAIAvatarDots)]),
        const SizedBox(height: 3),
        _dot(DashboardUIColors.chatAIAvatarDots),
      ])));

  Widget _dot(Color color) => Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  Widget _buildAIChatInput(BuildContext context) {
    final viewPadding = MediaQuery.paddingOf(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width < 360;
    final isDark = context.isDarkMode;
    final theme = context.appTheme;
    final inputBg = isDark ? theme.surfaceElevated : const Color(0xFFF5F5F5);
    final inputBorder = isDark ? theme.borderLight : const Color(0xFFE0E0E0);
    final inputTextColor = isDark ? theme.textPrimary : const Color(0xFF1A1A1A);
    final hintColor = isDark ? theme.textSecondary : const Color(0xFF6B6B6B);
    final cameraBg = isDark ? theme.borderMedium : const Color(0xFFE8E8E8);
    final cameraIconColor = isDark ? theme.textPrimary : const Color(0xFF444444);
    final sendButtonBg = isDark ? theme.primary : DashboardUIColors.giovanniBlue;
    final chipBg = isDark ? theme.surfaceElevated : const Color(0xFFEEEEEE);
    final chipTextColor = isDark ? theme.textPrimary : const Color(0xFF333333);
    final barBg = isDark ? Colors.transparent : const Color(0xFFF8F8F8);
    return AnimatedContainer(
        duration: const Duration(milliseconds: 150), curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(16 + viewPadding.left, 14, 16 + viewPadding.right, (20 + bottomInset).clamp(20.0, 400.0)),
        decoration: BoxDecoration(color: barBg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56, maxHeight: 132),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: isNarrow ? 14 : 18, vertical: 12),
                  decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(28), border: Border.all(color: inputBorder, width: 1), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.06), blurRadius: isDark ? 12 : 8, offset: const Offset(0, 2))]),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Material(color: Colors.transparent, child: InkWell(onTap: _pickImage, borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: cameraBg, shape: BoxShape.circle), child: Icon(Icons.camera_alt_outlined, color: cameraIconColor, size: 22)))),
                    SizedBox(width: isNarrow ? 12 : 14),
                    Expanded(child: TextField(
                        controller: _messageController,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: inputTextColor, height: 1.4),
                        maxLines: 4, minLines: 1, textInputAction: TextInputAction.send,
                        decoration: InputDecoration(hintText: 'Ask for outfit suggestions, try-on, or style tips...', hintStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: hintColor, height: 1.4), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 8), isDense: true),
                        onSubmitted: (_) => _sendMessage())),
                  ]),
                ))),
            const SizedBox(width: 12),
            Material(color: Colors.transparent, child: InkWell(onTap: _sendMessage, customBorder: const CircleBorder(),
                child: Container(width: 52, height: 52, alignment: Alignment.center, decoration: BoxDecoration(color: sendButtonBg, shape: BoxShape.circle, boxShadow: [BoxShadow(color: sendButtonBg.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))]),
                    child: const Icon(Icons.send_rounded, size: 24, color: Colors.white)))),
          ]),
          const SizedBox(height: 14),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: ['beach parties', 'birthday parties', 'dinner parties'].map((label) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Material(color: chipBg, borderRadius: BorderRadius.circular(22), elevation: 0,
                      child: InkWell(onTap: () { _messageController.text = 'I want outfit suggestions for $label'; _sendMessage(); }, borderRadius: BorderRadius.circular(22),
                          child: Padding(padding: EdgeInsets.symmetric(horizontal: isNarrow ? 14 : 18, vertical: 12), child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: chipTextColor))))))).toList())),
        ]));
  }

  // ── Chat bubble helpers (preserved exactly) ────────────────────────────────
  Widget _buildWardrobeMessageBubble(ChatMessage message, bool isDark, BuildContext context) {
    final items = message.wardrobeItems!;
    final luxuryTheme = context.luxuryTheme;
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd, vertical: DesignTokens.spacingSm),
        child: Align(alignment: Alignment.centerLeft, child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
            decoration: BoxDecoration(color: luxuryTheme.chatAIBubble, borderRadius: BorderRadius.circular(DesignTokens.radiusLg), border: Border.all(color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder, width: 0.5)),
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(message.text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black)),
              const SizedBox(height: 12),
              SizedBox(height: 120, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(width: 12), itemBuilder: (context, index) {
                final item = items[index];
                final imageUrl = item.processedImageUrl ?? item.imageUrl;
                return SizedBox(width: 100, child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ClipRRect(borderRadius: BorderRadius.circular(DesignTokens.radiusMd), child: Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: DesignTokens.darkCard, child: Icon(Icons.checkroom, color: context.textSecondaryColor)))),
                  const SizedBox(height: 4),
                  Text(item.category, style: Theme.of(context).textTheme.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  TextButton(onPressed: () => _runTryOnInChat(item.id), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: const Text('Try on')),
                ]));
              })),
            ]))));
  }

  Widget _buildExternalProductBubble(ChatMessage message, bool isDark, BuildContext context) {
    final luxuryTheme = context.luxuryTheme;
    final imageUrl = message.externalImageUrl!;
    final displayImageUrl = message.externalDisplayImageUrl ?? imageUrl;
    final pageUrl = message.externalProductPageUrl;
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd, vertical: DesignTokens.spacingSm),
        child: Align(alignment: Alignment.centerLeft, child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
            decoration: BoxDecoration(color: luxuryTheme.chatAIBubble, borderRadius: BorderRadius.circular(DesignTokens.radiusLg), border: Border.all(color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder, width: 0.5)),
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(message.text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black)),
              const SizedBox(height: DesignTokens.spacingSm),
              ClipRRect(borderRadius: BorderRadius.circular(DesignTokens.radiusMd), child: Image.network(displayImageUrl, width: 280, height: 280, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Container(width: 280, height: 200, color: DesignTokens.darkCard, child: Icon(Icons.broken_image_outlined, color: context.textSecondaryColor, size: 48)))),
              const SizedBox(height: DesignTokens.spacingSm),
              Row(mainAxisSize: MainAxisSize.min, children: [
                FilledButton.icon(onPressed: () => _runTryOnWithGarmentUrl(imageUrl), icon: const Icon(Icons.checkroom, size: 18), label: const Text('Try on'), style: FilledButton.styleFrom(backgroundColor: context.accentColor, foregroundColor: Colors.white)),
                if (pageUrl != null && pageUrl.isNotEmpty) ...[const SizedBox(width: DesignTokens.spacingSm), TextButton.icon(onPressed: () async { try { final uri = Uri.parse(pageUrl); if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {} }, icon: const Icon(Icons.shopping_bag_outlined, size: 18), label: const Text('Buy'))],
              ]),
            ]))));
  }

  Widget _buildSearchedProductsBubble(ChatMessage message, bool isDark, BuildContext context) {
    final luxuryTheme = context.luxuryTheme;
    final products = message.searchedProducts!;
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd, vertical: DesignTokens.spacingSm),
        child: Align(alignment: Alignment.centerLeft, child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.95),
            decoration: BoxDecoration(color: luxuryTheme.chatAIBubble, borderRadius: BorderRadius.circular(DesignTokens.radiusLg), border: Border.all(color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder, width: 0.5)),
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(message.text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black)),
              const SizedBox(height: DesignTokens.spacingSm),
              SizedBox(height: 200, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: products.length, separatorBuilder: (_, __) => const SizedBox(width: 12), itemBuilder: (context, index) {
                final p = products[index];
                return SizedBox(width: 140, child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ClipRRect(borderRadius: BorderRadius.circular(DesignTokens.radiusMd), child: Image.network(p.displayImageUrl ?? p.imageUrl, width: 120, height: 140, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 120, height: 140, color: DesignTokens.darkCard, child: Icon(Icons.checkroom, color: context.textSecondaryColor)))),
                  const SizedBox(height: 4),
                  Text(p.title, style: Theme.of(context).textTheme.labelSmall, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    TextButton(onPressed: () => _runTryOnWithGarmentUrl(p.imageUrl), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: const Text('Try on')),
                    if (p.link.isNotEmpty) TextButton(onPressed: () async { try { final uri = Uri.parse(p.link); if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {} }, style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: const Text('Buy')),
                  ]),
                ]));
              })),
            ]))));
  }
}
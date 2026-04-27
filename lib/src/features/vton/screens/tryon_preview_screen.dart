
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/vton_service.dart';
import '../providers/vton_provider.dart';
import '../../tryon/utils/save_tryon_result_stub.dart'
    if (dart.library.io) '../../tryon/utils/save_tryon_result_io.dart'
    if (dart.library.html) '../../tryon/utils/save_tryon_result_web.dart'
    as save_tryon_result;

// ══════════════════════════════════════════════════════════════════════════════
//  NX PALETTE — exact from previous screens
// ══════════════════════════════════════════════════════════════════════════════
const _cosmicTop = Color(0xFF020810);
const _cosmicMid = Color(0xFF050F2A);
const _cosmicDeep = Color(0xFF0A4E8F);
const _cosmicBright = Color(0xFF1848C0);
const _cosmicBlue = Color(0xFF1AACCF);

const _rimL = Color(0xFF1E2E50);
const _rimM = Color(0xFF90B4D8);
const _rimW = Color(0xFFFFFFFF);
const _rimC = Color(0xFFC8DFF0);
const _rimE = Color(0xFFE8F4FF);

const _bodyWhite = Color(0xFFFFFFFF);
const _darkText = Color(0xFF0C1E48);
const _midText = Color(0xFF3A4A6A);
const _lightText = Color(0xFF6070A0);
const _borderLight = Color(0xFFDDE3F0);

const _nxBlue = Color(0xFF2A58C8);
const _nxBlueDark = Color(0xFF1A3A9A);
const _nxAccent = Color(0xFF6AA4FF);
const _goldBg1 = Color(0xFFB87D3A);
const _goldBg2 = Color(0xFFA06828);

const _footerGradTop = Color(0xFFB8C8E0);
const _footerGradBot = Color(0xFFB0C4DC);
const _footerText = Color(0xFF1A3060);
const _footerTextAct = Color(0xFF0A4E8F);
const _notifRed = Color(0xFFE85A4F);

// ══════════════════════════════════════════════════════════════════════════════
//  PAINTERS (identical to previous screens)
// ══════════════════════════════════════════════════════════════════════════════
class _CosmicPainter extends CustomPainter {
  const _CosmicPainter();
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(
      Rect.fromLTWH(0, 0, s.width, s.height),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.9),
          radius: 1.4,
          colors: [
            _cosmicBlue,
            _cosmicBright,
            _cosmicDeep,
            _cosmicMid,
            _cosmicTop
          ],
          stops: [0.0, 0.16, 0.36, 0.62, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, s.width, s.height)),
    );
    final glowC = Offset(s.width / 2, s.height * 0.35);
    c.drawOval(
      Rect.fromCenter(
          center: glowC, width: s.width * 1.1, height: s.height * 1.4),
      Paint()
        ..shader = const RadialGradient(
                colors: [Color(0x3878BEFF), Colors.transparent])
            .createShader(Rect.fromCenter(
                center: glowC, width: s.width * 1.1, height: s.height * 1.4)),
    );
    // Ray cone
    final ray = Path()
      ..moveTo(s.width * 0.22, s.height * 1.3)
      ..lineTo(s.width * 0.38, -s.height * 0.2)
      ..lineTo(s.width * 0.62, -s.height * 0.2)
      ..lineTo(s.width * 0.78, s.height * 1.3)
      ..close();
    c.drawPath(ray, Paint()..color = const Color(0x2264B4FF));
    // Shimmer rim
    c.drawRect(
        Rect.fromLTWH(0, 0, s.width, 5),
        Paint()
          ..shader = const LinearGradient(colors: [
            _rimL,
            Color(0xFF4868A8),
            _rimM,
            _rimC,
            _rimE,
            _rimW,
            _rimE,
            _rimC,
            _rimM,
            Color(0xFF4868A8),
            _rimL
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
          ]).createShader(Rect.fromLTWH(0, 0, s.width, 5)));
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter();
  @override
  void paint(Canvas c, Size s) {
    final glow = Paint()
      ..shader = const LinearGradient(colors: [
        Colors.transparent,
        Color(0x384878D8),
        Color(0x706AA4FF),
        Color(0x384878D8),
        Colors.transparent
      ]).createShader(Rect.fromLTWH(0, 0, s.width, s.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    final main = Paint()
      ..shader = const LinearGradient(colors: [
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
        Color(0x591A2E50)
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
      ]).createShader(Rect.fromLTWH(0, 0, s.width, s.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    final highlight = Paint()
      ..color = const Color(0x8CFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final inner = Paint()
      ..shader = const LinearGradient(colors: [
        Color(0x261A2E50),
        Color(0xA46888B8),
        Color(0xD9B0CCE4),
        Color(0xFFDEEEFF),
        Color(0xD9B0CCE4),
        Color(0xA46888B8),
        Color(0x261A2E50)
      ], stops: [
        0.0,
        0.10,
        0.28,
        0.50,
        0.72,
        0.90,
        1.0
      ]).createShader(Rect.fromLTWH(0, 0, s.width, s.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final p1 = Path()
      ..moveTo(0, 6)
      ..quadraticBezierTo(s.width / 2, 30, s.width, 6);
    final p2 = Path()
      ..moveTo(4, 5.3)
      ..quadraticBezierTo(s.width / 2, 27.5, s.width - 4, 5.3);
    final p3 = Path()
      ..moveTo(14, 2.5)
      ..quadraticBezierTo(s.width / 2, 18, s.width - 14, 2.5);
    c.drawPath(p1, glow);
    c.drawPath(p1, main);
    c.drawPath(p2, highlight);
    c.drawPath(p3, inner);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS
// ══════════════════════════════════════════════════════════════════════════════
class _IBtn extends StatelessWidget {
  const _IBtn({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x29FFFFFF), Color(0x0FFFFFFF)]),
            border: Border.all(color: const Color(0x42FFFFFF), width: 1),
            boxShadow: const [
              BoxShadow(color: Color(0x661E001E), blurRadius: 6)
            ],
          ),
          child: Center(child: child),
        ),
      );
}

class _LogoRing extends StatelessWidget {
  const _LogoRing();
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 80,
        height: 80,
        child: Stack(alignment: Alignment.center, children: [
          // Halo
          Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Color(0x7A50A0FF),
                    Color(0x2D2864DC),
                    Colors.transparent
                  ], stops: [
                    0.0,
                    0.36,
                    0.65
                  ]))),
          // Ring
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(startAngle: 0.26, colors: [
                  Color(0xFF1E3060),
                  Color(0xFF5080B0),
                  Color(0xFF90B8D8),
                  Color(0xFFC8DCF0),
                  Color(0xFFE8F4FF),
                  Color(0xFFFFFFFF),
                  Color(0xFFE8F4FF),
                  Color(0xFFC8DCF0),
                  Color(0xFF90B8D8),
                  Color(0xFF5080B0),
                  Color(0xFF1E3060)
                ]),
                boxShadow: [
                  BoxShadow(color: Color(0x7A96C8FF), blurRadius: 14),
                  BoxShadow(color: Color(0x593078E6), blurRadius: 30)
                ]),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                      center: Alignment(-0.2, -0.3),
                      colors: [
                        Color(0xFF1A3A7A),
                        Color(0xFF0D1E50),
                        Color(0xFF08122E)
                      ]),
                  border: Border.all(color: const Color(0x4DB4DCFF), width: 1)),
              child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0x4DB4DCFF), width: 1)),
                  child: const Icon(Icons.check,
                      color: Color(0x8C96C8FF), size: 12)),
            ),
          ),
          // Flare cross
          Positioned(
              top: 2,
              child: CustomPaint(
                  size: const Size(11, 11), painter: _FlarePainter())),
        ]),
      );
}

class _FlarePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0xE6DCF0FF)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final p2 = Paint()
      ..color = const Color(0x4DDCF0FF)
      ..strokeWidth = .6
      ..style = PaintingStyle.stroke;
    c.drawLine(Offset(s.width / 2, 0), Offset(s.width / 2, s.height), p);
    c.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), p);
    c.drawLine(Offset(s.width * .14, s.height * .14),
        Offset(s.width * .86, s.height * .86), p2);
    c.drawLine(Offset(s.width * .86, s.height * .14),
        Offset(s.width * .14, s.height * .86), p2);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _HomeLogo extends StatelessWidget {
  const _HomeLogo();
  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(startAngle: 0.26, colors: [
              Color(0xFF1E3060),
              Color(0xFF5080B0),
              Color(0xFF90B8D8),
              Color(0xFFC8DCF0),
              Color(0xFFE8F4FF),
              Color(0xFFFFFFFF),
              Color(0xFFE8F4FF),
              Color(0xFFC8DCF0),
              Color(0xFF90B8D8),
              Color(0xFF5080B0),
              Color(0xFF1E3060)
            ]),
            boxShadow: [BoxShadow(color: Color(0x7382B4FF), blurRadius: 10)]),
        child: Container(
            margin: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                    center: Alignment(-0.2, -0.3),
                    colors: [
                      Color(0xFF1A3A7A),
                      Color(0xFF0D1E50),
                      Color(0xFF08122E)
                    ])),
            child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0x478AB4FF), width: 1)),
                child: const Icon(Icons.check,
                    color: Color(0x6696C8FF), size: 14))),
      );
}

class _NavSep extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1.5,
        height: 32,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
              Colors.transparent,
              Color(0x8C3C78DC),
              Color(0xB35096FF),
              Color(0x8C3C78DC),
              Colors.transparent
            ])),
      );
}

class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap});
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
        child: Container(
          decoration: active
              ? const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: _footerTextAct, width: 2)))
              : null,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: color,
                    shadows: const [
                      Shadow(
                          color: Color(0xCCFFFFFF),
                          blurRadius: 0,
                          offset: Offset(0, 1))
                    ]),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class TryOnPreviewScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const TryOnPreviewScreen({super.key, required this.sessionId});

  @override
  ConsumerState<TryOnPreviewScreen> createState() => _TryOnPreviewScreenState();
}

class _TryOnPreviewScreenState extends ConsumerState<TryOnPreviewScreen>
    with TickerProviderStateMixin {
  // ── original backend state (unchanged) ───────────────────────────────────
  double _sliderValue = 0.5;
  bool _isPolling = true;

  // ── UI animation state ────────────────────────────────────────────────────
  bool _showBefore = false; // label toggle
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _pulseAnim;
  late Animation<Offset> _slideAnim;
  final int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _startPolling();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutBack));
  }

  // ── ORIGINAL backend polling (unchanged) ─────────────────────────────────
  void _startPolling() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || !_isPolling) return;
      ref.read(tryonStatusProvider(widget.sessionId).future).then((status) {
        if (status['status'] == 'completed' && mounted) {
          setState(() => _isPolling = false);
          _slideCtrl.forward(); // slide action bar up
        } else if (status['status'] == 'failed' && mounted) {
          setState(() => _isPolling = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Try-on failed: ${status['error_message']}')),
          );
        } else if (mounted) {
          _startPolling();
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(tryonStatusProvider(widget.sessionId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bodyWhite,
        body: Column(children: [
          // ① Cosmic header
          _buildCosmicHeader(context),

          // ② Main content
          Expanded(
            child: statusAsync.when(
              loading: () => _buildProcessingView('preparing'),
              error: (e, _) => _buildErrorView(e.toString()),
              data: (status) {
                final resultUrl = status['result_url'] as String?;
                final rawPhotoUrl = status['raw_photo_url'] as String;
                final isCompleted = status['status'] == 'completed';

                if (!isCompleted || resultUrl == null) {
                  return _buildProcessingView(
                      status['status'] as String? ?? 'processing');
                }

                return _buildCompletedView(rawPhotoUrl, resultUrl, status);
              },
            ),
          ),

          // ③ Footer nav
          _buildFooterNav(context),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ① COSMIC HEADER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCosmicHeader(BuildContext context) {
    return SizedBox(
      height: 99,
      child: Stack(clipBehavior: Clip.none, children: [
        const Positioned.fill(child: CustomPaint(painter: _CosmicPainter())),

        // Stars
        _star(.12, .06, 2.0, .75), _star(.05, .46, 1.5, .50),
        _star(.16, .87, 2.0, .70), _star(.04, .93, 2.5, .28),
        _star(.08, .30, 1.5, .40), _star(.03, .14, 1.5, .50),

        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(children: [
                  // Back
                  _IBtn(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.chevron_left,
                        color: Color(0xFFC8DCF4), size: 18),
                  ),
                  const Spacer(),
                  // Logo
                  const _LogoRing(),
                  const Spacer(),
                  // Share
                  _IBtn(
                    onTap: () => _onShare(),
                    child: const Icon(Icons.ios_share_outlined,
                        color: Color(0xFFC8DCF4), size: 14),
                  ),
                ]),
              ),
            ),
          ),
        ),

        // Arc
        const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
                size: Size(double.infinity, 30), painter: _ArcPainter())),
      ]),
    );
  }

  Widget _star(double top, double left, double size, double opacity) =>
      Positioned(
        top: 99 * top,
        left: MediaQuery.of(context).size.width * left,
        child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xCCC8E6FF), blurRadius: size * 2)
                ])),
      );

  // ══════════════════════════════════════════════════════════════════════════
  //  PROCESSING VIEW
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildProcessingView(String status) {
    return Container(
      color: _bodyWhite,
      child: Column(children: [
        // Section label
        _sectionLabel('Try-On Preview', Icons.camera_enhance_outlined),

        Expanded(
          child: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              // Animated logo-style spinner
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) =>
                    Transform.scale(scale: _pulseAnim.value, child: child),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(startAngle: 0.26, colors: [
                      Color(0xFF1E3060),
                      Color(0xFF5080B0),
                      Color(0xFF90B8D8),
                      Color(0xFFC8DCF0),
                      Color(0xFFE8F4FF),
                      Color(0xFFFFFFFF),
                      Color(0xFFE8F4FF),
                      Color(0xFFC8DCF0),
                      Color(0xFF90B8D8),
                      Color(0xFF5080B0),
                      Color(0xFF1E3060)
                    ]),
                    boxShadow: [
                      BoxShadow(color: Color(0x5596C8FF), blurRadius: 24),
                      BoxShadow(color: Color(0x332A58C8), blurRadius: 40),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                            center: Alignment(-0.2, -0.3),
                            colors: [
                              Color(0xFF1A3A7A),
                              Color(0xFF0D1E50),
                              Color(0xFF08122E)
                            ])),
                    child: const Center(
                        child: Icon(Icons.camera_enhance_outlined,
                            color: Color(0x8CB4DCFF), size: 36)),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                status == 'processing'
                    ? 'Generating your try-on…'
                    : 'Preparing your session…',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _darkText,
                    letterSpacing: -.2),
              ),
              const SizedBox(height: 8),
              const Text('This may take 20–60 seconds',
                  style:
                      TextStyle(fontSize: 13, color: _lightText, height: 1.5)),
              const SizedBox(height: 32),
              // Progress dots
              _ProgressDots(),
              const SizedBox(height: 40),
              // Status chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFFF0F4FF),
                  border: Border.all(color: _borderLight),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: _nxBlue)),
                  const SizedBox(width: 7),
                  Text(
                      status == 'processing'
                          ? 'AI is working on your outfit…'
                          : 'Queued — starting soon',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _midText)),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ERROR VIEW
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildErrorView(String error) {
    return Container(
      color: _bodyWhite,
      child: Column(children: [
        _sectionLabel('Try-On Preview', Icons.camera_enhance_outlined),
        Expanded(
            child: Center(
                child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFF0F0),
                    border: Border.all(color: _notifRed.withOpacity(.3))),
                child: const Icon(Icons.error_outline,
                    color: _notifRed, size: 36)),
            const SizedBox(height: 20),
            const Text('Something went wrong',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _darkText)),
            const SizedBox(height: 8),
            Text(error,
                style: const TextStyle(
                    fontSize: 12, color: _lightText, height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient:
                      const LinearGradient(colors: [_nxBlue, _nxBlueDark]),
                  boxShadow: const [
                    BoxShadow(color: Color(0x3D2A58C8), blurRadius: 10)
                  ],
                ),
                child: const Text('Go Back',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ]),
        ))),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  COMPLETED VIEW
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCompletedView(
      String beforeUrl, String afterUrl, Map<String, dynamic> status) {
    return Column(children: [
      // Section label + toggle
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(children: [
          // Label badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(colors: [_nxBlue, _nxBlueDark]),
              boxShadow: const [
                BoxShadow(color: Color(0x3D2A58C8), blurRadius: 8)
              ],
            ),
            child: const Row(children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 12),
              SizedBox(width: 5),
              Text('Try-On Result',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: .3)),
            ]),
          ),
          const Spacer(),
          // Before/After toggle
          GestureDetector(
            onTap: () => setState(() => _showBefore = !_showBefore),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFFF0F4FF),
                border: Border.all(color: _borderLight),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                    _showBefore
                        ? Icons.visibility_off_outlined
                        : Icons.compare_outlined,
                    size: 12,
                    color: _nxBlue),
                const SizedBox(width: 5),
                Text(_showBefore ? 'Show After' : 'Compare',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _nxBlue)),
              ]),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 8),

      // Before/After slider — fills remaining space
      Expanded(
        child: Stack(children: [
          // The comparison slider widget
          _NXBeforeAfterSlider(
            beforeUrl: beforeUrl,
            afterUrl: afterUrl,
            sliderValue: _sliderValue,
            showBefore: _showBefore,
            onSliderChanged: (v) => setState(() => _sliderValue = v),
          ),

          // Slider instruction hint (fades after interaction)
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
                child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withOpacity(.45),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.swap_horiz, color: Colors.white60, size: 13),
                SizedBox(width: 6),
                Text('Drag to compare Before / After',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500)),
              ]),
            )),
          ),
        ]),
      ),

      // Slide-up action bar
      SlideTransition(
        position: _slideAnim,
        child: _buildActionBar(status),
      ),
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ACTION BAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildActionBar(Map<String, dynamic> status) {
    return Container(
      decoration: const BoxDecoration(
        color: _bodyWhite,
        border: Border(top: BorderSide(color: Color(0xFFDDE3F0), width: 1)),
        boxShadow: [
          BoxShadow(
              color: Color(0x1A0A1E58), blurRadius: 16, offset: Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Main CTA — Save to Wardrobe
            GestureDetector(
              onTap: () => _onSave(status['result_url'] as String?),
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) =>
                    Transform.scale(scale: _pulseAnim.value, child: child),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_nxBlue, _nxBlueDark]),
                    border:
                        Border.all(color: const Color(0x516490FF), width: 1),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x4D2A58C8),
                          blurRadius: 14,
                          offset: Offset(0, 4)),
                      BoxShadow(
                          color: Color(0x2EFFFFFF),
                          blurRadius: 0,
                          offset: Offset(0, 1)),
                    ],
                  ),
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_alt_outlined,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Save to Wardrobe',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: .2)),
                      ]),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Like / Dislike row
            Row(children: [
              Expanded(
                  child: _FeedbackBtn(
                icon: Icons.thumb_down_alt_outlined,
                label: 'Not my style',
                color: _notifRed,
                bgColor: const Color(0xFFFFF0F0),
                borderColor: const Color(0xFFFFCDD2),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref
                      .read(vtonServiceProvider)
                      .submitFeedback(widget.sessionId, 'dislike');
                  _showFeedbackSnack(
                      'Got it — we\'ll improve your recommendations 👌');
                },
              )),
              const SizedBox(width: 10),
              // Retry button
              _FeedbackBtn(
                icon: Icons.refresh_outlined,
                label: 'Retry',
                color: _midText,
                bgColor: const Color(0xFFF0F4FF),
                borderColor: _borderLight,
                onTap: () => Navigator.of(context).pop(),
                isSmall: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: _FeedbackBtn(
                icon: Icons.thumb_up_alt_outlined,
                label: 'Love this!',
                color: const Color(0xFF2A9A58),
                bgColor: const Color(0xFFF0FFF6),
                borderColor: const Color(0xFFC3E6CB),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref
                      .read(vtonServiceProvider)
                      .submitFeedback(widget.sessionId, 'like');
                  _showFeedbackSnack('Awesome! Added to your style profile ✨');
                },
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ③ FOOTER NAV
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFooterNav(BuildContext context) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _footerGradTop,
              Color(0xFFD4E0F0),
              Color(0xFFE8F0F8),
              Color(0xFFF2F6FC),
              Color(0xFFE0EAF6),
              Color(0xFFC8D8EC),
              _footerGradBot
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
        border: Border(top: BorderSide(color: Color(0xB3FFFFFF), width: 1)),
        boxShadow: [
          BoxShadow(
              color: Color(0x0F143278), blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: Row(children: [
        _NavItem(
            icon: Icons.camera_enhance_outlined,
            label: 'Try-On',
            active: true,
            onTap: () {}),
        _NavSep(),
        _NavItem(
            icon: Icons.checkroom_outlined,
            label: 'Wardrobe',
            active: false,
            onTap: () => Navigator.of(context).pop()),
        _NavSep(),
        // Home logo
        Expanded(
            child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _HomeLogo(),
                SizedBox(height: 2),
                Text('Home',
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: _footerText,
                        shadows: [
                          Shadow(
                              color: Color(0xCCFFFFFF),
                              blurRadius: 0,
                              offset: Offset(0, 1))
                        ])),
              ]),
        )),
        _NavSep(),
        _NavItem(
            icon: Icons.people_outline,
            label: 'Friends Space',
            active: false,
            onTap: () {}),
        _NavSep(),
        _NavItem(
            icon: Icons.shopping_bag_outlined,
            label: 'Shopping',
            active: false,
            onTap: () {}),
      ]),
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, IconData icon) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [_nxBlue, _nxBlueDark]),
                boxShadow: const [
                  BoxShadow(color: Color(0x3D2A58C8), blurRadius: 8)
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, color: Colors.white, size: 12),
                const SizedBox(width: 5),
                Text(text,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: .3)),
              ]),
            )),
      );

  Future<void> _onSave(String? resultUrl) async {
    HapticFeedback.mediumImpact();

    if (resultUrl == null || resultUrl.isEmpty) {
      _showFeedbackSnack('Unable to save image: no result available.');
      return;
    }

    _showFeedbackSnack('Saving your try-on…');

    try {
      final response = await http
          .get(Uri.parse(resultUrl))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('Image download failed (${response.statusCode})');
      }

      final bytes = response.bodyBytes;
      final savedPath = await save_tryon_result.saveTryOnResultToDevice(bytes);

      if (savedPath != null && savedPath.isNotEmpty) {
        _showFeedbackSnack('Try-on image saved successfully ✓');
      } else {
        _showFeedbackSnack(
            'Download started. Check your device photos or downloads.');
      }
    } catch (e) {
      _showFeedbackSnack('Failed to save image. Please try again.');
    }
  }

  void _onShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Share link copied ✓'),
          behavior: SnackBarBehavior.floating),
    );
  }

  void _showFeedbackSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

const _cardBg = Color(0xFF0A4E8F);

// ══════════════════════════════════════════════════════════════════════════════
//  NX BEFORE / AFTER SLIDER
// ══════════════════════════════════════════════════════════════════════════════
class _NXBeforeAfterSlider extends StatelessWidget {
  final String beforeUrl, afterUrl;
  final double sliderValue;
  final bool showBefore;
  final ValueChanged<double> onSliderChanged;

  const _NXBeforeAfterSlider({
    required this.beforeUrl,
    required this.afterUrl,
    required this.sliderValue,
    required this.showBefore,
    required this.onSliderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final displayValue = showBefore ? 0.0 : sliderValue;

    return GestureDetector(
      onPanUpdate: (details) {
        if (showBefore) return;
        final raw = details.localPosition.dx / w;
        onSliderChanged(raw.clamp(0.05, 0.95));
      },
      child: Container(
        color: const Color(0xFFF6F9FF),
        child: Stack(fit: StackFit.expand, children: [
          // ── BEFORE image (full background) ──────────────────────────────
          Positioned.fill(
              child: CachedNetworkImage(
            imageUrl: beforeUrl,
            fit: BoxFit.contain,
            placeholder: (_, __) =>
                const Center(child: CircularProgressIndicator(color: _nxBlue)),
            errorWidget: (_, __, ___) => const Center(
                child: Icon(Icons.person_outline, size: 80, color: _lightText)),
          )),

          // ── AFTER image (clipped reveal) ─────────────────────────────────
          Positioned.fill(
              child: ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: displayValue,
              child: SizedBox(
                width: w,
                child: CachedNetworkImage(
                  imageUrl: afterUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox.shrink(),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          )),

          // ── Divider line ─────────────────────────────────────────────────
          if (!showBefore)
            Positioned(
              left: w * displayValue - 1,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0xFFFFFFFF),
                        Color(0xFFFFFFFF),
                        Colors.transparent
                      ],
                      stops: [
                        0.0,
                        0.1,
                        0.9,
                        1.0
                      ]),
                  boxShadow: [
                    BoxShadow(color: Color(0x40000000), blurRadius: 4)
                  ],
                ),
              ),
            ),

          // ── Drag handle ──────────────────────────────────────────────────
          if (!showBefore)
            Positioned(
              left: w * displayValue - 22,
              top: 0,
              bottom: 0,
              child: Center(
                  child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFFFFF), Color(0xFFE8F0FF)]),
                  border: Border.all(color: _nxBlue.withOpacity(.5), width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x3D2A58C8), blurRadius: 12),
                    BoxShadow(color: Color(0x33000000), blurRadius: 8),
                  ],
                ),
                child: const Icon(Icons.swap_horiz_outlined,
                    color: _nxBlue, size: 20),
              )),
            ),

          // ── BEFORE label ─────────────────────────────────────────────────
          Positioned(
            top: 48,
            left: 12,
            child: _imageLabel('Before', Icons.person_outline),
          ),

          // ── AFTER label ──────────────────────────────────────────────────
          if (!showBefore && displayValue > 0.15)
            Positioned(
              top: 48,
              left: (w * displayValue * 0.3).clamp(12.0, w - 80),
              child: _imageLabel('After', Icons.auto_awesome),
            ),
        ]),
      ),
    );
  }

  Widget _imageLabel(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black.withOpacity(.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white60, size: 11),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ANIMATED PROGRESS DOTS
// ══════════════════════════════════════════════════════════════════════════════
class _ProgressDots extends StatefulWidget {
  @override
  State<_ProgressDots> createState() => _ProgressDotsState();
}

class _ProgressDotsState extends State<_ProgressDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _step;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _step = IntTween(begin: 0, end: 2).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _step,
        builder: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final active = _step.value == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: active ? 20 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: active ? _nxBlue : const Color(0xFFD0DCF0),
                  boxShadow: active
                      ? const [
                          BoxShadow(color: Color(0x3D2A58C8), blurRadius: 6)
                        ]
                      : null,
                ),
              );
            })),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
//  FEEDBACK BUTTON
// ══════════════════════════════════════════════════════════════════════════════
class _FeedbackBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, bgColor, borderColor;
  final VoidCallback onTap;
  final bool isSmall;

  const _FeedbackBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 14 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: bgColor,
            border: Border.all(color: borderColor, width: 1),
            boxShadow: const [
              BoxShadow(color: Color(0x080A1E58), blurRadius: 4)
            ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 16),
            if (!isSmall) ...[
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            ],
          ]),
        ),
      );
}

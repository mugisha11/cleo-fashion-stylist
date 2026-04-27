import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/vton_service.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import 'tryon_preview_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  PALETTE — exact NX colour system from the previous screens
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

const _cardBg = Color(0xFF0A4E8F);
const _cardBg2 = Color(0xFF060F2E);
const _cardBdr = Color(0x5C78B4FF);

const _nxBlue = Color(0xFF2A58C8);
const _nxBlueDark = Color(0xFF1A3A9A);
const _nxAccent = Color(0xFF6AA4FF);
const _goldBg1 = Color(0xFFB87D3A);
const _goldBg2 = Color(0xFFA06828);

const _notifRed = Color(0xFFE85A4F);

const _footerGradTop = Color(0xFFB8C8E0);
const _footerGradBot = Color(0xFFB0C4DC);
const _footerText = Color(0xFF1A3060);
const _footerTextAct = Color(0xFF0A4E8F);

// ══════════════════════════════════════════════════════════════════════════════
//  COSMIC HEADER PAINTER (identical to previous screens)
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
          colors: [Color(0x3878BEFF), Colors.transparent],
        ).createShader(Rect.fromCenter(
            center: glowC, width: s.width * 1.1, height: s.height * 1.4)),
    );
    final rayPath = Path()
      ..moveTo(s.width * 0.22, s.height * 1.3)
      ..lineTo(s.width * 0.38, -s.height * 0.2)
      ..lineTo(s.width * 0.62, -s.height * 0.2)
      ..lineTo(s.width * 0.78, s.height * 1.3)
      ..close();
    c.drawPath(rayPath, Paint()..color = const Color(0x2264B4FF));
    c.drawRect(
      Rect.fromLTWH(0, 0, s.width, 5),
      Paint()
        ..shader = const LinearGradient(
          colors: [
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
        ).createShader(Rect.fromLTWH(0, 0, s.width, 5)),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
//  ARC PAINTER (identical)
// ══════════════════════════════════════════════════════════════════════════════
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
    final highlight = Paint()
      ..color = const Color(0x8CFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

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
    c.drawPath(path2, highlight);
    c.drawPath(path3, inner);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
//  REUSED WIDGETS
// ══════════════════════════════════════════════════════════════════════════════
class _IBtn extends StatelessWidget {
  const _IBtn({required this.child, required this.onTap, required this.badge});
  final Widget child;
  final VoidCallback onTap;
  final int badge;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
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
          if (badge > 0)
            Positioned(
                top: -1,
                right: -1,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                      color: _notifRed,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF060E28), width: 1.5)),
                )),
        ]),
      );
}

class _LogoRing extends StatelessWidget {
  const _LogoRing();
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 80,
        height: 80,
        child: Stack(alignment: Alignment.center, children: [
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
          Positioned(top: 2, child: _FlareCross()),
        ]),
      );
}

class _FlareCross extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(11, 11), painter: _FlarePainter());
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

// ══════════════════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class OutfitSourceScreen extends ConsumerStatefulWidget {
  final String photoUrl;
  const OutfitSourceScreen({super.key, required this.photoUrl});

  @override
  ConsumerState<OutfitSourceScreen> createState() => _OutfitSourceScreenState();
}

class _OutfitSourceScreenState extends ConsumerState<OutfitSourceScreen>
    with TickerProviderStateMixin {
  // ── backend state (unchanged) ────────────────────────────────────────────
  String? _selectedOutfitId;
  String? _selectedOutfitUrl;
  String _selectedSource = 'wardrobe';
  final _webUrlController = TextEditingController();

  // ── multi-select combination state ───────────────────────────────────────
  final Set<String> _selectedIds = {};
  late AnimationController _trayController;
  late AnimationController _pulseController;
  late Animation<double> _trayAnim;
  late Animation<double> _pulseAnim;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _trayController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _trayAnim =
        CurvedAnimation(parent: _trayController, curve: Curves.easeOutBack);
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _webUrlController.dispose();
    _trayController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleItem(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _trayController.reverse();
      } else {
        _selectedIds.add(id);
        if (_selectedIds.length == 1) _trayController.forward();
      }
      // keep legacy single-select in sync for backend
      _selectedOutfitId = _selectedIds.isNotEmpty ? _selectedIds.last : null;
    });
  }

  // ── backend method (unchanged logic) ────────────────────────────────────
  Future<void> _proceedWithTryOn() async {
    if (_selectedSource == 'wardrobe' && _selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one outfit item')),
      );
      return;
    }
    if (_selectedSource == 'web' && _selectedOutfitUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid outfit URL')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final sessionId = await ref.read(vtonServiceProvider).submitTryOnJob(
            photoUrl: widget.photoUrl,
            outfitSource: _selectedSource,
            outfitId: _selectedOutfitId,
            outfitUrl: _selectedOutfitUrl,
          );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => TryOnPreviewScreen(sessionId: sessionId)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bodyWhite,
        body: Column(children: [
          // ① Cosmic header
          _buildCosmicHeader(context),

          // ② Source tabs
          _buildSourceTabs(),

          // ③ Content area
          Expanded(
            child: Stack(children: [
              _selectedSource == 'wardrobe'
                  ? _WardrobeGrid(
                      selectedIds: _selectedIds,
                      onToggle: _toggleItem,
                    )
                  : _WebUrlPanel(
                      controller: _webUrlController,
                      onUrlSet: (url) =>
                          setState(() => _selectedOutfitUrl = url),
                    ),

              // Combination tray + CTA — slides up from bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _trayAnim,
                  builder: (_, __) {
                    if (_selectedSource == 'web') {
                      return const SizedBox.shrink();
                    }
                    final show = _selectedIds.isNotEmpty;
                    return show
                        ? FadeTransition(
                            opacity: _trayAnim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                      begin: const Offset(0, 1),
                                      end: Offset.zero)
                                  .animate(_trayAnim),
                              child: _buildCombinationTray(),
                            ),
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ),

              // Web source CTA
              if (_selectedSource == 'web')
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: _buildTryOnButton(isWeb: true),
                ),
            ]),
          ),

          // ④ Footer nav
          _buildFooterNav(context),
        ]),
      ),
    );
  }

  // ── ① COSMIC HEADER ────────────────────────────────────────────────────────
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
                  _IBtn(
                    onTap: () => Navigator.of(context).pop(),
                    badge: 0,
                    child: const Icon(Icons.chevron_left,
                        color: Color(0xFFC8DCF4), size: 18),
                  ),
                  const Spacer(),
                  const _LogoRing(),
                  const Spacer(),
                  _IBtn(
                    onTap: () {},
                    badge: 0,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHLine(12),
                          const SizedBox(height: 3),
                          _buildHLine(12),
                          const SizedBox(height: 3),
                          _buildHLine(9),
                        ]),
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

  Widget _buildHLine(double w) => Container(
      width: w,
      height: 1.5,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1),
          color: const Color(0xFFC8DCF4)));

  Widget _star(double top, double left, double size, double opacity) {
    return LayoutBuilder(
        builder: (context, constraints) => Positioned(
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
                            color: const Color(0xCCC8E6FF),
                            blurRadius: size * 2)
                      ])),
            ));
  }

  // ── ② SOURCE TABS ──────────────────────────────────────────────────────────
  Widget _buildSourceTabs() {
    return Container(
      color: _bodyWhite,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Page title
        Row(children: [
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
              Icon(Icons.checkroom, color: Colors.white, size: 13),
              SizedBox(width: 5),
              Text('Outfit Builder',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: .3)),
            ]),
          ),
          const Spacer(),
          if (_selectedIds.isNotEmpty && _selectedSource == 'wardrobe')
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFFE8F0FF),
                border: Border.all(color: _nxBlue.withOpacity(.4), width: 1),
              ),
              child: Text('${_selectedIds.length} selected',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _nxBlue)),
            ),
        ]),
        const SizedBox(height: 12),
        // Tabs
        Container(
          height: 44,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFFF0F4FF),
            border: Border.all(color: _borderLight, width: 1),
          ),
          child: Row(children: [
            _Tab(
                label: 'My Wardrobe',
                icon: Icons.dry_cleaning_outlined,
                isSelected: _selectedSource == 'wardrobe',
                onTap: () => setState(() => _selectedSource = 'wardrobe')),
            const SizedBox(width: 3),
            _Tab(
                label: 'Web / Catalog',
                icon: Icons.link_outlined,
                isSelected: _selectedSource == 'web',
                onTap: () => setState(() => _selectedSource = 'web')),
          ]),
        ),
        const SizedBox(height: 12),
        // Subtle subtitle
        Text(
          _selectedSource == 'wardrobe'
              ? 'Tap items to build your combination. Select multiple to try on together.'
              : 'Paste an image URL from any online shop.',
          style: const TextStyle(fontSize: 11, color: _lightText, height: 1.5),
        ),
        const SizedBox(height: 10),
        Container(
            height: 1,
            decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
              Colors.transparent,
              Color(0x80B4CDE8),
              Color(0x80B4CDE8),
              Colors.transparent
            ]))),
      ]),
    );
  }

  // ── COMBINATION TRAY ────────────────────────────────────────────────────────
  Widget _buildCombinationTray() {
    final wardrobeAsync = ref.watch(wardrobeItemsProvider);
    final items = wardrobeAsync.valueOrNull ?? [];
    final selected = items.where((i) => _selectedIds.contains(i.id)).toList();

    return Container(
      decoration: const BoxDecoration(
        color: _bodyWhite,
        border: Border(top: BorderSide(color: Color(0xFFDDE3F0), width: 1)),
        boxShadow: [
          BoxShadow(
              color: Color(0x1A0A1E58), blurRadius: 20, offset: Offset(0, -4))
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Header strip
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A4E8F),
                  Color(0xFF060F2E),
                  Color(0xFF0D1E50)
                ]),
          ),
          child: Row(children: [
            const Icon(Icons.layers_outlined,
                color: Color(0xB3B4D7FF), size: 14),
            const SizedBox(width: 6),
            const Text('Your Combination',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xF2D2E8FF),
                    letterSpacing: .4)),
            const Spacer(),
            GestureDetector(
              onTap: () {
                setState(() => _selectedIds.clear());
                _trayController.reverse();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0x1AFFFFFF),
                    border: Border.all(color: const Color(0x33FFFFFF))),
                child: const Text('Clear all',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xB3B4D7FF))),
              ),
            ),
          ]),
        ),

        // Selected items horizontal strip
        Container(
          height: 82,
          color: const Color(0xFFF8FAFF),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: selected.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final item = selected[i];
              return Stack(children: [
                Container(
                  width: 58,
                  height: 66,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: _nxBlue.withOpacity(.5), width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1A0A1E58), blurRadius: 6)
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.network(item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFE8F0FF),
                            child: const Icon(Icons.checkroom,
                                color: _lightText, size: 22))),
                  ),
                ),
                // Remove X
                Positioned(
                    top: -3,
                    right: -3,
                    child: GestureDetector(
                      onTap: () => _toggleItem(item.id),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                            color: _nxBlue, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 10),
                      ),
                    )),
                // Category label
                Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(8)),
                        gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(.65),
                              Colors.transparent
                            ]),
                      ),
                      child: Text(item.category,
                          style: const TextStyle(
                              fontSize: 6.5,
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    )),
              ]);
            },
          ),
        ),

        // CTA button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: _buildTryOnButton(isWeb: false),
        ),
      ]),
    );
  }

  // ── TRY ON BUTTON ──────────────────────────────────────────────────────────
  Widget _buildTryOnButton({required bool isWeb}) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: (_selectedIds.isNotEmpty || isWeb) ? _pulseAnim.value : 1.0,
        child: child,
      ),
      child: GestureDetector(
        onTap: _isLoading ? null : _proceedWithTryOn,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_nxBlue, _nxBlueDark],
            ),
            border: Border.all(color: const Color(0x516490FF), width: 1),
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
          child: _isLoading
              ? const Center(
                  child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.camera_enhance_outlined,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isWeb
                        ? 'Try On This Outfit'
                        : _selectedIds.isEmpty
                            ? 'Select Items to Try On'
                            : 'Try On ${_selectedIds.length} Item${_selectedIds.length > 1 ? " Combination" : ""}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: .3),
                  ),
                ]),
        ),
      ),
    );
  }

  // ── ④ FOOTER NAV ───────────────────────────────────────────────────────────
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
        _FooterNavItem(
            icon: Icons.camera_alt_outlined,
            label: 'Try-On',
            active: true,
            onTap: () {}),
        _NavSep(),
        _FooterNavItem(
            icon: Icons.checkroom_outlined,
            label: 'Wardrobe',
            active: false,
            onTap: () => Navigator.of(context).pop()),
        _NavSep(),
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
        _FooterNavItem(
            icon: Icons.people_outline,
            label: 'Friends Space',
            active: false,
            onTap: () {}),
        _NavSep(),
        _FooterNavItem(
            icon: Icons.shopping_bag_outlined,
            label: 'Shopping',
            active: false,
            onTap: () {}),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TAB WIDGET
// ══════════════════════════════════════════════════════════════════════════════
class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _Tab(
      {required this.label,
      required this.icon,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_nxBlue, _nxBlueDark])
                  : null,
              color: isSelected ? null : Colors.transparent,
              boxShadow: isSelected
                  ? const [
                      BoxShadow(
                          color: Color(0x3D2A58C8),
                          blurRadius: 8,
                          offset: Offset(0, 2))
                    ]
                  : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon,
                  size: 13, color: isSelected ? Colors.white : _lightText),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : _lightText)),
            ]),
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
//  WARDROBE MULTI-SELECT GRID
// ══════════════════════════════════════════════════════════════════════════════
class _WardrobeGrid extends ConsumerWidget {
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  const _WardrobeGrid({required this.selectedIds, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wardrobeAsync = ref.watch(wardrobeItemsProvider);

    return wardrobeAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _nxBlue)),
      error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: _midText))),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF0F4FF),
                    border: Border.all(color: _borderLight)),
                child: const Icon(Icons.dry_cleaning_outlined,
                    size: 36, color: _lightText),
              ),
              const SizedBox(height: 16),
              const Text('Your wardrobe is empty',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _darkText)),
              const SizedBox(height: 6),
              const Text('Add items to your wardrobe first',
                  style: TextStyle(fontSize: 12, color: _lightText)),
            ]),
          );
        }

        // Group by category
        final Map<String, List<dynamic>> grouped = {};
        for (final item in items) {
          grouped.putIfAbsent(item.category, () => []).add(item);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 200),
          children: grouped.entries.map((entry) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFF0F4FF),
                          border: Border.all(color: _borderLight),
                        ),
                        child: Text(entry.key,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _darkText,
                                letterSpacing: .3)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Container(
                              height: 1,
                              decoration: const BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                Color(0x80B4CDE8),
                                Colors.transparent
                              ])))),
                      const SizedBox(width: 6),
                      Text('${entry.value.length}',
                          style: const TextStyle(
                              fontSize: 9,
                              color: _lightText,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),

                  // Items row
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: .78,
                    ),
                    itemCount: entry.value.length,
                    itemBuilder: (_, i) {
                      final item = entry.value[i];
                      final isSelected = selectedIds.contains(item.id);
                      return _WardrobeItemCard(
                          item: item,
                          isSelected: isSelected,
                          onTap: () => onToggle(item.id));
                    },
                  ),
                  const SizedBox(height: 16),
                ]);
          }).toList(),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  WARDROBE ITEM CARD (with animated select state)
// ══════════════════════════════════════════════════════════════════════════════
class _WardrobeItemCard extends StatelessWidget {
  final dynamic item;
  final bool isSelected;
  final VoidCallback onTap;
  const _WardrobeItemCard(
      {required this.item, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _nxBlue : const Color(0xFFDDE3F0),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                      color: Color(0x3D2A58C8),
                      blurRadius: 10,
                      offset: Offset(0, 3))
                ]
              : const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isSelected ? 12 : 13),
          child: Stack(fit: StackFit.expand, children: [
            // Image
            Image.network(item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFEEF3FF),
                    child: const Center(
                        child: Icon(Icons.checkroom,
                            color: _lightText, size: 28)))),

            // Overlay on selected
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        _nxBlue.withOpacity(.55),
                        _nxBlue.withOpacity(.18),
                        Colors.transparent
                      ]),
                ),
              ),
            ),

            // Check badge
            Positioned(
              top: 6,
              right: 6,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 220),
                curve: Curves.elasticOut,
                scale: isSelected ? 1.0 : 0.0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        const LinearGradient(colors: [_nxBlue, _nxBlueDark]),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0x3D2A58C8), blurRadius: 6)
                    ],
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 13),
                ),
              ),
            ),

            // Unselected circle hint
            if (!isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(.85),
                    border:
                        Border.all(color: const Color(0xFFDDE3F0), width: 1.5),
                  ),
                ),
              ),

            // Label at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(.7),
                        Colors.transparent
                      ]),
                ),
                child: Text(
                  item.colorTags.isNotEmpty
                      ? item.colorTags.first
                      : item.category,
                  style: const TextStyle(
                      fontSize: 8.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  WEB URL PANEL
// ══════════════════════════════════════════════════════════════════════════════
class _WebUrlPanel extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onUrlSet;
  const _WebUrlPanel({required this.controller, required this.onUrlSet});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Icon header
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [_nxBlue, _nxBlueDark]),
            boxShadow: [BoxShadow(color: Color(0x3D2A58C8), blurRadius: 12)],
          ),
          child: const Icon(Icons.travel_explore_outlined,
              color: Colors.white, size: 26),
        ),
        const SizedBox(height: 16),
        const Text('Outfit Image URL',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _darkText,
                letterSpacing: -.3)),
        const SizedBox(height: 6),
        const Text(
            'Paste a direct link to an outfit image from any online catalog or shop.',
            style: TextStyle(fontSize: 13, color: _lightText, height: 1.5)),
        const SizedBox(height: 24),

        // URL input
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _bodyWhite,
            border: Border.all(color: _borderLight, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x0A0A1E58), blurRadius: 8)
            ],
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(
                fontSize: 13, color: _darkText, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'https://shop.example.com/outfit.jpg',
              hintStyle:
                  TextStyle(fontSize: 13, color: _lightText.withOpacity(.6)),
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFFF0F4FF)),
                child: const Icon(Icons.link, color: _nxBlue, size: 16),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && Uri.tryParse(value) != null) {
                onUrlSet(value);
              }
            },
          ),
        ),
        const SizedBox(height: 20),

        // Info card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEEF4FF), Color(0xFFE8F0FF)]),
            border: Border.all(color: const Color(0xFFBDD0F0), width: 1),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: _nxBlue.withOpacity(.12)),
              child:
                  const Icon(Icons.lightbulb_outline, color: _nxBlue, size: 16),
            ),
            const SizedBox(width: 12),
            const Expanded(
                child: Text(
              'Make sure the URL points directly to an image (ends with .jpg, .png, .webp) and is publicly accessible.',
              style: TextStyle(fontSize: 12, color: _midText, height: 1.55),
            )),
          ]),
        ),
        const SizedBox(height: 16),

        // Popular shops hint
        const Text('Popular shops to try:',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: _darkText)),
        const SizedBox(height: 10),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'ASOS',
              'Zara',
              'H&M',
              'Nordstrom',
              'Farfetch',
              'Net-a-Porter',
            ]
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: _bodyWhite,
                        border: Border.all(color: _borderLight),
                        boxShadow: const [
                          BoxShadow(color: Color(0x080A1E58), blurRadius: 4)
                        ],
                      ),
                      child: Text(s,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _midText)),
                    ))
                .toList()),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  FOOTER NAV ITEM
// ══════════════════════════════════════════════════════════════════════════════
class _FooterNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FooterNavItem(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap});

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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/dashboard_components.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../../../core/services/recommendations_service.dart';
import '../../../core/providers/user_image_provider.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../../settings/screens/fashion_preferences_screen.dart';
import '../providers/recommendations_provider.dart';
import '../../social/providers/social_provider.dart';
import '../../tryon/providers/tryon_provider.dart';
import '../../../routes.dart';
import '../../../core/widgets/fashion_drawer.dart';
import '../../../core/widgets/theme_wrapper.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─────────────────────────────────────────────
// CONSTANTS  (mirrors the CSS vars & sizes)
// ─────────────────────────────────────────────
class _C {
  // cosmic / header
  static const cosmicTop = Color(0xFF4880E0);
  static const cosmicMid = Color(0xFF1848C0);
  static const cosmicDeep = Color(0xFF0A1E58);
  static const cosmicDark = Color(0xFF050F2A);
  static const cosmicBlack = Color(0xFF020810);

  // browser chrome
  static const browserBg = Color(0xFF0A1030);
  static const chromeDark = Color(0xFF080F36);
  static const chromeMid = Color(0xFF0D1E58);
  static const urlBarBg = Color(0xEBFFFFFF);
  static const tabActiveBg = Color(0xF0FFFFFF);
  static const tabInactiveBg = Color(0x12FFFFFF);
  static const tabBorder = Color(0x26649FFF);

  // product page
  static const pageWhite = Color(0xFFFFFFFF);
  static const pageBg = Color(0xFF0C1E48);
  static const textDark = Color(0xFF0C1E48);
  static const textMid = Color(0xFF2A3A6A);
  static const textLight = Color(0xFF6070A0);
  static const borderLight = Color(0xFFDDE3F0);
  static const promoBg = Color(0xFFF0F3FF);

  // NX action bar
  static const nxBarBg = Color(0xF7081246);
  static const nxBtnBg = Color(0xE60F2680);
  static const nxBtnBorder = Color(0x615090FF);
  static const nxText = Color(0xE0C8E1FF);

  // footer
  static const footerBg = Color(0xFFD4E0F0);
  static const footerText = Color(0xFF1A3060);
  static const footerActive = Color(0xFF0A1E58);

  // buttons
  static const bagGold = Color(0xFFB87D3A);
  static const bagGoldDark = Color(0xFFA06828);
  static const sizeNavy = Color(0xFF0A1E58);
  static const sizeNavyDark = Color(0xFF060F2E);
  static const confirmBlue = Color(0xFF2A58C8);
  static const confirmBlueDark = Color(0xFF1A3A9A);

  // misc
  static const starBlue = Color(0xFF4878D8);
  static const logoRingLight = Color(0xFFC8DCF0);
  static const accent = Color(0xFF6AA4FF);
  static const notifRed = Color(0xFFE85A4F);
}

// ─────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────
class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState
    extends ConsumerState<RecommendationsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Browser state
  int _activeTab = 0; // 0=Brooks, 1=CharlesTyrwhitt, 99=newtab
  final List<_BrowserTab> _tabs = [
    _BrowserTab(id: 0, title: 'Sky Blue Shirt — Brooks', url: 'brooksbros.com/shirts/classic-blue', favicon: 'B', faviconColor: _C.pageBg),
    _BrowserTab(id: 1, title: 'Slim-Fit — Charles T', url: 'ctshirts.com/slim-blue', favicon: 'C', faviconColor: const Color(0xFF1A4A8A)),
  ];
  final List<String> _urlHistory = ['brooksbros.com/shirts/classic-blue'];
  int _histIdx = 0;
  bool _isLoading = false;
  String _currentUrl = 'brooksbros.com/shirts/classic-blue';
  final TextEditingController _urlController = TextEditingController(
    text: 'brooksbros.com/shirts/classic-blue',
  );
  bool _urlEditing = false;

  // Product page state
  String _prodTab = 'desc';
  int _activeThumb = 0;
  String? _selectedSize;
  int _bagCount = 0;
  String? _toastMsg;
  bool _showToast = false;

  // Size modal
  final List<String> _sizes = [
    '14.5/32','14.5/33','15/32','15/33','15.5/33','15.5/34',
    '16/33','16/34','16.5/34','16.5/35','17/34','17/35'
  ];
  final List<String> _soldOut = ['14.5/32','15.5/33'];
  String? _pendingSize;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────
  void _showToastMsg(String msg) {
    setState(() { _toastMsg = msg; _showToast = true; });
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) setState(() => _showToast = false);
    });
  }

  Future<void> _simulateLoad(VoidCallback onDone) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isLoading = false);
      onDone();
    }
  }

  void _switchTab(int id) {
    setState(() => _activeTab = id);
    final t = _tabs.where((t) => t.id == id).firstOrNull;
    if (t != null) {
      _urlController.text = t.url;
      _currentUrl = t.url;
    }
  }

  void _addTab() {
    final newId = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _tabs.add(_BrowserTab(id: newId, title: 'New Tab', url: '', favicon: '+', faviconColor: const Color(0xFF4A5A80)));
      _activeTab = newId;
      _urlController.text = '';
      _currentUrl = '';
    });
  }

  void _closeTab(int id) {
    setState(() {
      _tabs.removeWhere((t) => t.id == id);
      if (_tabs.isEmpty) {
        _addTab();
      } else if (_activeTab == id) {
        _activeTab = _tabs.first.id;
        _urlController.text = _tabs.first.url;
        _currentUrl = _tabs.first.url;
      }
    });
    _showToastMsg('Tab closed');
  }

  void _navBack() {
    if (_histIdx > 0) {
      _histIdx--;
      _urlController.text = _urlHistory[_histIdx];
      _currentUrl = _urlHistory[_histIdx];
      _simulateLoad(() => setState(() {}));
    }
  }

  void _navFwd() {
    if (_histIdx < _urlHistory.length - 1) {
      _histIdx++;
      _urlController.text = _urlHistory[_histIdx];
      _currentUrl = _urlHistory[_histIdx];
      _simulateLoad(() => setState(() {}));
    }
  }

  void _commitUrl(String val) {
    setState(() { _urlEditing = false; });
    if (val.trim().isEmpty) return;
    final v = val.toLowerCase();
    _urlHistory.removeRange(_histIdx + 1, _urlHistory.length);
    _urlHistory.add(val);
    _histIdx = _urlHistory.length - 1;
    if (v.contains('brooks')) {
      _simulateLoad(() => setState(() { _activeTab = 0; _currentUrl = val; }));
    } else if (v.contains('charles') || v.contains('ct')) {
      _simulateLoad(() => setState(() { _activeTab = 1; _currentUrl = val; }));
    } else {
      _simulateLoad(() => _showToastMsg('Page not available in preview'));
    }
  }

  void _openSizeModal(BuildContext context) {
    setState(() => _pendingSize = _selectedSize);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SizeModal(
        sizes: _sizes,
        soldOut: _soldOut,
        selected: _pendingSize,
        onChanged: (s) => setState(() => _pendingSize = s),
        onConfirm: () {
          setState(() { _selectedSize = _pendingSize; });
          Navigator.pop(context);
          if (_selectedSize != null) {
            _showToastMsg('Size $_selectedSize selected ✓');
          } else {
            _showToastMsg('Please select a size first');
          }
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _addToBag(BuildContext context) {
    if (_selectedSize == null) {
      _openSizeModal(context);
      return;
    }
    setState(() => _bagCount++);
    _showToastMsg('Added to bag ✓');
  }

  String get _prodTabContent {
    switch (_prodTab) {
      case 'desc':
        return 'Crafted from 100% Supima® cotton. Wide-spread collar, barrel cuffs, easy-care finish. Our signature tailored fit for all-day comfort.';
      case 'det':
        return 'Material: 100% Supima Cotton · Fit: Classic · Collar: Wide-Spread · Cuff: Barrel · Care: Machine wash cold · Country: USA';
      case 'rev':
        return '★★★★★ 4.8 / 5 — "Perfect fit and incredibly soft fabric." — James L.\n\n★★★★☆ — "Great shirt for the office." — Michael R.\n\nSee all 208 reviews on brooksbros.com';
      default:
        return '';
    }
  }

  // ── BUILD ──────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final recommendationsAsync = ref.watch(recommendationsProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _C.browserBg,
      drawer: const AppDrawer(currentRoute: Routes.recommendations),
      body: Stack(
        children: [
          Column(
            children: [
              // ① Cosmic header
              _CosmicHeader(
                onBack: () => _showToastMsg('Returned to Shopping'),
                onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                notifCount: ref.watch(socialUnreadCountProvider),
              ),

              // ② Browser chrome
              _BrowserChrome(
                tabs: _tabs,
                activeTab: _activeTab,
                urlController: _urlController,
                urlEditing: _urlEditing,
                isLoading: _isLoading,
                canBack: _histIdx > 0,
                canFwd: _histIdx < _urlHistory.length - 1,
                onTabSwitch: _switchTab,
                onTabClose: _closeTab,
                onAddTab: _addTab,
                onBack: _navBack,
                onFwd: _navFwd,
                onUrlTap: () => setState(() => _urlEditing = true),
                onUrlSubmit: _commitUrl,
                onReload: () => _simulateLoad(() => _showToastMsg('Page reloaded')),
                onShare: () => _showToastMsg('Share link copied ✓'),
                onMenu: () => _showToastMsg('Browser menu opening…'),
                onFav: () => _showToastMsg('Added to My Favourites ♥'),
                onOutfit: () => _showToastMsg('Added to Outfit ✓'),
                onTryOn: () => _showToastMsg('Opening Try-On…'),
                onRemove: () => _showToastMsg('Removed from list'),
              ),

              // ③ Viewport
              Expanded(
                child: Container(
                  color: _C.pageWhite,
                  child: _activeTab == 99 || _tabs.where((t) => t.id == _activeTab).isEmpty
                      ? _NewTabPage(
                          onVisit: (url, idx) => _simulateLoad(() {
                            setState(() {
                              _activeTab = idx;
                              _currentUrl = url;
                              _urlController.text = url;
                            });
                          }),
                          onSearch: (q) => _simulateLoad(() => _showToastMsg('Searching for: $q')),
                        )
                      : _activeTab == 1
                          ? _CharlesTyrwhittPage(
                              onSizeSelect: () => _showToastMsg('Size selector opening…'),
                              onAddBag: () => _showToastMsg('Added to bag ✓'),
                            )
                          : _BrooksBrothersPage(
                              activeThumb: _activeThumb,
                              prodTab: _prodTab,
                              tabContent: _prodTabContent,
                              selectedSize: _selectedSize,
                              onThumb: (i) => setState(() => _activeThumb = i),
                              onProdTab: (t) => setState(() => _prodTab = t),
                              onSelectSize: () => _openSizeModal(context),
                              onAddBag: () => _addToBag(context),
                              onZoom: () => _showToastMsg('Image zoomed'),
                            ),
                ),
              ),

              // ④ NX action bar
              _NXActionBar(
                onFav: () => _showToastMsg('Added to My Favourites ♥'),
                onRemove: () => _showToastMsg('Removed from list'),
                onOutfit: () => _showToastMsg('Added to Outfit ✓'),
              ),

              // ⑤ Footer nav
              _FooterNav(
                onTryOn: () => Navigator.of(context).pushNamed(Routes.tryon),
                onChat: () => _showToastMsg('NX Chat opening…'),
                onHome: () => Navigator.of(context).pushNamed(Routes.recommendations),
                onFriends: () => _showToastMsg('Friends Space opening…'),
              ),
            ],
          ),

          // Toast overlay
          if (_showToast && _toastMsg != null)
            Positioned(
              bottom: 90,
              left: 0,
              right: 0,
              child: Center(
                child: _Toast(message: _toastMsg!),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────
class _BrowserTab {
  final int id;
  final String title;
  final String url;
  final String favicon;
  final Color faviconColor;
  _BrowserTab({required this.id, required this.title, required this.url, required this.favicon, required this.faviconColor});
}

// ─────────────────────────────────────────────
// ① COSMIC HEADER
// ─────────────────────────────────────────────
class _CosmicHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onMenu;
  final int notifCount;
  const _CosmicHeader({required this.onBack, required this.onMenu, required this.notifCount});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 99,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.85),
                  radius: 1.8,
                  colors: [_C.cosmicTop, _C.cosmicMid, _C.cosmicDeep, _C.cosmicDark, _C.cosmicBlack],
                  stops: [0.0, 0.16, 0.36, 0.62, 1.0],
                ),
              ),
            ),
          ),
          // top shimmer rim
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  Color(0xFF1E2E50), Color(0xFF4868A8), Color(0xFF90B4D8),
                  Color(0xFFC8DFF0), Color(0xFFE8F4FF), Color(0xFFFFFFFF),
                  Color(0xFFE8F4FF), Color(0xFFC8DFF0), Color(0xFF90B4D8),
                  Color(0xFF4868A8), Color(0xFF1E2E50),
                ]),
                boxShadow: [BoxShadow(color: Color(0x80B4DCFF), blurRadius: 8)],
              ),
            ),
          ),
          // stars
          ..._buildStars(),
          // top bar content
          Positioned(
            top: 8, left: 0, right: 0,
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // back button
                    _GlassBtn(onTap: onBack, child: const Icon(Icons.chevron_left, color: _C.logoRingLight, size: 18)),
                    const Spacer(),
                    // Logo center (absolute in HTML)
                    _LogoRing(),
                    const Spacer(),
                    // right buttons
                    _GlassBtn(
                      onTap: onMenu,
                      child: const Icon(Icons.person_outline, color: _C.logoRingLight, size: 16),
                    ),
                    const SizedBox(width: 5),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _GlassBtn(
                          onTap: () {},
                          child: const Icon(Icons.notifications_none, color: _C.logoRingLight, size: 16),
                        ),
                        if (notifCount > 0)
                          Positioned(
                            top: -1, right: -1,
                            child: Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: _C.notifRed,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF060E28), width: 1),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // arc at bottom
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 30),
              painter: _ArcPainter(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStars() => [
    _Star(top: .12, left: .06, size: 2, opacity: .75),
    _Star(top: .05, left: .46, size: 1.5, opacity: .5),
    _Star(top: .16, left: .87, size: 2, opacity: .7),
    _Star(top: .04, left: .93, size: 2.5, opacity: .28),
    _Star(top: .08, left: .30, size: 1.5, opacity: .4),
  ];
}

class _Star extends StatelessWidget {
  final double top, left, size, opacity;
  const _Star({required this.top, required this.left, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Positioned(
        top: constraints.maxHeight * top,
        left: constraints.maxWidth * left,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: const Color(0xCCC8E1FF), blurRadius: 3)],
          ),
        ),
      ),
    );
  }
}

class _LogoRing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // halo
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              const Color(0x7A50A0FF), const Color(0x2D2864DC), Colors.transparent,
            ], stops: const [0.0, 0.36, 0.65]),
          ),
        ),
        // ring
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(colors: [
              Color(0xFF1E3060), Color(0xFF5080B0), Color(0xFF90B8D8),
              Color(0xFFC8DCF0), Color(0xFFE8F4FF), Color(0xFFFFFFFF),
              Color(0xFFE8F4FF), Color(0xFFC8DCF0), Color(0xFF90B8D8),
              Color(0xFF5080B0), Color(0xFF1E3060),
            ]),
            boxShadow: [
              BoxShadow(color: const Color(0x7A96C3FF), blurRadius: 14),
              BoxShadow(color: const Color(0x592878E6), blurRadius: 30),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.2, -0.3),
                colors: [Color(0xFF1A3A7A), Color(0xFF0D1E50), Color(0xFF08122E)],
              ),
            ),
            child: const Icon(Icons.check_box_outline_blank, color: Color(0x6696C8FF), size: 22),
          ),
        ),
        // flares
        Positioned(
          top: 0,
          child: CustomPaint(size: const Size(11, 11), painter: _FlarePainter()),
        ),
      ],
    );
  }
}

class _GlassBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _GlassBtn({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x29FFFFFF), Color(0x0FFFFFFF)],
          ),
          border: Border.all(color: const Color(0x42FFFFFF), width: 1),
          boxShadow: const [BoxShadow(color: Color(0x661E001E), blurRadius: 6)],
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..shader = LinearGradient(colors: [
        const Color(0x003060C0), const Color(0x384878D8), const Color(0x706AA4FF),
        const Color(0x384878D8), const Color(0x003060C0),
      ]).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    final mainPaint = Paint()
      ..shader = LinearGradient(colors: [
        const Color(0x591A2E50), const Color(0xE04868A8), const Color(0xFF90B4D8),
        const Color(0xFFC8DFF2), const Color(0xFFEEF6FF), const Color(0xFFFFFFFF),
        const Color(0xFFEEF6FF), const Color(0xFFC8DFF2), const Color(0xFF90B4D8),
        const Color(0xE04868A8), const Color(0x591A2E50),
      ]).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;

    final path = Path()
      ..moveTo(0, 6)
      ..quadraticBezierTo(size.width / 2, 30, size.width, 6);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, mainPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FlarePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xE6DCF0FF)..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), p);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// ② BROWSER CHROME
// ─────────────────────────────────────────────
class _BrowserChrome extends StatelessWidget {
  final List<_BrowserTab> tabs;
  final int activeTab;
  final TextEditingController urlController;
  final bool urlEditing;
  final bool isLoading;
  final bool canBack, canFwd;
  final void Function(int) onTabSwitch;
  final void Function(int) onTabClose;
  final VoidCallback onAddTab, onBack, onFwd, onUrlTap, onReload, onShare, onMenu;
  final void Function(String) onUrlSubmit;
  final VoidCallback onFav, onOutfit, onTryOn, onRemove;

  const _BrowserChrome({
    required this.tabs, required this.activeTab, required this.urlController,
    required this.urlEditing, required this.isLoading, required this.canBack,
    required this.canFwd, required this.onTabSwitch, required this.onTabClose,
    required this.onAddTab, required this.onBack, required this.onFwd,
    required this.onUrlTap, required this.onUrlSubmit, required this.onReload,
    required this.onShare, required this.onMenu, required this.onFav,
    required this.onOutfit, required this.onTryOn, required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_C.chromeMid, _C.chromeDark],
        ),
        border: Border(bottom: BorderSide(color: Color(0x384096FF), width: 1)),
      ),
      child: Column(
        children: [
          // Nav row
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 5),
            child: Row(
              children: [
                _NavBtn(enabled: canBack, onTap: onBack, child: const Icon(Icons.chevron_left, color: Color(0xD9B4D7FF), size: 14)),
                const SizedBox(width: 5),
                _NavBtn(enabled: canFwd, onTap: onFwd, child: const Icon(Icons.chevron_right, color: Color(0xD9B4D7FF), size: 14)),
                const SizedBox(width: 5),
                // URL bar
                Expanded(
                  child: GestureDetector(
                    onTap: onUrlTap,
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: _C.urlBarBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x59A0C8F0), width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline, size: 10, color: Color(0xFF6070A0)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: urlEditing
                                ? TextField(
                                    controller: urlController,
                                    autofocus: true,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _C.textDark),
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                                    onSubmitted: onUrlSubmit,
                                  )
                                : Text(
                                    urlController.text,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _C.textDark),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                          GestureDetector(
                            onTap: onReload,
                            child: const Icon(Icons.refresh, size: 12, color: Color(0xFF6070A0)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                _NavBtn(enabled: true, onTap: onShare, child: const Icon(Icons.ios_share, color: Color(0xD9B4D7FF), size: 13)),
                const SizedBox(width: 3),
                _NavBtn(enabled: true, onTap: onMenu, child: const Icon(Icons.more_vert, color: Color(0xCCB4D7FF), size: 13)),
              ],
            ),
          ),

          // Progress bar
          SizedBox(
            height: 2,
            child: isLoading
                ? LinearProgressIndicator(
                    backgroundColor: const Color(0x1A6490FF),
                    valueColor: const AlwaysStoppedAnimation(_C.accent),
                  )
                : const SizedBox(),
          ),

          // Quick action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
            child: Row(
              children: [
                _ActionBtn(icon: Icons.favorite, label: 'Favourite', onTap: onFav),
                const SizedBox(width: 4),
                _ActionBtn(icon: Icons.checkroom, label: 'Add to Outfit', onTap: onOutfit),
                const SizedBox(width: 4),
                _ActionBtn(icon: Icons.camera_alt_outlined, label: 'Try On', onTap: onTryOn),
                const SizedBox(width: 4),
                _ActionBtn(icon: Icons.delete_outline, label: 'Remove', onTap: onRemove),
              ],
            ),
          ),

          // Tabs row
          SizedBox(
            height: 30,
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(8, 4, 0, 0),
                    child: Row(
                      children: [
                        ...tabs.map((t) => _BrowserTabWidget(
                          tab: t,
                          isActive: t.id == activeTab,
                          onTap: () => onTabSwitch(t.id),
                          onClose: () => onTabClose(t.id),
                        )),
                      ],
                    ),
                  ),
                ),
                // New tab button
                GestureDetector(
                  onTap: onAddTab,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8, bottom: 0, left: 4),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: _C.tabInactiveBg,
                      border: Border.all(color: _C.tabBorder, width: 1),
                    ),
                    child: const Icon(Icons.add, color: Color(0xB3B4D7FF), size: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;
  const _NavBtn({required this.enabled, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.3,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: const Color(0x176496FF),
            border: Border.all(color: const Color(0x336490FF), width: 1),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: const Color(0x126496FF),
            border: Border.all(color: const Color(0x2E6490FF), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 10, color: const Color(0xBFB4D7FF)),
              const SizedBox(width: 3),
              Flexible(
                child: Text(label, style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.w700, color: Color(0xBFB4D7FF)), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowserTabWidget extends StatelessWidget {
  final _BrowserTab tab;
  final bool isActive;
  final VoidCallback onTap, onClose;
  const _BrowserTabWidget({required this.tab, required this.isActive, required this.onTap, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        constraints: const BoxConstraints(minWidth: 60, maxWidth: 110),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          color: isActive ? _C.tabActiveBg : _C.tabInactiveBg,
          border: Border.all(color: isActive ? const Color(0x66A0C8F0) : _C.tabBorder, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: tab.faviconColor, borderRadius: BorderRadius.circular(2)),
              child: Center(child: Text(tab.favicon, style: const TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                tab.title,
                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: isActive ? _C.textDark : const Color(0xB3B4D7FF)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 3),
            GestureDetector(
              onTap: onClose,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? const Color(0x1A000000) : const Color(0x1AFFFFFF),
                ),
                child: Center(
                  child: Text('×', style: TextStyle(fontSize: 9, color: isActive ? const Color(0xFF3A4A6A) : const Color(0xCCB4D7FF), height: 1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ③ BROOKS BROTHERS PAGE
// ─────────────────────────────────────────────
class _BrooksBrothersPage extends StatelessWidget {
  final int activeThumb;
  final String prodTab, tabContent;
  final String? selectedSize;
  final void Function(int) onThumb;
  final void Function(String) onProdTab;
  final VoidCallback onSelectSize, onAddBag, onZoom;

  const _BrooksBrothersPage({
    required this.activeThumb, required this.prodTab, required this.tabContent,
    required this.selectedSize, required this.onThumb, required this.onProdTab,
    required this.onSelectSize, required this.onAddBag, required this.onZoom,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // store bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: _C.pageWhite,
            border: Border(bottom: BorderSide(color: _C.borderLight)),
          ),
          child: Row(
            children: [
              const Icon(Icons.menu, color: _C.pageBg, size: 16),
              const SizedBox(width: 8),
              const Icon(Icons.search, color: _C.pageBg, size: 16),
              const Spacer(),
              Column(children: [
                const Text('Brooks Brothers', style: TextStyle(fontFamily: 'Georgia', fontSize: 13, fontStyle: FontStyle.italic, color: _C.pageBg)),
                const Text('Est. 1818', style: TextStyle(fontSize: 7, color: Color(0xFF8090B0), letterSpacing: 1.5)),
              ]),
              const Spacer(),
              const Icon(Icons.person_outline, color: _C.pageBg, size: 16),
              const SizedBox(width: 7),
              const Icon(Icons.shopping_bag_outlined, color: _C.pageBg, size: 16),
            ],
          ),
        ),
        // promo bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: const BoxDecoration(
            color: _C.promoBg,
            border: Border(bottom: BorderSide(color: _C.borderLight)),
          ),
          child: Row(
            children: [
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 9.5, color: _C.textMid, fontFamily: 'sans-serif'),
                    children: [
                      TextSpan(text: 'Enjoy 15% off your first purchase with code '),
                      TextSpan(text: 'WELCOME.', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2A9A))),
                    ],
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF6070A0)),
            ],
          ),
        ),
        // product area
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // image col
                Container(
                  width: 148,
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF6F9FF),
                    border: Border(right: BorderSide(color: _C.borderLight)),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: onZoom,
                        child: AspectRatio(
                          aspectRatio: 4 / 5,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE8F0FF), Color(0xFFDCE8F8)]),
                            ),
                            child: CustomPaint(painter: _ShirtPainter(thumbIndex: activeThumb)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(3, (i) => Padding(
                          padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
                          child: GestureDetector(
                            onTap: () => onThumb(i),
                            child: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: activeThumb == i ? _C.confirmBlue : const Color(0xFFC8D8F0), width: 1.5),
                                color: const Color(0xFFEEF3FF),
                              ),
                              child: CustomPaint(painter: _ThumbPainter(index: i)),
                            ),
                          ),
                        )),
                      ),
                      const SizedBox(height: 8),
                      const Align(alignment: Alignment.centerLeft, child: Text('Sky Blue Classic Dress Shirt', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _C.pageBg))),
                      const SizedBox(height: 4),
                      const Align(alignment: Alignment.centerLeft, child: Text('\$99.00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _C.pageBg))),
                    ],
                  ),
                ),
                // info col
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sky Blue Classic Dress Shirt', style: TextStyle(fontFamily: 'Georgia', fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.pageBg, height: 1.3)),
                        const SizedBox(height: 4),
                        const Text('\$99.00', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _C.pageBg)),
                        const SizedBox(height: 9),
                        // product tabs
                        Row(
                          children: [
                            _ProdTab(label: 'Description', active: prodTab == 'desc', onTap: () => onProdTab('desc')),
                            _ProdTab(label: 'Details', active: prodTab == 'det', onTap: () => onProdTab('det')),
                            _ProdTab(label: 'Reviews (208)', active: prodTab == 'rev', onTap: () => onProdTab('rev')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(tabContent, style: const TextStyle(fontSize: 9, color: Color(0xFF3A4A6A), height: 1.6)),
                        const SizedBox(height: 10),
                        // size button
                        GestureDetector(
                          onTap: onSelectSize,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(colors: selectedSize != null
                                  ? [const Color(0xFF1A6A3A), const Color(0xFF0F4A28)]
                                  : [_C.sizeNavy, _C.sizeNavyDark]),
                              border: Border.all(color: const Color(0x516490FF), width: 1),
                              boxShadow: const [BoxShadow(color: Color(0x4703082A), blurRadius: 8)],
                            ),
                            child: Text(
                              selectedSize != null ? 'Size: $selectedSize ✓' : 'Select a Size',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xF2D2E8FF)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        // add to bag
                        GestureDetector(
                          onTap: onAddBag,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(colors: [_C.bagGold, _C.bagGoldDark]),
                              border: Border.all(color: const Color(0x66C8963C), width: 1),
                              boxShadow: const [BoxShadow(color: Color(0x47643200), blurRadius: 8)],
                            ),
                            child: const Text('ADD TO BAG', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: .5)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // features grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 3.5,
                          crossAxisSpacing: 7,
                          mainAxisSpacing: 7,
                          children: const [
                            _FeatItem(icon: Icons.shield_outlined, title: 'Signature', sub: 'Craftsmanship'),
                            _FeatItem(icon: Icons.refresh, title: 'Free Returns', sub: ''),
                            _FeatItem(icon: Icons.format_align_left, title: 'Free In-Store', sub: 'Alterations'),
                            _FeatItem(icon: Icons.local_shipping_outlined, title: 'Free Shipping', sub: 'on \$200+'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProdTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ProdTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: active ? _C.pageBg : Colors.transparent, width: 2)),
        ),
        child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: active ? _C.pageBg : _C.textLight)),
      ),
    );
  }
}

class _FeatItem extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  const _FeatItem({required this.icon, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _C.pageBg.withOpacity(.6)),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.w700, color: _C.textMid)),
              if (sub.isNotEmpty) Text(sub, style: const TextStyle(fontSize: 7, color: _C.textLight)),
            ],
          ),
        ),
      ],
    );
  }
}

// Shirt painters
class _ShirtPainter extends CustomPainter {
  final int thumbIndex;
  const _ShirtPainter({required this.thumbIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final shirtColor = thumbIndex == 1
        ? const Color(0xCCC3D9F8)
        : const Color(0xD9AFD3F2);

    final paint = Paint()..color = shirtColor..style = PaintingStyle.fill;
    final strokePaint = Paint()..color = const Color(0x6678AFF0)..style = PaintingStyle.stroke..strokeWidth = 1.2;

    // left sleeve
    final leftPath = Path()
      ..moveTo(w * .2, h * .27)
      ..quadraticBezierTo(w * .1, h * .3, w * .09, h * .47)
      ..lineTo(w * .09, h * .93)
      ..quadraticBezierTo(w * .09, h * .96, w * .12, h * .96)
      ..lineTo(w * .41, h * .96)
      ..lineTo(w * .41, h * .53)
      ..quadraticBezierTo(w * .41, h * .4, w * .32, h * .32)
      ..close();
    canvas.drawPath(leftPath, paint);
    canvas.drawPath(leftPath, strokePaint);

    // right sleeve
    final rightPath = Path()
      ..moveTo(w * .8, h * .27)
      ..quadraticBezierTo(w * .9, h * .3, w * .91, h * .47)
      ..lineTo(w * .91, h * .93)
      ..quadraticBezierTo(w * .91, h * .96, w * .88, h * .96)
      ..lineTo(w * .59, h * .96)
      ..lineTo(w * .59, h * .53)
      ..quadraticBezierTo(w * .59, h * .4, w * .68, h * .32)
      ..close();
    canvas.drawPath(rightPath, paint);
    canvas.drawPath(rightPath, strokePaint);

    // body center seam
    canvas.drawRect(Rect.fromLTWH(w * .41, h * .27, w * .18, h * .69), paint);

    // collar
    final collarPath = Path()
      ..moveTo(w * .32, h * .27)
      ..quadraticBezierTo(w * .42, h * .13, w * .5, h * .10)
      ..quadraticBezierTo(w * .58, h * .13, w * .68, h * .27)
      ..lineTo(w * .58, h * .36)
      ..lineTo(w * .5, h * .24)
      ..lineTo(w * .42, h * .36)
      ..close();
    canvas.drawPath(collarPath, Paint()..color = const Color(0xF2EBF5FF));
    canvas.drawPath(collarPath, strokePaint);

    // placket / button strip
    final placketPaint = Paint()..color = thumbIndex == 1
        ? const Color(0xB3643030)
        : const Color(0xE80C1C64);
    final placket = Path()
      ..moveTo(w * .478, h * .27)
      ..lineTo(w * .482, h * .71)
      ..lineTo(w * .5, h * .77)
      ..lineTo(w * .518, h * .71)
      ..lineTo(w * .522, h * .27)
      ..close();
    canvas.drawPath(placket, placketPaint);

    // buttons
    final btnPaint = Paint()..color = const Color(0x7346A0C3);
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(Offset(w * .5, h * (.54 + i * .065)), w * .025, btnPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShirtPainter old) => old.thumbIndex != thumbIndex;
}

class _ThumbPainter extends CustomPainter {
  final int index;
  const _ThumbPainter({required this.index});

  @override
  void paint(Canvas canvas, Size size) {
    final color = index == 1
        ? const Color(0xCCC3D9F8)
        : const Color(0xD9AFD3F2);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
        const Radius.circular(3)),
        Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────
// CHARLES TYRWHITT PAGE
// ─────────────────────────────────────────────
class _CharlesTyrwhittPage extends StatelessWidget {
  final VoidCallback onSizeSelect, onAddBag;
  const _CharlesTyrwhittPage({required this.onSizeSelect, required this.onAddBag});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(color: _C.pageWhite, border: Border(bottom: BorderSide(color: _C.borderLight))),
          child: Row(children: [
            const Icon(Icons.menu, color: _C.pageBg, size: 16),
            const Spacer(),
            const Text('Charles Tyrwhitt', style: TextStyle(fontFamily: 'Georgia', fontSize: 12, fontStyle: FontStyle.italic, color: _C.pageBg)),
            const Spacer(),
            const Icon(Icons.shopping_bag_outlined, color: _C.pageBg, size: 16),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: _C.promoBg,
          child: Row(children: [
            Expanded(child: RichText(text: const TextSpan(style: TextStyle(fontSize: 9.5, color: _C.textMid), children: [
              TextSpan(text: '3 for \$99 on all shirts — use code '),
              TextSpan(text: '3FOR99', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2A9A))),
            ]))),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              const Text('Sky Blue Slim-Fit Dress Shirt', style: TextStyle(fontFamily: 'Georgia', fontSize: 14, fontWeight: FontWeight.w700, color: _C.pageBg)),
              const SizedBox(height: 8),
              const Text('\$85.00', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _C.pageBg)),
              const SizedBox(height: 16),
              Container(
                width: 120, height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE0EEFC), Color(0xFFCCDFF8)]),
                ),
                child: CustomPaint(painter: _ShirtPainter(thumbIndex: 0)),
              ),
              const SizedBox(height: 16),
              const Text('Slim fit, non-iron, pure cotton. Perfect for business or smart casual occasions.', style: TextStyle(fontSize: 10, color: Color(0xFF3A4A6A), height: 1.6), textAlign: TextAlign.center),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: onSizeSelect,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: const LinearGradient(colors: [_C.sizeNavy, _C.sizeNavyDark])),
                  child: const Text('Select a Size', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xF2D2E8FF))),
                ),
              ),
              const SizedBox(height: 7),
              GestureDetector(
                onTap: onAddBag,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: const LinearGradient(colors: [_C.bagGold, _C.bagGoldDark])),
                  child: const Text('ADD TO BAG', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: .5)),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// NEW TAB PAGE
// ─────────────────────────────────────────────
class _NewTabPage extends StatelessWidget {
  final void Function(String url, int idx) onVisit;
  final void Function(String query) onSearch;
  const _NewTabPage({required this.onVisit, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Container(
      color: const Color(0xFFF0F4FF),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NX Shopping Browser', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _C.pageBg)),
          const SizedBox(height: 12),
          const Text('Recently visited', style: TextStyle(fontSize: 10, color: _C.textLight)),
          const SizedBox(height: 14),
          _RecentSite(favicon: 'B', faviconColor: _C.pageBg, name: 'Brooks Brothers', domain: 'brooksbros.com', onTap: () => onVisit('brooksbros.com/shirts/classic-blue', 0)),
          const SizedBox(height: 7),
          _RecentSite(favicon: 'C', faviconColor: const Color(0xFF1A4A8A), name: 'Charles Tyrwhitt', domain: 'ctshirts.com', onTap: () => onVisit('ctshirts.com/slim-blue', 1)),
          const SizedBox(height: 7),
          _RecentSite(favicon: 'N', faviconColor: const Color(0xFF8B0000), name: 'Nordstrom', domain: 'nordstrom.com', onTap: () => onVisit('nordstrom.com/shirts', 0)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(colors: [_C.sizeNavy, _C.sizeNavyDark]),
              border: Border.all(color: const Color(0x4D6490FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NX Smart Search', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xF2D2E8FF))),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0x146496FF),
                    border: Border.all(color: const Color(0x406490FF)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: const TextStyle(fontSize: 10, color: Color(0xCCD2E8FF)),
                          decoration: const InputDecoration(
                            hintText: 'Search shops, items or brands…',
                            hintStyle: TextStyle(fontSize: 10, color: Color(0x80D2E8FF)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: onSearch,
                        ),
                      ),
                      const Icon(Icons.search, size: 14, color: Color(0x99A0C8FF)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSite extends StatelessWidget {
  final String favicon, name, domain;
  final Color faviconColor;
  final VoidCallback onTap;
  const _RecentSite({required this.favicon, required this.faviconColor, required this.name, required this.domain, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: _C.pageWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: faviconColor, borderRadius: BorderRadius.circular(6)),
              child: Center(child: Text(favicon, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 9),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _C.pageBg)),
              Text(domain, style: const TextStyle(fontSize: 8.5, color: _C.textLight)),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ④ NX ACTION BAR
// ─────────────────────────────────────────────
class _NXActionBar extends StatelessWidget {
  final VoidCallback onFav, onRemove, onOutfit;
  const _NXActionBar({required this.onFav, required this.onRemove, required this.onOutfit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xF7081246), Color(0xFC050C32)]),
        border: Border(top: BorderSide(color: Color(0x476490FF), width: 1)),
      ),
      child: Row(
        children: [
          _NXBtn(icon: Icons.favorite, label: 'Add to\nMy Favourites', onTap: onFav),
          const SizedBox(width: 6),
          _NXBtn(icon: Icons.delete_outline, label: 'Remove\nfrom List', onTap: onRemove),
          const SizedBox(width: 6),
          _NXBtn(icon: Icons.checkroom, label: 'Add to\nOutfit', onTap: onOutfit),
        ],
      ),
    );
  }
}

class _NXBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NXBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xE60F2680), Color(0xF2081658)]),
            border: Border.all(color: _C.nxBtnBorder, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xCCDCEBFF), size: 16),
              const SizedBox(height: 3),
              Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xE0C8E1FF)), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ⑤ FOOTER NAV
// ─────────────────────────────────────────────
class _FooterNav extends StatelessWidget {
  final VoidCallback onTryOn, onChat, onHome, onFriends;
  const _FooterNav({required this.onTryOn, required this.onChat, required this.onHome, required this.onFriends});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
          Color(0xFFB8C8E0), Color(0xFFD4E0F0), Color(0xFFE8F0F8),
          Color(0xFFF2F6FC), Color(0xFFE0EAF6), Color(0xFFC8D8EC), Color(0xFFB0C4DC),
        ]),
        border: Border(top: BorderSide(color: Colors.white70, width: 1)),
        boxShadow: [BoxShadow(color: Color(0x1F143278), blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          _FooterBtn(icon: Icons.camera_alt_outlined, label: 'Try-On', active: false, onTap: onTryOn),
          _VSep(),
          _FooterBtn(icon: Icons.chat_bubble_outline, label: 'NX Chat', active: false, onTap: onChat),
          _VSep(),
          // Home logo
          Expanded(
            child: GestureDetector(
              onTap: onHome,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(colors: [
                        Color(0xFF1E3060), Color(0xFF5080B0), Color(0xFF90B8D8),
                        Color(0xFFC8DCF0), Color(0xFFFFFFFF), Color(0xFFC8DCF0),
                        Color(0xFF90B8D8), Color(0xFF5080B0), Color(0xFF1E3060),
                      ]),
                      boxShadow: [
                        BoxShadow(color: Color(0x7382B4FF), blurRadius: 10),
                        BoxShadow(color: Color(0x803278DC), blurRadius: 5),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(center: Alignment(-.2, -.3), colors: [Color(0xFF1A3A7A), Color(0xFF0D1E50), Color(0xFF08122E)]),
                      ),
                      child: const Icon(Icons.check_box_outline_blank, color: Color(0x5C8CB4FF), size: 18),
                    ),
                  ),
                  const Text('Home', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: _C.footerText)),
                ],
              ),
            ),
          ),
          _VSep(),
          _FooterBtn(icon: Icons.group_outlined, label: 'Friends Space', active: false, onTap: onFriends),
          _VSep(),
          _FooterBtn(icon: Icons.shopping_bag_outlined, label: 'Shopping', active: true, onTap: () {}),
        ],
      ),
    );
  }
}

class _FooterBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FooterBtn({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? _C.footerActive : _C.footerText;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: active
              ? const BoxDecoration(border: Border(bottom: BorderSide(color: _C.footerActive, width: 2)))
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _VSep extends StatelessWidget {
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

// ─────────────────────────────────────────────
// SIZE MODAL
// ─────────────────────────────────────────────
class _SizeModal extends StatefulWidget {
  final List<String> sizes, soldOut;
  final String? selected;
  final void Function(String) onChanged;
  final VoidCallback onConfirm, onClose;

  const _SizeModal({
    required this.sizes, required this.soldOut, required this.selected,
    required this.onChanged, required this.onConfirm, required this.onClose,
  });

  @override
  State<_SizeModal> createState() => _SizeModalState();
}

class _SizeModalState extends State<_SizeModal> {
  String? _sel;

  @override
  void initState() {
    super.initState();
    _sel = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_C.chromeMid, _C.sizeNavyDark]),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        border: Border(top: BorderSide(color: Color(0x4D6490FF))),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select a Size', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xF2D2E8FF))),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x1AFFFFFF), border: Border.all(color: const Color(0x406490FF))),
                    child: const Center(child: Text('×', style: TextStyle(color: Color(0xCCB4D7FF), fontSize: 16, height: 1))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Align(alignment: Alignment.centerLeft, child: Text('Neck / Sleeve — Select your fit', style: TextStyle(fontSize: 8.5, color: Color(0x998CC8FF)))),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
              childAspectRatio: 1.6,
              children: widget.sizes.map((s) {
                final sold = widget.soldOut.contains(s);
                final selected = _sel == s;
                return GestureDetector(
                  onTap: sold ? null : () => setState(() { _sel = s; widget.onChanged(s); }),
                  child: Opacity(
                    opacity: sold ? .3 : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: selected ? const Color(0xD96A58C8) : const Color(0x146496FF),
                        border: Border.all(color: selected ? const Color(0x8C64AAFF) : const Color(0x386490FF)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: selected ? const Color(0xFADCEBFF) : const Color(0xCCB9D7FF), decoration: sold ? TextDecoration.lineThrough : null)),
                          if (sold) const Text('Sold out', style: TextStyle(fontSize: 6, color: Color(0x99B9D7FF))),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: widget.onConfirm,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [Color(0xE62A58C8), Color(0xF21A3A9A)]),
                  border: Border.all(color: const Color(0x666490FF)),
                  boxShadow: const [BoxShadow(color: Color(0x4D03082A), blurRadius: 10)],
                ),
                child: const Text('Confirm Size', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xF2D2E8FF))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TOAST
// ─────────────────────────────────────────────
class _Toast extends StatelessWidget {
  final String message;
  const _Toast({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_C.sizeNavy, _C.sizeNavyDark]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x616490FF)),
        boxShadow: const [BoxShadow(color: Color(0x6603082A), blurRadius: 12)],
      ),
      child: Text(message, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xF2D2E8FF)), maxLines: 1),
    );
  }
}
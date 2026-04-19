// ══════════════════════════════════════════════════════════════════════════════
//  wardrobe_screen.dart
//  Header & Footer: 100% clone of Nikonyx HTML mockup (cosmic v14)
//  Body + backend: unchanged from original Dart implementation
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/cosmic_header_widget.dart';
import '../../../core/widgets/cosmic_footer_widget.dart';

import '../../../core/models/wardrobe_item_model.dart';
import '../../../core/widgets/fashion_drawer.dart';
import '../../../routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/providers/social_provider.dart';
import '../providers/wardrobe_provider.dart';
import '../screens/wardrobe_item_details_screen.dart';

// ─── Route shims ──────────────────────────────────────────────────────────────
const _rCalendar = Routes.calendar;
const _rWardrobe = Routes.wardrobe;
const _rChat = Routes.chat;
const _rProfile = '/settings';
const _rTryOn = '/tryon';
const _rSocial = '/style-feed';
const _rShopping = '/shopping';
const _rAddItem = '/wardrobe/add';

const _cosmicTop = Color(0xFF020810); // background darkest
const _cosmicMid = Color(0xFF0A4E8F); // mid navy
const _cosmicBot = Color(0xFF1848C0); // bright navy for radial centre
const _srimL = Color(0xFF1E2E50);
const _srimM = Color(0xFFC8DFF0);
const _srimH = Color(0xFFFFFFFF);
const _arcSilver = Color(0xFFC8DFF2);
const _arcWhite = Color(0xFFFFFFFF);

// ── HTML footer nav ───────────────────────────────────────────────────────────
const _navTopSilver = Color(0xFFB8C8E0);
const _navMidSilver = Color(0xFFD4E0F0);
const _navBotSilver = Color(0xFFB0C4DC);
const _navSepBlue = Color(0xFF3C78DC);

const _hlogoRing1 = Color(0xFF1E3060);
const _hlogoRing2 = Color(0xFF5080B0);
const _hlogoRing3 = Color(0xFFC8DCF0);
const _hlogoBg = Color(0xFF0D1E50);

// ── Body (unchanged) ─────────────────────────────────────────────────────────
const _pgTop = Color(0xFFB8CCE4);
const _pgMid = Color(0xFF9AB4D0);
const _pgBot = Color(0xFF7A98BE);
const _crdT = Color(0xFFF0F4FA);
const _crdM = Color(0xFFDCE8F4);
const _crdB = Color(0xFFC0D4E8);
const _secBg = Color(0xFF0B1D4C);
const _secBdr = Color(0xFF1D3268);
const _btnFill = Color(0xFF0B1C48);
const _slv = Color(0xFFCCDDFF);
const _blue = Color(0xFF2050C8);
const _chr1 = Color(0xFFBBD0EE);

class _BgPainter extends CustomPainter {
  const _BgPainter();
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = Colors.white;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
//  ██   HTML FOOTER NAV  (100% clone of .nav)
// ══════════════════════════════════════════════════════════════════════════════

/// Home logo ring for nav — mirrors `.hlogo` conic-gradient
class _HomeLogoRing extends StatelessWidget {
  const _HomeLogoRing({this.size = 36.0});
  final double size;
  @override
  Widget build(BuildContext ctx) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(
            startAngle: 0.26,
            colors: [
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
            ],
          ),
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
        child: Center(
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: size * 0.83,
              height: size * 0.83,
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
            Container(
              width: size * 0.69,
              height: size * 0.69,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFA0D0FF).withOpacity(0.28), width: 1),
              ),
            ),
            SizedBox(
              width: size * 0.72,
              height: size * 0.72,
              child: CustomPaint(painter: _ChecklistIconPainter()),
            ),
          ]),
        ),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
//  CHECKLIST ICON PAINTER (used by _HomeLogoRing)
// ──────────────────────────────────────────────────────────────────────────────
class _ChecklistIconPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0xFFA0C8FF).withOpacity(0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTRB(
          s.width * .09, s.height * .09, s.width * .91, s.height * .91),
      const Radius.circular(3.5),
    );
    c.drawRRect(r, p);
    final cp = Paint()
      ..color = const Color(0xFFA0C8FF).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(s.width * .31, s.height * .50)
      ..lineTo(s.width * .44, s.height * .63)
      ..lineTo(s.width * .69, s.height * .38);
    c.drawPath(path, cp);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Vertical separator line — mirrors `.nav-sep`

/// Full silver-blue metallic footer nav — 100% HTML .nav clone
// ══════════════════════════════════════════════════════════════════════════════
//  SECTION HEADER BAR  (unchanged)
// ══════════════════════════════════════════════════════════════════════════════
class _SecHeader extends StatelessWidget {
  const _SecHeader({required this.title, this.onTap});
  final String title;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: _secBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _secBdr, width: 1),
          ),
          child: Row(children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2)),
            const SizedBox(width: 12),
            Expanded(
                child: Container(
                    height: 1,
                    color: const Color(0xFF3A5A8A).withOpacity(0.55))),
            const SizedBox(width: 10),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4A6A9A), width: 1),
                color: Colors.white.withOpacity(0.06),
              ),
              child: const Icon(Icons.chevron_right, color: _slv, size: 14),
            ),
          ]),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
//  ITEM CARD  (body — unchanged)
// ══════════════════════════════════════════════════════════════════════════════
class _XMark extends StatelessWidget {
  @override
  Widget build(BuildContext c) =>
      SizedBox(width: 9, height: 9, child: CustomPaint(painter: _XP()));
}

class _XP extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..strokeWidth = 0.9;
    c.drawLine(Offset.zero, Offset(s.width, s.height), p);
    c.drawLine(Offset(s.width, 0), Offset(0, s.height), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.isSelected,
    required this.isMultiSelect,
    required this.onTap,
    required this.onLongPress,
  });
  final WardrobeItemModel item;
  final bool isSelected, isMultiSelect;
  final VoidCallback onTap, onLongPress;

  @override
  Widget build(BuildContext context) {
    final img = item.processedImageUrl ?? item.imageUrl;
    final name = item.brand ?? item.category;
    final sub =
        item.colorTags.isNotEmpty ? item.colorTags.first : 'Wardrobe essential';

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2050C8).withOpacity(0.8)
                : const Color(0xFF8AAACF).withOpacity(0.5),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              height: 162,
              child: Stack(children: [
                Positioned.fill(
                    child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_crdT, _crdM, _crdB],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                )),
                Positioned.fill(
                    child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.35),
                      radius: 0.85,
                      colors: [
                        Colors.white.withOpacity(0.55),
                        Colors.transparent
                      ],
                    ),
                  ),
                )),
                Positioned(
                    top: 15,
                    left: 0,
                    right: 0,
                    child: Center(
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 32,
                          height: 1,
                          color: Colors.black.withOpacity(0.18)),
                      Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.22))),
                      Container(
                          width: 32,
                          height: 1,
                          color: Colors.black.withOpacity(0.18)),
                    ]))),
                Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                        child: Container(
                            width: 1.5,
                            height: 16,
                            color: Colors.black.withOpacity(0.15)))),
                Positioned(top: 9, left: 18, child: _XMark()),
                Positioned(top: 9, right: 18, child: _XMark()),
                Positioned.fill(
                    child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 22, 6, 4),
                  child: Image.network(img,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.checkroom,
                              size: 64, color: Color(0xFF8AAABB)))),
                )),
                if (isMultiSelect)
                  Positioned(
                      top: 7,
                      right: 7,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? _blue
                              : Colors.white.withOpacity(0.7),
                          border: Border.all(
                              color: isSelected
                                  ? _blue
                                  : Colors.grey.withOpacity(0.5),
                              width: 1.5),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 13)
                            : null,
                      )),
              ]),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(11, 8, 9, 10),
              decoration: const BoxDecoration(color: Colors.white),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: Color(0xFF0A1830),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(sub,
                        style: const TextStyle(
                            color: Color(0xFF5A7A9A), fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                )),
                const SizedBox(width: 6),
                Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE8F0FA),
                    border:
                        Border.all(color: const Color(0xFFAACCEE), width: 1),
                  ),
                  child: const Icon(Icons.chevron_right,
                      color: Color(0xFF2A5A8A), size: 15),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TRENDING CARD  (body — unchanged)
// ══════════════════════════════════════════════════════════════════════════════
class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.item, required this.onTap});
  final WardrobeItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final img = item.processedImageUrl ?? item.imageUrl;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8AAACF).withOpacity(0.5)),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F0FA), Color(0xFFD0DFF0), Color(0xFFB8CCDE)],
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(fit: StackFit.expand, children: [
            Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 180,
                child: Image.network(img,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.checkroom,
                            color: Color(0xFF7799BB), size: 48)))),
            Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 200,
                child: Container(
                    decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0E1E48),
                      Color(0xCC0E1E48),
                      Colors.transparent
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ))),
            Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 5),
                  color: Colors.black.withOpacity(0.5),
                  child: const Text('Trending Items: Spring 2024',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic)),
                )),
            Positioned(
                left: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.brand ?? item.category,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                        item.colorTags.isNotEmpty
                            ? item.colorTags.first
                            : 'Trending piece',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 11.5)),
                  ],
                )),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});
  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _selectedCategory;
  final Set<String> _selectedItems = {};
  bool _isMultiSelectMode = false;
  int _navIndex = 2; // 2 = Home (centre)

  static const _tabs = <(String, IconData?)>[
    ('Suits', null),
    ('Tops', Icons.dry_cleaning_outlined),
    ('Pants', Icons.crop_portrait_outlined),
    ('Shoes', Icons.do_not_step_outlined),
    ('Accessories', Icons.watch_outlined),
  ];

  List<WardrobeItemModel> _filter(List<WardrobeItemModel> items) {
    if (_selectedCategory == null) return items;
    const m = <String, List<String>>{
      'Suits': ['Suit', 'Suits'],
      'Tops': ['Top', 'Tops', 'Shirt', 'Shirts', 'Blouse', 'T-Shirt'],
      'Pants': ['Pants', 'Jeans', 'Trousers', 'Trouser', 'Skirt', 'Bottom'],
      'Shoes': ['Shoes', 'Shoe', 'Sneakers', 'Boots', 'Boot'],
      'Accessories': [
        'Accessory',
        'Accessories',
        'Bag',
        'Hat',
        'Jewelry',
        'Sunglasses',
        'Watch'
      ],
    };
    final cats = m[_selectedCategory!] ?? [_selectedCategory!];
    return items.where((i) => cats.contains(i.category)).toList();
  }

  Map<String, List<WardrobeItemModel>> _group(List<WardrobeItemModel> items) {
    const sm = <String, String>{
      'Shirt': 'Shirts',
      'Blouse': 'Shirts',
      'T-Shirt': 'Shirts',
      'Top': 'Shirts',
      'Tops': 'Shirts',
      'Shirts': 'Shirts',
      'Casual Jacket': 'Casual Jackets',
      'Jacket': 'Casual Jackets',
      'Blazer': 'Casual Jackets',
      'Suit': 'Suits',
      'Suits': 'Suits',
      'Trouser': 'Trousers',
      'Trousers': 'Trousers',
      'Pants': 'Trousers',
      'Jeans': 'Trousers',
      'Shoes': 'Shoes',
      'Shoe': 'Shoes',
      'Sneakers': 'Shoes',
      'Boots': 'Shoes',
      'Boot': 'Shoes',
      'Sunglasses': 'Trending Items',
      'Hat': 'Trending Items',
      'Accessory': 'Accessories',
      'Accessories': 'Accessories',
      'Watch': 'Accessories',
      'Bag': 'Accessories',
    };
    const order = [
      'Shirts',
      'Casual Jackets',
      'Suits',
      'Trousers',
      'Shoes',
      'Accessories',
      'Trending Items'
    ];
    final raw = <String, List<WardrobeItemModel>>{};
    for (final it in items) {
      final sec = sm[it.category] ?? it.category;
      raw.putIfAbsent(sec, () => []).add(it);
    }
    final out = <String, List<WardrobeItemModel>>{};
    for (final k in order) {
      if (raw.containsKey(k)) out[k] = raw[k]!;
    }
    raw.forEach((k, v) {
      if (!out.containsKey(k)) out[k] = v;
    });
    return out;
  }

  void _open(WardrobeItemModel it) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => WardrobeItemDetailsScreen(item: it)));

  void _toggle(String id) => setState(() {
        if (_selectedItems.contains(id)) {
          _selectedItems.remove(id);
        } else {
          _selectedItems.add(id);
        }
      });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final mobile = mq.size.width < 768;
    final ward = ref.watch(wardrobeItemsProvider);
    final unread = ref.watch(socialUnreadCountProvider) ?? 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(currentRoute: Routes.wardrobe),
        backgroundColor: Colors.white,
        extendBody: true,
        body: Stack(children: [
          const Positioned.fill(child: CustomPaint(painter: _BgPainter())),
          ward.when(
            data: (all) {
              final filtered = _filter(all);
              final grouped = _group(filtered);
              return _body(all, filtered, grouped, unread, mobile, mq);
            },
            loading: () =>
                const Center(child: CircularProgressIndicator(color: _blue)),
            error: (e, _) => _errView(e),
          ),
          if (_isMultiSelectMode) _multiBar(mobile, mq),
        ]),
        // ── COSMIC FOOTER ────────────────────────────────────────────────
        bottomNavigationBar: CosmicFooter(
          bottomPadding: mq.padding.bottom,
          activeIndex: _navIndex,
          onTryOn: () {
            setState(() => _navIndex = 0);
            Navigator.pushNamed(context, _rTryOn);
          },
          onWardrobe: () {
            setState(() => _navIndex = 1);
            Navigator.pushNamed(context, _rWardrobe);
          },
          onHome: () {
            setState(() => _navIndex = 2);
            Navigator.pushNamed(context, Routes.dashboard);
          },
          onFriends: () {
            setState(() => _navIndex = 3);
            Navigator.pushNamed(context, _rSocial);
          },
          onProfile: () {
            setState(() => _navIndex = 4);
            Navigator.pushNamed(context, _rProfile);
          },
        ),
      ),
    );
  }

  // ─── SCROLLABLE BODY ───────────────────────────────────────────────────────
  Widget _body(
          List<WardrobeItemModel> all,
          List<WardrobeItemModel> filtered,
          Map<String, List<WardrobeItemModel>> grouped,
          int unread,
          bool mobile,
          MediaQueryData mq) =>
      RefreshIndicator(
        onRefresh: () async => ref.invalidate(wardrobeItemsProvider),
        color: _blue,
        backgroundColor: const Color(0xFF0B1D4C),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── HTML cosmic header (scrolls with content) ─────────────────
            SliverToBoxAdapter(
              child: CosmicHeader(
                topPadding: mq.padding.top,
                hasNotification: unread > 0,
                onMenuTap: () {
                  try {
                    _scaffoldKey.currentState?.openDrawer();
                  } catch (_) {}
                },
                onBellTap: () {},
                onAvatarTap: () => Navigator.pushNamed(context, _rProfile),
              ),
            ),

            // ── body action rows (unchanged) ──────────────────────────────
            SliverToBoxAdapter(child: _actionRow()),
            SliverToBoxAdapter(child: _outfitRow()),
            SliverToBoxAdapter(child: _catRow()),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            if (filtered.isEmpty)
              SliverFillRemaining(
                  hasScrollBody: false, child: _emptyW(all.isEmpty))
            else
              SliverPadding(
                padding: EdgeInsets.only(bottom: mobile ? 160.0 : 110.0),
                sliver: SliverToBoxAdapter(child: _sections(grouped)),
              ),
          ],
        ),
      );

  // ─── ACTION ROW (unchanged) ────────────────────────────────────────────────
  Widget _actionRow() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Row(children: [
          _ABtn(
              label: 'Stats',
              icon: Icons.bar_chart,
              filled: true,
              onTap: () {}),
          const SizedBox(width: 7),
          _ABtn(label: 'Wish List', icon: Icons.favorite_border, onTap: () {}),
          const SizedBox(width: 7),
          _ABtn(
              label: 'Calendar',
              icon: Icons.calendar_today,
              onTap: () => Navigator.pushNamed(context, _rCalendar)),
          const SizedBox(width: 7),
          Expanded(
              child: _ABtn(
                  label: 'Sort by: Newest',
                  icon: Icons.sort,
                  dropdown: true,
                  onTap: () {})),
        ]),
      );

  // ─── CREATE OUTFIT TOGGLE (unchanged) ─────────────────────────────────────
  Widget _outfitRow() => Container(
        margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: Row(children: [
          RichText(
              text: TextSpan(style: const TextStyle(fontSize: 13), children: [
            TextSpan(
                text: 'Select to ',
                style: TextStyle(
                    color: const Color(0xFF1A2A4A).withOpacity(0.75))),
            const TextSpan(
                text: 'create outfit',
                style: TextStyle(
                    color: Color(0xFF0A1830), fontWeight: FontWeight.w700)),
          ])),
          const Spacer(),
          Transform.scale(
            scale: 0.82,
            child: Switch(
              value: _isMultiSelectMode,
              onChanged: (v) => setState(() => _isMultiSelectMode = v),
              activeColor: Colors.white,
              activeTrackColor: _blue,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.blueGrey.withOpacity(0.4),
            ),
          ),
        ]),
      );

  // ─── CATEGORY TABS (unchanged) ─────────────────────────────────────────────
  Widget _catRow() => SizedBox(
        height: 46,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: _tabs.length * 2 - 1,
          itemBuilder: (_, i) {
            if (i.isOdd) {
              return Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 9),
                color: const Color(0xFF3A5A8A).withOpacity(0.45),
              );
            }
            final idx = i ~/ 2;
            final (label, icon) = _tabs[idx];
            final isFirst = idx == 0;
            final sel = isFirst
                ? (_selectedCategory == null)
                : (_selectedCategory == label);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() =>
                    _selectedCategory = isFirst ? null : (sel ? null : label));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                    horizontal: isFirst ? 18 : 12, vertical: 8),
                decoration: BoxDecoration(
                  color: sel && isFirst
                      ? const Color(0xFF0B1D4C)
                      : sel
                          ? Colors.white.withOpacity(0.3)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: sel
                        ? (isFirst
                            ? const Color(0xFF1D3268)
                            : const Color(0xFF3A5A8A).withOpacity(0.6))
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[
                    Icon(icon,
                        size: 13,
                        color: sel
                            ? (isFirst ? Colors.white : const Color(0xFF1A2A4A))
                            : const Color(0xFF2A3A6A).withOpacity(0.75)),
                    const SizedBox(width: 5),
                  ],
                  Text(label,
                      style: TextStyle(
                        color: sel
                            ? (isFirst ? Colors.white : const Color(0xFF0A1830))
                            : const Color(0xFF2A3A6A).withOpacity(0.85),
                        fontSize: 13.5,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      )),
                ]),
              ),
            );
          },
        ),
      );

  // ─── SECTIONS (unchanged) ─────────────────────────────────────────────────
  Widget _sections(Map<String, List<WardrobeItemModel>> groups) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: groups.entries
            .map((e) => Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                  child: _block(e.key, e.value),
                ))
            .toList(),
      );

  Widget _block(String title, List<WardrobeItemModel> items) {
    final trend = title.startsWith('Trending');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _SecHeader(title: title),
      const SizedBox(height: 10),
      if (trend)
        ...items.map((it) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TrendCard(item: it, onTap: () => _open(it)),
            ))
      else
        _SlidingPairSection(
          items: items,
          isMultiSelect: _isMultiSelectMode,
          selectedItems: _selectedItems,
          onTap: (item) => _isMultiSelectMode ? _toggle(item.id) : _open(item),
          onLongPress: (item) {
            HapticFeedback.mediumImpact();
            setState(() => _isMultiSelectMode = true);
            _toggle(item.id);
          },
        ),
    ]);
  }

  // ─── MULTI-SELECT BAR (unchanged) ─────────────────────────────────────────
  Widget _multiBar(bool mobile, MediaQueryData mq) {
    final botH = 52.0 + mq.padding.bottom;
    return Positioned(
      bottom: botH,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1A3A),
          border: const Border(
            top: BorderSide(color: Color(0xFF2A4070), width: 1),
            bottom: BorderSide(color: Color(0xFF2A4070), width: 1),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, -2))
          ],
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Row(children: [
            Text('${_selectedItems.length} selected',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _selectedItems.isEmpty
                  ? null
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Opening try-on for ${_selectedItems.length} items'),
                        backgroundColor: const Color(0xFF091C4E),
                      ));
                    },
              icon: const Icon(Icons.checkroom, size: 16),
              label: const Text('Try On'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              onPressed: _selectedItems.isEmpty ? null : _confirmDel,
            ),
            IconButton(
              icon: const Icon(Icons.close, color: _slv, size: 20),
              onPressed: () => setState(() {
                _isMultiSelectMode = false;
                _selectedItems.clear();
              }),
            ),
          ]),
        ),
      ),
    );
  }

  void _confirmDel() => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF091C4E),
          title: Text('Delete ${_selectedItems.length} items?',
              style: const TextStyle(color: Colors.white)),
          content: const Text('This cannot be undone.',
              style: TextStyle(color: _slv)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: _slv)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedItems.clear();
                  _isMultiSelectMode = false;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

  Widget _emptyW(bool noItems) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.checkroom_outlined,
              size: 72, color: const Color(0xFF3A5A8A).withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
              noItems
                  ? 'Your wardrobe is empty'
                  : 'No items match your filters',
              style: const TextStyle(
                  color: Color(0xFF2A4A6A),
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          if (noItems) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, _rAddItem),
              icon: const Icon(Icons.add),
              label: const Text('Add your first item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ]),
      );

  Widget _errView(Object e) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 52),
            const SizedBox(height: 16),
            const Text('Failed to load wardrobe',
                style: TextStyle(color: Color(0xFF0A1830), fontSize: 16)),
            const SizedBox(height: 8),
            Text(e.toString(),
                style: const TextStyle(color: Color(0xFF3A5A8A), fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(wardrobeItemsProvider),
              style: ElevatedButton.styleFrom(backgroundColor: _blue),
              child: const Text('Retry'),
            ),
          ]),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
//  SLIDING PAIR SECTION  (unchanged)
// ══════════════════════════════════════════════════════════════════════════════
class _SlidingPairSection extends StatefulWidget {
  const _SlidingPairSection({
    required this.items,
    required this.isMultiSelect,
    required this.selectedItems,
    required this.onTap,
    required this.onLongPress,
  });
  final List<WardrobeItemModel> items;
  final bool isMultiSelect;
  final Set<String> selectedItems;
  final void Function(WardrobeItemModel) onTap;
  final void Function(WardrobeItemModel) onLongPress;

  @override
  State<_SlidingPairSection> createState() => _SlidingPairSectionState();
}

class _SlidingPairSectionState extends State<_SlidingPairSection> {
  late final PageController _pc;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pc = PageController();
    _pc.addListener(() {
      final p = _pc.page?.round() ?? 0;
      if (p != _page) setState(() => _page = p);
    });
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pairs = <List<WardrobeItemModel>>[];
    for (int i = 0; i < widget.items.length; i += 2) {
      pairs.add([
        widget.items[i],
        if (i + 1 < widget.items.length) widget.items[i + 1]
      ]);
    }
    final pageCount = pairs.length;

    return Column(children: [
      SizedBox(
        height: 215,
        child: PageView.builder(
          controller: _pc,
          physics: pageCount > 1
              ? const BouncingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemCount: pageCount,
          itemBuilder: (ctx, pageIdx) {
            final pair = pairs[pageIdx];
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: _ItemCard(
                item: pair[0],
                isSelected: widget.selectedItems.contains(pair[0].id),
                isMultiSelect: widget.isMultiSelect,
                onTap: () => widget.onTap(pair[0]),
                onLongPress: () => widget.onLongPress(pair[0]),
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: pair.length > 1
                      ? _ItemCard(
                          item: pair[1],
                          isSelected: widget.selectedItems.contains(pair[1].id),
                          isMultiSelect: widget.isMultiSelect,
                          onTap: () => widget.onTap(pair[1]),
                          onLongPress: () => widget.onLongPress(pair[1]),
                        )
                      : const SizedBox.shrink()),
            ]);
          },
        ),
      ),
      if (pageCount > 1) ...[
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
              pageCount,
              (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: i == _page
                          ? const Color(0xFF0B1D4C)
                          : const Color(0xFF0B1D4C).withOpacity(0.25),
                    ),
                  )),
        ),
      ],
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SMALL REUSABLE WIDGETS  (body — unchanged)
// ══════════════════════════════════════════════════════════════════════════════
class _ChromeRail extends StatelessWidget {
  const _ChromeRail();
  @override
  Widget build(BuildContext context) => Container(
        height: 10,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x0DFFFFFF),
              Color(0x99CCDDFF),
              Colors.white,
              Color(0x99AABBDD),
              Color(0x0DFFFFFF),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge(this.n);
  final int n;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration:
            const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        child: Text('$n',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
      );
}

class _ABtn extends StatelessWidget {
  const _ABtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.dropdown = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled, dropdown;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
          decoration: BoxDecoration(
            color: filled ? _btnFill : Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: filled
                  ? const Color(0xFF253C6A)
                  : Colors.white.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: filled ? Colors.white : const Color(0xFF0A1830)),
              const SizedBox(width: 5),
              Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: filled ? Colors.white : const Color(0xFF0A1830),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ))),
              if (dropdown) ...[
                const SizedBox(width: 3),
                Icon(Icons.keyboard_arrow_down,
                    color: filled ? Colors.white70 : const Color(0xFF0A1830),
                    size: 14),
              ],
            ],
          ),
        ),
      );
}

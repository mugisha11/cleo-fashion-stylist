// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//  my_outfits_screen.dart
//  100% Dart translation of Nikonyx HTML mockup (cosmic v14)
//  Header: CosmicHeader | Body: Full outfit showcase | Footer: CosmicFooter
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/cosmic_header_widget.dart';
import '../../../core/widgets/cosmic_footer_widget.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../routes.dart';

// â”€â”€â”€ Models â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class OutfitCard {
  final String name;
  final String subtitle;
  final double score;
  final List<String> tags;
  final Color gradientStart;
  final Color gradientEnd;

  OutfitCard({
    required this.name,
    required this.subtitle,
    required this.score,
    required this.tags,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

class SuggestedCard {
  final String name;
  final double score;
  final Color gradientStart;
  final Color gradientEnd;

  SuggestedCard({
    required this.name,
    required this.score,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

// â”€â”€â”€ Provider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final outfitDataProvider = Provider<List<OutfitCard>>((ref) {
  return [
    OutfitCard(
      name: 'Formal Date\nNight',
      subtitle: 'Navy Â· Slim fit',
      score: 9.2,
      tags: ['Date', 'Navy'],
      gradientStart: const Color(0xFFBCD0EA),
      gradientEnd: const Color(0xFFD4E4F4),
    ),
    OutfitCard(
      name: 'Smart Casual\nFriday',
      subtitle: 'Layers Â· Relaxed',
      score: 8.7,
      tags: ['Casual', 'Work'],
      gradientStart: const Color(0xFFC8DAF0),
      gradientEnd: const Color(0xFFD8E8F4),
    ),
    OutfitCard(
      name: 'Evening\nGala Look',
      subtitle: 'Charcoal Â· Slim',
      score: 9.5,
      tags: ['Evening', 'Formal'],
      gradientStart: const Color(0xFFCCD4E8),
      gradientEnd: const Color(0xFFC0CCE0),
    ),
    OutfitCard(
      name: 'Weekend\nBrunch',
      subtitle: 'Warm tones Â· Easy',
      score: 8.4,
      tags: ['Casual', 'Day'],
      gradientStart: const Color(0xFFD4E4F0),
      gradientEnd: const Color(0xFFDCEEF8),
    ),
  ];
});

final suggestedDataProvider = Provider<List<SuggestedCard>>((ref) {
  return [
    SuggestedCard(
      name: 'Business\nLunch',
      score: 9.1,
      gradientStart: const Color(0xFFBCD0EA),
      gradientEnd: const Color(0xFFCCD8EC),
    ),
    SuggestedCard(
      name: 'Gallery\nOpening',
      score: 8.8,
      gradientStart: const Color(0xFFD0DAF0),
      gradientEnd: const Color(0xFFC4D0E8),
    ),
    SuggestedCard(
      name: 'Garden\nParty',
      score: 9.3,
      gradientStart: const Color(0xFFC8E0D0),
      gradientEnd: const Color(0xFFD4E8DC),
    ),
    SuggestedCard(
      name: 'Warm\nWeekend',
      score: 8.6,
      gradientStart: const Color(0xFFE0D4C8),
      gradientEnd: const Color(0xFFD8CCC0),
    ),
  ];
});

// â”€â”€â”€ Main Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class MyOutfitsScreen extends ConsumerStatefulWidget {
  const MyOutfitsScreen({super.key});

  @override
  ConsumerState<MyOutfitsScreen> createState() => _MyOutfitsScreenState();
}

class _MyOutfitsScreenState extends ConsumerState<MyOutfitsScreen> {
  String _activeFilter = 'All';
  bool _chatOpen = true;
  int _navIndex = 1; // Wardrobe tab

  final List<String> _filters = ['All', 'Date Night', 'Business', 'Casual', 'Evening', 'Weekend'];

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final outfits = ref.watch(outfitDataProvider);
    final suggested = ref.watch(suggestedDataProvider);

    return ThemeWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FF),
        body: SafeArea(
          child: Column(
            children: [
              // â”€â”€ HEADER (Cosmic v14) â”€â”€
              CosmicHeader(
                topPadding: mq.padding.top,
                hasNotification: false,
                onMenuTap: () {},
                onBellTap: () {},
                onAvatarTap: () => Navigator.pushNamed(context, Routes.settings),
              ),

              // â”€â”€ SCROLLABLE BODY â”€â”€
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Page header + Create button
                      _buildPageHeader(),

                      // Filter tabs
                      _buildFilterTabs(),

                      // Saved Outfits section
                      _buildSectionHeader('Saved Outfits', 'See all'),
                      _buildOutfitCardsScroll(outfits),

                      // Divider
                      _buildDivider(),

                      // Reuse bar
                      _buildReuseBar(),

                      // Suggested section
                      _buildSectionHeader('NX Suggests For You', 'See all'),
                      _buildSuggestedCardsScroll(suggested),

                      // Chat panel
                      _buildChatPanel(),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // â”€â”€ FOOTER (Cosmic v14) â”€â”€
        bottomNavigationBar: CosmicFooter(
          bottomPadding: mq.padding.bottom,
          activeIndex: _navIndex,
          onTryOn: () {
            setState(() => _navIndex = 0);
            Navigator.pushNamed(context, '/tryon');
          },
          onWardrobe: () {
            setState(() => _navIndex = 1);
          },
          onHome: () {
            setState(() => _navIndex = 2);
            Navigator.pushNamed(context, Routes.dashboard);
          },
          onFriends: () {
            setState(() => _navIndex = 3);
            Navigator.pushNamed(context, '/style-feed');
          },
          onOutfits: () {
            setState(() => _navIndex = 4);
          },
        ),
      ),
    );
  }

  // â”€â”€ PAGE HEADER â”€â”€
  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'My Outfits',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0C1E48),
              letterSpacing: -0.2,
            ),
          ),
          _buildCreateButton(),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1E58), Color(0xFF060F2E)],
          ),
          border: Border.all(
            color: const Color(0xFF64A0FF).withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF030828).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CustomPaint(
                painter: _PlusPainter(),
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              'Create',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD2E8FF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ FILTER TABS â”€â”€
  Widget _buildFilterTabs() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFB4CDF0).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        children: _filters.map((filter) {
          final isActive = filter == _activeFilter;
          return _buildFilterTab(filter, isActive);
        }).toList(),
      ),
    );
  }

  Widget _buildFilterTab(String label, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isActive
                ? const [Color(0xFF0A1E58), Color(0xFF060F2E)]
                : const [Color(0xFFF0F5FF), Color(0xFFE4EDF8)],
          ),
          border: Border.all(
            color: isActive
                ? const Color(0xFF64A0FF).withValues(alpha: 0.4)
                : const Color(0xFFB4CDF0).withValues(alpha: 0.55),
            width: 1,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: const Color(0xFF030828).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            if (!isActive)
              BoxShadow(
                color: const Color(0xff1432780).withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: isActive ? const Color(0xFFD2E8FF) : const Color(0xFF1A2A50),
          ),
        ),
      ),
    );
  }

  // â”€â”€ SECTION HEADER â”€â”€
  Widget _buildSectionHeader(String title, String link) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0C1E48),
              letterSpacing: -0.1,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Text(
              link,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2A58C8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ OUTFIT CARDS SCROLL â”€â”€
  Widget _buildOutfitCardsScroll(List<OutfitCard> outfits) {
    return SizedBox(
      height: 320,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: outfits
            .map((outfit) => _buildOutfitCard(outfit))
            .toList(),
      ),
    );
  }

  Widget _buildOutfitCard(OutfitCard outfit) {
    return Container(
      width: 148,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        boxShadow: [
          const BoxShadow(
            color: Color(0xFF8AACCC),
            blurRadius: 0,
            offset: Offset.zero,
            spreadRadius: 1.5,
          ),
          const BoxShadow(
            color: Color(0xFFD4E8F8),
            blurRadius: 0,
            offset: Offset.zero,
            spreadRadius: 3,
          ),
          const BoxShadow(
            color: Color(0xFF7898B8),
            blurRadius: 0,
            offset: Offset.zero,
            spreadRadius: 4.5,
          ),
          BoxShadow(
            color: const Color(0xff1432780).withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image placeholder
          Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [outfit.gradientStart, outfit.gradientEnd],
              ),
            ),
            child: Stack(
              children: [
                // Image placeholder box
                Center(
                  child: Container(
                    width: 72,
                    height: 82,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF5A8CC8).withValues(alpha: 0.42),
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CustomPaint(
                            painter: _ImagePlaceholderPainter(),
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Add Photo',
                          style: TextStyle(
                            fontSize: 7,
                            color: Color(0xFF508CC8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                // Score badge
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0A1E58), Color(0xFF060F2E)],
                      ),
                      border: Border.all(
                        color: const Color(0xFF78B4FF).withValues(alpha: 0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF030828).withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: const Color(0xFFA0D2FF).withValues(alpha: 0.2),
                          blurRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 8, color: Color(0xFF4DA3FF)),
                        const SizedBox(width: 3),
                        Text(
                          outfit.score.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFC8E8FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info section
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFB4D2F0).withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outfit.name,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0C1E48),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    outfit.subtitle,
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: Color(0xFF6070A0),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Tags
                  Wrap(
                    spacing: 4,
                    children: outfit.tags
                        .map((tag) => _buildTag(tag))
                        .toList(),
                  ),
                  const SizedBox(height: 6),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildCardButton('Try-On', true),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildCardButton('Edit', false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEEF3FF), Color(0xFFE4EDF8)],
        ),
        border: Border.all(
          color: const Color(0xFFB4CDF0).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2A4080),
        ),
      ),
    );
  }

  Widget _buildCardButton(String label, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: isPrimary
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A1E58), Color(0xFF060F2E)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF0F5FF), Color(0xFFE4EDF8)],
              ),
        border: Border.all(
          color: isPrimary
              ? const Color(0xFF64A0FF).withValues(alpha: 0.32)
              : const Color(0xFFB4CDF0).withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: isPrimary ? const Color(0xFFD2E8FF) : const Color(0xFF1A3060),
        ),
      ),
    );
  }

  // â”€â”€ DIVIDER â”€â”€
  Widget _buildDivider() {
    return Container(
      height: 3,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            const Color(0xFF96B9E6).withValues(alpha: 0.3),
            const Color(0xFFC8E1F8).withValues(alpha: 0.8),
            const Color(0xFFF4F7FF),
            const Color(0xFFC8E1F8).withValues(alpha: 0.8),
            const Color(0xFF96B9E6).withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  // â”€â”€ REUSE BAR â”€â”€
  Widget _buildReuseBar() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1E58), Color(0xFF060F2E)],
          ),
          border: Border.all(
            color: const Color(0xFF64A0FF).withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF030828).withValues(alpha: 0.32),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color(0xFFA0D2FF).withValues(alpha: 0.18),
              blurRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reuse Existing Outfit',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD2E8FF),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mix & match from your wardrobe',
                    style: TextStyle(
                      fontSize: 9,
                      color: const Color(0xFFA0C8FF).withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward,
              size: 14,
              color: const Color(0xFFA0C8FF).withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ SUGGESTED CARDS â”€â”€
  Widget _buildSuggestedCardsScroll(List<SuggestedCard> suggested) {
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: suggested
            .map((card) => _buildSuggestedCard(card))
            .toList(),
      ),
    );
  }

  Widget _buildSuggestedCard(SuggestedCard card) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          const BoxShadow(
            color: Color(0xFFB0C8E0),
            blurRadius: 0,
            offset: Offset.zero,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Color(0xFFD8ECF8),
            blurRadius: 0,
            offset: Offset.zero,
            spreadRadius: 2.5,
          ),
          const BoxShadow(
            color: Color(0xFF8AACCC),
            blurRadius: 0,
            offset: Offset.zero,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: const Color(0xff1432780).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [card.gradientStart, card.gradientEnd],
              ),
            ),
            child: Center(
              child: Container(
                width: 44,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF5A8CC8).withValues(alpha: 0.35),
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CustomPaint(
                      painter: _ImagePlaceholderPainter(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFB4D2F0).withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0C1E48),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'â˜… ${card.score.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2A58C8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ CHAT PANEL â”€â”€
  Widget _buildChatPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1E58), Color(0xFF060F2E)],
        ),
        border: Border.all(
          color: const Color(0xFF64A0FF).withValues(alpha: 0.38),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF030828).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: const Color(0xFFA0D2FF).withValues(alpha: 0.18),
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Chat header
          GestureDetector(
            onTap: () => setState(() => _chatOpen = !_chatOpen),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF64A0FF).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          3,
                          (i) => Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(right: 2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFC8E1FF).withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'NX Chat',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD2E8FF),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF78A0FF).withValues(alpha: 0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _chatOpen ? 'Minimize' : 'Expand',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFA0C8FF).withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Chat body (expandable)
          if (_chatOpen)
            Column(
              children: [
                // Chat message
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0x29FFFFFF), Color(0x0FFFFFFF)],
                          ),
                          border: Border.all(
                            color: const Color(0xFFA0D2FF).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 16,
                          color: const Color(0xFFB4D7FF).withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCEBFF).withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Ready for a new look? Let me know if you\'d like outfit ideas or occasion-based recommendations!',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF0A1428),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Chat input
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF).withValues(alpha: 0.08),
                            border: Border.all(
                              color: const Color(0xFF64A0FF).withValues(alpha: 0.28),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFD2E8FF),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ask NX about your outfitsâ€¦',
                              hintStyle: TextStyle(
                                fontSize: 10,
                                color: const Color(0xFFA0C8FF).withValues(alpha: 0.45),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF2A58C8), Color(0xFF1A3A9A)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF143CC8).withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.send,
                            size: 11,
                            color: Color(0xFFD2E8FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// â”€â”€ CUSTOM PAINTERS â”€â”€
class _PlusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD2E8FF)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _ImagePlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF508CC8).withValues(alpha: 0.48)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    // Rectangle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3, 3, size.width - 6, size.height - 6),
        const Radius.circular(3),
      ),
      paint,
    );

    // Circle for focus point
    canvas.drawCircle(
      Offset(size.width * 0.42, size.height * 0.42),
      1.5,
      Paint()..color = const Color(0xFF508CC8).withValues(alpha: 0.48),
    );

    // Diagonal line (mountains)
    final linePaint = Paint()
      ..color = const Color(0xFF508CC8).withValues(alpha: 0.48)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.8, size.height * 0.6),
      Offset(size.width * 0.2, size.height * 0.8),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

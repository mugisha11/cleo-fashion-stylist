import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/fashion_scaffold.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/models/tryon_session_model.dart';
import '../../../core/models/tryon_session_model.dart' as models;
import '../../../core/providers/ai_recommendation_provider.dart';
import '../../../core/providers/tryon_memory_provider.dart';
import '../../../core/providers/fashion_ai_chat_provider.dart';
import '../../../core/services/fashion_ai_chat_service.dart';
import '../../../core/services/chat_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../routes.dart';
import '../providers/chat_provider.dart';
import '../widgets/daily_outfit_pick_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/latest_tryons_carousel.dart';
import '../widgets/intelligent_chat_section.dart';
// import '../widgets/ai_notification_banner.dart'; // TODO: Create notification banner

/// Intelligent Fashion AI Dashboard
/// World-class, premium, emotionally engaging fashion AI experience
class IntelligentFashionDashboard extends ConsumerStatefulWidget {
  const IntelligentFashionDashboard({super.key});

  @override
  ConsumerState<IntelligentFashionDashboard> createState() =>
      _IntelligentFashionDashboardState();
}

class _IntelligentFashionDashboardState
    extends ConsumerState<IntelligentFashionDashboard> {
  final ScrollController _scrollController = ScrollController();
  bool _isChatExpanded = false;

  @override
  void initState() {
    super.initState();
    // Initialize conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeConversation();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeConversation() async {
    try {
      final supabase = Supabase.instance.client;
      final auth = FirebaseAuth.instance;
      final chatService = ChatService(supabase, auth);
      final conversationId = await chatService.getOrCreateConversation();
      ref.read(conversationIdProvider.notifier).state = conversationId;
      ref.read(chatMessagesProvider.notifier).updateConversationId(conversationId);
    } catch (e) {
      debugPrint('Error initializing conversation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final dailyRecommendationsAsync = ref.watch(dailyRecommendationsProvider);
    final savedTryOnsAsync = ref.watch(savedTryOnsProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return FashionScaffold(
      title: 'AI Stylist',
      currentBottomNavIndex: 0,
      currentRoute: Routes.dashboard,
      backgroundColor: theme.backgroundPrimary,
      body: Container(
        decoration: theme.backgroundGradient != null
            ? BoxDecoration(gradient: theme.backgroundGradient)
            : BoxDecoration(color: theme.backgroundPrimary),
        child: SafeArea(
          child: Column(
            children: [
              // AI Notification Banner (if any)
              _buildNotificationBanner(theme),

              // Main Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(dailyRecommendationsProvider);
                    ref.invalidate(savedTryOnsProvider);
                  },
                  color: theme.primary,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Header Section
                      SliverToBoxAdapter(
                        child: _buildHeader(theme, isMobile),
                      ),

                      // Today's 3 AI Picks
                      SliverToBoxAdapter(
                        child: _buildDailyPicksSection(
                          theme,
                          dailyRecommendationsAsync,
                          isMobile,
                        ),
                      ),

                      // Quick AI Actions
                      SliverToBoxAdapter(
                        child: _buildQuickActions(theme, isMobile),
                      ),

                      // Latest Try-Ons Carousel
                      savedTryOnsAsync.when(
                        data: (tryOns) => SliverToBoxAdapter(
                          child: _buildLatestTryOns(
                            theme,
                            tryOns,
                            isMobile,
                          ),
                        ),
                        loading: () => const SliverToBoxAdapter(
                          child: SizedBox(height: 200),
                        ),
                        error: (_, __) => const SliverToBoxAdapter(
                          child: SizedBox.shrink(),
                        ),
                      ),

                      // AI Chat Section (Expandable)
                      SliverToBoxAdapter(
                        child: _buildChatSection(theme, isMobile),
                      ),

                      // Bottom spacing
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 24),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBanner(AppThemeData theme) {
    // TODO: Integrate with notification provider
    // For now, return empty
    return const SizedBox.shrink();
  }

  Widget _buildHeader(AppThemeData theme, bool isMobile) {
    final now = DateTime.now();
    final greeting = _getGreeting(now);
    final dateFormat = DateFormat('EEEE, MMMM d');

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 32,
        24,
        isMobile ? 20 : 32,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: theme.titleLarge(color: theme.textPrimary).copyWith(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            dateFormat.format(now),
            style: theme.bodyMedium(color: theme.textSecondary).copyWith(
                  fontSize: isMobile ? 14 : 16,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  String _getGreeting(DateTime now) {
    final hour = now.hour;
    if (hour < 12) {
      return 'Good morning 🌞';
    } else if (hour < 17) {
      return 'Good afternoon ☀️';
    } else {
      return 'Good evening 🌙';
    }
  }

  Widget _buildDailyPicksSection(
    AppThemeData theme,
    AsyncValue<List<models.OutfitRecommendation>> recommendationsAsync,
    bool isMobile,
  ) {
    return recommendationsAsync.when(
      loading: () => _buildDailyPicksLoading(theme, isMobile),
      error: (error, stack) => _buildDailyPicksError(theme, error),
      data: (recommendations) {
        if (recommendations.isEmpty) {
          return _buildEmptyDailyPicks(theme, isMobile);
        }
        return _buildDailyPicks(theme, recommendations, isMobile);
      },
    );
  }

  Widget _buildDailyPicksLoading(AppThemeData theme, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 32,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's 3 AI Picks",
            style: theme.titleMedium(color: theme.textPrimary).copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: isMobile ? 280 : 320,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) => Container(
                width: isMobile ? 240 : 280,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: theme.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: CircularProgressIndicator(color: theme.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyPicksError(AppThemeData theme, Object error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.accentError.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.accentError, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Unable to load recommendations',
                style: theme.bodyMedium(color: theme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDailyPicks(AppThemeData theme, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 32,
        vertical: 16,
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.borderLight.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: 48,
              color: theme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No recommendations yet',
              style: theme.titleMedium(color: theme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Add clothes to your wardrobe to get AI picks',
              style: theme.bodyMedium(color: theme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(Routes.wardrobe);
              },
              icon: Icon(Icons.add, color: theme.surface),
              label: Text(
                'Add to Wardrobe',
                style: theme.bodyMedium(color: theme.surface),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyPicks(
    AppThemeData theme,
    List<models.OutfitRecommendation> recommendations,
    bool isMobile,
  ) {
    // Always show exactly 3 recommendations
    final picks = recommendations.length >= 3
        ? recommendations.take(3).toList()
        : recommendations;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 32,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Today's 3 AI Picks",
                style: theme.titleMedium(color: theme.textPrimary).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 18 : 20,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  ref.invalidate(dailyRecommendationsProvider);
                },
                icon: Icon(Icons.refresh, size: 16, color: theme.primary),
                label: Text(
                  'Refresh',
                  style: theme.bodySmall(color: theme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: isMobile ? 280 : 320,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: picks.length,
              itemBuilder: (context, index) {
                return DailyOutfitPickCard(
                  recommendation: picks[index],
                  index: index,
                  onTap: () => _handleOutfitPickTap(picks[index]),
                  onAddToCalendar: () => _handleAddToCalendar(picks[index]),
                  onTryNow: () => _handleTryNow(picks[index]),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildQuickActions(AppThemeData theme, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 32,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick AI Actions',
            style: theme.titleMedium(color: theme.textPrimary).copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              QuickActionButton(
                icon: Icons.help_outline,
                label: 'What should I wear?',
                onTap: () => _handleQuickAction('What should I wear today?'),
                color: theme.primary,
              ),
              QuickActionButton(
                icon: Icons.event,
                label: 'Plan for event',
                onTap: () => _handleQuickAction('Plan an outfit for an event'),
                color: theme.primaryLight,
              ),
              QuickActionButton(
                icon: Icons.wb_sunny_outlined,
                label: 'Weather plan',
                onTap: () => _handleQuickAction('What should I wear for the weather?'),
                color: theme.accentWarning,
              ),
              QuickActionButton(
                icon: Icons.style,
                label: 'Mix & match',
                onTap: () => _handleQuickAction('Suggest mix and match outfits'),
                color: theme.primaryDark,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildLatestTryOns(
    AppThemeData theme,
    List<TryOnSession> tryOns,
    bool isMobile,
  ) {
    if (tryOns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 32,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Latest Try-Ons',
                style: theme.titleMedium(color: theme.textPrimary).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(Routes.tryonHistory);
                },
                child: Text(
                  'View All',
                  style: theme.bodySmall(color: theme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LatestTryOnsCarousel(
            tryOns: tryOns.take(5).toList(),
            onTap: (tryOn) => _handleTryOnTap(tryOn),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildChatSection(AppThemeData theme, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 32,
        vertical: 16,
      ),
      child: IntelligentChatSection(
        isExpanded: _isChatExpanded,
        onToggle: () {
          setState(() {
            _isChatExpanded = !_isChatExpanded;
          });
        },
      ),
    );
  }

  void _handleOutfitPickTap(models.OutfitRecommendation recommendation) {
    // Show outfit details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OutfitDetailSheet(recommendation: recommendation),
    );
  }

  void _handleAddToCalendar(models.OutfitRecommendation recommendation) {
    // TODO: Implement add to calendar
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Adding to calendar...'),
        backgroundColor: context.appTheme.accentSuccess,
      ),
    );
  }

  void _handleTryNow(models.OutfitRecommendation recommendation) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushNamed(Routes.tryon);
  }

  void _handleQuickAction(String prompt) {
    HapticFeedback.selectionClick();
    setState(() {
      _isChatExpanded = true;
    });
    // Send message to chat
    Future.delayed(const Duration(milliseconds: 300), () {
      ref.read(chatMessagesProvider.notifier).sendMessage(prompt);
    });
  }

  void _handleTryOnTap(TryOnSession tryOn) {
    // Show try-on details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TryOnDetailSheet(tryOn: tryOn),
    );
  }
}

class _OutfitDetailSheet extends StatelessWidget {
  final models.OutfitRecommendation recommendation;

  const _OutfitDetailSheet({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  if (recommendation.tryOnImageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: recommendation.tryOnImageUrl!,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    recommendation.name,
                    style: theme.titleLarge(color: theme.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  // Reasoning
                  Text(
                    recommendation.reasoning,
                    style: theme.bodyMedium(color: theme.textSecondary),
                  ),
                  if (recommendation.weatherMatch != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.wb_sunny, size: 16, color: theme.primary),
                        const SizedBox(width: 8),
                        Text(
                          recommendation.weatherMatch!,
                          style: theme.bodySmall(color: theme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                  if (recommendation.eventMatch != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.event, size: 16, color: theme.primary),
                        const SizedBox(width: 8),
                        Text(
                          recommendation.eventMatch!,
                          style: theme.bodySmall(color: theme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Add to calendar
                    },
                    icon: Icon(Icons.calendar_today, color: theme.primary),
                    label: Text(
                      'Add to Calendar',
                      style: theme.bodyMedium(color: theme.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: theme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed(Routes.tryon);
                    },
                    icon: Icon(Icons.checkroom, color: theme.surface),
                    label: Text(
                      'Try Now',
                      style: theme.bodyMedium(color: theme.surface),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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

class _TryOnDetailSheet extends StatelessWidget {
  final TryOnSession tryOn;

  const _TryOnDetailSheet({required this.tryOn});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: CachedNetworkImage(
              imageUrl: tryOn.resultImageUrl,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(Routes.tryon);
              },
              icon: Icon(Icons.refresh, color: theme.surface),
              label: Text(
                'Reuse This Image',
                style: theme.bodyMedium(color: theme.surface),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

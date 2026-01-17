import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/services/recommendations_service.dart';
import '../../../core/models/chat_model.dart';
import '../providers/chat_provider.dart';
import '../../../features/recommendations/providers/recommendations_provider.dart';
import '../widgets/daily_recommendation_card.dart';
import '../widgets/quick_actions_bar.dart';
import '../widgets/chat_preview_card.dart';
import '../widgets/chatgpt_chat_interface.dart';
import '../../../routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';

/// Premium Fashion Dashboard
/// Complete redesign from scratch - ChatGPT + Pinterest + Farfetch inspired
class PremiumFashionDashboard extends ConsumerStatefulWidget {
  const PremiumFashionDashboard({super.key});

  @override
  ConsumerState<PremiumFashionDashboard> createState() => _PremiumFashionDashboardState();
}

class _PremiumFashionDashboardState extends ConsumerState<PremiumFashionDashboard>
    with SingleTickerProviderStateMixin {
  bool _isChatExpanded = false;
  late AnimationController _chatAnimationController;
  late Animation<double> _chatAnimation;

  @override
  void initState() {
    super.initState();
    _chatAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _chatAnimation = CurvedAnimation(
      parent: _chatAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _chatAnimationController.dispose();
    super.dispose();
  }

  void _expandChat() {
    setState(() {
      _isChatExpanded = true;
    });
    _chatAnimationController.forward();
    HapticFeedback.mediumImpact();
  }

  void _collapseChat() {
    _chatAnimationController.reverse().then((_) {
      setState(() {
        _isChatExpanded = false;
      });
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _handleSendMessage(String message, {List<Uint8List>? images}) async {
    // This will be handled by the chat interface
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isMobile = MediaQuery.of(context).size.width < 768;
    final chatMessages = ref.watch(chatMessagesProvider);
    final recommendations = ref.watch(recommendationsProvider);

    // If chat is expanded, show fullscreen chat
    if (_isChatExpanded) {
      return _buildExpandedChat(theme, isMobile, chatMessages);
    }

    // Compact mode - show recommendations, quick actions, and chat preview
    return _buildCompactMode(theme, isMobile, chatMessages, recommendations);
  }

  Widget _buildExpandedChat(
    AppThemeData theme,
    bool isMobile,
    AsyncValue<List<ChatMessage>> chatMessages,
  ) {
    return Container(
      decoration: theme.backgroundGradient != null
          ? BoxDecoration(gradient: theme.backgroundGradient)
          : BoxDecoration(color: theme.backgroundPrimary),
      child: Stack(
        children: [
          // Fullscreen chat
          chatMessages.when(
            data: (messages) => ChatGPTChatInterface(
              messages: messages,
              onSendMessage: _handleSendMessage,
              onTryOnRequest: (imageUrl) {
                Navigator.of(context).pushNamed(
                  Routes.tryon,
                  arguments: {'imageUrl': imageUrl},
                );
              },
            ),
            loading: () => Center(
              child: CircularProgressIndicator(color: theme.primary),
            ),
            error: (_, __) => ChatGPTChatInterface(
              messages: [],
              onSendMessage: _handleSendMessage,
            ),
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _collapseChat,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.surface.withOpacity(0.8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.borderLight.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.close,
                    color: theme.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMode(
    AppThemeData theme,
    bool isMobile,
    AsyncValue<List<ChatMessage>> chatMessages,
    AsyncValue<List<RecommendedOutfit>> recommendations,
  ) {
    return Container(
      decoration: theme.backgroundGradient != null
          ? BoxDecoration(gradient: theme.backgroundGradient)
          : BoxDecoration(color: theme.backgroundPrimary),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 100), // Space for bottom nav
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 20 : 32,
                  isMobile ? 20 : 32,
                  isMobile ? 20 : 32,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Style Today',
                      style: TextStyle(
                        fontSize: isMobile ? 28 : 32,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Daily Recommendations Section
              _buildRecommendationsSection(theme, isMobile, recommendations),

              const SizedBox(height: 24),

              // Quick Actions Bar
              QuickActionsBar(
                onAskAI: _expandChat,
                onTryOn: () => Navigator.of(context).pushNamed(Routes.tryon),
                onCalendar: () => Navigator.of(context).pushNamed(Routes.calendar),
                onWardrobe: () => Navigator.of(context).pushNamed(Routes.wardrobe),
              ),

              const SizedBox(height: 24),

              // Chat Preview
              chatMessages.when(
                data: (messages) => ChatPreviewCard(
                  lastMessage: messages.isNotEmpty ? messages.last : null,
                  hasUnreadMessages: false, // TODO: Implement unread tracking
                  onExpand: _expandChat,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => ChatPreviewCard(
                  onExpand: _expandChat,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(
    AppThemeData theme,
    bool isMobile,
    AsyncValue<List<RecommendedOutfit>> recommendations,
  ) {
    return recommendations.when(
      data: (recs) {
        if (recs.isEmpty) {
          return _buildEmptyRecommendations(theme, isMobile);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 32,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Recommendations',
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(Routes.recommendations);
                    },
                    child: Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: isMobile ? 380 : 420,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 32,
                ),
                itemCount: recs.length,
                itemBuilder: (context, index) {
                  final rec = recs[index];
                  return DailyRecommendationCard(
                    recommendation: rec,
                    isNew: index == 0, // First recommendation is "new"
                    weatherContext: _getWeatherContext(),
                    calendarContext: _getCalendarContext(),
                    onTap: () => _showRecommendationDetails(rec),
                    onAddToCalendar: () => _addToCalendar(rec),
                    onTryAgain: () => _tryOnRecommendation(rec),
                    onViewDetails: () => _showRecommendationDetails(rec),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => _buildRecommendationsLoading(theme, isMobile),
      error: (error, stack) => _buildRecommendationsError(theme, isMobile),
    );
  }

  Widget _buildEmptyRecommendations(AppThemeData theme, bool isMobile) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.borderLight.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.style_outlined,
            size: 48,
            color: theme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No recommendations yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to your wardrobe to get personalized recommendations',
            style: TextStyle(
              fontSize: 14,
              color: theme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushNamed(Routes.wardrobe),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Go to Wardrobe'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsLoading(AppThemeData theme, bool isMobile) {
    return Container(
      height: isMobile ? 380 : 420,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 32),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: isMobile ? 280 : 320,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: theme.surface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: CircularProgressIndicator(color: theme.primary),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationsError(AppThemeData theme, bool isMobile) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.accentError.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.accentError.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.accentError,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Failed to load recommendations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning! Ready to style your day?';
    } else if (hour < 17) {
      return 'Good afternoon! What will you wear?';
    } else {
      return 'Good evening! Planning tomorrow\'s look?';
    }
  }

  String? _getWeatherContext() {
    // TODO: Integrate with weather service
    return 'Sunny, 72°F';
  }

  String? _getCalendarContext() {
    // TODO: Integrate with calendar service
    final now = DateTime.now();
    if (now.weekday == DateTime.monday) {
      return 'Work week starts';
    }
    return null;
  }

  void _showRecommendationDetails(RecommendedOutfit recommendation) {
    // TODO: Show detail modal/sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRecommendationDetailSheet(recommendation),
    );
  }

  Widget _buildRecommendationDetailSheet(RecommendedOutfit recommendation) {
    final theme = context.appTheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recommendation.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            recommendation.reasoning,
            style: TextStyle(
              fontSize: 16,
              color: theme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _addToCalendar(RecommendedOutfit recommendation) {
    final theme = context.appTheme;
    // TODO: Implement calendar integration
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${recommendation.name}" to calendar'),
        backgroundColor: theme.primary,
      ),
    );
  }

  void _tryOnRecommendation(RecommendedOutfit recommendation) {
    Navigator.of(context).pushNamed(
      Routes.tryon,
      arguments: {'recommendation': recommendation},
    );
  }
}

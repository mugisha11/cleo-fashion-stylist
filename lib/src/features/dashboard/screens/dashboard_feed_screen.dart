import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/quora_design_system.dart';
import '../../../core/widgets/quora_bottom_navigation.dart';
import '../providers/chat_provider.dart';
import '../../../routes.dart';

/// Quora-Style Feed Dashboard
/// Feed-based layout with cards, like Quora's home feed
class DashboardFeedScreen extends ConsumerStatefulWidget {
  const DashboardFeedScreen({super.key});

  @override
  ConsumerState<DashboardFeedScreen> createState() => _DashboardFeedScreenState();
}

class _DashboardFeedScreenState extends ConsumerState<DashboardFeedScreen> {
  int _currentBottomNavIndex = 0;

  void _onBottomNavTap(int index) {
    setState(() => _currentBottomNavIndex = index);
    
    // Navigate based on tab
    switch (index) {
      case 0:
        // Already on feed
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(Routes.wardrobe);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(Routes.tryon);
        break;
      case 3:
        // Show notifications
        break;
      case 4:
        // Show profile
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider);

    return Scaffold(
      backgroundColor: QuoraDesignSystem.backgroundGray,
      appBar: AppBar(
        title: Text(
          'StyleApp',
          style: QuoraDesignSystem.headlineSmall(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: messagesAsync.when(
        data: (messages) => _buildFeed(messages),
        loading: () => _buildLoadingSkeleton(),
        error: (error, stack) => _buildErrorState(error),
      ),
      bottomNavigationBar: QuoraBottomNavigation(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildFeed(List messages) {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: messages.length + 3, // Messages + recommendation cards
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildRecommendationCard(
            title: 'AI Outfit Recommendation',
            description: 'Based on your style preferences, here are 3 outfits perfect for today',
            imageUrl: null,
          );
        }
        if (index == 1) {
          return _buildRecommendationCard(
            title: 'Try-On Available',
            description: 'Upload a photo to see how this outfit looks on you',
            imageUrl: null,
          );
        }
        if (index == 2) {
          return _buildDivider();
        }
        
        final messageIndex = index - 3;
        if (messageIndex < messages.length) {
          return _buildMessageCard(messages[messageIndex]);
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildRecommendationCard({
    required String title,
    required String description,
    String? imageUrl,
  }) {
    return Container(
      color: QuoraDesignSystem.backgroundWhite,
      padding: EdgeInsets.all(QuoraDesignSystem.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: QuoraDesignSystem.brandColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(QuoraDesignSystem.radiusMD),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: QuoraDesignSystem.brandColor,
                  size: QuoraDesignSystem.iconSize,
                ),
              ),
              SizedBox(width: QuoraDesignSystem.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: QuoraDesignSystem.titleLarge(),
                    ),
                    SizedBox(height: QuoraDesignSystem.spacingXS),
                    Text(
                      description,
                      style: QuoraDesignSystem.bodyMedium(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: QuoraDesignSystem.spacingMD),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(Routes.recommendations);
                },
                child: Text('View Recommendations', style: QuoraDesignSystem.linkText()),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.bookmark_border, size: QuoraDesignSystem.iconSize),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(message) {
    return Container(
      color: QuoraDesignSystem.backgroundWhite,
      padding: EdgeInsets.all(QuoraDesignSystem.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: QuoraDesignSystem.brandColor.withOpacity(0.1),
                child: Icon(
                  Icons.smart_toy,
                  size: QuoraDesignSystem.iconSizeSmall,
                  color: QuoraDesignSystem.brandColor,
                ),
              ),
              SizedBox(width: QuoraDesignSystem.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Stylist',
                      style: QuoraDesignSystem.bodyMedium().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '2 hours ago',
                      style: QuoraDesignSystem.caption(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: QuoraDesignSystem.spacingMD),
          Text(
            message['content'] ?? message.toString(),
            style: QuoraDesignSystem.bodyLarge(),
          ),
          SizedBox(height: QuoraDesignSystem.spacingMD),
          Row(
            children: [
              _buildActionButton(Icons.thumb_up_outlined, 'Upvote'),
              SizedBox(width: QuoraDesignSystem.spacingLG),
              _buildActionButton(Icons.comment_outlined, 'Comment'),
              SizedBox(width: QuoraDesignSystem.spacingLG),
              _buildActionButton(Icons.share_outlined, 'Share'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: QuoraDesignSystem.iconSizeSmall),
      label: Text(label, style: QuoraDesignSystem.bodySmall()),
      style: TextButton.styleFrom(
        foregroundColor: QuoraDesignSystem.textSecondary,
        padding: EdgeInsets.symmetric(
          horizontal: QuoraDesignSystem.spacingSM,
          vertical: QuoraDesignSystem.spacingXS,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: QuoraDesignSystem.spacingSM,
      color: QuoraDesignSystem.dividerColor,
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        color: QuoraDesignSystem.backgroundWhite,
        padding: EdgeInsets.all(QuoraDesignSystem.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: QuoraDesignSystem.borderColor,
                    borderRadius: BorderRadius.circular(QuoraDesignSystem.radiusMD),
                  ),
                ),
                SizedBox(width: QuoraDesignSystem.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: 150,
                        color: QuoraDesignSystem.borderColor,
                      ),
                      SizedBox(height: QuoraDesignSystem.spacingXS),
                      Container(
                        height: 12,
                        width: 100,
                        color: QuoraDesignSystem.borderColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: QuoraDesignSystem.spacingMD),
            Container(
              height: 14,
              width: double.infinity,
              color: QuoraDesignSystem.borderColor,
            ),
            SizedBox(height: QuoraDesignSystem.spacingXS),
            Container(
              height: 14,
              width: 200,
              color: QuoraDesignSystem.borderColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(QuoraDesignSystem.spacingXXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 64,
              color: QuoraDesignSystem.textTertiary,
            ),
            SizedBox(height: QuoraDesignSystem.spacingLG),
            Text(
              'Your feed is empty',
              style: QuoraDesignSystem.headlineMedium(),
            ),
            SizedBox(height: QuoraDesignSystem.spacingSM),
            Text(
              'Start by asking our AI stylist for outfit recommendations',
              style: QuoraDesignSystem.bodyMedium().copyWith(
                color: QuoraDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(QuoraDesignSystem.spacingXXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: QuoraDesignSystem.errorColor,
            ),
            SizedBox(height: QuoraDesignSystem.spacingLG),
            Text(
              'Something went wrong',
              style: QuoraDesignSystem.headlineMedium(),
            ),
            SizedBox(height: QuoraDesignSystem.spacingSM),
            Text(
              error.toString(),
              style: QuoraDesignSystem.bodyMedium().copyWith(
                color: QuoraDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

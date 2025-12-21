import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../../../core/widgets/fashion_scaffold.dart';
import '../../../core/models/chat_model.dart';
import '../providers/chat_provider.dart';
import '../../../routes.dart';

/// Premium Fashion Dashboard
/// Fashion Feed + AI Stylist Hybrid - Image-first, editorial layout
class FashionDashboardScreen extends ConsumerStatefulWidget {
  const FashionDashboardScreen({super.key});

  @override
  ConsumerState<FashionDashboardScreen> createState() => _FashionDashboardScreenState();
}

class _FashionDashboardScreenState extends ConsumerState<FashionDashboardScreen> {
  int _currentBottomNavIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    setState(() => _currentBottomNavIndex = index);
    
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider);

    return FashionScaffold(
      greeting: _getGreeting(),
      currentBottomNavIndex: _currentBottomNavIndex,
      onBottomNavTap: _onBottomNavTap,
      currentRoute: Routes.dashboard,
      body: Column(
        children: [
          // Fashion Feed
          Expanded(
            child: messagesAsync.when(
              data: (messages) => _buildFashionFeed(messages),
              loading: () => _buildLoadingSkeleton(),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
          
          // AI Stylist Input (Floating at bottom)
          _buildAIStylistInput(),
        ],
      ),
    );
  }

  Widget _buildFashionFeed(List<ChatMessage> messages) {
    // Filter to only show assistant messages in the feed
    final assistantMessages = messages.where((m) => m.role == 'assistant').toList();
    
    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.all(FashionDesignSystem.spacingLG),
      children: [
        // Hero Fashion Card
        _buildHeroCard(),
        
        SizedBox(height: FashionDesignSystem.spacingXXL),
        
        // Section Title
        Text(
          'AI Style Recommendations',
          style: FashionDesignSystem.titleLarge(),
        ),
        
        SizedBox(height: FashionDesignSystem.spacingLG),
        
        // Outfit Recommendation Cards
        _buildOutfitRecommendations(),
        
        SizedBox(height: FashionDesignSystem.spacingXXL),
        
        // AI Stylist Responses (as fashion cards)
        if (assistantMessages.isNotEmpty) ...[
          Text(
            'Your Style Journey',
            style: FashionDesignSystem.titleLarge(),
          ),
          SizedBox(height: FashionDesignSystem.spacingLG),
          ...assistantMessages.map((message) => _buildMessageCard(message)),
        ],
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      height: 400,
      decoration: FashionDesignSystem.heroCardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Hero Image (Full-bleed)
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: FashionDesignSystem.backgroundLight,
              ),
              errorWidget: (context, url, error) => Container(
                color: FashionDesignSystem.backgroundLight,
                child: Icon(
                  Icons.image_outlined,
                  size: 64,
                  color: FashionDesignSystem.textTertiary,
                ),
              ),
            ),
          ),
          
          // Gradient Overlay (Subtle)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
          
          // Content Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.all(FashionDesignSystem.spacingXXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Style Recommendation",
                    style: FashionDesignSystem.headlineMedium().copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  SizedBox(height: FashionDesignSystem.spacingSM),
                  Text(
                    'A perfect blend of elegance and comfort',
                    style: FashionDesignSystem.bodyMedium().copyWith(
                      color: Colors.white.withOpacity(0.9),
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

  Widget _buildOutfitRecommendations() {
    // Sample outfit recommendations
    final outfits = [
      {
        'image': 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
        'title': 'Elegant Evening Look',
        'description': 'Perfect for dinner dates',
      },
      {
        'image': 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=400',
        'title': 'Casual Weekend Style',
        'description': 'Comfortable and chic',
      },
      {
        'image': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
        'title': 'Professional Power Suit',
        'description': 'Confident and polished',
      },
    ];

    return SizedBox(
      height: 320,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: outfits.length,
        itemBuilder: (context, index) {
          final outfit = outfits[index];
          return Container(
            width: 280,
            margin: EdgeInsets.only(
              right: index < outfits.length - 1 ? FashionDesignSystem.spacingLG : 0,
            ),
            child: _buildOutfitCard(
              imageUrl: outfit['image']!,
              title: outfit['title']!,
              description: outfit['description']!,
            ),
          );
        },
      ),
    );
  }

  Widget _buildOutfitCard({
    required String imageUrl,
    required String title,
    required String description,
  }) {
    return Container(
      decoration: FashionDesignSystem.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image (Dominant)
          Expanded(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: FashionDesignSystem.backgroundLight,
              ),
              errorWidget: (context, url, error) => Container(
                color: FashionDesignSystem.backgroundLight,
                child: Icon(
                  Icons.image_outlined,
                  color: FashionDesignSystem.textTertiary,
                ),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: EdgeInsets.all(FashionDesignSystem.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: FashionDesignSystem.titleMedium(),
                ),
                SizedBox(height: FashionDesignSystem.spacingXS),
                Text(
                  description,
                  style: FashionDesignSystem.bodySmall(),
                ),
                SizedBox(height: FashionDesignSystem.spacingMD),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.check, size: FashionDesignSystem.iconSizeSmall),
                        label: Text('Like', style: FashionDesignSystem.bodySmall()),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: FashionDesignSystem.successColor),
                          foregroundColor: FashionDesignSystem.successColor,
                          padding: EdgeInsets.symmetric(
                            vertical: FashionDesignSystem.spacingSM,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: FashionDesignSystem.spacingSM),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.close, size: FashionDesignSystem.iconSizeSmall),
                        label: Text('Pass', style: FashionDesignSystem.bodySmall()),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: FashionDesignSystem.textTertiary),
                          foregroundColor: FashionDesignSystem.textTertiary,
                          padding: EdgeInsets.symmetric(
                            vertical: FashionDesignSystem.spacingSM,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(ChatMessage message) {
    // Only show assistant messages in the feed
    if (message.role != 'assistant') {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: FashionDesignSystem.spacingLG),
      decoration: FashionDesignSystem.cardDecoration,
      padding: EdgeInsets.all(FashionDesignSystem.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: FashionDesignSystem.avatarSizeSmall / 2,
                backgroundColor: FashionDesignSystem.primaryColor.withOpacity(0.2),
                child: Icon(
                  Icons.star,
                  size: FashionDesignSystem.iconSizeSmall,
                  color: FashionDesignSystem.primaryColor,
                ),
              ),
              SizedBox(width: FashionDesignSystem.spacingMD),
              Text(
                'Your AI Stylist',
                style: FashionDesignSystem.bodyMedium().copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: FashionDesignSystem.spacingMD),
          Text(
            message.content,
            style: FashionDesignSystem.bodyLarge(),
          ),
        ],
      ),
    );
  }

  Widget _buildAIStylistInput() {
    return Container(
      padding: EdgeInsets.all(FashionDesignSystem.spacingLG),
      decoration: BoxDecoration(
        color: FashionDesignSystem.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ask your AI Stylist',
            style: FashionDesignSystem.caption().copyWith(
              color: FashionDesignSystem.textSecondary,
            ),
          ),
          SizedBox(height: FashionDesignSystem.spacingSM),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'What should I wear for...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(FashionDesignSystem.radiusMD),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: FashionDesignSystem.spacingLG,
                      vertical: FashionDesignSystem.spacingMD,
                    ),
                  ),
                ),
              ),
              SizedBox(width: FashionDesignSystem.spacingMD),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: FashionDesignSystem.primaryColor,
                  borderRadius: BorderRadius.circular(FashionDesignSystem.radiusMD),
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () {
                    // TODO: Send message
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: FashionDesignSystem.spacingSM),
          Wrap(
            spacing: FashionDesignSystem.spacingSM,
            children: [
              _buildPromptChip('What should I wear for a wedding?'),
              _buildPromptChip('Style my black dress'),
              _buildPromptChip('Weekend outfit ideas'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String text) {
    return ActionChip(
      label: Text(text, style: FashionDesignSystem.bodySmall()),
      onPressed: () {
        // TODO: Use prompt
      },
      backgroundColor: FashionDesignSystem.backgroundLight,
      side: BorderSide.none,
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: EdgeInsets.all(FashionDesignSystem.spacingLG),
      children: [
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: FashionDesignSystem.backgroundLight,
            borderRadius: BorderRadius.circular(FashionDesignSystem.radiusHero),
          ),
        ),
        SizedBox(height: FashionDesignSystem.spacingXXL),
        Container(
          height: 20,
          width: 200,
          color: FashionDesignSystem.backgroundLight,
        ),
      ],
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(FashionDesignSystem.spacingXXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: FashionDesignSystem.errorColor,
            ),
            SizedBox(height: FashionDesignSystem.spacingLG),
            Text(
              'Something went wrong',
              style: FashionDesignSystem.headlineMedium(),
            ),
            SizedBox(height: FashionDesignSystem.spacingSM),
            Text(
              error.toString(),
              style: FashionDesignSystem.bodyMedium().copyWith(
                color: FashionDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

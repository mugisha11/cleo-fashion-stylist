import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/chatgpt_dark_theme.dart';
import '../widgets/chatgpt_chat_interface.dart';
import '../providers/chat_provider.dart';
import '../../../routes.dart';

/// ChatGPT-like Fashion Dashboard
/// Centered AI chat, collapsing UI when focused
/// Fashion-first, minimal, calm
class ChatGPTFashionDashboard extends ConsumerStatefulWidget {
  const ChatGPTFashionDashboard({super.key});

  @override
  ConsumerState<ChatGPTFashionDashboard> createState() => _ChatGPTFashionDashboardState();
}

class _ChatGPTFashionDashboardState extends ConsumerState<ChatGPTFashionDashboard> {
  bool _isChatFocused = false;

  @override
  Widget build(BuildContext context) {
    final chatMessages = ref.watch(chatMessagesProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Theme(
      data: ChatGPTDarkTheme.theme,
      child: Scaffold(
        backgroundColor: ChatGPTDarkTheme.background,
        body: SafeArea(
          child: _isChatFocused && isMobile
              ? _buildFullscreenChat(chatMessages)
              : _buildDashboardWithChat(chatMessages, isMobile),
        ),
      ),
    );
  }

  Widget _buildDashboardWithChat(
    AsyncValue<List<dynamic>> chatMessages,
    bool isMobile,
  ) {
    return Column(
      children: [
        // Minimal header (hidden when chat focused)
        if (!_isChatFocused) _buildMinimalHeader(),
        
        // Main content area
        Expanded(
          child: Row(
            children: [
              // Left sidebar - Recommendations (hidden on mobile, collapsible on desktop)
              if (!isMobile && !_isChatFocused)
                Container(
                  width: 300,
                  color: ChatGPTDarkTheme.surface,
                  child: _buildRecommendationsSidebar(),
                ),
              
              // Center - Chat interface (main focus)
              Expanded(
                child: chatMessages.when(
                  data: (messages) => ChatGPTChatInterface(
                    messages: messages.cast(),
                    onSendMessage: _handleSendMessage,
                    onTryOnRequest: (imageUrl) => Navigator.of(context).pushNamed(Routes.tryon),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(ChatGPTDarkTheme.accent),
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Text(
                      'Failed to load chat: $error',
                      style: const TextStyle(color: ChatGPTDarkTheme.textSecondary),
                    ),
                  ),
                ),
              ),
              
              // Right sidebar - Quick actions (hidden on mobile, collapsible on desktop)
              if (!isMobile && !_isChatFocused)
                Container(
                  width: 250,
                  color: ChatGPTDarkTheme.surface,
                  child: _buildQuickActionsSidebar(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFullscreenChat(AsyncValue<List<dynamic>> chatMessages) {
    return Stack(
      children: [
        chatMessages.when(
          data: (messages) => ChatGPTChatInterface(
            messages: messages.cast(),
            onSendMessage: _handleSendMessage,
            onTryOnRequest: (imageUrl) => Navigator.of(context).pushNamed(Routes.tryon),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ChatGPTDarkTheme.accent),
            ),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Failed to load chat: $error',
              style: const TextStyle(color: ChatGPTDarkTheme.textSecondary),
            ),
          ),
        ),
        // Close button for fullscreen
        Positioned(
          top: 16,
          left: 16,
          child: IconButton(
            icon: const Icon(Icons.close, color: ChatGPTDarkTheme.textPrimary),
            onPressed: () => setState(() => _isChatFocused = false),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ChatGPTDarkTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Fashion AI',
            style: TextStyle(
              color: ChatGPTDarkTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: ChatGPTDarkTheme.textSecondary),
            onPressed: () => Navigator.of(context).pushNamed(Routes.calendar),
            tooltip: 'Calendar',
          ),
          IconButton(
            icon: const Icon(Icons.checkroom, color: ChatGPTDarkTheme.textSecondary),
            onPressed: () => Navigator.of(context).pushNamed(Routes.wardrobe),
            tooltip: 'Wardrobe',
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSidebar() {
    // Elegant, small recommendation cards
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Recommendations',
          style: TextStyle(
            color: ChatGPTDarkTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        // Placeholder for recommendation cards
        _buildRecommendationCard('Summer Look', 'Perfect for warm days'),
        const SizedBox(height: 12),
        _buildRecommendationCard('Evening Outfit', 'Elegant and sophisticated'),
        const SizedBox(height: 12),
        _buildRecommendationCard('Casual Style', 'Comfortable and stylish'),
      ],
    );
  }

  Widget _buildRecommendationCard(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ChatGPTDarkTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ChatGPTDarkTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ChatGPTDarkTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: ChatGPTDarkTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSidebar() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: ChatGPTDarkTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          'Try On',
          Icons.checkroom,
          () => Navigator.of(context).pushNamed(Routes.tryon),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Wardrobe',
          Icons.inventory_2,
          () => Navigator.of(context).pushNamed(Routes.wardrobe),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Calendar',
          Icons.calendar_today,
          () => Navigator.of(context).pushNamed(Routes.calendar),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ChatGPTDarkTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ChatGPTDarkTheme.border, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: ChatGPTDarkTheme.accent, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: ChatGPTDarkTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSendMessage(String message, {List<Uint8List>? images}) async {
    try {
      final chatMessagesNotifier = ref.read(chatMessagesProvider.notifier);
      await chatMessagesNotifier.sendMessage(message);
      // TODO: Handle images if needed
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: ChatGPTDarkTheme.error,
          ),
        );
      }
    }
  }
}

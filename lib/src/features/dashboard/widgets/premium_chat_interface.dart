/// Premium ChatGPT-Style Chat Interface
/// Production-ready, streaming-capable, intelligent conversation UI
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/models/chat_model.dart';

class PremiumChatInterface extends ConsumerStatefulWidget {
  final List<ChatMessage> messages;
  final Function(String) onSendMessage;
  final bool isStreaming;
  final String? streamingText;
  final VoidCallback? onTryOn;
  final VoidCallback? onCalendarView;

  const PremiumChatInterface({
    super.key,
    required this.messages,
    required this.onSendMessage,
    this.isStreaming = false,
    this.streamingText,
    this.onTryOn,
    this.onCalendarView,
  });

  @override
  ConsumerState<PremiumChatInterface> createState() => _PremiumChatInterfaceState();
}

class _PremiumChatInterfaceState extends ConsumerState<PremiumChatInterface>
    with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _typingController;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    widget.onSendMessage(text);
    _inputController.clear();
    HapticFeedback.lightImpact();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppThemeData.animationMedium,
          curve: AppThemeData.smoothCurve,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final theme = context.appTheme;

    return Container(
      decoration: theme.backgroundGradient != null
          ? BoxDecoration(gradient: theme.backgroundGradient)
          : BoxDecoration(color: theme.backgroundPrimary),
      child: Column(
        children: [
          // Chat Messages Area (scrollable, respects available space)
          Expanded(
            child: widget.messages.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      left: isMobile ? AppThemeData.spacingMD : AppThemeData.spacingXXL,
                      right: isMobile ? AppThemeData.spacingMD : AppThemeData.spacingXXL,
                      top: AppThemeData.spacingLG,
                      bottom: AppThemeData.spacingLG,
                    ),
                    itemCount: widget.messages.length + (widget.isStreaming ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == widget.messages.length && widget.isStreaming) {
                        return _buildStreamingMessage(theme);
                      }
                      return _buildMessageBubble(widget.messages[index], isMobile, theme);
                    },
                  ),
          ),

          // Input Area (fixed at bottom, respects SafeArea)
          _buildInputArea(isMobile, theme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: theme.primaryGlow != null ? [theme.primaryGlow!] : null,
            ),
            child: Icon(
              Icons.auto_awesome,
              color: theme.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: AppThemeData.spacingLG),
          Text(
            'How can I help you style today?',
            style: theme.titleLarge(),
          ),
          const SizedBox(height: AppThemeData.spacingSM),
          Text(
            'Ask me about outfits, try-ons, or calendar planning',
            style: theme.bodyMedium(color: theme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMobile, AppThemeData theme) {
    final isUser = message.role == 'user';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppThemeData.spacingLG),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAIAvatar(theme),
            const SizedBox(width: AppThemeData.spacingMD),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 700,
              ),
              padding: const EdgeInsets.all(AppThemeData.spacingMD),
              decoration: BoxDecoration(
                color: isUser ? theme.chatUserBubble : theme.chatAIBubble,
                borderRadius: BorderRadius.circular(theme.borderRadiusLarge),
                border: isUser
                    ? null
                    : Border.all(
                        color: theme.chatAIBorder,
                        width: 1,
                      ),
                boxShadow: isUser && theme.primaryGlow != null
                    ? [theme.primaryGlow!]
                    : theme.cardGlow != null
                        ? [theme.cardGlow!]
                        : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.content,
                    style: theme.bodyMedium(
                      color: isUser ? theme.textInverse ?? Colors.white : theme.textPrimary,
                    ),
                  ),
                  if (message.metadata != null && message.metadata!['outfit'] != null)
                    _buildInlineOutfitCard(message.metadata!['outfit'], theme),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppThemeData.spacingMD),
            _buildUserAvatar(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildAIAvatar(AppThemeData theme) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: theme.primary,
        shape: BoxShape.circle,
        boxShadow: theme.primaryGlow != null ? [theme.primaryGlow!] : null,
      ),
      child: Icon(
        Icons.auto_awesome,
        color: theme.textInverse ?? Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildUserAvatar(AppThemeData theme) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: theme.textTertiary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        color: theme.textInverse ?? Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildStreamingMessage(AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppThemeData.spacingLG),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAIAvatar(theme),
          const SizedBox(width: AppThemeData.spacingMD),
          Container(
            padding: const EdgeInsets.all(AppThemeData.spacingMD),
            decoration: BoxDecoration(
              color: theme.chatAIBubble,
              borderRadius: BorderRadius.circular(theme.borderRadiusLarge),
              border: Border.all(
                color: theme.chatAIBorder,
                width: 1,
              ),
              boxShadow: theme.cardGlow != null ? [theme.cardGlow!] : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.streamingText != null)
                  SelectableText(
                    widget.streamingText!,
                    style: theme.bodyMedium(),
                  )
                else
                  _buildTypingIndicator(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(AppThemeData theme) {
    return SizedBox(
      width: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _typingController,
            builder: (context, child) {
              final delay = index * 0.2;
              final value = (_typingController.value + delay) % 1.0;
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.textTertiary.withValues(
                    alpha: 0.3 + (value * 0.7),
                  ),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildInlineOutfitCard(Map<String, dynamic> outfitData, AppThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: AppThemeData.spacingMD),
      padding: const EdgeInsets.all(AppThemeData.spacingMD),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        border: Border.all(
          color: theme.borderLight,
          width: 1,
        ),
        boxShadow: theme.cardGlow != null ? [theme.cardGlow!] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            outfitData['title'] ?? 'Outfit Suggestion',
            style: theme.titleMedium(),
          ),
          if (outfitData['description'] != null) ...[
            const SizedBox(height: AppThemeData.spacingSM),
            Text(
              outfitData['description'],
              style: theme.bodySmall(),
            ),
          ],
          const SizedBox(height: AppThemeData.spacingMD),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onTryOn,
                  icon: const Icon(Icons.checkroom, size: 18),
                  label: const Text('Try On'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primary,
                    side: BorderSide(color: theme.primary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isMobile, AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppThemeData.spacingMD),
      decoration: BoxDecoration(
        color: theme.backgroundPrimary,
        border: Border(
          top: BorderSide(
            color: theme.borderLight,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(theme.borderRadiusLarge),
                  border: Border.all(
                    color: theme.borderLight,
                    width: 1,
                  ),
                  boxShadow: theme.primaryGlow != null
                      ? [
                          BoxShadow(
                            color: theme.primary.withValues(alpha: 0.1),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: TextField(
                  controller: _inputController,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  style: theme.bodyMedium(),
                  decoration: InputDecoration(
                    hintText: 'Message AI stylist...',
                    hintStyle: theme.bodyMedium(
                      color: theme.textTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppThemeData.spacingLG,
                      vertical: AppThemeData.spacingMD,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: AppThemeData.spacingMD),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.primary,
                shape: BoxShape.circle,
                boxShadow: theme.primaryGlow != null ? [theme.primaryGlow!] : null,
              ),
              child: Material(
                color: theme.backgroundPrimary,
                child: InkWell(
                  onTap: _sendMessage,
                  borderRadius: BorderRadius.circular(24),
                  child: Icon(
                    Icons.send,
                    color: theme.textInverse ?? Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

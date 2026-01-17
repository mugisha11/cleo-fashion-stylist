import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/grok_design_system.dart';
import '../../../core/models/chat_model.dart';

/// Grok-Inspired AI Chat Workspace
/// AI-first, chat-centric, minimal, confident
class GrokChatWorkspace extends StatefulWidget {
  final List<ChatMessage> messages;
  final Function(String) onSendMessage;
  final Function()? onImageUpload;
  final bool isLoading;

  const GrokChatWorkspace({
    super.key,
    required this.messages,
    required this.onSendMessage,
    this.onImageUpload,
    this.isLoading = false,
  });

  @override
  State<GrokChatWorkspace> createState() => _GrokChatWorkspaceState();
}

class _GrokChatWorkspaceState extends State<GrokChatWorkspace> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Fashion-aware prompt suggestions
  final List<String> _fashionPrompts = [
    'Pick outfit for event',
    'What should I wear today?',
    'Analyze my wardrobe',
    'Color palette suggestions',
    'Style tips for work',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    widget.onSendMessage(text);
    _messageController.clear();
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: GrokDesignSystem.animationMedium,
          curve: GrokDesignSystem.defaultCurve,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      color: GrokDesignSystem.backgroundOffWhite,
      child: Column(
        children: [
          // Messages Area (Full-height chat area)
          Expanded(
            child: widget.messages.isEmpty
                ? _buildEmptyState(isMobile)
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(
                      isMobile ? GrokDesignSystem.spacingMD : GrokDesignSystem.spacingLG,
                    ),
                    itemCount: widget.messages.length + (widget.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == widget.messages.length && widget.isLoading) {
                        return _buildLoadingMessage();
                      }
                      return _buildMessageBubble(widget.messages[index], isMobile);
                    },
                  ),
          ),

          // Suggestions chips above input (Fashion-aware prompts)
          if (widget.messages.isEmpty) _buildSuggestionsChips(isMobile),

          // Input Area (Pinned at bottom)
          _buildInputArea(isMobile),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: GrokDesignSystem.backgroundLightGray,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 32,
              color: GrokDesignSystem.textPrimary,
            ),
          ),
          SizedBox(height: GrokDesignSystem.spacingLG),
          Text(
            'Your AI Fashion Stylist',
            style: GrokDesignSystem.headlineMedium(isMobile: isMobile),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: GrokDesignSystem.spacingSM),
          Text(
            'Ask me anything about fashion, outfits, or styling.',
            style: GrokDesignSystem.bodyMedium(isMobile: isMobile),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsChips(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? GrokDesignSystem.spacingMD : GrokDesignSystem.spacingLG,
        vertical: GrokDesignSystem.spacingSM,
      ),
      child: Wrap(
        spacing: GrokDesignSystem.spacingSM,
        runSpacing: GrokDesignSystem.spacingSM,
        alignment: WrapAlignment.start,
        children: _fashionPrompts.map((prompt) {
          return _buildSuggestionChip(prompt, isMobile);
        }).toList(),
      ),
    );
  }

  Widget _buildSuggestionChip(String label, bool isMobile) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onSendMessage(label),
        borderRadius: BorderRadius.circular(GrokDesignSystem.radiusLG),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: GrokDesignSystem.spacingMD,
            vertical: GrokDesignSystem.spacingSM,
          ),
          decoration: BoxDecoration(
            color: GrokDesignSystem.backgroundWhite,
            borderRadius: BorderRadius.circular(GrokDesignSystem.radiusLG),
            border: Border.all(
              color: GrokDesignSystem.borderLight,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: GrokDesignSystem.bodyMedium(isMobile: isMobile).copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMobile) {
    final isUser = message.role == 'user';
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: GrokDesignSystem.spacingMD),
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 600,
        ),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: GrokDesignSystem.primaryCharcoal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: GrokDesignSystem.textInverse,
                  size: 18,
                ),
              ),
              const SizedBox(width: GrokDesignSystem.spacingSM),
            ],
            Flexible(
              child: Container(
                padding: EdgeInsets.all(
                  isMobile ? GrokDesignSystem.spacingMD : GrokDesignSystem.spacingLG,
                ),
                decoration: BoxDecoration(
                  color: isUser ? GrokDesignSystem.chatUserBubble : GrokDesignSystem.chatAIBubble,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(GrokDesignSystem.radiusLG),
                    topRight: const Radius.circular(GrokDesignSystem.radiusLG),
                    bottomLeft: Radius.circular(
                      isUser ? GrokDesignSystem.radiusLG : GrokDesignSystem.radiusSM,
                    ),
                    bottomRight: Radius.circular(
                      isUser ? GrokDesignSystem.radiusSM : GrokDesignSystem.radiusLG,
                    ),
                  ),
                  border: !isUser
                      ? Border.all(
                          color: GrokDesignSystem.chatAIBorder,
                          width: 1,
                        )
                      : null,
                  boxShadow: GrokDesignSystem.chatBubbleShadow,
                ),
                child: Text(
                  message.content,
                  style: isUser
                      ? GrokDesignSystem.userMessageText(isMobile: isMobile)
                      : GrokDesignSystem.aiMessageText(isMobile: isMobile),
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: GrokDesignSystem.spacingSM),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: GrokDesignSystem.backgroundLightGray,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: GrokDesignSystem.textPrimary,
                  size: 18,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: GrokDesignSystem.animationFast).slideY(
          begin: 0.1,
          duration: GrokDesignSystem.animationFast,
        );
  }

  Widget _buildLoadingMessage() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: GrokDesignSystem.spacingMD),
        padding: const EdgeInsets.all(GrokDesignSystem.spacingLG),
        decoration: BoxDecoration(
          color: GrokDesignSystem.chatAIBubble,
          borderRadius: BorderRadius.circular(GrokDesignSystem.radiusLG),
          border: Border.all(
            color: GrokDesignSystem.chatAIBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(GrokDesignSystem.primaryCharcoal),
              ),
            ),
            const SizedBox(width: GrokDesignSystem.spacingMD),
            Text(
              'Thinking...',
              style: GrokDesignSystem.bodyMedium().copyWith(
                fontStyle: FontStyle.italic,
                color: GrokDesignSystem.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(
        isMobile ? GrokDesignSystem.spacingMD : GrokDesignSystem.spacingLG,
      ),
      decoration: const BoxDecoration(
        color: GrokDesignSystem.backgroundWhite,
        border: Border(
          top: BorderSide(
            color: GrokDesignSystem.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Image Upload Button (optional)
          if (widget.onImageUpload != null) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onImageUpload,
                borderRadius: BorderRadius.circular(GrokDesignSystem.radiusMD),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: GrokDesignSystem.backgroundLightGray,
                    borderRadius: BorderRadius.circular(GrokDesignSystem.radiusMD),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    size: GrokDesignSystem.iconSize,
                    color: GrokDesignSystem.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: GrokDesignSystem.spacingSM),
          ],
          
          // Text Input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: GrokDesignSystem.backgroundLightGray,
                borderRadius: BorderRadius.circular(GrokDesignSystem.radiusMD),
                border: Border.all(
                  color: GrokDesignSystem.borderLight,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: GrokDesignSystem.bodyMedium(),
                decoration: InputDecoration(
                  hintText: 'Ask about fashion, outfits, styling...',
                  hintStyle: GrokDesignSystem.bodyMedium().copyWith(
                    color: GrokDesignSystem.textTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: GrokDesignSystem.spacingMD,
                    vertical: GrokDesignSystem.spacingMD,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: GrokDesignSystem.spacingSM),
          
          // Send Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _sendMessage,
              borderRadius: BorderRadius.circular(GrokDesignSystem.radiusMD),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: GrokDesignSystem.primaryCharcoal,
                  borderRadius: BorderRadius.all(Radius.circular(GrokDesignSystem.radiusMD)),
                ),
                child: const Icon(
                  Icons.send,
                  color: GrokDesignSystem.textInverse,
                  size: GrokDesignSystem.iconSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


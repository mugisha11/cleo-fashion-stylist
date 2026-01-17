import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/grok_design_system.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/models/outfit_model.dart';
import '../../../core/services/fashion_prompt_service.dart';
import '../widgets/outfit_card.dart';

/// Enhanced Fashion Chat Workspace
/// Handles fashion prompts, displays outfits inline, integrates try-on
class EnhancedFashionChatWorkspace extends ConsumerStatefulWidget {
  final List<ChatMessage> messages;
  final Function(String) onSendMessage;
  final Function()? onImageUpload;
  final bool isLoading;

  const EnhancedFashionChatWorkspace({
    super.key,
    required this.messages,
    required this.onSendMessage,
    this.onImageUpload,
    this.isLoading = false,
  });

  @override
  ConsumerState<EnhancedFashionChatWorkspace> createState() => _EnhancedFashionChatWorkspaceState();
}

class _EnhancedFashionChatWorkspaceState extends ConsumerState<EnhancedFashionChatWorkspace> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, List<OutfitRecommendation>> _outfitCache = {};

  final List<String> _fashionPrompts = [
    'What should I wear today?',
    'Style me for a wedding',
    'Use only my wardrobe',
    'Try this outfit on me',
    'Show me modern streetwear',
    'Pick outfit for event',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleFashionPrompt(String prompt) async {
    try {
      final promptService = ref.read(fashionPromptServiceProvider);
      
      // Classify intent
      final intent = await promptService.classifyIntent(prompt);
      
      // Extract details
      final occasion = promptService.extractOccasion(prompt);
      final styleKeywords = promptService.extractStyleKeywords(prompt);
      final wardrobeOnly = intent == FashionIntent.wardrobeOnly;

      // Send user message
      widget.onSendMessage(prompt);

      // Generate outfit recommendations
      final result = await promptService.generateOutfitRecommendations(
        prompt: prompt,
        intent: intent,
        occasion: occasion,
        styleKeywords: styleKeywords,
        wardrobeOnly: wardrobeOnly,
      );

      // Cache outfits for this message
      if (result['outfits'] != null) {
        final outfits = (result['outfits'] as List)
            .map((o) => OutfitRecommendation.fromJson(o))
            .toList();
        
        final messageId = 'msg-${DateTime.now().millisecondsSinceEpoch}';
        _outfitCache[messageId] = outfits;
      }
    } catch (e) {
      // Show error message
      widget.onSendMessage('Error: $e');
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Check if it's a fashion prompt
    final lowerText = text.toLowerCase();
    final isFashionPrompt = lowerText.contains('wear') ||
        lowerText.contains('outfit') ||
        lowerText.contains('style') ||
        lowerText.contains('try on') ||
        lowerText.contains('wardrobe') ||
        lowerText.contains('occasion');

    if (isFashionPrompt) {
      _handleFashionPrompt(text);
    } else {
      widget.onSendMessage(text);
    }

    _messageController.clear();
    
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

  Future<void> _handleTryOn(OutfitRecommendation outfit) async {
    try {
      final promptService = ref.read(fashionPromptServiceProvider);
      
      // Request user photo if needed
      // For now, use existing avatar or request photo
      final resultUrl = await promptService.requestTryOn(
        outfitImageUrl: outfit.imageUrl,
        userPhotoUrl: null, // TODO: Get from user profile or request
      );

      // Show try-on result
      if (mounted) {
        Navigator.of(context).pushNamed(
          '/tryon-preview',
          arguments: {'resultUrl': resultUrl},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Try-on failed: $e'),
            backgroundColor: GrokDesignSystem.error,
          ),
        );
      }
    }
  }

  void _handleLike(OutfitRecommendation outfit) {
    final promptService = ref.read(fashionPromptServiceProvider);
    promptService.saveOutfitFeedback(
      outfitId: outfit.id,
      liked: true,
    );
  }

  void _handleDislike(OutfitRecommendation outfit) {
    final promptService = ref.read(fashionPromptServiceProvider);
    promptService.saveOutfitFeedback(
      outfitId: outfit.id,
      liked: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: GrokDesignSystem.backgroundOffWhite,
      child: Column(
        children: [
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
                      final message = widget.messages[index];
                      final messageId = message.id;
                      final outfits = _outfitCache[messageId];
                      
                      return Column(
                        children: [
                          _buildMessageBubble(message, isMobile),
                          if (outfits != null && outfits.isNotEmpty) ...[
                            const SizedBox(height: GrokDesignSystem.spacingMD),
                            _buildOutfitDisplay(outfits, isMobile),
                          ],
                        ],
                      );
                    },
                  ),
          ),

          if (widget.messages.isEmpty) _buildSuggestionsChips(isMobile),

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
        onTap: () => _handleFashionPrompt(label),
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

  Widget _buildOutfitDisplay(List<OutfitRecommendation> outfits, bool isMobile) {
    return Container(
      height: 500,
      margin: const EdgeInsets.only(bottom: GrokDesignSystem.spacingMD),
      child: SwipeableOutfitList(
        outfits: outfits,
        onTryOn: _handleTryOn,
        onLike: _handleLike,
        onDislike: _handleDislike,
      ),
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


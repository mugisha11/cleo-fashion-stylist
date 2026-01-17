import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/dashboard_design_system.dart';
import '../../../core/models/chat_model.dart';

/// AI Chat Workspace - ChatGPT Style
class AIChatWorkspace extends StatefulWidget {
  final List<ChatMessage> messages;
  final Function(String) onSendMessage;
  final Function()? onImageUpload;
  final Function()? onVoiceInput;
  final bool isLoading;

  const AIChatWorkspace({
    super.key,
    required this.messages,
    required this.onSendMessage,
    this.onImageUpload,
    this.onVoiceInput,
    this.isLoading = false,
  });

  @override
  State<AIChatWorkspace> createState() => _AIChatWorkspaceState();
}

class _AIChatWorkspaceState extends State<AIChatWorkspace> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      color: DashboardDesignSystem.surfaceOffWhite,
      child: Column(
        children: [
          // Messages Area
          Expanded(
            child: widget.messages.isEmpty
                ? _buildEmptyState(isMobile)
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(
                      isMobile
                          ? DashboardDesignSystem.spacingMD
                          : DashboardDesignSystem.spacingLG,
                    ),
                    itemCount: widget.messages.length + (widget.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == widget.messages.length && widget.isLoading) {
                        return _buildLoadingMessage();
                      }
                      return _buildMessageBubble(
                        widget.messages[index],
                        isMobile,
                      );
                    },
                  ),
          ),

          // Input Area
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: DashboardDesignSystem.secondaryLavender.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.style,
              size: 40,
              color: DashboardDesignSystem.secondaryLavender,
            ),
          ),
          const SizedBox(height: DashboardDesignSystem.spacingLG),
          Text(
            'Your AI Fashion Stylist',
            style: DashboardDesignSystem.headlineMedium(isMobile: isMobile),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DashboardDesignSystem.spacingSM),
          Text(
            'Ask me anything about fashion, outfits, or styling!',
            style: DashboardDesignSystem.bodyMedium(isMobile: isMobile),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DashboardDesignSystem.spacingXL),
          Wrap(
            spacing: DashboardDesignSystem.spacingSM,
            runSpacing: DashboardDesignSystem.spacingSM,
            alignment: WrapAlignment.center,
            children: [
              _buildQuickActionChip('Suggest an outfit', () {
                widget.onSendMessage('Suggest an outfit');
              }),
              _buildQuickActionChip('What should I wear today?', () {
                widget.onSendMessage('What should I wear today?');
              }),
              _buildQuickActionChip('Analyze my wardrobe', () {
                widget.onSendMessage('Analyze my wardrobe');
              }),
              _buildQuickActionChip('Color palette suggestions', () {
                widget.onSendMessage('Color palette suggestions');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusLG),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DashboardDesignSystem.spacingMD,
            vertical: DashboardDesignSystem.spacingSM,
          ),
          decoration: BoxDecoration(
            color: DashboardDesignSystem.sidebarBackground,
            borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusLG),
            border: Border.all(
              color: DashboardDesignSystem.borderLight,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: DashboardDesignSystem.textCharcoal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMobile) {
    final isUser = message.role == 'user';
    final timestamp = _formatTimestamp(message.createdAt);
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: DashboardDesignSystem.spacingMD),
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 600,
        ),
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: DashboardDesignSystem.secondaryLavender,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.style,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: DashboardDesignSystem.spacingSM),
            ],
            Flexible(
              child: Container(
                padding: EdgeInsets.all(
                  isMobile
                      ? DashboardDesignSystem.spacingMD
                      : DashboardDesignSystem.spacingLG,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? DashboardDesignSystem.chatUserBubble
                      : DashboardDesignSystem.chatAIBubble,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(DashboardDesignSystem.radiusLG),
                    topRight: const Radius.circular(DashboardDesignSystem.radiusLG),
                    bottomLeft: Radius.circular(
                      isUser ? DashboardDesignSystem.radiusLG : DashboardDesignSystem.radiusSM,
                    ),
                    bottomRight: Radius.circular(
                      isUser ? DashboardDesignSystem.radiusSM : DashboardDesignSystem.radiusLG,
                    ),
                  ),
                  border: !isUser
                      ? Border.all(
                          color: DashboardDesignSystem.chatAIBorder.withValues(alpha: 0.2),
                          width: 1,
                        )
                      : null,
                  boxShadow: DashboardDesignSystem.chatBubbleShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 15 : 16,
                        fontWeight: FontWeight.normal,
                        color: isUser
                            ? Colors.white
                            : DashboardDesignSystem.textCharcoal,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: DashboardDesignSystem.spacingXS),
                    Text(
                      timestamp,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isUser
                            ? Colors.white70
                            : DashboardDesignSystem.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: DashboardDesignSystem.spacingSM),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: DashboardDesignSystem.primaryNavy,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(
          begin: 0.2,
          duration: 300.ms,
        );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Widget _buildLoadingMessage() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: DashboardDesignSystem.spacingMD),
        padding: const EdgeInsets.all(DashboardDesignSystem.spacingLG),
        decoration: BoxDecoration(
          color: DashboardDesignSystem.chatAIBubble,
          borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusLG),
          border: Border.all(
            color: DashboardDesignSystem.chatAIBorder.withValues(alpha: 0.2),
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
                valueColor: AlwaysStoppedAnimation<Color>(
                  DashboardDesignSystem.secondaryLavender,
                ),
              ),
            ),
            const SizedBox(width: DashboardDesignSystem.spacingMD),
            Text(
              'AI is thinking...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: DashboardDesignSystem.textSecondary,
                fontStyle: FontStyle.italic,
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
        isMobile
            ? DashboardDesignSystem.spacingMD
            : DashboardDesignSystem.spacingLG,
      ),
      decoration: BoxDecoration(
        color: DashboardDesignSystem.sidebarBackground,
        border: Border(
          top: BorderSide(
            color: DashboardDesignSystem.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Image Upload Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onImageUpload,
              borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusMD),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DashboardDesignSystem.surfaceOffWhite,
                  borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusMD),
                ),
                child: Icon(
                  Icons.image_outlined,
                  size: 20,
                  color: DashboardDesignSystem.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: DashboardDesignSystem.spacingSM),
          
          // Text Input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: DashboardDesignSystem.surfaceOffWhite,
                borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusMD),
                border: Border.all(
                  color: DashboardDesignSystem.borderLight,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask about fashion, outfits, styling...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: DashboardDesignSystem.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DashboardDesignSystem.spacingMD,
                    vertical: DashboardDesignSystem.spacingMD,
                  ),
                ),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: DashboardDesignSystem.textCharcoal,
                ),
              ),
            ),
          ),
          const SizedBox(width: DashboardDesignSystem.spacingSM),
          
          // Voice Input Button (Optional)
          if (widget.onVoiceInput != null) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onVoiceInput,
                borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusMD),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: DashboardDesignSystem.surfaceOffWhite,
                    borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusMD),
                  ),
                  child: Icon(
                    Icons.mic_outlined,
                    size: 20,
                    color: DashboardDesignSystem.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: DashboardDesignSystem.spacingSM),
          ],
          
          // Send Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _sendMessage,
              borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusMD),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DashboardDesignSystem.accentTeal,
                  borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusMD),
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/models/chat_model.dart';
import '../providers/chat_provider.dart';

/// Intelligent Chat Interface
/// Clean, minimal chat UI for AI conversations
class IntelligentChatInterface extends ConsumerStatefulWidget {
  final Function(String) onSendMessage;

  const IntelligentChatInterface({
    super.key,
    required this.onSendMessage,
  });

  @override
  ConsumerState<IntelligentChatInterface> createState() =>
      _IntelligentChatInterfaceState();
}

class _IntelligentChatInterfaceState
    extends ConsumerState<IntelligentChatInterface> {
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
    HapticFeedback.selectionClick();

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
    final theme = context.appTheme;
    final messagesAsync = ref.watch(chatMessagesProvider);

    return Container(
      color: theme.backgroundPrimary,
      child: Column(
        children: [
          // Messages
          Expanded(
            child: messagesAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: theme.primary),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading messages',
                  style: theme.bodyMedium(color: theme.textSecondary),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return _buildEmptyState(theme);
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(theme, messages[index]);
                  },
                );
              },
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.borderLight.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask me about fashion...',
                      hintStyle: theme.bodyMedium(
                        color: theme.textTertiary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.borderLight.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.borderLight.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: theme.bodyMedium(color: theme.textPrimary),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: theme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: Icon(Icons.send, color: theme.surface),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 48,
              color: theme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Start a conversation',
              style: theme.titleMedium(color: theme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me about outfits, styling tips, or what to wear',
              style: theme.bodyMedium(color: theme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AppThemeData theme, ChatMessage message) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? theme.primary : theme.surfaceElevated,
          borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: isUser ? const Radius.circular(4) : null,
                bottomLeft: !isUser ? const Radius.circular(4) : null,
              ),
        ),
        child: Text(
          message.content,
          style: theme.bodyMedium(
            color: isUser ? theme.surface : theme.textPrimary,
          ),
        ),
      ),
    );
  }
}

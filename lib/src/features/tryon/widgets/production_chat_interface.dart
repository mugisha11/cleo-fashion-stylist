/// Production Chat Interface
/// ChatGPT-like chat interface for try-on
/// Centered, expands to fullscreen on focus, supports image attachments
/// Maintains chat history for 7 days
library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/theme/design_tokens.dart';
import '../../dashboard/providers/chat_provider.dart';

class ProductionChatInterface extends ConsumerStatefulWidget {
  final ColorScheme colorScheme;
  final VoidCallback? onImageAttach;
  final VoidCallback? onTryOnRequest;

  const ProductionChatInterface({
    super.key,
    required this.colorScheme,
    this.onImageAttach,
    this.onTryOnRequest,
  });

  @override
  ConsumerState<ProductionChatInterface> createState() => _ProductionChatInterfaceState();
}

class _ProductionChatInterfaceState extends ConsumerState<ProductionChatInterface> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !_isExpanded) {
        setState(() {
          _isExpanded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = Theme.of(context).brightness == Brightness.dark
        ? DesignTokens.darkAccent
        : DesignTokens.lightAccent;
    final chatMessagesAsync = ref.watch(chatMessagesProvider);

    return Container(
      color: widget.colorScheme.surface,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: widget.colorScheme.outline.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'AI Assistant',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: widget.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_isExpanded)
                  IconButton(
                    icon: Icon(Icons.close, color: widget.colorScheme.onSurface),
                    onPressed: () {
                      _focusNode.unfocus();
                      setState(() {
                        _isExpanded = false;
                      });
                    },
                  ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: chatMessagesAsync.when(
              data: (messages) {
                // Filter messages from last 7 days
                final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
                final recentMessages = messages.where((msg) {
                  final msgDate = msg.createdAt ?? DateTime.now();
                  return msgDate.isAfter(sevenDaysAgo);
                }).toList();

                if (recentMessages.isEmpty) {
                  return _buildEmptyState(context, accent);
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: recentMessages.length,
                  itemBuilder: (context, index) {
                    return _buildMessage(recentMessages[index], theme, accent);
                  },
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: accent,
                ),
              ),
              error: (_, __) => _buildEmptyState(context, accent),
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: widget.colorScheme.outline.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                // Image attach button
                IconButton(
                  icon: Icon(Icons.image, color: accent),
                  onPressed: widget.onImageAttach,
                  tooltip: 'Attach image',
                ),
                // Text input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Ask about outfits...',
                      hintStyle: TextStyle(
                        color: widget.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: widget.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      filled: true,
                      fillColor: widget.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(color: widget.colorScheme.onSurface),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                // Send button
                IconButton(
                  icon: Icon(Icons.send, color: accent),
                  onPressed: _sendMessage,
                  tooltip: 'Send',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: widget.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: widget.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          if (widget.onTryOnRequest != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: widget.onTryOnRequest,
              icon: const Icon(Icons.checkroom),
              label: const Text('Try On Selected Items'),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: widget.colorScheme.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message, ThemeData theme, Color accent) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser
              ? accent
              : widget.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser
                ? widget.colorScheme.onPrimary
                : widget.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    _scrollToBottom();

    // Send message via chat provider
    ref.read(chatMessagesProvider.notifier).sendMessage(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}


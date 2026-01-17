import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/widgets/theme_wrapper.dart';

/// Chat Preview Card
/// Collapsible preview of AI chat with last message
class ChatPreviewCard extends StatelessWidget {
  final ChatMessage? lastMessage;
  final bool hasUnreadMessages;
  final VoidCallback onExpand;

  const ChatPreviewCard({
    super.key,
    this.lastMessage,
    this.hasUnreadMessages = false,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return GestureDetector(
      onTap: onExpand,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: 12,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.surface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasUnreadMessages
                ? theme.primary.withOpacity(0.3)
                : theme.borderLight.withOpacity(0.2),
            width: hasUnreadMessages ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.style,
                    color: theme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Fashion Stylist',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastMessage != null
                            ? _formatTimestamp(lastMessage!.createdAt)
                            : 'Ready to help',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasUnreadMessages)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.textSecondary,
                ),
              ],
            ),
            // Last message preview
            if (lastMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.backgroundPrimary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: lastMessage!.role == 'user'
                            ? theme.primary.withOpacity(0.2)
                            : theme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        lastMessage!.role == 'user'
                            ? Icons.person
                            : Icons.style,
                        size: 16,
                        color: lastMessage!.role == 'user'
                            ? theme.primary
                            : theme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        lastMessage!.content,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Text(
                'Tap to start a conversation with your AI stylist',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(
          begin: 0.1,
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
}

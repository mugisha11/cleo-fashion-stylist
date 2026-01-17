import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../providers/chat_provider.dart';
import 'intelligent_chat_interface.dart';

/// Intelligent Chat Section
/// Expandable chat interface for AI conversations
class IntelligentChatSection extends ConsumerStatefulWidget {
  final bool isExpanded;
  final VoidCallback onToggle;

  const IntelligentChatSection({
    super.key,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  ConsumerState<IntelligentChatSection> createState() =>
      _IntelligentChatSectionState();
}

class _IntelligentChatSectionState
    extends ConsumerState<IntelligentChatSection> {
  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.borderLight.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onToggle();
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
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
                          'AI Stylist Chat',
                          style: theme.titleMedium(color: theme.textPrimary)
                              .copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ask me anything about fashion',
                          style: theme.bodySmall(color: theme.textSecondary)
                              .copyWith(
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    widget.isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    color: theme.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Chat Interface (when expanded)
          if (widget.isExpanded)
            Container(
              height: 400,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.borderLight.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: IntelligentChatInterface(
                  onSendMessage: (message) {
                    ref.read(chatMessagesProvider.notifier).sendMessage(message);
                  },
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: -0.1, duration: 300.ms),
        ],
      ),
    );
  }
}

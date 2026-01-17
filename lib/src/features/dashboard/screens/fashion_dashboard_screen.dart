import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../providers/chat_provider.dart';
import '../widgets/premium_chat_interface.dart';
import '../../../routes.dart';

/// Premium AI Fashion Dashboard Content
/// ChatGPT-level intelligence, properly contained within FashionScaffold
/// This widget provides ONLY the body content - no Scaffold, no sidebar, no header
class FashionDashboardScreen extends ConsumerStatefulWidget {
  const FashionDashboardScreen({super.key});

  @override
  ConsumerState<FashionDashboardScreen> createState() => _FashionDashboardScreenState();
}

class _FashionDashboardScreenState extends ConsumerState<FashionDashboardScreen> {
  bool _isAITyping = false;
  String? _streamingText;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleSendChatMessage(String message) async {
    setState(() {
      _isAITyping = true;
      _streamingText = null;
    });
    
    HapticFeedback.lightImpact();
    
    try {
      final chatMessages = ref.read(chatMessagesProvider.notifier);
      await chatMessages.sendMessage(message);
    } catch (e) {
      if (mounted) {
        final theme = context.appTheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: theme.accentError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAITyping = false;
          _streamingText = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatMessages = ref.watch(chatMessagesProvider);
    final theme = context.appTheme;
    
    // This widget is contained within FashionScaffold's body
    // It must respect the available space and not create its own Scaffold
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: theme.backgroundGradient != null
              ? BoxDecoration(gradient: theme.backgroundGradient)
              : BoxDecoration(color: theme.backgroundPrimary),
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: chatMessages.when(
            data: (messages) => PremiumChatInterface(
              messages: messages,
              onSendMessage: _handleSendChatMessage,
              isStreaming: _isAITyping,
              streamingText: _streamingText,
              onTryOn: () => Navigator.of(context).pushNamed(Routes.tryon),
              onCalendarView: () => Navigator.of(context).pushNamed(Routes.calendar),
            ),
            loading: () => Center(
              child: CircularProgressIndicator(
                color: theme.primary,
              ),
            ),
            error: (_, __) => PremiumChatInterface(
              messages: [],
              onSendMessage: _handleSendChatMessage,
            ),
          ),
        );
      },
    );
  }
}

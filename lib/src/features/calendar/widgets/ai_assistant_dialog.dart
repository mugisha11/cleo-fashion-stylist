import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../theme/calendar_theme.dart';
import '../services/calendar_ai_integration.dart';
import '../providers/calendar_provider.dart';

/// AI Assistant Dialog - Natural language outfit planning
/// Integrated with calendar system for automatic event creation
class AIAssistantDialog extends ConsumerStatefulWidget {
  const AIAssistantDialog({super.key});

  @override
  ConsumerState<AIAssistantDialog> createState() => _AIAssistantDialogState();
}

class _AIAssistantDialogState extends ConsumerState<AIAssistantDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final List<AIMessage> _messages = [];
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      vsync: this,
      duration: CalendarTheme.mediumAnimation,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: CalendarTheme.springCurve,
      ),
    );
    
    _slideController.forward();
    
    // Initial AI greeting
    _messages.add(AIMessage(
      text: "Hi! I'm your AI style assistant. How can I help you plan your outfits?",
      isAI: true,
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(AIMessage(text: text, isAI: false));
      _textController.clear();
    });

    // Process message and check if it's a calendar request
    final aiIntegration = ref.read(calendarAIIntegrationProvider);
    final lowerText = text.toLowerCase();
    
    // Check if user wants to plan an outfit for a specific date
    if (lowerText.contains('plan') && lowerText.contains('outfit') ||
        lowerText.contains('friday') || lowerText.contains('saturday') ||
        lowerText.contains('sunday') || lowerText.contains('tomorrow')) {
      
      // Parse date from text
      final eventDate = aiIntegration.parseDateTimeFromText(text);
      final eventType = aiIntegration.extractEventType(text);
      
      if (eventDate != null) {
        // Create calendar event
        try {
          await aiIntegration.createEventFromAI(
            date: eventDate,
            outfitName: 'AI Suggested Outfit',
            outfitImageUrl: '', // Will be set when outfit is generated
            eventType: eventType,
            eventName: _extractEventName(text),
            confidenceScore: 0.85,
          );
          
          if (mounted) {
            setState(() {
              _messages.add(AIMessage(
                text: "✅ I've created a calendar event for ${_formatDate(eventDate)}! I'll suggest an outfit for that day. Would you like me to generate outfit options now?",
                isAI: true,
              ));
            });
          }
          return;
        } catch (e) {
          if (mounted) {
            setState(() {
              _messages.add(AIMessage(
                text: "I had trouble creating the calendar event. Please try again or create it manually.",
                isAI: true,
              ));
            });
          }
          return;
        }
      }
    }

    // Simulate AI response (in production, call actual AI service)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _messages.add(AIMessage(
          text: _generateAIResponse(text),
          isAI: true,
        ));
      });
    });
  }

  String _generateAIResponse(String input) {
    final lower = input.toLowerCase();
    
    if (lower.contains('friday') || lower.contains('friday night')) {
      return "I'll plan a stylish outfit for Friday night! What's the occasion? (party, dinner, casual?)";
    }
    
    if (lower.contains('retry') || lower.contains('failed')) {
      return "I can help you retry that try-on! When would you like to schedule it?";
    }
    
    if (lower.contains('outfit') && lower.contains('work')) {
      return "For work, I'd suggest something professional yet stylish. Should I show you some options?";
    }
    
    return "I understand! Let me help you with that. Can you tell me more about the event or occasion?";
  }

  String? _extractEventName(String text) {
    // Simple extraction - can be enhanced
    if (text.toLowerCase().contains('dinner')) return 'Dinner';
    if (text.toLowerCase().contains('brunch')) return 'Brunch';
    if (text.toLowerCase().contains('party')) return 'Party';
    if (text.toLowerCase().contains('meeting')) return 'Meeting';
    return null;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'today';
    }
    if (date.year == now.year && date.month == now.month && date.day == now.day + 1) {
      return 'tomorrow';
    }
    return '${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: CalendarTheme.deepShadow,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primary, theme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Style Assistant',
                          style: CalendarTheme.headlineText(color: Colors.white),
                        ),
                        Text(
                          'Plan outfits with natural language',
                          style: CalendarTheme.captionText(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
            
            // Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FashionDesignSystem.backgroundWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: "Try: 'Plan outfit for Friday night'",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: FashionDesignSystem.backgroundLight,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: CalendarTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AIMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (message.isAI) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: CalendarTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isAI
                    ? CalendarTheme.electricAccent.withOpacity(0.1)
                    : null,
                gradient: message.isAI
                    ? null
                    : CalendarTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: CalendarTheme.bodyText(
                  color: message.isAI
                      ? CalendarTheme.deepCharcoal as Color
                      : Colors.white,
                ),
              ),
            ),
          ),
          if (!message.isAI) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: FashionDesignSystem.primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: FashionDesignSystem.primaryColor,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AIMessage {
  final String text;
  final bool isAI;

  AIMessage({required this.text, required this.isAI});
}

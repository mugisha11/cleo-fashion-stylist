import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/questionnaire_service.dart';
import '../../../routes.dart';
import 'fashion_dashboard_screen.dart';

/// Main Dashboard Screen - Premium Fashion Feed + AI Stylist
/// Image-first, editorial layout, female-attractive design
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Check questionnaire and initialize conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkQuestionnaire();
      _initializeConversation();
    });
  }

  Future<void> _checkQuestionnaire() async {
    try {
      final questionnaireService = ref.read(questionnaireServiceProvider);
      final hasCompleted = await questionnaireService.hasCompletedQuestionnaire();
      
      if (!hasCompleted && mounted) {
        // Redirect to questionnaire
        Navigator.of(context).pushReplacementNamed(Routes.fashionQuestionnaire);
      }
    } catch (e) {
      // Continue to dashboard even if check fails
    }
  }

  Future<void> _initializeConversation() async {
    try {
      final chatService = ref.read(chatServiceProvider);
      final conversationId = await chatService.getOrCreateConversation();
      ref.read(conversationIdProvider.notifier).state = conversationId;
      ref.read(chatMessagesProvider.notifier).updateConversationId(conversationId);
    } catch (e) {
      debugPrint('Error initializing conversation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const FashionDashboardScreen();
  }
}

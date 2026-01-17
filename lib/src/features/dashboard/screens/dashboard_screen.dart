import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/questionnaire_service.dart';
import '../../../core/widgets/fashion_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../../../core/theme/executive_blue_theme.dart';
import '../widgets/notification_panel.dart';
import '../../../routes.dart';
import 'premium_fashion_dashboard.dart';

/// Main Dashboard Screen - Premium Fashion Feed + AI Stylist
/// Wrapped with FashionScaffold for proper layout integration
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

  void _showNotificationPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final unreadCountAsync = ref.watch(unreadCountProvider);
    const currentBottomNavIndex = 0; // Dashboard is index 0

    return FashionScaffold(
      greeting: 'AI Stylist',
      currentBottomNavIndex: currentBottomNavIndex,
      currentRoute: Routes.dashboard,
      notificationCount: unreadCountAsync.valueOrNull,
      onNotificationTap: () => _showNotificationPanel(),
      userName: currentUser?.displayName,
      userEmail: currentUser?.email,
      profileImageUrl: currentUser?.avatarUrl,
      backgroundColor: ExecutiveBlueTheme.backgroundPrimary,
      body: const PremiumFashionDashboard(),
    );
  }
}

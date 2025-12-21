import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/models/chat_model.dart';

/// Provider for current conversation ID
final conversationIdProvider = StateProvider<String?>((ref) => null);

/// Provider for chat messages
final chatMessagesProvider = StateNotifierProvider<ChatMessagesNotifier, AsyncValue<List<ChatMessage>>>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  final conversationId = ref.watch(conversationIdProvider);
  
  final notifier = ChatMessagesNotifier(chatService, conversationId);
  
  // Watch for conversation ID changes
  ref.listen(conversationIdProvider, (previous, next) {
    notifier.updateConversationId(next);
  });
  
  return notifier;
});

class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatService _chatService;
  String? _conversationId;

  ChatMessagesNotifier(this._chatService, this._conversationId) : super(const AsyncValue.loading()) {
    if (_conversationId != null) {
      _loadMessages();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  void updateConversationId(String? conversationId) {
    if (_conversationId != conversationId) {
      _conversationId = conversationId;
      if (conversationId != null) {
        _loadMessages();
      } else {
        if (mounted) {
          state = const AsyncValue.data([]);
        }
      }
    }
  }

  Future<void> _loadMessages() async {
    if (_conversationId == null) {
      if (mounted) {
        state = const AsyncValue.data([]);
      }
      return;
    }

    try {
      if (mounted) {
        state = const AsyncValue.loading();
      }
      final messages = await _chatService.getMessages(_conversationId!);
      if (mounted) {
        state = AsyncValue.data(messages);
      }
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> sendMessage(String message) async {
    if (_conversationId == null) {
      // Get or create conversation
      try {
        _conversationId = await _chatService.getOrCreateConversation();
        // Update provider
        // Note: We can't directly update another provider here, so we'll handle it in the widget
      } catch (e) {
        if (mounted) {
          state = AsyncValue.error(e, StackTrace.current);
        }
        return;
      }
    }

    try {
      // Add user message optimistically
      final currentMessages = state.value ?? [];
      final userMessage = ChatMessage(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        conversationId: _conversationId!,
        userId: _chatService.userId,
        role: 'user',
        content: message,
        createdAt: DateTime.now(),
        sequenceNumber: currentMessages.length + 1,
      );
      
      if (mounted) {
        state = AsyncValue.data([...currentMessages, userMessage]);
      }

      // Send to server and get AI response
      final aiMessage = await _chatService.sendMessage(_conversationId!, message);
      
      // Update with AI response
      if (mounted) {
        final updatedMessages = state.value ?? [];
        state = AsyncValue.data([...updatedMessages, aiMessage]);
      }
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> refresh() => _loadMessages();
}

/// Provider for loading state
final chatLoadingProvider = Provider<bool>((ref) {
  final messages = ref.watch(chatMessagesProvider);
  return messages.isLoading;
});


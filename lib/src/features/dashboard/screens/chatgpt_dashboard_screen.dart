import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../../../core/widgets/theme_wrapper.dart';
import '../providers/chat_provider.dart';
import '../widgets/chatgpt_chat_interface.dart';
import '../../../core/services/openai_service.dart';
import '../../../core/services/vton_service.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../../../core/models/chat_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../routes.dart';

/// ChatGPT-like AI Fashion Dashboard
/// Full-screen chat workspace with image support and try-on integration
class ChatGPTDashboardScreen extends ConsumerStatefulWidget {
  const ChatGPTDashboardScreen({super.key});

  @override
  ConsumerState<ChatGPTDashboardScreen> createState() => _ChatGPTDashboardScreenState();
}

class _ChatGPTDashboardScreenState extends ConsumerState<ChatGPTDashboardScreen> {
  bool _isAITyping = false;
  String? _streamingText;

  Future<void> _handleSendMessage(
    String message, {
    List<Uint8List>? images,
  }) async {
    setState(() {
      _isAITyping = true;
      _streamingText = null;
    });

    HapticFeedback.lightImpact();

    try {
      final chatMessages = ref.read(chatMessagesProvider.notifier);
      final conversationId = ref.read(conversationIdProvider);

      // If images are attached, process them first
      if (images != null && images.isNotEmpty) {
        await _handleImageMessage(message, images, chatMessages, conversationId);
      } else {
        // Regular text message
        await chatMessages.sendMessage(message);
      }
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

  Future<void> _handleImageMessage(
    String message,
    List<Uint8List> images,
    ChatMessagesNotifier chatMessages,
    String? conversationId,
  ) async {
    try {
      // Upload images to storage
      final storageService = SupabaseStorageService(Supabase.instance.client);
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final imageUrls = <String>[];
      for (int i = 0; i < images.length; i++) {
        final fileName = 'chat-images/$userId/$timestamp-$i.jpg';
        final url = await storageService.uploadFile(
          bucket: 'uploads',
          path: fileName,
          file: images[i],
          contentType: 'image/jpeg',
        );
        imageUrls.add(url);
      }

      // Get OpenAI service for image understanding
      final openAIServiceAsync = ref.read(openAIServiceProvider);
      await openAIServiceAsync.when(
        data: (openAIService) async {
          // Analyze first image with OpenAI Vision
          final imageAnalysis = await openAIService.understandFashionImage(
            imageBytes: images[0],
            userQuery: message.isNotEmpty ? message : null,
          );

          // Check if user wants try-on
          final wantsTryOn = _detectTryOnIntent(message, imageAnalysis['analysis'] as String);

          if (wantsTryOn) {
            // Trigger try-on flow
            await _handleTryOnRequest(
              imageUrls[0],
              message,
              imageAnalysis,
              chatMessages,
            );
          } else {
            // Send regular message with image analysis
            final combinedMessage = message.isNotEmpty
                ? message
                : 'Analyze this image';
            
            final analysisText = imageAnalysis['analysis'] as String;
            final fullMessage = '$combinedMessage\n\n[Image Analysis]\n$analysisText';

            // Save message with image metadata
            await _saveMessageWithImage(
              chatMessages,
              conversationId,
              combinedMessage,
              imageUrls,
              imageAnalysis,
            );

            // Get AI response
            await chatMessages.sendMessage(fullMessage);
          }
        },
        loading: () async {
          // Fallback: just send message with image URLs
          await _saveMessageWithImage(
            chatMessages,
            conversationId,
            message,
            imageUrls,
            null,
          );
          await chatMessages.sendMessage(message);
        },
        error: (error, stack) async {
          // Fallback: send message without AI analysis
          await _saveMessageWithImage(
            chatMessages,
            conversationId,
            message,
            imageUrls,
            null,
          );
          await chatMessages.sendMessage(message);
        },
      );
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }

  bool _detectTryOnIntent(String message, String analysis) {
    final lowerMessage = message.toLowerCase();
    final lowerAnalysis = analysis.toLowerCase();
    
    final tryOnKeywords = [
      'try on',
      'try-on',
      'try this',
      'try it',
      'wear this',
      'how would i look',
      'virtual try',
      'try this on',
    ];

    return tryOnKeywords.any((keyword) => 
      lowerMessage.contains(keyword) || lowerAnalysis.contains(keyword)
    );
  }

  Future<void> _handleTryOnRequest(
    String userImageUrl,
    String message,
    Map<String, dynamic> imageAnalysis,
    ChatMessagesNotifier chatMessages,
  ) async {
    try {
      setState(() {
        _streamingText = 'Analyzing your request and preparing try-on...';
      });

      // Get wardrobe items (simplified - in production, use wardrobe service)
      // For now, ask AI to suggest or use first available item
      
      // Call try-on service
      final vtonService = ref.read(vtonServiceProvider);
      
      setState(() {
        _streamingText = 'Processing virtual try-on...';
      });

      // Note: This is a simplified flow. In production, you'd:
      // 1. Let AI suggest wardrobe items based on image analysis
      // 2. User selects item or AI auto-selects best match
      // 3. Run try-on pipeline
      
      // For now, show a message that try-on is being processed
      final tryOnMessage = '''I see you'd like to try this on! 

Based on the image, I can help you:
1. Find matching items from your wardrobe
2. Run a virtual try-on
3. Suggest styling options

Would you like me to proceed with the try-on?''';

      await chatMessages.sendMessage(tryOnMessage);
    } catch (e) {
      throw Exception('Failed to process try-on request: $e');
    }
  }

  Future<void> _saveMessageWithImage(
    ChatMessagesNotifier chatMessages,
    String? conversationId,
    String message,
    List<String> imageUrls,
    Map<String, dynamic>? analysis,
  ) async {
    // This would be handled by the chat service
    // For now, we'll let the regular sendMessage handle it
    // In production, extend ChatService to support image messages
  }

  void _handleTryOnRequestFromMessage(String imageUrl) {
    Navigator.of(context).pushNamed(
      Routes.tryon,
      arguments: {'imageUrl': imageUrl},
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatMessages = ref.watch(chatMessagesProvider);
    final theme = context.appTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: theme.backgroundGradient != null
              ? BoxDecoration(gradient: theme.backgroundGradient)
              : BoxDecoration(color: theme.backgroundPrimary),
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: chatMessages.when(
            data: (messages) => ChatGPTChatInterface(
              messages: messages,
              onSendMessage: _handleSendMessage,
              isStreaming: _isAITyping,
              streamingText: _streamingText,
              onTryOnRequest: _handleTryOnRequestFromMessage,
            ),
            loading: () => Center(
              child: CircularProgressIndicator(
                color: theme.primary,
              ),
            ),
            error: (_, __) => ChatGPTChatInterface(
              messages: [],
              onSendMessage: _handleSendMessage,
              onTryOnRequest: _handleTryOnRequestFromMessage,
            ),
          ),
        );
      },
    );
  }
}

// Provider for VTON Service
final vtonServiceProvider = Provider<VTONService>((ref) {
  return VTONService(
    Supabase.instance.client,
    FirebaseAuth.instance,
  );
});

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/chat_model.dart';
import 'multilingual_nlu_service.dart';
import 'fashion_ai_chat_service.dart';
import '../../features/dashboard/providers/ai_providers.dart' show multilingualNLUServiceProvider;

/// Chat service for AI conversations with persistent storage
class ChatService {
  final SupabaseClient _supabase;
  final FirebaseAuth _auth;
  final MultilingualNLUService? _nluService;

  ChatService(this._supabase, this._auth, [this._nluService]);

  String get _userId => _auth.currentUser?.uid ?? '';
  
  // Expose userId for provider access
  String get userId => _userId;

  /// Get or create current conversation
  Future<String> getOrCreateConversation() async {
    try {
      // Try to get most recent conversation
      final response = await _supabase
          .from('chat_conversations')
          .select()
          .eq('user_id', _userId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return response['id'] as String;
      }

      // Create new conversation
      final newConv = await _supabase
          .from('chat_conversations')
          .insert({
            'user_id': _userId,
            'title': 'New Chat',
          })
          .select()
          .single();

      return newConv['id'] as String;
    } catch (e) {
      throw Exception('Failed to get/create conversation: $e');
    }
  }

  /// Get conversation messages
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('sequence_number');

      return (response as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  /// Send user message and get AI response
  Future<ChatMessage> sendMessage(String conversationId, String userMessage) async {
    try {
      // Process multilingual input
      String processedMessage = userMessage;
      if (_nluService != null) {
        try {
          processedMessage = await _nluService!.processQuery(userMessage);
        } catch (e) {
          // Continue with original message if NLU fails
        }
      }

      // Get conversation history
      final history = await getMessages(conversationId);
      
      // Get next sequence number
      final nextSequence = history.length + 1;

      // Save user message
      final userMsgResponse = await _supabase
          .from('chat_messages')
          .insert({
            'conversation_id': conversationId,
            'user_id': _userId,
            'role': 'user',
            'content': processedMessage,
            'sequence_number': nextSequence,
          })
          .select()
          .single();

      final userMessageObj = ChatMessage.fromJson(userMsgResponse);

      // Try to use Supabase Edge Function first (no local server needed)
      // Fallback to local FastAPI server if Edge Function not available
      String? aiContent;
      Map<String, dynamic>? metadata;
      
      try {
        // Option 1: Use Supabase Edge Function (recommended - no local server needed)
        try {
          final edgeFunctionResponse = await _supabase.functions.invoke(
            'chat-completion',
            body: {
              'conversation_id': conversationId,
              'user_id': _userId,
              'message': processedMessage,
              'history': history.map((m) => <String, String>{
                'role': m.role,
                'content': m.content,
              }).toList(),
            },
          );
          
          if (edgeFunctionResponse.status == 200) {
            final data = edgeFunctionResponse.data as Map<String, dynamic>;
            aiContent = data['content'] as String?;
            metadata = data['metadata'] as Map<String, dynamic>?;
          }
        } catch (e) {
          // Edge function not available, try local server
          throw Exception('Edge function failed, trying local server');
        }
      } catch (_) {
        // Option 2: Fallback to local FastAPI server
        try {
          const apiBaseUrl = 'http://localhost:8000';
          
          final requestBody = {
            'conversation_id': conversationId,
            'user_id': _userId,
            'message': processedMessage,
            'history': history.map((m) => <String, String>{
              'role': m.role,
              'content': m.content,
            }).toList(),
          };

          final response = await http.post(
            Uri.parse('$apiBaseUrl/chat/completion'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode != 200) {
            throw Exception('Server returned ${response.statusCode}');
          }

          final aiData = jsonDecode(response.body) as Map<String, dynamic>;
          aiContent = aiData['content'] as String;
          metadata = aiData['metadata'] as Map<String, dynamic>?;
        } catch (e) {
          // Both options failed - provide helpful error
          if (e.toString().contains('Failed to fetch') || 
              e.toString().contains('Connection refused') ||
              e.toString().contains('NetworkException')) {
            throw Exception(
              'Chat service unavailable. Please ensure:\n'
              '1. Supabase Edge Function "chat-completion" is deployed, OR\n'
              '2. Local FastAPI server is running on port 8000\n\n'
              'To start local server: cd server/api && python -m uvicorn main:app --reload --port 8000'
            );
          }
          rethrow;
        }
      }
      
      // If still no response, throw error
      if (aiContent == null || aiContent.isEmpty) {
        throw Exception('AI service returned empty response. Please try again.');
      }

      // Save AI response
      final aiMsgResponse = await _supabase
          .from('chat_messages')
          .insert({
            'conversation_id': conversationId,
            'user_id': _userId,
            'role': 'assistant',
            'content': aiContent,
            'metadata': metadata,
            'sequence_number': nextSequence + 1,
          })
          .select()
          .single();

      return ChatMessage.fromJson(aiMsgResponse);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get all user conversations
  Future<List<ChatConversation>> getConversations() async {
    try {
      final response = await _supabase
          .from('chat_conversations')
          .select()
          .eq('user_id', _userId)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => ChatConversation.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load conversations: $e');
    }
  }

  /// Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _supabase
          .from('chat_conversations')
          .delete()
          .eq('id', conversationId)
          .eq('user_id', _userId);
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }
}

/// Provider for ChatService
final chatServiceProvider = Provider<ChatService>((ref) {
  final supabase = Supabase.instance.client;
  final auth = FirebaseAuth.instance;
  try {
    final nluService = ref.watch(multilingualNLUServiceProvider);
    return ChatService(supabase, auth, nluService);
  } catch (e) {
    // Fallback if NLU provider not available
    return ChatService(supabase, auth, null);
  }
});


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/chat_model.dart';
import '../models/social_user_profile.dart';
import '../providers/social_provider.dart';
import '../../../routes.dart';
import 'chat_screen.dart';

/// List of chats (DMs). Only with accepted friends.
class ChatsListScreen extends ConsumerWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final chatsAsync = ref.watch(chatsListProvider);
    final isDark = context.isDarkMode;
    final accent = isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent;

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? DesignTokens.darkBackground : DesignTokens.lightBackground,
        appBar: AppBar(title: const Text('Messages'), backgroundColor: Colors.transparent),
        body: const Center(child: Text('Sign in to see messages')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? DesignTokens.darkBackground : DesignTokens.lightBackground,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? DesignTokens.darkText : DesignTokens.lightText,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => Navigator.of(context).pushNamed(Routes.friendRequests),
            tooltip: 'Friend requests',
          ),
        ],
      ),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 64, color: accent.withValues(alpha: 0.6)),
                  const SizedBox(height: 16),
                  Text('No messages yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? DesignTokens.darkText : DesignTokens.lightText)),
                  const SizedBox(height: 8),
                  Text('Chat with friends after you connect', style: TextStyle(color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherId = chat.otherUserId(user.uid);
              return _ChatTile(chat: chat, otherUserId: otherId, currentUserId: user.uid, isDark: isDark, accent: accent);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  final ChatModel chat;
  final String otherUserId;
  final String currentUserId;
  final bool isDark;
  final Color accent;

  const _ChatTile({required this.chat, required this.otherUserId, required this.currentUserId, required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<SocialUserProfile?>(
      future: ref.read(socialServiceProvider).getUserProfile(otherUserId),
      builder: (context, snap) {
        final profile = snap.data;
        final name = profile?.name ?? 'User';
        final avatar = profile?.avatarUrl;
        final isFromMe = chat.lastSenderId == currentUserId;
        return ListTile(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ChatScreen(chatId: chat.id, otherUserId: otherUserId, otherUserName: name, otherUserAvatar: avatar),
              ),
            );
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard),
            clipBehavior: Clip.antiAlias,
            child: avatar != null && avatar.startsWith('http')
                ? Image.network(avatar, fit: BoxFit.cover, width: 56, height: 56, errorBuilder: (_, __, ___) => Icon(Icons.person, color: accent))
                : Icon(Icons.person, color: accent),
          ),
          title: Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? DesignTokens.darkText : DesignTokens.lightText)),
          subtitle: Text(
            chat.lastMessage ?? 'No messages yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary),
          ),
        ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.03, end: 0, curve: Curves.easeOut);
      },
    );
  }
}

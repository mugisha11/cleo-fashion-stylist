import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/chat_message_model.dart';
import '../providers/social_provider.dart';
import '../services/social_service.dart';

/// Single chat: message bubbles, input, image/tryon support.
/// Pass [chatId] when known, or leave null to resolve from [otherUserId].
class ChatScreen extends ConsumerStatefulWidget {
  final String? chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatScreen({
    super.key,
    this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _resolvedChatId;
  bool _resolveError = false;

  String? get _effectiveChatId => widget.chatId ?? _resolvedChatId;

  @override
  void initState() {
    super.initState();
    if (widget.chatId == null) _resolveChatId();
  }

  Future<void> _resolveChatId() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      final id = await ref.read(socialServiceProvider).getOrCreateChat(user.uid, widget.otherUserId);
      if (mounted) setState(() {
        _resolvedChatId = id;
        _resolveError = false;
      });
    } catch (e) {
      if (mounted) setState(() => _resolveError = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final chatId = _effectiveChatId;
    final messagesAsync = chatId != null ? ref.watch(chatMessagesProvider(chatId)) : const AsyncValue.loading();
    final isDark = context.isDarkMode;
    final accent = isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    final surface = isDark ? DesignTokens.darkSurface : DesignTokens.lightSurface;
    final bubbleMe = accent;
    final bubbleOther = isDark ? DesignTokens.darkCard : DesignTokens.lightCard;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Sign in to chat')));
    }
    if (_resolveError) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.otherUserName)),
        body: const Center(child: Text('Could not open chat')),
      );
    }
    if (chatId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.otherUserName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? DesignTokens.darkBackground : DesignTokens.lightBackground,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: surface,
              backgroundImage: widget.otherUserAvatar != null && widget.otherUserAvatar!.startsWith('http')
                  ? NetworkImage(widget.otherUserAvatar!)
                  : null,
              child: widget.otherUserAvatar == null || !widget.otherUserAvatar!.startsWith('http')
                  ? Icon(Icons.person, size: 22, color: accent)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.otherUserName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? DesignTokens.darkText : DesignTokens.lightText,
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hi!',
                      style: TextStyle(color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary),
                    ),
                  );
                }
                ref.read(socialServiceProvider).markMessagesSeen(chatId, user.uid);
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final showDate = index == 0 || _differentDay(messages[index - 1].createdAt, msg.createdAt);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDate) _DateSeparator(date: msg.createdAt, isDark: isDark),
                        _MessageBubble(
                          message: msg,
                          isMe: msg.senderId == user.uid,
                          bubbleMe: bubbleMe,
                          bubbleOther: bubbleOther,
                          isDark: isDark,
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          _InputBar(
            controller: _controller,
            accent: accent,
            isDark: isDark,
            onSend: () => _send(ref, user.uid),
            onAttachImage: () => _attachImage(ref, user.uid),
          ),
        ],
      ),
    );
  }

  bool _differentDay(DateTime a, DateTime b) {
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }

  Future<void> _send(WidgetRef ref, String uid) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final chatId = _effectiveChatId;
    if (chatId == null) return;
    _controller.clear();
    HapticFeedback.mediumImpact();
    final senderName = ref.read(currentUserProvider).valueOrNull?.displayName ?? 'Someone';
    await ref.read(socialServiceProvider).sendMessage(
      chatId,
      uid,
      text,
      senderName: senderName,
    );
  }

  void _attachImage(WidgetRef ref, String uid) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image picker: use gallery to share try-on'), behavior: SnackBarBehavior.floating),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  final bool isDark;

  const _DateSeparator({required this.date, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            DateFormat.MMMd().format(date),
            style: TextStyle(fontSize: 12, color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final Color bubbleMe;
  final Color bubbleOther;
  final bool isDark;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.bubbleMe,
    required this.bubbleOther,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isMe ? bubbleMe : bubbleOther,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.isImage && message.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(message.imageUrl!, width: 200, height: 200, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, color: isMe ? Colors.white70 : DesignTokens.lightTextSecondary)),
              ),
            if (message.isImage && message.imageUrl != null && message.text.isNotEmpty) const SizedBox(height: 8),
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  color: isMe ? Colors.white : (isDark ? DesignTokens.darkText : DesignTokens.lightText),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat.jm().format(message.createdAt),
                  style: TextStyle(fontSize: 11, color: isMe ? Colors.white70 : DesignTokens.lightTextSecondary),
                ),
                if (isMe && message.seen) ...[const SizedBox(width: 4), Icon(Icons.done_all, size: 14, color: Colors.white70)],
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 150.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final Color accent;
  final bool isDark;
  final VoidCallback onSend;
  final VoidCallback onAttachImage;

  const _InputBar({
    required this.controller,
    required this.accent,
    required this.isDark,
    required this.onSend,
    required this.onAttachImage,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? DesignTokens.darkSurface : DesignTokens.lightSurface;
    final border = isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(color: surface, border: Border(top: BorderSide(color: border))),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: onAttachImage,
              icon: Icon(Icons.image_outlined, color: accent),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary),
                  filled: true,
                  fillColor: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                style: TextStyle(color: isDark ? DesignTokens.darkText : DesignTokens.lightText),
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: accent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: onSend,
                borderRadius: BorderRadius.circular(24),
                child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.send_rounded, color: Colors.white, size: 24)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

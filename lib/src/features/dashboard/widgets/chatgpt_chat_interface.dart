import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'dart:typed_data';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';

/// ChatGPT-like AI Chat Interface
/// Premium, minimal, distraction-free chat workspace
class ChatGPTChatInterface extends StatefulWidget {
  final List<ChatMessage> messages;
  final Function(String message, {List<Uint8List>? images}) onSendMessage;
  final bool isStreaming;
  final String? streamingText;
  final Function(String imageUrl)? onTryOnRequest;

  const ChatGPTChatInterface({
    super.key,
    required this.messages,
    required this.onSendMessage,
    this.isStreaming = false,
    this.streamingText,
    this.onTryOnRequest,
  });

  @override
  State<ChatGPTChatInterface> createState() => _ChatGPTChatInterfaceState();
}

class _ChatGPTChatInterfaceState extends State<ChatGPTChatInterface> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  List<Uint8List> _attachedImages = [];
  bool _isComposing = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _attachedImages.add(bytes);
        });
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _attachedImages.removeAt(index);
    });
    HapticFeedback.lightImpact();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty && _attachedImages.isEmpty) return;

    widget.onSendMessage(text, images: _attachedImages.isNotEmpty ? _attachedImages : null);
    _messageController.clear();
    setState(() {
      _attachedImages.clear();
      _isComposing = false;
    });
    _scrollToBottom();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: theme.backgroundPrimary,
      child: Column(
        children: [
          // Messages Area
          Expanded(
            child: widget.messages.isEmpty
                ? _buildEmptyState(theme, isMobile)
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 24,
                      vertical: 24,
                    ),
                    itemCount: widget.messages.length + (widget.isStreaming ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == widget.messages.length && widget.isStreaming) {
                        return _buildStreamingMessage(theme);
                      }
                      return _buildMessageBubble(widget.messages[index], theme, isMobile);
                    },
                  ),
          ),

          // Attached Images Preview
          if (_attachedImages.isNotEmpty) _buildImagePreview(theme),

          // Input Area
          _buildInputArea(theme, isMobile),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppThemeData theme, bool isMobile) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.style,
                size: 32,
                color: theme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your AI Fashion Stylist',
              style: TextStyle(
                fontSize: isMobile ? 24 : 28,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Ask me anything about fashion, outfits, or styling.\nUpload images to try on clothes or get styling advice.',
              style: TextStyle(
                fontSize: isMobile ? 15 : 16,
                color: theme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickActionChip('Suggest an outfit', theme, () {
                  _messageController.text = 'Suggest an outfit';
                  _sendMessage();
                }),
                _buildQuickActionChip('What should I wear today?', theme, () {
                  _messageController.text = 'What should I wear today?';
                  _sendMessage();
                }),
                _buildQuickActionChip('Analyze my wardrobe', theme, () {
                  _messageController.text = 'Analyze my wardrobe';
                  _sendMessage();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChip(String label, AppThemeData theme, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.borderLight.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, AppThemeData theme, bool isMobile) {
    final isUser = message.role == 'user';
    final hasImage = message.metadata?['image_url'] != null ||
        message.metadata?['image_base64'] != null;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 700,
        ),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.style,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUser ? theme.primary : theme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 20 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasImage) _buildMessageImage(message, theme),
                        if (message.content.isNotEmpty) ...[
                          if (hasImage) const SizedBox(height: 12),
                          Text(
                            message.content,
                            style: TextStyle(
                              fontSize: isMobile ? 15 : 16,
                              color: isUser ? Colors.white : theme.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ],
                        // Try-on result actions
                        if (message.metadata?['tryon_result'] != null)
                          _buildTryOnResult(message, theme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textSecondary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 12),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: theme.primary,
                  size: 18,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(
          begin: 0.2,
          duration: 300.ms,
        );
  }

  Widget _buildMessageImage(ChatMessage message, AppThemeData theme) {
    String? imageUrl = message.metadata?['image_url'] as String?;
    String? imageBase64 = message.metadata?['image_base64'] as String?;

    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    } else if (imageBase64 != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          base64Decode(imageBase64),
          width: 200,
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTryOnResult(ChatMessage message, AppThemeData theme) {
    final resultUrl = message.metadata?['tryon_result'] as String?;
    if (resultUrl == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: resultUrl,
            width: 300,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _buildActionButton('Save to Calendar', theme, () {
              // TODO: Save to calendar
            }),
            _buildActionButton('Save to Favorites', theme, () {
              // TODO: Save to favorites
            }),
            _buildActionButton('Try Another', theme, () {
              widget.onTryOnRequest?.call(resultUrl);
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, AppThemeData theme, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreamingMessage(AppThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.streamingText ?? 'AI is thinking...',
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(AppThemeData theme) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surface.withOpacity(0.5),
        border: Border(
          top: BorderSide(color: theme.borderLight.withOpacity(0.3)),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _attachedImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _attachedImages[index],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea(AppThemeData theme, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.surface.withOpacity(0.8),
        border: Border(
          top: BorderSide(
            color: theme.borderLight.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Image Attachment Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.borderLight.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    size: 20,
                    color: theme.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Text Input
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.borderLight.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  onChanged: (text) {
                    setState(() {
                      _isComposing = text.trim().isNotEmpty || _attachedImages.isNotEmpty;
                    });
                  },
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Message AI Stylist...',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: theme.textSecondary.withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Send Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isComposing ? _sendMessage : null,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isComposing ? theme.primary : theme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isComposing
                          ? theme.primary
                          : theme.borderLight.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.send,
                    size: 20,
                    color: _isComposing ? Colors.white : theme.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

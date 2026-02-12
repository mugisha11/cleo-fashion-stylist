import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/models/generated_outfit_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tryon/utils/save_tryon_result_io.dart' if (dart.library.io) '../../tryon/utils/save_tryon_result_stub.dart' as save_tryon_result;
import '../models/chat_model.dart';
import '../providers/social_provider.dart';
import '../../../routes.dart';

/// My Outfits: grid of saved generated outfits (from Try-On). Share to chats.
class GeneratedOutfitsScreen extends ConsumerWidget {
  const GeneratedOutfitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final outfitsAsync = ref.watch(generatedOutfitsProvider);
    final isDark = context.isDarkMode;
    final accent = isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    final surface = isDark ? DesignTokens.darkSurface : DesignTokens.lightSurface;

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? DesignTokens.darkBackground : DesignTokens.lightBackground,
        appBar: AppBar(title: const Text('My Outfits'), backgroundColor: Colors.transparent),
        body: const Center(child: Text('Sign in to see your outfits')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? DesignTokens.darkBackground : DesignTokens.lightBackground,
      appBar: AppBar(
        title: const Text('My Outfits'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? DesignTokens.darkText : DesignTokens.lightText,
      ),
      body: outfitsAsync.when(
        data: (outfits) {
          if (outfits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checkroom_rounded, size: 64, color: accent.withValues(alpha: 0.6)),
                  const SizedBox(height: 16),
                  Text(
                    'No outfits yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? DesignTokens.darkText : DesignTokens.lightText),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save looks from Try On to share in messages',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.tryon),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Try On'),
                    style: FilledButton.styleFrom(backgroundColor: accent),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(generatedOutfitsProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: outfits.length,
              itemBuilder: (context, index) {
                final outfit = outfits[index];
                return _OutfitCard(
                  outfit: outfit,
                  isDark: isDark,
                  accent: accent,
                  surface: surface,
                  onImageTap: () => _showFullScreenImage(context, outfit),
                  onShareToChat: () => _showShareSheet(context, ref, user.uid, outfit),
                  onDownload: () => _downloadOutfit(context, outfit),
                  onShareExternally: () => _shareOutfitExternally(context, outfit),
                  onDelete: () => _confirmDelete(context, ref, outfit),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  static void _showShareSheet(BuildContext context, WidgetRef ref, String currentUserId, GeneratedOutfitModel outfit) {
    HapticFeedback.selectionClick();
    final chatsAsync = ref.read(chatsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text('Share to', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? DesignTokens.darkText : DesignTokens.lightText)),
              const SizedBox(height: 8),
              Flexible(
                child: chatsAsync.when(
                  data: (chats) {
                    if (chats.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('No chats yet. Add a friend to share.', style: TextStyle(color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary)),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final otherId = chat.otherUserId(currentUserId);
                        return _ShareChatTile(
                          chat: chat,
                          otherUserId: otherId,
                          outfit: outfit,
                          isDark: isDark,
                          accent: accent,
                          onSent: () {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sent!'), behavior: SnackBarBehavior.floating),
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => Padding(padding: const EdgeInsets.all(24), child: Text('Error: $e')),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Downloads outfit image and saves it to device (gallery/documents) using the shared Try-On saver.
  static Future<void> _downloadOutfit(BuildContext context, GeneratedOutfitModel outfit) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saving outfit...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final uri = Uri.tryParse(outfit.imageUrl);
      if (uri == null) {
        throw Exception('Invalid image URL');
      }

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Download failed (${response.statusCode})');
      }

      final path = await save_tryon_result.saveTryOnResultToDevice(response.bodyBytes);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path != null ? 'Outfit saved to your device' : 'Outfit saved.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save outfit: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Shares outfit externally via the system share sheet (Instagram, WhatsApp, Facebook, TikTok, etc.).
  /// Opens the outfit image in a full-screen viewer. Tap image or close to dismiss.
  static void _showFullScreenImage(BuildContext context, GeneratedOutfitModel outfit) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, _, __) => _FullScreenImageView(
          imageUrl: outfit.imageUrl,
          caption: outfit.caption,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  static Future<void> _shareOutfitExternally(BuildContext context, GeneratedOutfitModel outfit) async {
    try {
      final caption = outfit.caption?.trim();
      final text = caption == null || caption.isEmpty
          ? outfit.imageUrl
          : '$caption\n${outfit.imageUrl}';

      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'My look',
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share outfit: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static Future<void> _confirmDelete(BuildContext context, WidgetRef ref, GeneratedOutfitModel outfit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove outfit?'),
        content: const Text('This will remove the outfit from My Outfits.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(generatedOutfitsServiceProvider).deleteGeneratedOutfit(outfit.id, outfit.userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Outfit removed'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}

class _OutfitCard extends StatelessWidget {
  final GeneratedOutfitModel outfit;
  final bool isDark;
  final Color accent;
  final Color surface;
  final VoidCallback onImageTap;
  final VoidCallback onShareToChat;
  final VoidCallback onDownload;
  final VoidCallback onShareExternally;
  final VoidCallback onDelete;

  const _OutfitCard({
    required this.outfit,
    required this.isDark,
    required this.accent,
    required this.surface,
    required this.onImageTap,
    required this.onShareToChat,
    required this.onDownload,
    required this.onShareExternally,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onImageTap,
              child: Image.network(
                outfit.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, size: 40, color: accent),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                if (outfit.caption != null && outfit.caption!.isNotEmpty)
                  Expanded(
                    child: Text(
                      outfit.caption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.download_rounded, size: 20, color: accent),
                  onPressed: onDownload,
                  tooltip: 'Download',
                ),
                IconButton(
                  icon: Icon(Icons.share_rounded, size: 20, color: accent),
                  onPressed: onShareExternally,
                  tooltip: 'Share',
                ),
                IconButton(
                  icon: Icon(Icons.send_rounded, size: 20, color: accent),
                  onPressed: onShareToChat,
                  tooltip: 'Share in chat',
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, size: 20, color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary),
                  onPressed: onDelete,
                  tooltip: 'Remove',
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOut);
  }
}

/// Full-screen image viewer. Tap image or close button to dismiss.
class _FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  final String? caption;

  const _FullScreenImageView({required this.imageUrl, this.caption});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
            ),
          ),
          if (caption != null && caption!.isNotEmpty)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Text(
                    caption!,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShareChatTile extends ConsumerWidget {
  final ChatModel chat;
  final String otherUserId;
  final GeneratedOutfitModel outfit;
  final bool isDark;
  final Color accent;
  final VoidCallback onSent;

  const _ShareChatTile({
    required this.chat,
    required this.otherUserId,
    required this.outfit,
    required this.isDark,
    required this.accent,
    required this.onSent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userSocialProfileProvider(otherUserId));
    final senderName = ref.read(currentUserProvider).valueOrNull?.displayName ?? 'Someone';

    return profileAsync.when(
      data: (profile) {
        final name = profile?.name ?? 'User';
        final avatar = profile?.avatarUrl;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: accent.withValues(alpha: 0.2),
            backgroundImage: avatar != null && avatar.startsWith('http') ? NetworkImage(avatar) : null,
            child: avatar == null || !avatar.startsWith('http') ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: accent)) : null,
          ),
          title: Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? DesignTokens.darkText : DesignTokens.lightText)),
          onTap: () async {
            try {
              final uid = ref.read(authStateProvider).valueOrNull?.uid;
              if (uid == null) return;
              await ref.read(socialServiceProvider).sendMessage(
                    chat.id,
                    uid,
                    outfit.caption ?? 'My look',
                    type: 'image',
                    imageUrl: outfit.imageUrl,
                    senderName: senderName,
                  );
              onSent();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to send: $e'), behavior: SnackBarBehavior.floating),
                );
              }
            }
          },
        );
      },
      loading: () => ListTile(leading: const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2)), title: Text(otherUserId)),
      error: (_, __) => ListTile(
        leading: CircleAvatar(backgroundColor: accent.withValues(alpha: 0.2), child: Icon(Icons.person, color: accent)),
        title: const Text('User'),
        onTap: () async {
          try {
            final uid = ref.read(authStateProvider).valueOrNull?.uid;
            if (uid == null) return;
            await ref.read(socialServiceProvider).sendMessage(
                  chat.id,
                  uid,
                  outfit.caption ?? 'My look',
                  type: 'image',
                  imageUrl: outfit.imageUrl,
                  senderName: senderName,
                );
            onSent();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to send: $e'), behavior: SnackBarBehavior.floating),
              );
            }
          }
        },
      ),
    );
  }
}

/// Premium Look Post Card — Instagram/Pinterest style
/// Header, full-width image, double-tap heart, actions, caption with "Read more"
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/services/sound_service.dart';
import '../../../routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/widgets/friend_request_button.dart';
import '../models/look_post_model.dart';
import '../providers/style_feed_provider.dart';
import 'style_feed_image.dart';
import 'comment_drawer.dart';

class LookPostCard extends ConsumerStatefulWidget {
  final LookPost post;
  final bool isLiked;
  final bool isSaved;
  final VoidCallback? onTryThisLook;
  final VoidCallback? onPostSimilar;
  final VoidCallback? onLike;
  final VoidCallback? onSave;

  const LookPostCard({
    super.key,
    required this.post,
    required this.isLiked,
    required this.isSaved,
    this.onTryThisLook,
    this.onPostSimilar,
    this.onLike,
    this.onSave,
  });

  @override
  ConsumerState<LookPostCard> createState() => _LookPostCardState();
}

class _LookPostCardState extends ConsumerState<LookPostCard> {
  bool _showHeartBurst = false;
  bool _captionExpanded = false;

  void _onDoubleTap() {
    HapticFeedback.mediumImpact();
    SoundService.play(AppSound.like);
    if (mounted) setState(() => _showHeartBurst = true);
    if (widget.onLike != null) {
      widget.onLike!();
    } else {
      ref.read(styleFeedProvider.notifier).toggleLike(widget.post.id);
    }
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showHeartBurst = false);
    });
  }

  void _openComments() {
    if (mounted) {
      ref.read(styleFeedProvider.notifier).incrementViewCount(widget.post.id);
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(0, 193, 181, 181),
      builder: (ctx) => CommentDrawer(
        post: widget.post,
        isLiked: widget.isLiked,
        isSaved: widget.isSaved,
        onLike: () {
          if (!mounted) return;
          SoundService.play(AppSound.like);
          if (widget.onLike != null) {
            widget.onLike!();
          } else {
            ref.read(styleFeedProvider.notifier).toggleLike(widget.post.id);
          }
        },
        onSave: () {
          if (!mounted) return;
          if (widget.onSave != null) {
            widget.onSave!();
          } else {
            ref.read(styleFeedProvider.notifier).toggleSavePost(widget.post.id);
          }
        },
        onShare: () {
          if (!mounted) return;
          ref
              .read(styleFeedProvider.notifier)
              .incrementShareCount(widget.post.id);
        },
        onTryThisLook: widget.onTryThisLook,
      ),
    );
  }

  void _openFullScreen() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => _StyleFeedImageViewer(
        post: widget.post,
        heroTag: 'style-feed-image-${widget.post.id}',
        isLiked: widget.isLiked,
        isSaved: widget.isSaved,
        onLike: widget.onLike ??
            () {
              if (!mounted) return;
              ref.read(styleFeedProvider.notifier).toggleLike(widget.post.id);
            },
        onSave: widget.onSave ??
            () {
              if (!mounted) return;
              ref
                  .read(styleFeedProvider.notifier)
                  .toggleSavePost(widget.post.id);
            },
        onShare: () {
          if (!mounted) return;
          ref
              .read(styleFeedProvider.notifier)
              .incrementShareCount(widget.post.id);
        },
        onComment: _openComments,
        onTryThisLook: widget.onTryThisLook,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final accent = isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    final surface =
        isDark ? DesignTokens.darkSurface : DesignTokens.lightSurface;
    final textColor = isDark ? DesignTokens.darkText : DesignTokens.lightText;
    final textSecondary = isDark
        ? DesignTokens.darkTextSecondary
        : DesignTokens.lightTextSecondary;
    final post = widget.post;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ① Header: avatar, name, time, more (⋮)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? DesignTokens.darkBorder
                          : DesignTokens.lightBorder,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: post.userAvatarUrl != null &&
                            post.userAvatarUrl!.startsWith('http')
                        ? Image.network(
                            post.userAvatarUrl!,
                            fit: BoxFit.cover,
                            width: 36,
                            height: 36,
                            errorBuilder: (_, __, ___) => Icon(
                                Icons.person_rounded,
                                color: textSecondary,
                                size: 20),
                          )
                        : Icon(Icons.person_rounded,
                            color: textSecondary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                        ),
                        Text(
                          _formatDate(post.createdAt),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (ref.watch(authStateProvider).valueOrNull?.uid !=
                      post.userId)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: FriendRequestButton(
                        otherUserId: post.userId,
                        otherUserName: post.userName,
                        size: const Size(100, 32),
                        onFriendsTap: () {
                          Navigator.of(context)
                              .pushNamed(Routes.chat, arguments: {
                            'otherUserId': post.userId,
                            'otherUserName': post.userName,
                            'otherUserAvatar': post.userAvatarUrl,
                          });
                        },
                      ),
                    ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _showPostOptions(context);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.more_horiz_rounded, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ② Image: full-width, rounded, tap to view fullscreen, double-tap heart, shimmer
            GestureDetector(
              onTap: _openFullScreen,
              onDoubleTap: _onDoubleTap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Hero(
                        tag: 'style-feed-image-${post.id}',
                        child: StyleFeedImage(
                          imagePath: post.imagePath,
                          fit: BoxFit.cover,
                          placeholder: _ShimmerPlaceholder(),
                          errorWidget: Container(
                            color: isDark
                                ? DesignTokens.darkCard
                                : DesignTokens.lightCard,
                            child: Icon(Icons.image_not_supported_rounded,
                                size: 48, color: textSecondary),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_showHeartBurst)
                    Icon(Icons.favorite_rounded,
                            size: 100, color: Colors.red.withValues(alpha: 0.9))
                        .animate()
                        .scale(
                            begin: const Offset(0.2, 0.2),
                            end: const Offset(1.2, 1.2),
                            curve: Curves.elasticOut)
                        .fadeOut(duration: 600.ms),
                ],
              ),
            ),
            // ③ Actions: Like, Comment, Share, Save, Try This Look
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _ActionButton(
                        icon: widget.isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: widget.isLiked ? Colors.red : textColor,
                        count: post.likeCount,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          SoundService.play(AppSound.like);
                          ref
                              .read(styleFeedProvider.notifier)
                              .toggleLike(post.id);
                        },
                      ),
                      const SizedBox(width: 16),
                      _ActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        color: textColor,
                        count: post.commentCount,
                        onTap: _openComments,
                      ),
                      const SizedBox(width: 16),
                      _ActionButton(
                        icon: Icons.send_outlined,
                        color: textColor,
                        count: post.shareCount,
                        onTap: () {
                          if (!mounted) return;
                          ref
                              .read(styleFeedProvider.notifier)
                              .incrementShareCount(post.id);
                        },
                      ),
                      const Spacer(),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            if (!mounted) return;
                            ref
                                .read(styleFeedProvider.notifier)
                                .toggleSavePost(post.id);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              widget.isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              size: 24,
                              color: widget.isSaved ? accent : textColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Error messages for engagement actions
                  _ErrorMessageWidget(postId: post.id),
                ],
              ),
            ),
            // Try This Look — prominent CTA
            if (widget.onTryThisLook != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onTryThisLook!();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.checkroom_rounded,
                              size: 20, color: accent),
                          const SizedBox(width: 8),
                          Text(
                            'Try This Look',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // ④ Caption: username bold, caption, hashtags, "Read more"
            if (post.caption.isNotEmpty || post.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.caption.isNotEmpty) ...[
                      RichText(
                        maxLines: _captionExpanded ? null : 3,
                        overflow: _captionExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        text: TextSpan(
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: textColor),
                          children: [
                            TextSpan(
                              text: '${post.userName} ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: post.caption),
                          ],
                        ),
                      ),
                      if (post.caption.length > 80 && !_captionExpanded)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            if (!mounted) return;
                            setState(() => _captionExpanded = true);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'more',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                    ],
                    if (post.tags.isNotEmpty) ...[
                      if (post.caption.isNotEmpty) const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: post.tags
                            .map((t) => Text(
                                  '#$t',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: accent,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.03, end: 0, curve: Curves.easeOutCubic);
  }

  void _showPostOptions(BuildContext context) {
    final isDark = context.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onPostSimilar != null)
              ListTile(
                leading: const Icon(Icons.add_photo_alternate_outlined),
                title: const Text('Post similar'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onPostSimilar!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(ctx);
                ref
                    .read(styleFeedProvider.notifier)
                    .incrementShareCount(widget.post.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copy link'),
              onTap: () {
                Navigator.pop(ctx);
                // No backend — could copy caption
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays > 7) return DateFormat.MMMd().format(d);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Now';
  }
}

class _ViewerIconButton extends StatelessWidget {
  const _ViewerIconButton({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: active ? Colors.pinkAccent : Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleFeedImageViewer extends StatefulWidget {
  const _StyleFeedImageViewer({
    required this.post,
    required this.heroTag,
    this.isLiked = false,
    this.isSaved = false,
    this.onLike,
    this.onSave,
    this.onShare,
    this.onComment,
    this.onTryThisLook,
  });

  final LookPost post;
  final String heroTag;
  final bool isLiked;
  final bool isSaved;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onComment;
  final VoidCallback? onTryThisLook;

  @override
  State<_StyleFeedImageViewer> createState() => _StyleFeedImageViewerState();
}

class _StyleFeedImageViewerState extends State<_StyleFeedImageViewer> {
  Color? _dominantColor;
  bool _isLoadingPalette = true;

  @override
  void initState() {
    super.initState();
    _generatePalette();
  }

  Future<void> _generatePalette() async {
    try {
      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
        _getImageProvider(widget.post.imagePath),
        size: const Size(200, 200),
        region: const Rect.fromLTRB(0, 0, 200, 200),
        maximumColorCount: 20,
      );

      if (mounted) {
        setState(() {
          _dominantColor =
              paletteGenerator.dominantColor?.color ?? Colors.black;
          _isLoadingPalette = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dominantColor = Colors.black;
          _isLoadingPalette = false;
        });
      }
    }
  }

  ImageProvider _getImageProvider(String imagePath) {
    if (imagePath.startsWith('data:')) {
      // For data URLs, we need to decode and create MemoryImage
      final base64 =
          imagePath.contains(',') ? imagePath.split(',').last : imagePath;
      final bytes = base64Decode(base64);
      return MemoryImage(bytes);
    } else if (imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    } else {
      return FileImage(File(imagePath));
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        _isLoadingPalette ? Colors.black : _dominantColor ?? Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      backgroundColor.withValues(alpha: 0.9),
                      backgroundColor.withValues(alpha: 0.7),
                      backgroundColor.withValues(alpha: 0.9),
                    ],
                  ),
                ),
                child: Center(
                  child: InteractiveViewer(
                    clipBehavior: Clip.none,
                    minScale: 1.0,
                    maxScale: 3.0,
                    child: Hero(
                      tag: widget.heroTag,
                      child: StyleFeedImage(
                        imagePath: widget.post.imagePath,
                        fit: BoxFit.contain,
                        placeholder:
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: const Center(
                          child: Icon(Icons.image_not_supported_rounded,
                              size: 64, color: Colors.white54),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.post.userAvatarUrl != null &&
                      widget.post.userAvatarUrl!.startsWith('http'))
                    ClipOval(
                      child: Image.network(
                        widget.post.userAvatarUrl!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_outline,
                          color: Colors.white54,
                          size: 28,
                        ),
                      ),
                    )
                  else
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person_outline,
                          color: Colors.white70, size: 22),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatDate(widget.post.createdAt),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.black45,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 26,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _ViewerIconButton(
                              icon: widget.isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              label: '${widget.post.likeCount}',
                              active: widget.isLiked,
                              onTap: widget.onLike,
                            ),
                            const SizedBox(width: 12),
                            _ViewerIconButton(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: '${widget.post.commentCount}',
                              onTap: widget.onComment,
                            ),
                            const SizedBox(width: 12),
                            _ViewerIconButton(
                              icon: Icons.send_outlined,
                              label: '${widget.post.shareCount}',
                              onTap: widget.onShare,
                            ),
                            const Spacer(),
                            _ViewerIconButton(
                              icon: widget.isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              label: 'Save',
                              active: widget.isSaved,
                              onTap: widget.onSave,
                            ),
                          ],
                        ),
                        if (widget.post.caption.isNotEmpty ||
                            widget.post.tags.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.post.caption.isNotEmpty)
                                  Text(
                                    widget.post.caption,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                if (widget.post.tags.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Wrap(
                                      spacing: 8,
                                      children: widget.post.tags
                                          .map((tag) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white10,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '#$tag',
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.onTryThisLook != null) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: widget.onTryThisLook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.checkroom_rounded),
                      label: const Text('Try This Look'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays > 7) return DateFormat.MMMd().format(d);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Now';
  }
}

class _ShimmerPlaceholder extends StatefulWidget {
  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final base = isDark ? DesignTokens.darkCard : DesignTokens.lightCard;
    final highlight =
        isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [base, highlight, base],
            ),
          ),
          child: const Center(
            child: Icon(Icons.photo_outlined, size: 48, color: Colors.white24),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = context.isDarkMode
        ? DesignTokens.darkTextSecondary
        : DesignTokens.lightTextSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 26, color: color),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Text(
                  _formatCount(count),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Error Message Widget - Extracted to avoid nested Consumer in gesture handlers
// ══════════════════════════════════════════════════════════════════════════════
class _ErrorMessageWidget extends ConsumerWidget {
  final String postId;

  const _ErrorMessageWidget({required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(styleFeedProvider);
    final errorMessages = state.valueOrNull?.errorMessages ?? {};

    final likeError = errorMessages['like_$postId'];
    final commentError = errorMessages['comment_$postId'];
    final shareError = errorMessages['share_$postId'];
    final saveError = errorMessages['save_$postId'];

    if (likeError?.isNotEmpty == true ||
        commentError?.isNotEmpty == true ||
        shareError?.isNotEmpty == true ||
        saveError?.isNotEmpty == true) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  likeError ?? commentError ?? shareError ?? saveError ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final key = likeError != null
                        ? 'like_$postId'
                        : commentError != null
                            ? 'comment_$postId'
                            : shareError != null
                                ? 'share_$postId'
                                : 'save_$postId';
                    ref
                        .read(styleFeedProvider.notifier)
                        .clearEngagementError(key);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 14, color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Premium Look Post Card — Instagram/Pinterest style
/// Header, full-width image, double-tap heart, actions, caption with "Read more"
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/widgets/theme_wrapper.dart';
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

  const LookPostCard({
    super.key,
    required this.post,
    required this.isLiked,
    required this.isSaved,
    this.onTryThisLook,
    this.onPostSimilar,
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
    setState(() => _showHeartBurst = true);
    ref.read(styleFeedProvider.notifier).toggleLike(widget.post.id);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showHeartBurst = false);
    });
  }

  void _openComments() {
    ref.read(styleFeedProvider.notifier).incrementViewCount(widget.post.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CommentDrawer(
        post: widget.post,
        isLiked: widget.isLiked,
        isSaved: widget.isSaved,
        onLike: () {
          SoundService.play(AppSound.like);
          ref.read(styleFeedProvider.notifier).toggleLike(widget.post.id);
        },
        onSave: () => ref.read(styleFeedProvider.notifier).toggleSavePost(widget.post.id),
        onShare: () => ref.read(styleFeedProvider.notifier).incrementShareCount(widget.post.id),
        onTryThisLook: widget.onTryThisLook,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final accent = isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    final surface = isDark ? DesignTokens.darkSurface : DesignTokens.lightSurface;
    final textColor = isDark ? DesignTokens.darkText : DesignTokens.lightText;
    final textSecondary = isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary;
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
                      color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: post.userAvatarUrl != null && post.userAvatarUrl!.startsWith('http')
                        ? Image.network(
                            post.userAvatarUrl!,
                            fit: BoxFit.cover,
                            width: 36,
                            height: 36,
                            errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, color: textSecondary, size: 20),
                          )
                        : Icon(Icons.person_rounded, color: textSecondary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Text(
                          _formatDate(post.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (ref.watch(authStateProvider).valueOrNull?.uid != post.userId)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: FriendRequestButton(
                        otherUserId: post.userId,
                        otherUserName: post.userName,
                        size: const Size(100, 32),
                        onFriendsTap: () {
                          Navigator.of(context).pushNamed(Routes.chat, arguments: {
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
            // ② Image: full-width, rounded, double-tap heart, shimmer
            GestureDetector(
              onDoubleTap: _onDoubleTap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: StyleFeedImage(
                        imagePath: post.imagePath,
                        fit: BoxFit.cover,
                        placeholder: _ShimmerPlaceholder(),
                        errorWidget: Container(
                          color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
                          child: Icon(Icons.image_not_supported_rounded, size: 48, color: textSecondary),
                        ),
                      ),
                    ),
                  ),
                  if (_showHeartBurst)
                    Icon(Icons.favorite_rounded, size: 100, color: Colors.red.withValues(alpha: 0.9))
                        .animate()
                        .scale(begin: const Offset(0.2, 0.2), end: const Offset(1.2, 1.2), curve: Curves.elasticOut)
                        .fadeOut(duration: 600.ms),
                ],
              ),
            ),
            // ③ Actions: Like, Comment, Share, Save, Try This Look
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                children: [
                  _ActionButton(
                    icon: widget.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: widget.isLiked ? Colors.red : textColor,
                    count: post.likeCount,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      SoundService.play(AppSound.like);
                      ref.read(styleFeedProvider.notifier).toggleLike(post.id);
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
                    onTap: () => ref.read(styleFeedProvider.notifier).incrementShareCount(post.id),
                  ),
                  const Spacer(),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(styleFeedProvider.notifier).toggleSavePost(post.id);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          widget.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          size: 24,
                          color: widget.isSaved ? accent : textColor,
                        ),
                      ),
                    ),
                  ),
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
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.checkroom_rounded, size: 20, color: accent),
                          const SizedBox(width: 8),
                          Text(
                            'Try This Look',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
                        overflow: _captionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor),
                          children: [
                            TextSpan(
                              text: '${post.userName} ',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: post.caption),
                          ],
                        ),
                      ),
                      if (post.caption.length > 80 && !_captionExpanded)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _captionExpanded = true);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'more',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                        children: post.tags.map((t) => Text(
                          '#$t',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w500,
                          ),
                        )).toList(),
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
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.03, end: 0, curve: Curves.easeOutCubic);
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
                ref.read(styleFeedProvider.notifier).incrementShareCount(widget.post.id);
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
    final highlight = isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder;

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
    final textSecondary = context.isDarkMode ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary;

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

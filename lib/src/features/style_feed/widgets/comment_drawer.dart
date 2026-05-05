import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../models/look_post_model.dart';
import '../providers/style_feed_provider.dart';

class CommentDrawer extends ConsumerStatefulWidget {
  final LookPost post;
  final bool isLiked;
  final bool isSaved;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback? onTryThisLook;

  const CommentDrawer({
    super.key,
    required this.post,
    required this.isLiked,
    required this.isSaved,
    required this.onLike,
    required this.onSave,
    required this.onShare,
    this.onTryThisLook,
  });

  @override
  ConsumerState<CommentDrawer> createState() => _CommentDrawerState();
}

class _CommentDrawerState extends ConsumerState<CommentDrawer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(styleFeedProvider.notifier).addComment(widget.post.id, text);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final accentPink =
        context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    final feedState = ref.watch(styleFeedProvider).valueOrNull;
    LookPost post = widget.post;
    if (feedState != null) {
      for (final p in feedState.posts) {
        if (p.id == widget.post.id) {
          post = p;
          break;
        }
      }
    }
    final comments = post.comments;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(theme.borderRadiusLarge)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Professional Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppThemeData.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Title
                Row(
                  children: [
                    Icon(
                      Icons.forum_rounded,
                      size: 24,
                      color: accentPink,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Community Discussion',
                      style: theme.titleLarge().copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.textPrimary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Engagement Stats
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.backgroundSecondary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.borderLight.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Likes
                      _buildEngagementStat(
                        icon: Icons.favorite_rounded,
                        count: post.likeCount,
                        label: 'Likes',
                        color: Colors.red.shade400,
                      ),
                      // Comments
                      _buildEngagementStat(
                        icon: Icons.chat_bubble_rounded,
                        count: post.commentCount,
                        label: 'Comments',
                        color: accentPink,
                      ),
                      // Shares
                      _buildEngagementStat(
                        icon: Icons.share_rounded,
                        count: post.shareCount,
                        label: 'Shares',
                        color: Colors.green.shade500,
                      ),
                      // Views
                      _buildEngagementStat(
                        icon: Icons.visibility_rounded,
                        count: post.viewCount,
                        label: 'Views',
                        color: theme.textTertiary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  'Join the conversation and share your thoughts!',
                  style: theme.bodyMedium(color: theme.textSecondary).copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: theme.borderLight),
          // Comments list
          Flexible(
            child: comments.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppThemeData.spacingXL),
                    child: Center(
                      child: Text(
                        'No comments yet. Be the first!',
                        style: theme.bodyMedium(color: theme.textTertiary),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppThemeData.spacingLG,
                      vertical: AppThemeData.spacingMD,
                    ),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppThemeData.spacingMD),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: theme.borderLight,
                              child: Text(
                                c.userName.isNotEmpty
                                    ? c.userName[0].toUpperCase()
                                    : '?',
                                style:
                                    theme.bodySmall(color: theme.textSecondary),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        c.userName,
                                        style: theme.bodyMedium().copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: theme.textPrimary,
                                            ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatDate(c.createdAt),
                                        style: theme.bodySmall(
                                            color: theme.textTertiary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    c.text,
                                    style: theme.bodyMedium(
                                        color: theme.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Divider(height: 1, color: theme.borderLight),
          // Error message display
          _CommentErrorWidget(postId: widget.post.id),
          // Input
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppThemeData.spacingMD,
              AppThemeData.spacingSM,
              AppThemeData.spacingMD,
              MediaQuery.of(context).padding.bottom + AppThemeData.spacingMD,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: theme.bodyMedium(color: theme.textTertiary),
                      filled: true,
                      fillColor: theme.backgroundSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    style: theme.bodyMedium(color: theme.textPrimary),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                    maxLength: 1000, // Enforce character limit
                  ),
                ),
                const SizedBox(width: 8),
                _CommentSendButton(
                    postId: widget.post.id,
                    onPressed: _submitComment,
                    accentColor: accentPink),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays > 7) return DateFormat.MMMd().format(d);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildEngagementStat({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    final theme = context.appTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          _formatCount(count),
          style: theme.bodySmall().copyWith(
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
                fontSize: 12,
              ),
        ),
        Text(
          label,
          style: theme.bodySmall(color: theme.textTertiary).copyWith(
                fontSize: 10,
              ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Comment Error Widget - Extracted to avoid nested Consumer in gesture handlers
// ══════════════════════════════════════════════════════════════════════════════
class _CommentErrorWidget extends ConsumerWidget {
  final String postId;

  const _CommentErrorWidget({required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final state = ref.watch(styleFeedProvider);
    final errorMessage = state.valueOrNull?.errorMessages['comment_$postId'];

    if (errorMessage?.isNotEmpty == true) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppThemeData.spacingMD),
        padding: const EdgeInsets.all(AppThemeData.spacingSM),
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
                errorMessage!,
                style: theme.bodySmall(color: Colors.red).copyWith(
                      fontSize: 12,
                    ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ref
                      .read(styleFeedProvider.notifier)
                      .clearEngagementError('comment_$postId');
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
      );
    }
    return const SizedBox.shrink();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Comment Send Button - Extracted to avoid nested Consumer in gesture handlers
// ══════════════════════════════════════════════════════════════════════════════
class _CommentSendButton extends ConsumerWidget {
  final String postId;
  final VoidCallback onPressed;
  final Color accentColor;

  const _CommentSendButton({
    required this.postId,
    required this.onPressed,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(styleFeedProvider);
    final isLoading =
        state.valueOrNull?.engagementStatuses['comment_$postId'] ==
            EngagementStatus.loading;

    return IconButton.filled(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.send_rounded, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

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
    final accentPink = context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent;
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(theme.borderRadiusLarge)),
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
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppThemeData.spacingLG),
            child: Row(
              children: [
                Text(
                  'Comments',
                  style: theme.titleLarge(),
                ),
                const SizedBox(width: 8),
                Text(
                  '${post.commentCount}',
                  style: theme.bodySmall(color: theme.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
                        padding: const EdgeInsets.only(bottom: AppThemeData.spacingMD),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: theme.borderLight,
                              child: Text(
                                c.userName.isNotEmpty ? c.userName[0].toUpperCase() : '?',
                                style: theme.bodySmall(color: theme.textSecondary),
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
                                        style: theme.bodySmall(color: theme.textTertiary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    c.text,
                                    style: theme.bodyMedium(color: theme.textPrimary),
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
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _submitComment,
                  icon: const Icon(Icons.send_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: accentPink,
                    foregroundColor: Colors.white,
                  ),
                ),
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
}

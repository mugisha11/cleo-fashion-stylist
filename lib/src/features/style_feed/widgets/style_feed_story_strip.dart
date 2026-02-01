/// Story-like horizontal strip: Add Look + recent/trending looks
/// Instagram Stories style for engagement
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../models/look_post_model.dart';
import 'style_feed_image.dart';

class StyleFeedStoryStrip extends StatelessWidget {
  final List<LookPost> recentPosts;
  final VoidCallback onAddLook;
  final void Function(LookPost post)? onStoryTap;
  final void Function(LookPost post)? onTryThisLook;

  const StyleFeedStoryStrip({
    super.key,
    this.recentPosts = const [],
    required this.onAddLook,
    this.onStoryTap,
    this.onTryThisLook,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final accent = isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    final surface = isDark ? DesignTokens.darkSurface : DesignTokens.lightSurface;

    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        clipBehavior: Clip.none,
        children: [
          _AddLookStory(onTap: onAddLook, accent: accent, surface: surface),
          const SizedBox(width: 16),
          ...recentPosts.take(10).map((post) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _StoryRing(
              post: post,
              onTap: () {
                HapticFeedback.selectionClick();
                onStoryTap?.call(post);
              },
              onTryThisLook: onTryThisLook != null
                  ? () => onTryThisLook!(post)
                  : null,
            ),
          )),
        ],
      ),
    );
  }
}

class _AddLookStory extends StatelessWidget {
  final VoidCallback onTap;
  final Color accent;
  final Color surface;

  const _AddLookStory({
    required this.onTap,
    required this.accent,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 2),
              color: surface,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.add_rounded, size: 32, color: accent),
          ),
          const SizedBox(height: 6),
          Text(
            'Add Look',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? DesignTokens.darkText
                  : DesignTokens.lightText,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryRing extends StatelessWidget {
  final LookPost post;
  final VoidCallback onTap;
  final VoidCallback? onTryThisLook;

  const _StoryRing({
    required this.post,
    required this.onTap,
    this.onTryThisLook,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final borderColor = isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor.withValues(alpha: 0.6), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: StyleFeedImage(
                imagePath: post.imagePath,
                fit: BoxFit.cover,
                placeholder: Center(
                  child: Icon(
                    Icons.person,
                    color: DesignTokens.lightTextSecondary,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text(
              post.userName.length > 10
                  ? '${post.userName.substring(0, 8)}…'
                  : post.userName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: isDark ? DesignTokens.darkText : DesignTokens.lightText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

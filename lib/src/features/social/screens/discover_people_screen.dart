/// Discover People — See all people on the platform, add friend, Instagram-style suggestions
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../routes.dart';
import '../models/social_user_profile.dart';
import '../providers/social_provider.dart';
import '../widgets/friend_request_button.dart';

class DiscoverPeopleScreen extends ConsumerWidget {
  const DiscoverPeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;
    final suggestedAsync = ref.watch(suggestedPeopleProvider);
    final everyoneAsync = ref.watch(discoverUsersProvider);
    final accent = isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    final textColor = isDark ? DesignTokens.darkText : DesignTokens.lightText;
    final textSecondary = isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary;
    final surface = isDark ? DesignTokens.darkSurface : DesignTokens.lightSurface;

    return Scaffold(
      backgroundColor: isDark ? DesignTokens.darkBackground : DesignTokens.lightBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).pop();
          },
          color: textColor,
        ),
        title: Text(
          'Discover People',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(discoverUsersProvider);
          ref.invalidate(suggestedPeopleProvider);
        },
        color: accent,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Suggested for you (Instagram algorithm: mutual friends / same style)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 20, color: accent),
                    const SizedBox(width: 8),
                    Text(
                      'Suggested for you',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            suggestedAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptySection(
                      message: 'Add friends to get suggestions based on mutual connections.',
                      isDark: isDark,
                      textSecondary: textSecondary,
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _PersonTile(
                      profile: list[index],
                      isDark: isDark,
                      accent: accent,
                      textColor: textColor,
                      textSecondary: textSecondary,
                    ),
                    childCount: list.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
              error: (_, __) => SliverToBoxAdapter(
                child: _EmptySection(
                  message: 'Could not load suggestions. Pull to refresh.',
                  isDark: isDark,
                  textSecondary: textSecondary,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            // Everyone on the platform
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Icon(Icons.people_rounded, size: 20, color: accent),
                    const SizedBox(width: 8),
                    Text(
                      'Everyone on Cleo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            everyoneAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptySection(
                      message: 'No other people on the platform yet.',
                      isDark: isDark,
                      textSecondary: textSecondary,
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _PersonTile(
                      profile: list[index],
                      isDark: isDark,
                      accent: accent,
                      textColor: textColor,
                      textSecondary: textSecondary,
                    ),
                    childCount: list.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: _EmptySection(
                  message: 'Could not load people. Pull to refresh.',
                  isDark: isDark,
                  textSecondary: textSecondary,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  final SocialUserProfile profile;
  final bool isDark;
  final Color accent;
  final Color textColor;
  final Color textSecondary;

  const _PersonTile({
    required this.profile,
    required this.isDark,
    required this.accent,
    required this.textColor,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: accent.withValues(alpha: isDark ? 0.25 : 0.15),
            backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.startsWith('http')
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null || !profile.avatarUrl!.startsWith('http')
                ? Text(
                    profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.bio!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          FriendRequestButton(
            otherUserId: profile.id,
            otherUserName: profile.name,
            onFriendsTap: () {
              Navigator.of(context).pushNamed(
                Routes.chat,
                arguments: <String, dynamic>{
                  'otherUserId': profile.id,
                  'otherUserName': profile.name,
                  'otherUserAvatar': profile.avatarUrl,
                },
              );
            },
            size: const Size(100, 36),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;
  final bool isDark;
  final Color textSecondary;

  const _EmptySection({
    required this.message,
    required this.isDark,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textSecondary),
        ),
      ),
    );
  }
}

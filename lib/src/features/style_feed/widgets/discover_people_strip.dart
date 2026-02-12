/// Discover People strip — Suggested for you + Add Friend on Style Feed (Instagram-style)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../routes.dart';
import '../../social/models/social_user_profile.dart';
import '../../social/providers/social_provider.dart';
import '../../social/widgets/friend_request_button.dart';

class DiscoverPeopleStrip extends ConsumerWidget {
  final VoidCallback? onSeeAll;

  const DiscoverPeopleStrip({super.key, this.onSeeAll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestedAsync = ref.watch(suggestedPeopleProvider);
    final isDark = context.isDarkMode;
    final accent = isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    final textColor = isDark ? DesignTokens.darkText : DesignTokens.lightText;
    final surface = isDark ? DesignTokens.darkSurface : DesignTokens.lightSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: accent),
              const SizedBox(width: 6),
              Text(
                'Suggested for you',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  if (onSeeAll != null) {
                    onSeeAll!();
                  } else {
                    Navigator.of(context).pushNamed(Routes.discoverPeople);
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('See all'),
              ),
            ],
          ),
        ),
        suggestedAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return _SeeAllCard(
                isDark: isDark,
                accent: accent,
                surface: surface,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pushNamed(Routes.discoverPeople);
                },
              );
            }
            return SizedBox(
              height: 112,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: list.length + 1,
                itemBuilder: (context, index) {
                  if (index == list.length) {
                    return _SeeAllCard(
                      isDark: isDark,
                      accent: accent,
                      surface: surface,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pushNamed(Routes.discoverPeople);
                      },
                    );
                  }
                  return _PersonChip(
                    profile: list[index],
                    isDark: isDark,
                    accent: accent,
                    textColor: textColor,
                  );
                },
              ),
            );
          },
          loading: () => SizedBox(
            height: 112,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _ShimmerChip(isDark: isDark, surface: surface),
                ),
              ),
            ),
          ),
          error: (_, __) => _SeeAllCard(
            isDark: isDark,
            accent: accent,
            surface: surface,
            onTap: () => Navigator.of(context).pushNamed(Routes.discoverPeople),
          ),
        ),
      ],
    );
  }
}

class _PersonChip extends StatelessWidget {
  final SocialUserProfile profile;
  final bool isDark;
  final Color accent;
  final Color textColor;

  const _PersonChip({
    required this.profile,
    required this.isDark,
    required this.accent,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        height: 112,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: isDark ? 0.25 : 0.15),
              ),
              clipBehavior: Clip.antiAlias,
              child: profile.avatarUrl != null && profile.avatarUrl!.startsWith('http')
                  ? Image.network(
                      profile.avatarUrl!,
                      fit: BoxFit.cover,
                      width: 52,
                      height: 52,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                          style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                        style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 80,
              child: Text(
                profile.name.length > 10 ? '${profile.name.substring(0, 8)}…' : profile.name,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            FriendRequestButton(
              otherUserId: profile.id,
              otherUserName: profile.name,
              size: const Size(80, 26),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeeAllCard extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final Color surface;
  final VoidCallback onTap;

  const _SeeAllCard({
    required this.isDark,
    required this.accent,
    required this.surface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_rounded, size: 28, color: accent),
              const SizedBox(height: 4),
              Text(
                'See all',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerChip extends StatelessWidget {
  final bool isDark;
  final Color surface;

  const _ShimmerChip({required this.isDark, required this.surface});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 88,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

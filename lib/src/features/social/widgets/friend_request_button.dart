import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/social_provider.dart';

/// Add Friend / Pending / Friends button. Use on profile, post header, user search.
class FriendRequestButton extends ConsumerWidget {
  final String otherUserId;
  final String? otherUserName;
  final VoidCallback? onFriendsTap;
  final Size? size;

  const FriendRequestButton({
    super.key,
    required this.otherUserId,
    this.otherUserName,
    this.onFriendsTap,
    this.size,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(friendStatusProvider(otherUserId));
    final isDark = context.isDarkMode;
    final accent = isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent;

    return status.when(
      data: (s) => _Button(
        status: s,
        otherUserId: otherUserId,
        accent: accent,
        isDark: isDark,
        onFriendsTap: onFriendsTap,
        size: size,
        ref: ref,
      ),
      loading: () => _loadingChip(isDark),
      error: (_, __) => _Button(
        status: FriendStatus.none,
        otherUserId: otherUserId,
        accent: accent,
        isDark: isDark,
        onFriendsTap: onFriendsTap,
        size: size,
        ref: ref,
      ),
    );
  }

  Widget _loadingChip(bool isDark) {
    return SizedBox(
      height: 36,
      width: 120,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  final FriendStatus status;
  final String otherUserId;
  final Color accent;
  final bool isDark;
  final VoidCallback? onFriendsTap;
  final Size? size;
  final WidgetRef ref;

  const _Button({
    required this.status,
    required this.otherUserId,
    required this.accent,
    required this.isDark,
    this.onFriendsTap,
    this.size,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final h = size?.height ?? 36.0;
    final minW = size?.width ?? 100.0;

    switch (status) {
      case FriendStatus.friends:
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onFriendsTap?.call();
            },
            borderRadius: BorderRadius.circular(h / 2),
            child: Container(
              height: h,
              constraints: BoxConstraints(minWidth: minW),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: h * 0.22),
              decoration: BoxDecoration(
                color: DesignTokens.lightSuccess.withValues(alpha: isDark ? 0.25 : 0.15),
                borderRadius: BorderRadius.circular(h / 2),
                border: Border.all(color: DesignTokens.lightSuccess.withValues(alpha: 0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: DesignTokens.lightSuccess),
                  SizedBox(width: 6),
                  Text('Friends', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DesignTokens.lightSuccess)),
                ],
              ),
            ),
          ),
        );
      case FriendStatus.pendingSent:
        return Container(
          height: h,
          constraints: BoxConstraints(minWidth: minW),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: h * 0.22),
          decoration: BoxDecoration(
            color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
            borderRadius: BorderRadius.circular(h / 2),
            border: Border.all(color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule, size: 18, color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary),
              const SizedBox(width: 8),
              Text('Requested', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary)),
            ],
          ),
        );
      case FriendStatus.pendingReceived:
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pushNamed(Routes.friendRequests);
            },
            borderRadius: BorderRadius.circular(h / 2),
            child: Container(
              height: h,
              constraints: BoxConstraints(minWidth: minW),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: h * 0.22),
              decoration: BoxDecoration(
                color: DesignTokens.lightSuccess.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(h / 2),
                border: Border.all(color: DesignTokens.lightSuccess.withValues(alpha: 0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_alt_1_rounded, size: 18, color: DesignTokens.lightSuccess),
                  SizedBox(width: 6),
                  Text('Accept request', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DesignTokens.lightSuccess)),
                ],
              ),
            ),
          ),
        );
      case FriendStatus.none:
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              HapticFeedback.mediumImpact();
              final user = ref.read(authStateProvider).valueOrNull;
              if (user == null) return;
              await ref.read(socialServiceProvider).sendFriendRequest(user.uid, otherUserId, fromName: user.displayName, fromAvatar: user.photoURL);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Friend request sent'), behavior: SnackBarBehavior.floating, backgroundColor: accent),
                );
              }
            },
            borderRadius: BorderRadius.circular(h / 2),
            child: Container(
              height: h,
              constraints: BoxConstraints(minWidth: minW),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: h * 0.22),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.25 : 0.15),
                borderRadius: BorderRadius.circular(h / 2),
                border: Border.all(color: accent.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_rounded, size: 18, color: accent),
                  const SizedBox(width: 6),
                  Text('Add Friend', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent)),
                ],
              ),
            ),
          ),
        );
    }
  }
}

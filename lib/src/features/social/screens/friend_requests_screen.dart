import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../models/friend_request_model.dart';
import '../models/social_user_profile.dart';
import '../providers/social_provider.dart';

/// Pending (to me) and Sent (from me) friend requests
class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;
    final accent = isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    final toMe = ref.watch(friendRequestsToMeProvider);
    final fromMe = ref.watch(friendRequestsFromMeProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? DesignTokens.darkBackground : DesignTokens.lightBackground,
        appBar: AppBar(
          title: const Text('Friend requests'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: isDark ? DesignTokens.darkText : DesignTokens.lightText,
          bottom: TabBar(
            labelColor: accent,
            unselectedLabelColor: isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary,
            indicatorColor: accent,
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Sent'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            toMe.when(
              data: (list) => list.isEmpty
                  ? _empty(context, 'No pending requests', isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (c, i) => _RequestToMeTile(request: list[i], ref: ref, isDark: isDark, accent: accent),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _empty(context, 'Something went wrong', isDark),
            ),
            fromMe.when(
              data: (list) => list.isEmpty
                  ? _empty(context, 'No sent requests', isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (c, i) => _RequestFromMeTile(request: list[i], ref: ref, isDark: isDark, accent: accent),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _empty(context, 'Something went wrong', isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, String text, bool isDark) {
    return Center(
      child: Text(text, style: TextStyle(color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary)),
    );
  }
}

class _RequestToMeTile extends ConsumerWidget {
  final FriendRequestModel request;
  final WidgetRef ref;
  final bool isDark;
  final Color accent;

  const _RequestToMeTile({required this.request, required this.ref, required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<SocialUserProfile?>(
      future: ref.read(socialServiceProvider).getUserProfile(request.from),
      builder: (context, snap) {
        final profile = snap.data;
        final name = profile?.name ?? 'Someone';
        final avatar = profile?.avatarUrl;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard),
            clipBehavior: Clip.antiAlias,
            child: avatar != null && avatar.startsWith('http')
                ? Image.network(avatar, fit: BoxFit.cover, width: 56, height: 56, errorBuilder: (_, __, ___) => Icon(Icons.person, color: accent))
                : Icon(Icons.person, color: accent),
          ),
          title: Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? DesignTokens.darkText : DesignTokens.lightText)),
          subtitle: Text('Wants to be friends', style: TextStyle(fontSize: 12, color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _smallButton(context, ref, label: 'Accept', isPrimary: true, onTap: () => _acceptAsync(context, ref)),
              const SizedBox(width: 8),
              _smallButton(context, ref, label: 'Reject', isPrimary: false, onTap: () => _rejectAsync(context, ref)),
            ],
          ),
        ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.05, end: 0, curve: Curves.easeOut);
      },
    );
  }

  Widget _smallButton(BuildContext context, WidgetRef ref, {required String label, required bool isPrimary, required VoidCallback onTap}) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? accent : (isDark ? DesignTokens.darkCard : DesignTokens.lightCard),
          foregroundColor: isPrimary ? Colors.white : (isDark ? DesignTokens.darkText : DesignTokens.lightText),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _acceptAsync(BuildContext context, WidgetRef ref) {
    ref.read(socialServiceProvider).acceptFriendRequest(request.id).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request accepted'), behavior: SnackBarBehavior.floating, backgroundColor: DesignTokens.lightSuccess),
        );
      }
    }).catchError((Object e, StackTrace _) {
      if (context.mounted) {
        String msg = 'Failed to accept request';
        if (e is Exception) msg = e.toString().replaceFirst('Exception: ', '');
        if (e.toString().contains('PERMISSION_DENIED') || e.toString().contains('permission-denied')) {
          msg = 'Permission denied. Deploy Firestore rules (firebase deploy --only firestore:rules) and try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  void _rejectAsync(BuildContext context, WidgetRef ref) {
    ref.read(socialServiceProvider).rejectFriendRequest(request.id).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request declined'), behavior: SnackBarBehavior.floating),
        );
      }
    }).catchError((Object e, StackTrace _) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Failed to decline'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    });
  }
}

class _RequestFromMeTile extends ConsumerWidget {
  final FriendRequestModel request;
  final WidgetRef ref;
  final bool isDark;
  final Color accent;

  const _RequestFromMeTile({required this.request, required this.ref, required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<SocialUserProfile?>(
      future: ref.read(socialServiceProvider).getUserProfile(request.to),
      builder: (context, snap) {
        final profile = snap.data;
        final name = profile?.name ?? 'User';
        final avatar = profile?.avatarUrl;
        final pending = request.isPending;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard),
            clipBehavior: Clip.antiAlias,
            child: avatar != null && avatar.startsWith('http')
                ? Image.network(avatar, fit: BoxFit.cover, width: 56, height: 56, errorBuilder: (_, __, ___) => Icon(Icons.person, color: accent))
                : Icon(Icons.person, color: accent),
          ),
          title: Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? DesignTokens.darkText : DesignTokens.lightText)),
          subtitle: Text(pending ? 'Pending' : request.status, style: TextStyle(fontSize: 12, color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.lightTextSecondary)),
          trailing: pending
              ? SizedBox(
                  height: 32,
                  child: TextButton(
                    onPressed: () async {
                      HapticFeedback.selectionClick();
                      await ref.read(socialServiceProvider).cancelFriendRequest(request.id);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request cancelled'), behavior: SnackBarBehavior.floating));
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                  ),
                )
              : null,
        ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.05, end: 0, curve: Curves.easeOut);
      },
    );
  }
}

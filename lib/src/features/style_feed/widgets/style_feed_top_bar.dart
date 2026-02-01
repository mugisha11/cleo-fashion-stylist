/// Instagram-style Style Feed top bar
/// Sticky, blur on scroll, smooth animations
library;

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/widgets/cleo_logo.dart';
import '../../../routes.dart';

class StyleFeedTopBar extends StatelessWidget {
  final bool enableBlur;
  final VoidCallback? onDiscover;
  final VoidCallback? onPostLook;
  final VoidCallback? onMessages;
  final VoidCallback? onProfileTap;

  const StyleFeedTopBar({
    super.key,
    this.enableBlur = false,
    this.onDiscover,
    this.onPostLook,
    this.onMessages,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final surface = isDark ? DesignTokens.darkSurface : DesignTokens.lightSurface;
    final textColor = isDark ? DesignTokens.darkText : DesignTokens.lightText;

    Widget content = SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            // Logo (left)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onProfileTap?.call();
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CleoLogo.small(
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Title
            Expanded(
              child: Text(
                'Style Feed',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: textColor,
                ),
              ),
            ),
            // Right icons: Discover, Post Look, Messages
            _TopBarIcon(
              icon: Icons.search_rounded,
              onTap: () {
                HapticFeedback.selectionClick();
                onDiscover?.call();
              },
              color: textColor,
            ),
            const SizedBox(width: 4),
            _TopBarIcon(
              icon: Icons.add_box_outlined,
              onTap: () {
                HapticFeedback.selectionClick();
                if (onPostLook != null) {
                  onPostLook!();
                } else {
                  Navigator.of(context).pushNamed(Routes.postLook);
                }
              },
              color: textColor,
            ),
            const SizedBox(width: 4),
            _TopBarIcon(
              icon: Icons.chat_bubble_outline_rounded,
              onTap: () {
                HapticFeedback.selectionClick();
                onMessages?.call();
              },
              color: textColor,
            ),
          ],
        ),
      ),
    );

    if (enableBlur) {
      return ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: surface.withValues(alpha: isDark ? 0.75 : 0.85),
              border: Border(
                bottom: BorderSide(
                  color: (isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder)
                      .withValues(alpha: 0.5),
                ),
              ),
            ),
            child: content,
          ),
        ),
      );
    }

    return Container(
      color: surface,
      child: content,
    );
  }
}

class _TopBarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _TopBarIcon({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 24, color: color),
        ),
      ),
    );
  }
}

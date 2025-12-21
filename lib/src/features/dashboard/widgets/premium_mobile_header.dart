import 'package:flutter/material.dart';

/// Premium mobile header matching Binance, Revolut, Stripe, Coinbase quality
/// Single-row layout that never wraps, fully responsive for 320px+ devices
class PremiumMobileHeader extends StatelessWidget implements PreferredSizeWidget {
  final String appTitle;
  final String? screenTitle;
  final bool showSearchIcon;
  final int notificationCount;
  final String? avatarUrl;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onAppTitleTap;
  final bool isDarkMode;

  const PremiumMobileHeader({
    super.key,
    required this.appTitle,
    this.screenTitle,
    this.showSearchIcon = false,
    this.notificationCount = 0,
    this.avatarUrl,
    this.onNotificationTap,
    this.onAvatarTap,
    this.onSearchTap,
    this.onAppTitleTap,
    this.isDarkMode = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final colors = _HeaderColors(isDarkMode);
    
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: App Title (max 40% width)
              Flexible(
                flex: 2,
                child: _AppTitle(
                  text: appTitle,
                  color: colors.textPrimary,
                  onTap: onAppTitleTap,
                ),
              ),
              
              // Center: Screen Title OR Search Icon
              if (screenTitle != null || showSearchIcon)
                Expanded(
                  flex: 3,
                  child: Center(
                    child: screenTitle != null
                        ? _ScreenTitle(
                            text: screenTitle!,
                            color: colors.textPrimary,
                          )
                        : _SearchIcon(
                            color: colors.textSecondary,
                            onTap: onSearchTap,
                          ),
                  ),
                ),
              
              // Right: Notification + Avatar
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NotificationIcon(
                    count: notificationCount,
                    color: colors.textPrimary,
                    badgeColor: colors.accent,
                    onTap: onNotificationTap,
                  ),
                  const SizedBox(width: 12),
                  _Avatar(
                    url: avatarUrl,
                    color: colors.accent,
                    onTap: onAvatarTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Color scheme for light/dark mode
class _HeaderColors {
  final Color background;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;

  _HeaderColors(bool isDark)
      : background = isDark ? const Color(0xFF1A1A1A) : Colors.white,
        textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A),
        textSecondary = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
        accent = isDark ? const Color(0xFF007AFF) : const Color(0xFF007AFF);
}

/// Left section: App title with ellipsis
class _AppTitle extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onTap;

  const _AppTitle({
    required this.text,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
      ),
    );

    return onTap != null
        ? GestureDetector(
            onTap: onTap,
            child: widget,
          )
        : widget;
  }
}

/// Center section: Screen title
class _ScreenTitle extends StatelessWidget {
  final String text;
  final Color color;

  const _ScreenTitle({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.2,
      ),
    );
  }
}

/// Center section: Search icon
class _SearchIcon extends StatelessWidget {
  final Color color;
  final VoidCallback? onTap;

  const _SearchIcon({
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _TapArea(
      onTap: onTap,
      child: Icon(
        Icons.search_rounded,
        size: 22,
        color: color,
      ),
    );
  }
}

/// Right section: Notification icon with badge
class _NotificationIcon extends StatelessWidget {
  final int count;
  final Color color;
  final Color badgeColor;
  final VoidCallback? onTap;

  const _NotificationIcon({
    required this.count,
    required this.color,
    required this.badgeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = count > 0;
    
    return _TapArea(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_outlined,
            size: 24,
            color: color,
          ),
          if (showBadge)
            Positioned(
              right: -4,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Right section: Circular avatar
class _Avatar extends StatelessWidget {
  final String? url;
  final Color color;
  final VoidCallback? onTap;

  const _Avatar({
    this.url,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: url != null
          ? ClipOval(
              child: Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultAvatar(color),
              ),
            )
          : _buildDefaultAvatar(color),
    );

    return _TapArea(
      onTap: onTap,
      child: avatar,
    );
  }

  Widget _buildDefaultAvatar(Color color) {
    return Icon(
      Icons.person_outline,
      size: 18,
      color: color,
    );
  }
}

/// Reusable tap area wrapper (44x44px minimum)
class _TapArea extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TapArea({
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}


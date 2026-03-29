import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/dashboard_ui_colors.dart';
import '../theme/luxury_theme.dart';
import '../../routes.dart';

/// Returns a time-based greeting (e.g. Good Morning, Good Afternoon, Good Evening).
String getTimeBasedGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning,';
  if (hour < 17) return 'Good Afternoon,';
  return 'Good Evening,';
}

/// Shared dashboard-style header: avatar, greeting + name, optional weather, notification bell.
/// Use on dashboard home, style feed, calendar, wardrobe for consistency.
class DashboardHomeHeader extends StatelessWidget {
  final String displayName;
  final String? photoUrl;
  final int unreadCount;
  final VoidCallback? onOpenDrawer;
  final String? subtitleOverride;
  final String? titleOverride;
  /// Optional: show temperature e.g. "22°C". When null, no weather is shown.
  final double? temperatureCelsius;

  const DashboardHomeHeader({
    super.key,
    required this.displayName,
    this.photoUrl,
    this.unreadCount = 0,
    this.onOpenDrawer,
    this.subtitleOverride,
    this.titleOverride,
    this.temperatureCelsius,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = displayName.split(' ').first;
    final subtitle = subtitleOverride ?? getTimeBasedGreeting();
    final title = titleOverride ?? (firstName.isNotEmpty ? firstName : 'User');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: onOpenDrawer ?? () => Scaffold.of(context).openDrawer(),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: DashboardUIColors.homeInputBg,
              backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                  ? NetworkImage(photoUrl!)
                  : null,
              child: photoUrl == null || photoUrl!.isEmpty
                  ? Text(
                      (displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U'),
                      style: const TextStyle(fontFamily: 'system-ui', 
                        fontWeight: FontWeight.bold,
                        color: DashboardUIColors.homePrimaryText,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(fontFamily: 'system-ui', 
                    fontSize: 14,
                    color: DashboardUIColors.homePrimaryText,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(fontFamily: 'system-ui', 
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DashboardUIColors.homePrimaryText,
                  ),
                ),
              ],
            ),
          ),
          if (temperatureCelsius != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: DashboardUIColors.homeInputBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DashboardUIColors.homeInputBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.thermostat, size: 18, color: DashboardUIColors.homePrimaryText),
                  const SizedBox(width: 4),
                  Text(
                    '${temperatureCelsius!.round()}°',
                    style: const TextStyle(fontFamily: 'system-ui', 
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DashboardUIColors.homePrimaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: DashboardUIColors.homeInputBg,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pushNamed(Routes.notificationCenter),
                  icon: const Icon(Icons.notifications_none, color: DashboardUIColors.homePrimaryText, size: 24),
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 🎯 TOP BAR - Navigation, status, and profile
class DashboardTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String aiStatus;
  final bool isAITyping;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onMenuTap;
  final Widget? profileImage;
  final int notificationCount;

  const DashboardTopBar({
    super.key,
    this.aiStatus = 'Ready to assist',
    this.isAITyping = false,
    this.onProfileTap,
    this.onNotificationsTap,
    this.onMenuTap,
    this.profileImage,
    this.notificationCount = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(DesignTokens.topBarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      height: DesignTokens.topBarHeight,
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : DesignTokens.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingLg,
        ),
        child: Row(
          children: [
            // Menu Button
            IconButton(
              onPressed: onMenuTap ?? () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu),
              color: context.textColor,
              tooltip: 'Open menu',
            ),

            // Logo/Branding
            Text(
              'Nikonyx',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isDark
                        ? DesignTokens.darkAccent
                        : DesignTokens.lightAccent,
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(width: DesignTokens.spacingXl),

            // AI Status (Center)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status Indicator
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isAITyping
                                ? (isDark
                                    ? DesignTokens.darkAccent
                                    : DesignTokens.lightAccent)
                                : Colors.green,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spacingSm),
                        Text(
                          isAITyping ? 'Thinking...' : aiStatus,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: context.textSecondaryColor,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: DesignTokens.spacingXl),

            // Notifications Badge
            Stack(
              children: [
                IconButton(
                  onPressed: onNotificationsTap,
                  icon: const Icon(Icons.notifications_none),
                  color: context.textColor,
                ),
                if (notificationCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isDark
                            ? DesignTokens.darkAccent
                            : DesignTokens.lightAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          notificationCount > 99 ? '99+' : '$notificationCount',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: DesignTokens.spacingMd),

            // Profile Avatar
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? DesignTokens.darkBorder
                        : DesignTokens.lightBorder,
                    width: 1.5,
                  ),
                ),
                child: profileImage ??
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? DesignTokens.darkCard
                            : DesignTokens.lightCard,
                      ),
                      child: Icon(
                        Icons.person,
                        color: context.textSecondaryColor,
                        size: 20,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📝 MESSAGE INPUT - Text + image upload (ChatGPT-style with voice)
class MessageInputBar extends StatefulWidget {
  final TextEditingController? controller;
  final VoidCallback? onSendMessage;
  final VoidCallback? onImagePick;
  final VoidCallback? onMicTap;
  final bool isLoading;
  final bool showMicButton;
  /// When true, shows ChatGPT-style listening UI: waveform, "Listening...", stop button.
  final bool isListening;
  /// Preview bytes for attached image (show thumbnail + remove).
  final Uint8List? attachedImageBytes;
  final VoidCallback? onRemoveAttachedImage;
  /// Quick action buttons: Tips, Favorites, Trending, Style. Called with 'tips'|'favorites'|'trending'|'style'.
  final void Function(String action)? onQuickActionTap;

  const MessageInputBar({
    super.key,
    this.controller,
    this.onSendMessage,
    this.onImagePick,
    this.onMicTap,
    this.isLoading = false,
    this.showMicButton = true,
    this.isListening = false,
    this.attachedImageBytes,
    this.onRemoveAttachedImage,
    this.onQuickActionTap,
  });

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  bool _isFocused = false;
  late AnimationController _waveformController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Listen to controller changes to trigger icon toggle
    widget.controller?.addListener(() {
      setState(() {}); // Rebuild when text changes
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _waveformController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void didUpdateWidget(MessageInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_waveformController.isAnimating) {
      _waveformController.repeat(reverse: true);
    } else if (!widget.isListening && _waveformController.isAnimating) {
      _waveformController.stop();
      _waveformController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final hasText = (widget.controller?.text.isNotEmpty ?? false);
    final hasAttachment = widget.attachedImageBytes != null;
    final hasContent = hasText || hasAttachment;
    final isListening = widget.isListening;
    // ChatGPT-style: when listening, show recording accent (coral/red)
    const recordingColor = Color(0xFFE57373); // Soft red/coral
    final inputBorderColor = isListening
        ? recordingColor
        : (_isFocused
            ? (isDark
                ? DesignTokens.darkAccent
                : DesignTokens.lightAccent)
            : (isDark
                ? DesignTokens.darkBorder
                : DesignTokens.lightBorder));

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      decoration: BoxDecoration(
        color:
            isDark ? DesignTokens.darkBackground : DesignTokens.lightBackground,
        border: Border(
          top: BorderSide(
            color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: DesignTokens.spacingSm,
        children: [
          // Quick Actions Row (hidden while listening, ChatGPT-style)
          if (!isListening)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: DesignTokens.spacingSm,
                children: [
                  _buildQuickActionButton(
                    context,
                    Icons.lightbulb_outline,
                    'Tips',
                    isDark,
                    onTap: () => widget.onQuickActionTap?.call('tips'),
                  ),
                  _buildQuickActionButton(
                    context,
                    Icons.favorite_outline,
                    'Favorites',
                    isDark,
                    onTap: () => widget.onQuickActionTap?.call('favorites'),
                  ),
                  _buildQuickActionButton(
                    context,
                    Icons.trending_up,
                    'Trending',
                    isDark,
                    onTap: () => widget.onQuickActionTap?.call('trending'),
                  ),
                  _buildQuickActionButton(
                    context,
                    Icons.style_outlined,
                    'Style',
                    isDark,
                    onTap: () => widget.onQuickActionTap?.call('style'),
                  ),
                ],
              ),
            ),

          // Attached image preview (ChatGPT-style)
          if (hasAttachment && !isListening)
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.spacingSm),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    child: Image.memory(
                      widget.attachedImageBytes!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingSm),
                  GestureDetector(
                    onTap: widget.onRemoveAttachedImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? DesignTokens.darkCard
                            : DesignTokens.lightCard,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? DesignTokens.darkBorder
                              : DesignTokens.lightBorder,
                        ),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Main Input Area (ChatGPT-style: waveform + "Listening..." when voice)
          Container(
            decoration: BoxDecoration(
              color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
              border: Border.all(
                color: inputBorderColor,
                width: isListening ? 1.5 : (_isFocused ? 1.5 : 0.5),
              ),
              boxShadow: (isListening || _isFocused)
                  ? [
                      BoxShadow(
                        color: (isListening
                                ? recordingColor
                                : (isDark
                                    ? DesignTokens.darkAccent
                                    : DesignTokens.lightAccent))
                            .withOpacity(0.2),
                        blurRadius: isListening ? 10 : 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Image Upload (hidden when listening)
                if (!isListening)
                  Padding(
                    padding: const EdgeInsets.only(left: DesignTokens.spacingMd),
                    child: GestureDetector(
                      onTap: widget.onImagePick,
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        color: context.textSecondaryColor,
                        size: 22,
                      ),
                    ),
                  ),
                // Waveform + "Listening..." when listening (ChatGPT-style)
                if (isListening)
                  Padding(
                    padding: const EdgeInsets.only(left: DesignTokens.spacingMd),
                    child: _VoiceWaveformBars(
                      color: recordingColor,
                      animation: _waveformController,
                    ),
                  ),

                // Text Input (shows live transcript when listening)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingMd,
                    ),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      minLines: 1,
                      readOnly: isListening,
                      decoration: InputDecoration(
                        hintText: isListening
                            ? 'Listening... Speak now.'
                            : 'Ask Nikonyx anything...',
                        hintStyle: TextStyle(
                          color: isListening
                              ? recordingColor.withOpacity(0.9)
                              : null,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: DesignTokens.spacingMd,
                        ),
                        border: InputBorder.none,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),

                // Action Buttons: Stop (when listening) | Mic | Send/Loading
                Padding(
                  padding: const EdgeInsets.only(right: DesignTokens.spacingMd),
                  child: Row(
                    spacing: DesignTokens.spacingSm,
                    children: [
                      if (isListening)
                        // ChatGPT-style: red stop button to end recording
                        GestureDetector(
                          onTap: widget.onMicTap,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: recordingColor,
                              boxShadow: [
                                BoxShadow(
                                  color: recordingColor.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.stop_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        )
                      else if (widget.showMicButton && !hasContent && !widget.isLoading)
                        GestureDetector(
                          onTap: widget.onMicTap,
                          child: Icon(
                            Icons.mic_outlined,
                            color: context.textSecondaryColor,
                            size: 22,
                          ),
                        ),
                      if (!isListening && (hasContent || widget.isLoading))
                        GestureDetector(
                          onTap: widget.onSendMessage,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? DesignTokens.darkAccent
                                  : DesignTokens.lightAccent,
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark
                                          ? DesignTokens.darkAccent
                                          : DesignTokens.lightAccent)
                                      .withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: widget.isLoading
                                ? const Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                            Colors.white),
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String label,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    final child = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingMd,
        vertical: DesignTokens.spacingSm,
      ),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
          color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: DesignTokens.spacingSm,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color:
                      isDark ? DesignTokens.darkText : DesignTokens.lightText,
                ),
          ),
        ],
      ),
    );
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: child,
      );
    }
    return child;
  }
}

/// ChatGPT-style animated waveform bars for voice input
class _VoiceWaveformBars extends StatelessWidget {
  final Color color;
  final Animation<double> animation;

  const _VoiceWaveformBars({
    required this.color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    const barCount = 5;
    const barWidth = 3.0;
    const barMaxHeight = 20.0;
    const spacing = 3.0;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(barCount, (i) {
            // Stagger heights for wave effect (0.3 to 1.0)
            final phase = (i / (barCount - 1)) * 0.7 + 0.3;
            final height = barMaxHeight *
                (phase * 0.5 + 0.5 * animation.value);
            return Padding(
              padding: EdgeInsets.only(
                  right: i < barCount - 1 ? spacing : 0),
              child: Container(
                width: barWidth,
                height: height.clamp(4.0, barMaxHeight),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(barWidth / 2),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// ⚙️ LOADING INDICATORS
class ShimmerLoadingCard extends StatefulWidget {
  final double width;
  final double height;

  const ShimmerLoadingCard({
    super.key,
    this.width = 280,
    this.height = 320,
  });

  @override
  State<ShimmerLoadingCard> createState() => _ShimmerLoadingCardState();
}

class _ShimmerLoadingCardState extends State<ShimmerLoadingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return FadeTransition(
      opacity: Tween(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: Border.all(
            color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
            width: 0.5,
          ),
        ),
      ),
    );
  }
}

class PulseLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const PulseLoadingIndicator({
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  State<PulseLoadingIndicator> createState() => _PulseLoadingIndicatorState();
}

class _PulseLoadingIndicatorState extends State<PulseLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final color = widget.color ??
        (isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent);

    return ScaleTransition(
      scale: Tween(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.3),
          border: Border.all(
            color: color,
            width: 2,
          ),
        ),
        child: Center(
          child: Container(
            width: widget.size * 0.5,
            height: widget.size * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class AITypingIndicator extends StatefulWidget {
  final double dotSize;
  final Color? color;

  const AITypingIndicator({
    super.key,
    this.dotSize = 8,
    this.color,
  });

  @override
  State<AITypingIndicator> createState() => _AITypingIndicatorState();
}

class _AITypingIndicatorState extends State<AITypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: DesignTokens.durationShort,
        vsync: this,
      ),
    );

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final color = widget.color ??
        (isDark ? DesignTokens.darkText : DesignTokens.lightText);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) => ScaleTransition(
          scale: Tween(begin: 0.8, end: 1.2).animate(
            CurvedAnimation(
                parent: _controllers[index], curve: Curves.easeInOut),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.dotSize * 0.5),
            child: Container(
              width: widget.dotSize,
              height: widget.dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LinearProgressBar extends StatefulWidget {
  final double? value; // 0.0 to 1.0, or null for indeterminate
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;

  const LinearProgressBar({
    super.key,
    this.value,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 4,
  });

  @override
  State<LinearProgressBar> createState() => _LinearProgressBarState();
}

class _LinearProgressBarState extends State<LinearProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.value == null) {
      _controller = AnimationController(
        duration: DesignTokens.durationMedium,
        vsync: this,
      )..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final backgroundColor = widget.backgroundColor ??
        (isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder);
    final foregroundColor = widget.foregroundColor ??
        (isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.height / 2),
      child: LinearProgressIndicator(
        value: widget.value,
        minHeight: widget.height,
        backgroundColor: backgroundColor,
        valueColor: AlwaysStoppedAnimation(foregroundColor),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/design_tokens.dart';
import '../theme/luxury_theme.dart';

/// 🎨 ELEGANT BUTTON - Primary, Secondary, Outline variants
class ElegantButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final ElegantButtonVariant variant;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final double? width;
  final EdgeInsets? padding;

  const ElegantButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ElegantButtonVariant.primary,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.padding,
  });

  @override
  State<ElegantButton> createState() => _ElegantButtonState();
}

enum ElegantButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
}

class _ElegantButtonState extends State<ElegantButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: DesignTokens.durationMicroShort,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final colors = _getColors(context, isDark);

    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
      ),
      child: SizedBox(
        width: widget.width,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: colors['background'],
              border: Border.all(
                color: colors['border'] ?? Colors.transparent,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              boxShadow: widget.variant == ElegantButtonVariant.primary
                  ? [DesignTokens.shadowMedium]
                  : [],
            ),
            child: InkWell(
              onTap: widget.isEnabled && !widget.isLoading
                  ? widget.onPressed
                  : null,
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _scaleController.reverse,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              child: Padding(
                padding: widget.padding ??
                    const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingLg,
                      vertical: DesignTokens.spacingMd,
                    ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(colors['text']),
                        ),
                      )
                    else if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 18,
                        color: colors['text'],
                      ),
                      const SizedBox(width: DesignTokens.spacingSm),
                    ],
                    Text(
                      widget.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: (colors['text'])?.withOpacity(
                              widget.isEnabled ? 1.0 : 0.5,
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, Color?> _getColors(BuildContext context, bool isDark) {
    switch (widget.variant) {
      case ElegantButtonVariant.primary:
        return {
          'background':
              isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent,
          'text': isDark ? Colors.black : Colors.white,
        };
      case ElegantButtonVariant.secondary:
        return {
          'background': isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
          'text': isDark ? DesignTokens.darkText : DesignTokens.lightText,
          'border': isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
        };
      case ElegantButtonVariant.outline:
        return {
          'background': Colors.transparent,
          'text': isDark ? DesignTokens.darkText : DesignTokens.lightText,
          'border': isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
        };
      case ElegantButtonVariant.ghost:
        return {
          'background': Colors.transparent,
          'text': isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent,
        };
    }
  }
}

/// 💬 CHAT MESSAGE BUBBLE - User/AI variants with animations
class ChatMessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final Widget? imagePreview;

  /// When set, show a "Buy this outfit" link (only for AI messages)
  final String? buyLinkUrl;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.imagePreview,
    this.buyLinkUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final luxuryTheme = context.luxuryTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingMd,
        vertical: DesignTokens.spacingSm,
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ScaleTransition(
          scale: Tween(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(
              parent: const AlwaysStoppedAnimation(1.0),
              curve: Curves.easeOut,
            ),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isUser
                  ? luxuryTheme.chatUserBubble
                  : luxuryTheme.chatAIBubble,
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              border: !isUser
                  ? Border.all(
                      color: isDark
                          ? DesignTokens.darkBorder
                          : DesignTokens.lightBorder,
                      width: 0.5,
                    )
                  : null,
            ),
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (imagePreview != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    child: imagePreview,
                  ),
                  const SizedBox(height: DesignTokens.spacingSm),
                ],
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                ),
                if (buyLinkUrl != null &&
                    buyLinkUrl!.isNotEmpty &&
                    !isUser) ...[
                  const SizedBox(height: DesignTokens.spacingSm),
                  InkWell(
                    onTap: () async {
                      try {
                        final uri = Uri.parse(buyLinkUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Cannot open: $buyLinkUrl'),
                                behavior: SnackBarBehavior.floating),
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Could not open link'),
                                behavior: SnackBarBehavior.floating),
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingMd,
                        vertical: DesignTokens.spacingSm,
                      ),
                      decoration: BoxDecoration(
                        color: context.accentColor.withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusMd),
                        border: Border.all(
                          color: context.accentColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 18,
                            color: context.accentColor,
                          ),
                          const SizedBox(width: DesignTokens.spacingXs),
                          Text(
                            'Buy this outfit',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: context.accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: DesignTokens.spacingXs),
                Text(
                  _formatTime(timestamp),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isUser
                            ? Colors.white.withOpacity(0.7)
                            : context.textSecondaryColor,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}

/// ✨ RECOMMENDATION CARD - Elegant carousel card
class RecommendationCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final IconData icon;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const RecommendationCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.icon,
    this.onTap,
    this.width = DesignTokens.recommendationCardWidth,
    this.height = DesignTokens.recommendationCardHeight,
  });

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: DesignTokens.durationShort,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return MouseRegion(
      onEnter: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _hoverController.forward();
        });
      },
      onExit: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _hoverController.reverse();
        });
      },
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.02).animate(
          CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
        ),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              border: Border.all(
                color:
                    isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
                width: 0.5,
              ),
              boxShadow: [DesignTokens.shadowSubtle],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDark
                            ? DesignTokens.darkCard
                            : DesignTokens.lightCard,
                        child: Icon(
                          Icons.image_not_supported,
                          color: context.textSecondaryColor,
                        ),
                      );
                    },
                  ),
                ),

                // Overlay Gradient
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacingMd),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: DesignTokens.spacingXs),
                          Text(
                            widget.subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                          ),
                          const SizedBox(height: DesignTokens.spacingSm),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 👗 WARDROBE ITEM CARD - Selectable clothing item
class WardrobeItemCard extends StatelessWidget {
  final String imageUrl;
  final String category;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final int itemCount;

  const WardrobeItemCard({
    super.key,
    required this.imageUrl,
    required this.category,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.itemCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(
            color: isSelected
                ? (isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent)
                : (isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder),
            width: isSelected ? 2 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  DesignTokens.shadowGlow(isDark
                      ? DesignTokens.darkAccent
                      : DesignTokens.lightAccent)
                ]
              : [DesignTokens.shadowSubtle],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color:
                        isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
                    child: Icon(
                      Icons.image_not_supported,
                      color: context.textSecondaryColor,
                    ),
                  );
                },
              ),
            ),

            // Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingMd),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingSm,
                      vertical: DesignTokens.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusXs),
                    ),
                    child: Text(
                      category,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),

                  // Selection Indicator or Item Count
                  if (isSelected)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDark
                            ? DesignTokens.darkAccent
                            : DesignTokens.lightAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    )
                  else if (itemCount > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingSm,
                        vertical: DesignTokens.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusXs),
                      ),
                      child: Text(
                        '+$itemCount',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📱 ELEGANT INPUT FIELD - Modern text input
class ElegantTextInput extends StatefulWidget {
  final String placeholder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final int maxLines;
  final bool obscureText;

  const ElegantTextInput({
    super.key,
    required this.placeholder,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.maxLines = 1,
    this.obscureText = false,
  });

  @override
  State<ElegantTextInput> createState() => _ElegantTextInputState();
}

class _ElegantTextInputState extends State<ElegantTextInput> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _hasFocus = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      onSubmitted: (_) => widget.onSubmitted?.call(),
      maxLines: widget.maxLines,
      obscureText: widget.obscureText,
      decoration: InputDecoration(
        hintText: widget.placeholder,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 20)
            : null,
        suffixIcon: widget.suffixIcon != null
            ? GestureDetector(
                onTap: widget.onSuffixIconTap,
                child: Icon(widget.suffixIcon, size: 20),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide(
            color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide(
            color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide(
            color: isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingMd,
          vertical: DesignTokens.spacingMd,
        ),
      ),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

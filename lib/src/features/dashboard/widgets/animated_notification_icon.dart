/// Animated Notification Icon
/// Premium bell icon with badge, micro-animations, and haptic feedback
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/grok_design_system.dart';
import '../providers/notification_provider.dart';

class AnimatedNotificationIcon extends ConsumerStatefulWidget {
  final VoidCallback? onTap;

  const AnimatedNotificationIcon({
    super.key,
    this.onTap,
  });

  @override
  ConsumerState<AnimatedNotificationIcon> createState() =>
      _AnimatedNotificationIconState();
}

class _AnimatedNotificationIconState
    extends ConsumerState<AnimatedNotificationIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _hasNewNotification = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _triggerNewNotificationAnimation() {
    setState(() {
      _hasNewNotification = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _hasNewNotification = false;
        });
      }
    });
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _scaleController.forward().then((_) {
      _scaleController.reverse();
      widget.onTap?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCountAsync = ref.watch(unreadCountProvider);
    
    // Listen for new notifications (setup listener once)
    ref.listen(unreadCountProvider, (previous, next) {
      next.whenData((count) {
        if (previous?.value != null && count > previous!.value!) {
          _triggerNewNotificationAnimation();
        }
      });
    });

    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(GrokDesignSystem.radiusSM),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: GrokDesignSystem.backgroundLightGray,
                borderRadius: BorderRadius.circular(GrokDesignSystem.radiusSM),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Bell icon
                  Center(
                    child: Icon(
                      Icons.notifications_outlined,
                      size: GrokDesignSystem.iconSize,
                      color: GrokDesignSystem.textPrimary,
                    ),
                  ),

                  // Badge (unread count or dot)
                  unreadCountAsync.when(
                    data: (count) {
                      if (count > 0) {
                        return Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: count > 9
                                ? const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  )
                                : EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                            decoration: BoxDecoration(
                              color: GrokDesignSystem.accentBlue,
                              shape: count > 9
                                  ? BoxShape.rectangle
                                  : BoxShape.circle,
                              borderRadius: count > 9
                                  ? BorderRadius.circular(8)
                                  : null,
                            ),
                            child: count > 9
                                ? Text(
                                    count > 99 ? '99+' : count.toString(),
                                    style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          )
                              .animate(
                                target: _hasNewNotification ? 1 : 0,
                              )
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.3, 1.3),
                                duration: 200.ms,
                                curve: Curves.elasticOut,
                              )
                              .then()
                              .scale(
                                begin: const Offset(1.3, 1.3),
                                end: const Offset(1, 1),
                                duration: 200.ms,
                                curve: Curves.easeOut,
                              ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


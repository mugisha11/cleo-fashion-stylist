import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/auth_design_system.dart';

/// Social authentication button (Google, Apple) - Canva/Discord style
class SocialAuthButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SocialAuthButton({
    super.key,
    required this.text,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<SocialAuthButton> createState() => _SocialAuthButtonState();
}

class _SocialAuthButtonState extends State<SocialAuthButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: widget.onPressed != null ? _handleTapDown : null,
        onTapUp: widget.onPressed != null ? _handleTapUp : null,
        onTapCancel: widget.onPressed != null ? _handleTapCancel : null,
        onTap: widget.isLoading ? null : widget.onPressed,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 52,
            decoration: BoxDecoration(
              color: widget.onPressed == null || widget.isLoading
                  ? widget.backgroundColor.withValues(alpha: 0.5)
                  : _isHovered
                      ? widget.backgroundColor.withValues(alpha: 0.95)
                      : widget.backgroundColor,
              borderRadius: BorderRadius.circular(AuthDesignSystem.radiusSM),
              border: Border.all(
                color: AuthDesignSystem.borderLight,
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onPressed,
                borderRadius: BorderRadius.circular(AuthDesignSystem.radiusSM),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.iconColor,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(widget.icon, color: widget.iconColor, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              widget.text,
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 15 : 16,
                                fontWeight: FontWeight.w600,
                                color: AuthDesignSystem.textPrimary,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(
          begin: const Offset(0.95, 0.95),
          duration: 300.ms,
        );
  }
}


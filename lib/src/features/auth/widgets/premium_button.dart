import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/auth_design_system.dart';

/// Premium button with Discord-style interactions and Canva-inspired colors
class PremiumButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final bool isSecondary;
  final double? width;

  const PremiumButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.isSecondary = false,
    this.width,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    final bgColor = widget.backgroundColor ?? 
        (widget.isSecondary 
            ? AuthDesignSystem.surfaceWhite 
            : AuthDesignSystem.accentTeal);
    final txtColor = widget.isSecondary 
        ? AuthDesignSystem.textPrimary 
        : Colors.white;
    final borderColor = widget.isSecondary 
        ? AuthDesignSystem.borderLight 
        : Colors.transparent;

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
            width: widget.width,
            height: 52,
            decoration: BoxDecoration(
              color: widget.onPressed == null || widget.isLoading
                  ? bgColor.withValues(alpha: 0.6)
                  : _isHovered && !widget.isSecondary
                      ? AuthDesignSystem.accentTeal.withValues(alpha: 0.9)
                      : bgColor,
              borderRadius: BorderRadius.circular(AuthDesignSystem.radiusSM),
              border: widget.isSecondary
                  ? Border.all(color: borderColor, width: 1.5)
                  : null,
              boxShadow: widget.onPressed != null && 
                         !widget.isLoading && 
                         !widget.isSecondary
                  ? AuthDesignSystem.buttonShadow
                  : null,
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
                            valueColor: AlwaysStoppedAnimation<Color>(txtColor),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon, color: txtColor, size: 18),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              widget.text,
                              style: AuthDesignSystem.buttonText(isMobile: isMobile),
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




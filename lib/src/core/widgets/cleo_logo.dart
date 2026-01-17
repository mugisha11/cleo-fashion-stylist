import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Cleo Logo Widget
/// Reusable logo component for consistent branding throughout the app
class CleoLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  const CleoLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
  });

  /// Small logo (32x32)
  const CleoLogo.small({
    super.key,
    this.fit = BoxFit.contain,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
  }) : width = 32, height = 32;

  /// Medium logo (64x64)
  const CleoLogo.medium({
    super.key,
    this.fit = BoxFit.contain,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
  }) : width = 64, height = 64;

  /// Large logo (120x120)
  const CleoLogo.large({
    super.key,
    this.fit = BoxFit.contain,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
  }) : width = 120, height = 120;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: Image.asset(
        'assets/images/cleologo.jpg',
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // Fallback if image not found
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: borderRadius ?? BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.style,
              size: (width ?? 32) * 0.6,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }
}

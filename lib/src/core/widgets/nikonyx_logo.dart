import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Nikonyx Logo Widget
/// Reusable logo component using the official Nikonyx SVG asset.
class NikonyxLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  const NikonyxLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
  });

  /// Small logo (32x32)
  const NikonyxLogo.small({
    super.key,
    this.fit = BoxFit.contain,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
  }) : width = 32, height = 32;

  /// Medium logo (64x64)
  const NikonyxLogo.medium({
    super.key,
    this.fit = BoxFit.contain,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
  }) : width = 64, height = 64;

  /// Large logo (120x120)
  const NikonyxLogo.large({
    super.key,
    this.fit = BoxFit.contain,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
  }) : width = 120, height = 120;

  static const String _assetPath = 'assets/images/Nikonyx logo.svg';

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
      child: SvgPicture.asset(
        _assetPath,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: (context) => Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          child: Icon(Icons.style, size: (width ?? 32) * 0.5, color: Colors.grey),
        ),
      ),
    );
  }
}

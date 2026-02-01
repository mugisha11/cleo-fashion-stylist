/// Skeleton loaders for Style Feed — premium shimmer
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';

class StyleFeedSkeleton extends StatelessWidget {
  final int itemCount;

  const StyleFeedSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _animation = Tween<double>(begin: -1.5, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final base = isDark ? DesignTokens.darkCard : DesignTokens.lightCard;
    final highlight = isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                _ShimmerBox(56, 56, base, highlight, _animation, shape: BoxShape.circle),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(120, 14, base, highlight, _animation),
                      const SizedBox(height: 8),
                      _ShimmerBox(60, 12, base, highlight, _animation),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Image skeleton
          AspectRatio(
            aspectRatio: 1,
            child: _ShimmerBox(double.infinity, double.infinity, base, highlight, _animation),
          ),
          // Actions skeleton
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _ShimmerBox(70, 24, base, highlight, _animation),
                const SizedBox(width: 16),
                _ShimmerBox(50, 24, base, highlight, _animation),
                const SizedBox(width: 16),
                _ShimmerBox(40, 24, base, highlight, _animation),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final Color base;
  final Color highlight;
  final Animation<double> animation;
  final BoxShape shape;

  const _ShimmerBox(
    this.width,
    this.height,
    this.base,
    this.highlight,
    this.animation, {
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: width == double.infinity ? null : width,
          height: height == double.infinity ? null : height,
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(8) : null,
            gradient: LinearGradient(
              begin: Alignment(animation.value - 1, 0),
              end: Alignment(animation.value, 0),
              colors: [base, highlight.withValues(alpha: 0.6), base],
            ),
          ),
        );
      },
    );
  }
}

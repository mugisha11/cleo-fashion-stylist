import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

/// Hero section with animated fashion elements
class FashionHeroSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isLogin;

  const FashionHeroSection({
    super.key,
    required this.title,
    required this.subtitle,
    this.isLogin = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isWeb = screenWidth > 1024;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 80 : isTablet ? 60 : 24,
        vertical: isWeb ? 60 : isTablet ? 40 : 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo placeholder - replace with actual logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4B39EF), Color(0xFF39D2C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.checkroom,
              color: Colors.white,
              size: 32,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(duration: 400.ms, begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 32),
          // Title
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: isWeb ? 48 : isTablet ? 40 : 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 100.ms)
              .slideY(begin: 0.2, duration: 500.ms, delay: 100.ms),
          const SizedBox(height: 12),
          // Subtitle
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: isWeb ? 18 : isTablet ? 16 : 15,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              height: 1.5,
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .slideY(begin: 0.2, duration: 500.ms, delay: 200.ms),
          const SizedBox(height: 32),
          // Animated fashion elements
          if (!isWeb)
            Row(
              children: [
                _FloatingElement(
                  icon: Icons.diamond_outlined,
                  delay: 300.ms,
                  color: const Color(0xFF4B39EF),
                ),
                const SizedBox(width: 16),
                _FloatingElement(
                  icon: Icons.checkroom_outlined,
                  delay: 400.ms,
                  color: const Color(0xFF39D2C0),
                ),
                const SizedBox(width: 16),
                _FloatingElement(
                  icon: Icons.star_outline,
                  delay: 500.ms,
                  color: const Color(0xFFEE8B60),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms),
        ],
      ),
    );
  }
}

class _FloatingElement extends StatelessWidget {
  final IconData icon;
  final Duration delay;
  final Color color;

  const _FloatingElement({
    required this.icon,
    required this.delay,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Icon(icon, color: color, size: 24),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 2000.ms, delay: delay)
        .then()
        .moveY(begin: 0, end: -8, duration: 2000.ms, curve: Curves.easeInOut)
        .then()
        .moveY(begin: -8, end: 0, duration: 2000.ms, curve: Curves.easeInOut);
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/models/tryon_session_model.dart';

/// Daily Outfit Pick Card
/// Shows a single AI-recommended outfit with try-on image
class DailyOutfitPickCard extends StatelessWidget {
  final OutfitRecommendation recommendation;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onAddToCalendar;
  final VoidCallback onTryNow;

  const DailyOutfitPickCard({
    super.key,
    required this.recommendation,
    required this.index,
    required this.onTap,
    required this.onAddToCalendar,
    required this.onTryNow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: isMobile ? 240 : 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.borderLight.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Try-on Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: recommendation.tryOnImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: recommendation.tryOnImageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(
                          color: theme.surfaceElevated,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: theme.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.surfaceElevated,
                          child: Icon(
                            Icons.checkroom_outlined,
                            size: 48,
                            color: theme.textTertiary,
                          ),
                        ),
                      )
                    : Container(
                        color: theme.surfaceElevated,
                        child: Center(
                          child: Icon(
                            Icons.checkroom_outlined,
                            size: 48,
                            color: theme.textTertiary,
                          ),
                        ),
                      ),
              ),
            ),

            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      recommendation.name,
                      style: theme.bodyMedium(color: theme.textPrimary).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Reasoning
                    Expanded(
                      child: Text(
                        recommendation.reasoning,
                        style: theme.bodySmall(color: theme.textSecondary).copyWith(
                              fontSize: 12,
                              height: 1.4,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Badges
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (recommendation.weatherMatch != null)
                          _buildBadge(
                            theme,
                            Icons.wb_sunny,
                            recommendation.weatherMatch!,
                            theme.primary,
                          ),
                        if (recommendation.eventMatch != null)
                          _buildBadge(
                            theme,
                            Icons.event,
                            recommendation.eventMatch!,
                            theme.primaryLight,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.borderLight.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      theme,
                      Icons.calendar_today,
                      'Calendar',
                      onAddToCalendar,
                      isSecondary: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      theme,
                      Icons.checkroom,
                      'Try Now',
                      onTryNow,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate()
        .fadeIn(duration: 400.ms, delay: (index * 100).ms)
        .slideX(begin: 0.1, duration: 400.ms, delay: (index * 100).ms);
  }

  Widget _buildBadge(
    AppThemeData theme,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.bodySmall(color: color).copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    AppThemeData theme,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isSecondary = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSecondary
              ? Colors.transparent
              : theme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: isSecondary
              ? Border.all(
                  color: theme.borderLight.withOpacity(0.5),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSecondary ? theme.textSecondary : theme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.bodySmall(
                color: isSecondary ? theme.textSecondary : theme.primary,
              ).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

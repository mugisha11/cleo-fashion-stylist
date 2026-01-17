import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/recommendations_service.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';

/// Daily Recommendation Card
/// Elegant card showing outfit recommendation with try-on preview
class DailyRecommendationCard extends StatelessWidget {
  final RecommendedOutfit recommendation;
  final String? tryOnImageUrl;
  final String? weatherContext;
  final String? calendarContext;
  final bool isNew;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCalendar;
  final VoidCallback? onTryAgain;
  final VoidCallback? onViewDetails;

  const DailyRecommendationCard({
    super.key,
    required this.recommendation,
    this.tryOnImageUrl,
    this.weatherContext,
    this.calendarContext,
    this.isNew = false,
    this.onTap,
    this.onAddToCalendar,
    this.onTryAgain,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isMobile ? 280 : 320,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: theme.surface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isNew
                ? theme.primary.withOpacity(0.3)
                : theme.borderLight.withOpacity(0.2),
            width: isNew ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with badge
              Stack(
                children: [
                  // Try-on preview image or placeholder
                  Container(
                    height: isMobile ? 200 : 240,
                    width: double.infinity,
                    color: theme.surface,
                    child: tryOnImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: tryOnImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: theme.surface,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: theme.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => _buildPlaceholder(theme),
                          )
                        : _buildPlaceholder(theme),
                  ),
                  // New badge
                  if (isNew)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'New',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Confidence badge
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(recommendation.confidence * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Outfit name
                    Text(
                      recommendation.name,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Reasoning
                    Text(
                      recommendation.reasoning,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: theme.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Context badges
                    if (weatherContext != null || calendarContext != null) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (weatherContext != null)
                            _buildContextBadge(
                              Icons.wb_sunny,
                              weatherContext!,
                              theme,
                            ),
                          if (calendarContext != null)
                            _buildContextBadge(
                              Icons.calendar_today,
                              calendarContext!,
                              theme,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Add to Calendar',
                            Icons.calendar_today,
                            theme,
                            onAddToCalendar,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            'Try Again',
                            Icons.refresh,
                            theme,
                            onTryAgain,
                          ),
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
    ).animate().fadeIn(duration: 300.ms).slideX(
          begin: 0.2,
          duration: 300.ms,
        );
  }

  Widget _buildPlaceholder(AppThemeData theme) {
    return Container(
      color: theme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.style,
              size: 48,
              color: theme.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'Try-on Preview',
              style: TextStyle(
                fontSize: 12,
                color: theme.textSecondary.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextBadge(IconData icon, String text, AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: theme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    AppThemeData theme,
    VoidCallback? onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: theme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.borderLight.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: theme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

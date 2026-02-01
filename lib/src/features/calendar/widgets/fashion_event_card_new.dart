import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/models/calendar_day_model.dart';

/// Fashion Event Card - Premium event card with outfit preview
class FashionEventCardNew extends StatelessWidget {
  final CalendarDay event;
  final VoidCallback onTap;

  const FashionEventCardNew({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.borderLight.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Outfit Image
            if (event.outfitImageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: event.outfitImageUrl!,
                      width: double.infinity,
                      height: isMobile ? 200 : 250,
                      fit: BoxFit.cover,
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
                          Icons.broken_image,
                          color: theme.textTertiary,
                          size: 48,
                        ),
                      ),
                    ),
                    
                    // Gradient Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Status Badge
                    if (event.isRecommended)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primary.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'AI',
                                style: theme.bodySmall(color: Colors.white).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Event Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date & Time
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: theme.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, MMM d').format(event.date),
                        style: theme.bodySmall(color: theme.textSecondary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Event Name / Outfit Name
                  if (event.eventName != null || event.outfitName != null)
                    Text(
                      event.eventName ?? event.outfitName ?? 'Outfit',
                      style: theme.titleMedium(color: theme.textPrimary).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                  // Event Type
                  if (event.eventType != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.eventType!.toUpperCase(),
                        style: theme.bodySmall(color: theme.primary).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Action Hint
                  Row(
                    children: [
                      Icon(Icons.touch_app, size: 14, color: theme.textTertiary),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to view details',
                        style: theme.bodySmall(color: theme.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

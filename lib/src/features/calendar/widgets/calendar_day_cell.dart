import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/grok_design_system.dart';
import '../../../core/models/calendar_day_model.dart';

/// Calendar Day Cell - Individual day in the calendar grid
class CalendarDayCell extends StatelessWidget {
  final CalendarDay day;
  final bool isSelected;
  final VoidCallback? onTap;

  const CalendarDayCell({
    super.key,
    required this.day,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = day.isToday;
    final hasOutfit = day.hasOutfit;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? GrokDesignSystem.accentBlueLight
              : (isToday
                  ? GrokDesignSystem.backgroundOffWhite
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(GrokDesignSystem.radiusSM),
          border: isToday
              ? Border.all(
                  color: GrokDesignSystem.accentBlue,
                  width: 1.5,
                )
              : (isSelected
                  ? Border.all(
                      color: GrokDesignSystem.accentBlue,
                      width: 1,
                    )
                  : null),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Date number
            Positioned(
              top: 4,
              left: 4,
              child: Text(
                '${day.date.day}',
                style: GrokDesignSystem.bodyMedium().copyWith(
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                  color: isToday
                      ? GrokDesignSystem.accentBlue
                      : GrokDesignSystem.textPrimary,
                ),
              ),
            ),

            // Outfit preview image (bottom)
            if (hasOutfit)
              Positioned(
                bottom: 2,
                right: 2,
                left: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Outfit image preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: day.outfitImageUrl!,
                        width: double.infinity,
                        height: 32,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: double.infinity,
                          height: 32,
                          color: GrokDesignSystem.backgroundLightGray,
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: double.infinity,
                          height: 32,
                          color: GrokDesignSystem.backgroundLightGray,
                          child: const Icon(
                            Icons.image_outlined,
                            size: 16,
                            color: GrokDesignSystem.textSecondary,
                          ),
                        ),
                      ),
                    ),

                    // AI recommendation indicator
                    if (day.isRecommended)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: GrokDesignSystem.accentBlue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Event type indicator (top-right)
            if (day.eventType != null && !hasOutfit)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _getEventColor(day.eventType!),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getEventColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'work':
        return GrokDesignSystem.accentBlue;
      case 'event':
        return GrokDesignSystem.accentPurple;
      case 'casual':
        return GrokDesignSystem.success;
      case 'formal':
        return GrokDesignSystem.textPrimary;
      default:
        return GrokDesignSystem.secondaryGray;
    }
  }
}


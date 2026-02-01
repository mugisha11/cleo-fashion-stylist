import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../../../core/models/calendar_day_model.dart';

/// Week Date Card - Large, fashion-styled date card for horizontal scroll
class WeekDateCard extends StatelessWidget {
  final CalendarDay day;
  final bool isSelected;
  final bool isToday;
  final VoidCallback? onTap;

  const WeekDateCard({
    super.key,
    required this.day,
    this.isSelected = false,
    this.isToday = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('EEE').format(day.date).toUpperCase();
    final dateNumber = day.date.day;
    final hasOutfit = day.hasOutfit;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: FashionDesignSystem.animationMedium,
        curve: Curves.easeOut,
        width: 72,
        margin: const EdgeInsets.only(right: FashionDesignSystem.spacingMD),
        decoration: BoxDecoration(
          color: isSelected
              ? FashionDesignSystem.primaryColor.withOpacity(0.1)
              : FashionDesignSystem.backgroundWhite,
          borderRadius: BorderRadius.circular(FashionDesignSystem.radiusLG),
          border: Border.all(
            color: isSelected
                ? FashionDesignSystem.primaryColor
                : (isToday
                    ? FashionDesignSystem.primaryColor.withOpacity(0.3)
                    : FashionDesignSystem.borderColor),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? FashionDesignSystem.cardShadow
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Day name
            Text(
              dayName,
              style: FashionDesignSystem.caption().copyWith(
                color: isSelected
                    ? FashionDesignSystem.primaryColor
                    : FashionDesignSystem.textSecondary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            
            const SizedBox(height: FashionDesignSystem.spacingXS),
            
            // Date number
            Text(
              '$dateNumber',
              style: FashionDesignSystem.headlineMedium().copyWith(
                color: isSelected
                    ? FashionDesignSystem.primaryColor
                    : FashionDesignSystem.textCharcoal,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: FashionDesignSystem.spacingSM),
            
            // Outfit preview thumbnail or event indicator
            if (hasOutfit && day.outfitImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(FashionDesignSystem.radiusSM),
                child: CachedNetworkImage(
                  imageUrl: day.outfitImageUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 40,
                    height: 40,
                    color: FashionDesignSystem.backgroundLight,
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 40,
                    height: 40,
                    color: FashionDesignSystem.backgroundLight,
                    child: const Icon(
                      Icons.image_outlined,
                      size: 16,
                      color: FashionDesignSystem.textTertiary,
                    ),
                  ),
                ),
              )
            else if (day.eventType != null)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getEventColor(day.eventType!),
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(
                width: 40,
                height: 40,
              ),
            
            // AI recommendation badge
            if (day.isRecommended)
              Padding(
                padding: const EdgeInsets.only(top: FashionDesignSystem.spacingXS),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FashionDesignSystem.spacingXS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: FashionDesignSystem.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'AI',
                    style: FashionDesignSystem.caption().copyWith(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
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
        return FashionDesignSystem.accentRose;
      case 'event':
        return FashionDesignSystem.accentGold;
      case 'casual':
        return FashionDesignSystem.successColor;
      case 'formal':
        return FashionDesignSystem.textCharcoal;
      default:
        return FashionDesignSystem.textSecondary;
    }
  }
}

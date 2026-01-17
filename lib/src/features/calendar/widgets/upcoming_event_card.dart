import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../../../core/models/calendar_day_model.dart';

/// Upcoming Event Card - Style-focused event card
class UpcomingEventCard extends StatelessWidget {
  final CalendarDay day;
  final VoidCallback? onEditOutfit;

  const UpcomingEventCard({
    super.key,
    required this.day,
    this.onEditOutfit,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d').format(day.date);
    final timeStr = day.eventName ?? day.eventType ?? 'Event';

    return Container(
      margin: EdgeInsets.only(
        bottom: FashionDesignSystem.spacingMD,
        left: FashionDesignSystem.spacingLG,
        right: FashionDesignSystem.spacingLG,
      ),
      padding: EdgeInsets.all(FashionDesignSystem.spacingLG),
      decoration: FashionDesignSystem.cardDecoration,
      child: Row(
        children: [
          // Outfit thumbnail
          if (day.hasOutfit && day.outfitImageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(FashionDesignSystem.radiusMD),
              child: CachedNetworkImage(
                imageUrl: day.outfitImageUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 60,
                  height: 60,
                  color: FashionDesignSystem.backgroundLight,
                ),
                errorWidget: (context, url, error) => Container(
                  width: 60,
                  height: 60,
                  color: FashionDesignSystem.backgroundLight,
                  child: Icon(
                    Icons.image_outlined,
                    size: 24,
                    color: FashionDesignSystem.textTertiary,
                  ),
                ),
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: FashionDesignSystem.backgroundLight,
                borderRadius: BorderRadius.circular(FashionDesignSystem.radiusMD),
              ),
              child: Icon(
                Icons.event_outlined,
                size: 24,
                color: FashionDesignSystem.textTertiary,
              ),
            ),
          
          SizedBox(width: FashionDesignSystem.spacingLG),
          
          // Event Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeStr,
                  style: FashionDesignSystem.titleMedium(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: FashionDesignSystem.spacingXS),
                Text(
                  dateStr,
                  style: FashionDesignSystem.bodySmall().copyWith(
                    color: FashionDesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Edit Outfit Button
          if (onEditOutfit != null)
            TextButton(
              onPressed: onEditOutfit,
              child: Text(
                'Edit Outfit',
                style: FashionDesignSystem.bodySmall().copyWith(
                  color: FashionDesignSystem.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

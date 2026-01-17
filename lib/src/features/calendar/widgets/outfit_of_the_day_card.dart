import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../../../core/models/calendar_day_model.dart';

/// Outfit of the Day Card - Hero section with large fashion image
class OutfitOfTheDayCard extends StatelessWidget {
  final CalendarDay? day;
  final VoidCallback? onTryOn;
  final VoidCallback? onChangeOutfit;

  const OutfitOfTheDayCard({
    super.key,
    this.day,
    this.onTryOn,
    this.onChangeOutfit,
  });

  @override
  Widget build(BuildContext context) {
    final hasOutfit = day?.hasOutfit ?? false;

    return Container(
      margin: EdgeInsets.all(FashionDesignSystem.spacingLG),
      decoration: FashionDesignSystem.heroCardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Hero Image
          if (hasOutfit && day!.outfitImageUrl != null)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: day!.outfitImageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: FashionDesignSystem.backgroundLight,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: FashionDesignSystem.primaryColor,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: FashionDesignSystem.backgroundLight,
                  child: Icon(
                    Icons.image_outlined,
                    size: 64,
                    color: FashionDesignSystem.textTertiary,
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: FashionDesignSystem.backgroundLight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.checkroom_outlined,
                      size: 64,
                      color: FashionDesignSystem.textTertiary,
                    ),
                    SizedBox(height: FashionDesignSystem.spacingMD),
                    Text(
                      'No outfit planned',
                      style: FashionDesignSystem.bodyMedium().copyWith(
                        color: FashionDesignSystem.textSecondary,
                      ),
                    ),
                  ],
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
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),
          
          // Content Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.all(FashionDesignSystem.spacingXXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Outfit Title
                  if (hasOutfit && day!.outfitName != null)
                    Text(
                      day!.outfitName!,
                      style: FashionDesignSystem.headlineMedium().copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                      ),
                    )
                  else
                    Text(
                      'Outfit of the Day',
                      style: FashionDesignSystem.headlineMedium().copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  
                  SizedBox(height: FashionDesignSystem.spacingSM),
                  
                  // Tags
                  if (hasOutfit && day!.eventType != null)
                    Wrap(
                      spacing: FashionDesignSystem.spacingSM,
                      children: [
                        _buildTag(day!.eventType!),
                        if (day!.isRecommended)
                          _buildTag('AI Recommended'),
                      ],
                    ),
                  
                  SizedBox(height: FashionDesignSystem.spacingLG),
                  
                  // Action Buttons
                  Row(
                    children: [
                      if (hasOutfit && onTryOn != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onTryOn,
                            icon: Icon(
                              Icons.auto_awesome,
                              size: FashionDesignSystem.iconSize,
                            ),
                            label: Text('Try On'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FashionDesignSystem.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: FashionDesignSystem.spacingMD,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  FashionDesignSystem.radiusMD,
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      if (hasOutfit && onTryOn != null)
                        SizedBox(width: FashionDesignSystem.spacingMD),
                      
                      TextButton(
                        onPressed: onChangeOutfit,
                        child: Text(
                          hasOutfit ? 'Change Outfit' : 'Plan Outfit',
                          style: FashionDesignSystem.bodyMedium().copyWith(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: FashionDesignSystem.spacingMD,
        vertical: FashionDesignSystem.spacingXS,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(FashionDesignSystem.radiusSM),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: FashionDesignSystem.caption().copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/dashboard_design_system.dart';

/// Fashion Recommendations Panel - Right Side
class FashionRecommendationsPanel extends StatefulWidget {
  final List<OutfitCard> outfits;
  final VoidCallback? onTryOnAvatar;
  final Function(OutfitCard)? onAddToWardrobe;
  final Function(OutfitCard)? onSaveOutfit;

  const FashionRecommendationsPanel({
    super.key,
    required this.outfits,
    this.onTryOnAvatar,
    this.onAddToWardrobe,
    this.onSaveOutfit,
  });

  @override
  State<FashionRecommendationsPanel> createState() =>
      _FashionRecommendationsPanelState();
}

class _FashionRecommendationsPanelState
    extends State<FashionRecommendationsPanel> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      width: isMobile ? double.infinity : DashboardDesignSystem.recommendationsPanelWidth,
      color: DashboardDesignSystem.sidebarBackground,
      child: Column(
        children: [
          // Header
          _buildHeader(isMobile),
          
          Divider(height: 1, color: DashboardDesignSystem.borderLight),
          
          // 3D Avatar Preview Area
          _buildAvatarPreview(isMobile),
          
          Divider(height: 1, color: DashboardDesignSystem.borderLight),
          
          // Outfit Recommendations
          Expanded(
            child: widget.outfits.isEmpty
                ? _buildEmptyState(isMobile)
                : _buildOutfitList(isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(
        isMobile
            ? DashboardDesignSystem.spacingMD
            : DashboardDesignSystem.spacingLG,
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 20,
            color: DashboardDesignSystem.accentTeal,
          ),
          const SizedBox(width: DashboardDesignSystem.spacingSM),
          Text(
            'Outfit Recommendations',
            style: DashboardDesignSystem.headlineMedium(isMobile: isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPreview(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(
        isMobile
            ? DashboardDesignSystem.spacingMD
            : DashboardDesignSystem.spacingLG,
      ),
      child: Column(
        children: [
          // 3D Avatar Placeholder
          Container(
            width: double.infinity,
            height: isMobile ? 200 : 240,
            decoration: BoxDecoration(
              color: DashboardDesignSystem.surfaceOffWhite,
              borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusLG),
              border: Border.all(
                color: DashboardDesignSystem.borderLight,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.face,
                  size: 64,
                  color: DashboardDesignSystem.textSecondary,
                ),
                const SizedBox(height: DashboardDesignSystem.spacingMD),
                Text(
                  '3D Avatar Preview',
                  style: DashboardDesignSystem.bodyMedium(isMobile: isMobile),
                ),
                const SizedBox(height: DashboardDesignSystem.spacingSM),
                Text(
                  'ReadyPlayer Me integration',
                  style: DashboardDesignSystem.caption(isMobile: isMobile),
                ),
              ],
            ),
          ),
          const SizedBox(height: DashboardDesignSystem.spacingMD),
          
          // Try On Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onTryOnAvatar,
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardDesignSystem.accentTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: DashboardDesignSystem.spacingMD,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusMD),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.checkroom, size: 18),
                  const SizedBox(width: DashboardDesignSystem.spacingSM),
                  Text(
                    'Try on Avatar',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isMobile
              ? DashboardDesignSystem.spacingLG
              : DashboardDesignSystem.spacingXL,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 48,
              color: DashboardDesignSystem.textSecondary,
            ),
            const SizedBox(height: DashboardDesignSystem.spacingMD),
            Text(
              'No recommendations yet',
              style: DashboardDesignSystem.bodyLarge(isMobile: isMobile),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DashboardDesignSystem.spacingSM),
            Text(
              'Chat with your AI stylist to get personalized outfit suggestions',
              style: DashboardDesignSystem.bodyMedium(isMobile: isMobile),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutfitList(bool isMobile) {
    return ListView.builder(
      padding: EdgeInsets.all(
        isMobile
            ? DashboardDesignSystem.spacingMD
            : DashboardDesignSystem.spacingLG,
      ),
      itemCount: widget.outfits.length,
      itemBuilder: (context, index) {
        return _buildOutfitCard(widget.outfits[index], isMobile);
      },
    );
  }

  Widget _buildOutfitCard(OutfitCard outfit, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: DashboardDesignSystem.spacingMD),
      decoration: BoxDecoration(
        color: DashboardDesignSystem.sidebarBackground,
        borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusLG),
        border: Border.all(
          color: DashboardDesignSystem.borderLight,
          width: 1,
        ),
        boxShadow: DashboardDesignSystem.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Outfit Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(DashboardDesignSystem.radiusLG),
              topRight: Radius.circular(DashboardDesignSystem.radiusLG),
            ),
            child: Container(
              width: double.infinity,
              height: isMobile ? 200 : 240,
              color: DashboardDesignSystem.surfaceOffWhite,
              child: outfit.imageUrl != null
                  ? Image.network(
                      outfit.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage(),
            ),
          ),
          
          // Outfit Details
          Padding(
            padding: EdgeInsets.all(
              isMobile
                  ? DashboardDesignSystem.spacingMD
                  : DashboardDesignSystem.spacingLG,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  outfit.title,
                  style: DashboardDesignSystem.headlineMedium(isMobile: isMobile),
                ),
                const SizedBox(height: DashboardDesignSystem.spacingXS),
                
                // Description
                if (outfit.description != null) ...[
                  Text(
                    outfit.description!,
                    style: DashboardDesignSystem.bodyMedium(isMobile: isMobile),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DashboardDesignSystem.spacingSM),
                ],
                
                // Tags
                if (outfit.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: DashboardDesignSystem.spacingXS,
                    runSpacing: DashboardDesignSystem.spacingXS,
                    children: outfit.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DashboardDesignSystem.spacingSM,
                          vertical: DashboardDesignSystem.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: DashboardDesignSystem.accentBlush,
                          borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusSM),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: DashboardDesignSystem.textCharcoal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: DashboardDesignSystem.spacingMD),
                ],
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => widget.onAddToWardrobe?.call(outfit),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DashboardDesignSystem.textCharcoal,
                          side: BorderSide(
                            color: DashboardDesignSystem.borderLight,
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: DashboardDesignSystem.spacingSM,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusMD),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, size: 16),
                            const SizedBox(width: DashboardDesignSystem.spacingXS),
                            Text(
                              'Add',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: DashboardDesignSystem.spacingSM),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => widget.onSaveOutfit?.call(outfit),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DashboardDesignSystem.secondaryLavender,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: DashboardDesignSystem.spacingSM,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusMD),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.favorite_border, size: 16),
                            const SizedBox(width: DashboardDesignSystem.spacingXS),
                            Text(
                              'Save',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(
          begin: 0.2,
          duration: 300.ms,
        );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: DashboardDesignSystem.surfaceOffWhite,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checkroom,
            size: 48,
            color: DashboardDesignSystem.textSecondary,
          ),
          const SizedBox(height: DashboardDesignSystem.spacingSM),
          Text(
            'Outfit Preview',
            style: DashboardDesignSystem.caption(),
          ),
        ],
      ),
    );
  }
}

class OutfitCard {
  final String title;
  final String? description;
  final String? imageUrl;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  OutfitCard({
    required this.title,
    this.description,
    this.imageUrl,
    this.tags = const [],
    this.metadata,
  });
}



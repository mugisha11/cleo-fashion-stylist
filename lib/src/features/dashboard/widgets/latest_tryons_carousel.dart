import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/models/tryon_session_model.dart';

/// Latest Try-Ons Carousel
/// Horizontal scrollable carousel of recent try-on images
class LatestTryOnsCarousel extends StatelessWidget {
  final List<TryOnSession> tryOns;
  final Function(TryOnSession) onTap;

  const LatestTryOnsCarousel({
    super.key,
    required this.tryOns,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (tryOns.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: isMobile ? 140 : 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tryOns.length,
        itemBuilder: (context, index) {
          final tryOn = tryOns[index];
          return _TryOnThumbnail(
            tryOn: tryOn,
            index: index,
            onTap: () => onTap(tryOn),
          );
        },
      ),
    );
  }
}

class _TryOnThumbnail extends StatelessWidget {
  final TryOnSession tryOn;
  final int index;
  final VoidCallback onTap;

  const _TryOnThumbnail({
    required this.tryOn,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final dateFormat = DateFormat('MMM d');

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.borderLight.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: tryOn.resultImageUrl,
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
                      Icons.image_not_supported,
                      color: theme.textTertiary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

            // Date
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                dateFormat.format(tryOn.createdAt),
                style: context.appTheme.bodySmall(
                  color: context.appTheme.textSecondary,
                ).copyWith(
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: (index * 50).ms)
        .slideX(begin: 0.1, duration: 300.ms, delay: (index * 50).ms);
  }
}

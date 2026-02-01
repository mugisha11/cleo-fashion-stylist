import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../../../core/models/calendar_day_model.dart';
import '../theme/calendar_theme.dart';
import '../screens/fashion_event_detail_screen.dart';
import 'quick_action_menu.dart';

/// Luxury Event Card - Glassmorphic card with try-on status
/// Enhanced with outfit preview and navigation to detail screen
class LuxuryEventCard extends ConsumerStatefulWidget {
  final CalendarDay day;
  final VoidCallback? onTryOn;

  const LuxuryEventCard({
    super.key,
    required this.day,
    this.onTryOn,
  });

  @override
  ConsumerState<LuxuryEventCard> createState() => _LuxuryEventCardState();
}

class _LuxuryEventCardState extends ConsumerState<LuxuryEventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isProcessing = false; // In production, get from try-on status

  @override
  void initState() {
    super.initState();
    
    // Shimmer animation for processing state
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    // Check if event has processing try-on
    _isProcessing = widget.day.outfitId != null; // Simplified check
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    if (_isProcessing) return CalendarTheme.processingAmber;
    if (widget.day.hasOutfit) return CalendarTheme.completedEmerald;
    return CalendarTheme.tryOnGreen;
  }

  String _getStatusText() {
    if (_isProcessing) return 'Processing';
    if (widget.day.hasOutfit) return 'Ready';
    return 'Try-On';
  }

  void _openEventDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FashionEventDetailScreen(
          calendarDay: widget.day,
          date: widget.day.date,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openEventDetails,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showQuickActionMenu(
          context: context,
          onViewDetails: _openEventDetails,
          onTryOn: widget.onTryOn,
          onEditOutfit: () {
            Navigator.pop(context);
            _openEventDetails();
          },
          onReschedule: () {
            Navigator.pop(context);
            // TODO: Show reschedule dialog
          },
          onDelete: () {
            Navigator.pop(context);
            // TODO: Show delete confirmation
          },
        );
      },
      child: Container(
        decoration: CalendarTheme.glassCard,
        child: Row(
          children: [
            // Preview Image
            if (widget.day.outfitImageUrl != null)
              _buildPreviewImage()
            else
              _buildPlaceholderImage(),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    Text(
                      DateFormat('EEEE, MMM d').format(widget.day.date),
                      style: CalendarTheme.captionText(
                        color: FashionDesignSystem.textSecondary,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Event Name
                    if (widget.day.eventName != null)
                      Text(
                        widget.day.eventName!,
                        style: CalendarTheme.headlineText(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    if (widget.day.eventType != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.day.eventType!,
                        style: CalendarTheme.bodyText(
                          color: FashionDesignSystem.textSecondary,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    // Status Badge
                    _buildStatusBadge(),
                  ],
                ),
              ),
            ),
            
            // Action Icon
            const Padding(
              padding: EdgeInsets.all(16),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: FashionDesignSystem.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewImage() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
        boxShadow: CalendarTheme.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: widget.day.outfitImageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: FashionDesignSystem.backgroundLight,
            ),
            errorWidget: (context, url, error) => Container(
              color: FashionDesignSystem.backgroundLight,
              child: const Icon(
                Icons.image_outlined,
                color: FashionDesignSystem.textTertiary,
              ),
            ),
          ),
          
          // Processing shimmer overlay
          if (_isProcessing)
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1 - _shimmerController.value * 2, 0),
                      end: Alignment(1 - _shimmerController.value * 2, 0),
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        color: FashionDesignSystem.backgroundLight,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: const Icon(
        Icons.checkroom_outlined,
        size: 40,
        color: FashionDesignSystem.textTertiary,
      ),
    );
  }

  Widget _buildStatusBadge() {
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: CalendarTheme.captionText(color: statusColor).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/models/calendar_day_model.dart';
import '../screens/fashion_event_detail_screen.dart';
import '../../../routes.dart';

/// Luxury Day View - Detailed single day view with swipe gestures
class LuxuryDayView extends StatefulWidget {
  final DateTime selectedDate;
  final Map<DateTime, CalendarDay> calendarDays;
  final VoidCallback? onTryOn;
  final Function(DateTime)? onDateChanged;

  const LuxuryDayView({
    super.key,
    required this.selectedDate,
    required this.calendarDays,
    this.onTryOn,
    this.onDateChanged,
  });

  @override
  State<LuxuryDayView> createState() => _LuxuryDayViewState();
}

class _LuxuryDayViewState extends State<LuxuryDayView> {
  late PageController _pageController;
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedDate;
    _pageController = PageController(initialPage: 0);
  }

  @override
  void didUpdateWidget(LuxuryDayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _currentDate = widget.selectedDate;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final newDate = _currentDate.add(Duration(days: index - 1));
    setState(() => _currentDate = newDate);
    widget.onDateChanged?.call(newDate);
    HapticFeedback.selectionClick();
  }

  void _openEventDetails(CalendarDay? day) {
    if (day == null) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FashionEventDetailScreen(
          calendarDay: day,
          date: _currentDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final dateKey = DateTime(
      _currentDate.year,
      _currentDate.month,
      _currentDate.day,
    );
    final calendarDay = widget.calendarDays[dateKey];
    final hasOutfit = calendarDay?.hasOutfit ?? false;

    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        final pageDate = widget.selectedDate.add(Duration(days: index - 1));
        final pageDateKey = DateTime(pageDate.year, pageDate.month, pageDate.day);
        final pageDay = widget.calendarDays[pageDateKey];
        final pageHasOutfit = pageDay?.hasOutfit ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Outfit Card
              if (pageHasOutfit && pageDay!.outfitImageUrl != null)
                _buildHeroOutfitCard(theme, pageDay)
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .scale(begin: const Offset(0.95, 0.95))
          else
                _buildEmptyState(theme)
                  .animate()
                  .fadeIn(duration: 300.ms),
          
          const SizedBox(height: 24),
          
          // Event Details
              if (pageDay != null && pageDay.eventName != null)
                _buildEventDetails(theme, pageDay)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 100.ms),
              
              // Try-On CTA
              if (pageHasOutfit)
                _buildTryOnCTA(theme, pageDay!)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 200.ms),
        ],
      ),
        );
      },
    );
  }

  Widget _buildHeroOutfitCard(AppThemeData theme, CalendarDay day) {
    return GestureDetector(
      onTap: () => _openEventDetails(day),
      child: Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Image
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: day.outfitImageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                  color: theme.surfaceElevated,
                child: Center(
                    child: CircularProgressIndicator(color: theme.primary),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: theme.surfaceElevated,
                  child: Icon(Icons.broken_image, color: theme.textTertiary),
              ),
            ),
          ),
          
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (day.outfitName != null)
                    Text(
                      day.outfitName!,
                        style: theme.titleLarge(color: Colors.white).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    ),
                  
                  if (day.eventType != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                          day.eventType!.toUpperCase(),
                          style: theme.bodySmall(color: Colors.white).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                    if (widget.onTryOn != null)
                    ElevatedButton.icon(
                        onPressed: widget.onTryOn,
                        icon: const Icon(Icons.checkroom, size: 20),
                      label: const Text('Try On'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppThemeData theme) {
    return GestureDetector(
      onTap: () {
        // Show AI assistant or add outfit dialog
        HapticFeedback.mediumImpact();
      },
      child: Container(
      height: 300,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.borderLight.withOpacity(0.3),
            width: 1,
          ),
        ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: 64,
                color: theme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No outfit planned',
                style: theme.titleMedium(color: theme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the AI assistant to plan one',
                style: theme.bodyMedium(color: theme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            ),
        ),
      ),
    );
  }

  Widget _buildEventDetails(AppThemeData theme, CalendarDay day) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.borderLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Details',
            style: theme.titleMedium(color: theme.textPrimary).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (day.eventName != null)
            _buildDetailRow(theme, Icons.event, day.eventName!),
          if (day.eventType != null)
            _buildDetailRow(theme, Icons.category, day.eventType!),
          if (day.isRecommended)
            _buildDetailRow(
              theme,
              Icons.auto_awesome,
              'AI Recommended',
              color: theme.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(AppThemeData theme, IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? theme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.bodyMedium(color: color ?? theme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTryOnCTA(AppThemeData theme, CalendarDay day) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.checkroom, color: theme.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ready to try this outfit?',
                  style: theme.bodyMedium(color: theme.textPrimary).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onTryOn ?? () {
                Navigator.of(context).pushNamed(Routes.tryon);
              },
              icon: const Icon(Icons.checkroom, size: 20),
              label: const Text('Try On Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

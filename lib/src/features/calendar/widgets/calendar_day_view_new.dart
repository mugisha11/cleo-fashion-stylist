import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/models/calendar_day_model.dart';
import 'fashion_event_card_new.dart';

/// Calendar Day View - Detailed single day with swipe navigation
class CalendarDayViewNew extends StatefulWidget {
  final DateTime selectedDate;
  final Map<DateTime, CalendarDay> calendarDays;
  final Function(DateTime) onDateSelected;
  final Function(CalendarDay) onEventTapped;

  const CalendarDayViewNew({
    super.key,
    required this.selectedDate,
    required this.calendarDays,
    required this.onDateSelected,
    required this.onEventTapped,
  });

  @override
  State<CalendarDayViewNew> createState() => _CalendarDayViewNewState();
}

class _CalendarDayViewNewState extends State<CalendarDayViewNew> {
  late PageController _pageController;
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedDate;
    _pageController = PageController(initialPage: 0);
  }

  @override
  void didUpdateWidget(CalendarDayViewNew oldWidget) {
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
    final newDate = widget.selectedDate.add(Duration(days: index - 1));
    setState(() => _currentDate = newDate);
    widget.onDateSelected(newDate);
    HapticFeedback.selectionClick();
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

    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        final pageDate = widget.selectedDate.add(Duration(days: index - 1));
        final pageDateKey = DateTime(pageDate.year, pageDate.month, pageDate.day);
        final pageDay = widget.calendarDays[pageDateKey];

        return SingleChildScrollView(
          key: ValueKey('day_${pageDateKey.toString()}'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day Header - Always visible
              _buildDayHeader(theme, pageDate),

              const SizedBox(height: 24),

              // Event Card
              if (pageDay != null && pageDay.hasOutfit)
                FashionEventCardNew(
                  event: pageDay,
                  onTap: () => widget.onEventTapped(pageDay),
                )
              else
                _buildEmptyState(theme, pageDate),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayHeader(AppThemeData theme, DateTime date) {
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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: theme.titleLarge(color: theme.primary).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDayName(date),
                  style: theme.titleMedium(color: theme.textPrimary).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getDateString(date),
                  style: theme.bodyMedium(color: theme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppThemeData theme, DateTime date) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.borderLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
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
    );
  }

  String _getDayName(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow';
    }
    return _getWeekdayName(date.weekday);
  }

  String _getWeekdayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getDateString(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

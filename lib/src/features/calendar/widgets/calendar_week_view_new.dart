import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/models/calendar_day_model.dart';
import 'fashion_event_card_new.dart';

/// Calendar Week View - Horizontal week layout with events
class CalendarWeekViewNew extends StatelessWidget {
  final DateTime selectedDate;
  final Map<DateTime, CalendarDay> calendarDays;
  final Function(DateTime) onDateSelected;
  final Function(CalendarDay) onEventTapped;

  const CalendarWeekViewNew({
    super.key,
    required this.selectedDate,
    required this.calendarDays,
    required this.onDateSelected,
    required this.onEventTapped,
  });

  List<DateTime> _getWeekDates(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final weekDates = _getWeekDates(selectedDate);
    final today = DateTime.now();

    return Column(
      children: [
        // Week Header - Always visible
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.surfaceElevated,
            border: Border(
              bottom: BorderSide(
                color: theme.borderLight.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: weekDates.map((date) {
              final dateKey = DateTime(date.year, date.month, date.day);
              final calendarDay = calendarDays[dateKey];
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isSelected = date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;
              final hasEvent = calendarDay?.hasEvent ?? false;

              return Expanded(
                child: _buildWeekDayHeader(
                  theme,
                  date: date,
                  isToday: isToday,
                  isSelected: isSelected,
                  hasEvent: hasEvent,
                ),
              );
            }).toList(),
          ),
        ),

        // Events List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Events for each day
              ...weekDates.map((date) {
                final dateKey = DateTime(date.year, date.month, date.day);
                final calendarDay = calendarDays[dateKey];

                if (calendarDay == null || !calendarDay.hasEvent) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FashionEventCardNew(
                    event: calendarDay,
                    onTap: () => onEventTapped(calendarDay),
                  ),
                ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.1);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDayHeader(
    AppThemeData theme, {
    required DateTime date,
    required bool isToday,
    required bool isSelected,
    required bool hasEvent,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onDateSelected(date);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primary
              : (isToday ? theme.primary.withOpacity(0.1) : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              DateFormat('EEE').format(date),
              style: theme
                  .bodySmall(
                    color: isSelected ? Colors.white : theme.textSecondary,
                  )
                  .copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: theme
                  .bodyMedium(
                    color: isSelected
                        ? Colors.white
                        : (isToday ? theme.primary : theme.textPrimary),
                  )
                  .copyWith(
                    fontWeight: (isSelected || isToday)
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
            ),
            if (hasEvent)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : theme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

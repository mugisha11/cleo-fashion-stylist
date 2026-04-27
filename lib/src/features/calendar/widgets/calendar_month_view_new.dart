import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/models/calendar_day_model.dart';

/// Calendar Month View - Clean grid layout with event indicators
class CalendarMonthViewNew extends StatelessWidget {
  final DateTime selectedDate;
  final Map<DateTime, CalendarDay> calendarDays;
  final Function(DateTime) onDateSelected;
  final Function(CalendarDay) onEventTapped;

  const CalendarMonthViewNew({
    super.key,
    required this.selectedDate,
    required this.calendarDays,
    required this.onDateSelected,
    required this.onEventTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final firstDay = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final firstWeekday = firstDay.weekday;
    final daysInMonth = lastDay.day;
    final today = DateTime.now();

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Weekday Headers
          Row(
            children: weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      day,
                      style:
                          theme.bodySmall(color: theme.textSecondary).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const Divider(height: 1),

          // Calendar Grid
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.1,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
              ),
              itemCount: firstWeekday - 1 + daysInMonth,
              itemBuilder: (context, index) {
                if (index < firstWeekday - 1) {
                  return const SizedBox(); // Empty cell
                }

                final day = index - (firstWeekday - 1) + 1;
                final date =
                    DateTime(selectedDate.year, selectedDate.month, day);
                final dateKey = DateTime(date.year, date.month, date.day);
                final calendarDay = calendarDays[dateKey];

                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final isSelected = date.year == selectedDate.year &&
                    date.month == selectedDate.month &&
                    date.day == selectedDate.day;
                final hasEvent = calendarDay?.hasEvent ?? false;

                return _buildDayCell(
                  theme,
                  date: date,
                  day: day,
                  isToday: isToday,
                  isSelected: isSelected,
                  hasEvent: hasEvent,
                  calendarDay: calendarDay,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    AppThemeData theme, {
    required DateTime date,
    required int day,
    required bool isToday,
    required bool isSelected,
    required bool hasEvent,
    CalendarDay? calendarDay,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (calendarDay != null && hasEvent) {
          onEventTapped(calendarDay);
        } else {
          onDateSelected(date);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primary.withOpacity(0.15)
              : (isToday
                  ? theme.primary.withOpacity(0.08)
                  : theme.surfaceElevated),
          border: Border.all(
            color: isSelected
                ? theme.primary.withOpacity(0.3)
                : theme.borderLight.withOpacity(0.2),
            width: isSelected ? 1.5 : 0.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day Number
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: (isSelected || isToday)
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? theme.primary
                          : (isToday ? theme.primary : theme.textPrimary),
                    ),
                  ),

                  const Spacer(),

                  // Event Indicator
                  if (hasEvent && calendarDay != null)
                    GestureDetector(
                      onTap: () => onEventTapped(calendarDay),
                      child: Container(
                        height: 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms, delay: (day * 10).ms);
  }
}

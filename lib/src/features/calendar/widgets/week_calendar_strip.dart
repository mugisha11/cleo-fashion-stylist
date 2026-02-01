import 'package:flutter/material.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../../../core/models/calendar_day_model.dart';
import 'week_date_card.dart';

/// Week Calendar Strip - Horizontal scrollable week view
class WeekCalendarStrip extends StatelessWidget {
  final DateTime selectedDate;
  final Map<DateTime, CalendarDay> calendarDays;
  final Function(DateTime) onDateSelected;
  final ScrollController? scrollController;

  const WeekCalendarStrip({
    super.key,
    required this.selectedDate,
    required this.calendarDays,
    required this.onDateSelected,
    this.scrollController,
  });

  List<DateTime> _getWeekDates(DateTime date) {
    // Get Monday of the week
    final monday = date.subtract(Duration(days: date.weekday - 1));
    
    // Return 7 days starting from Monday
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = _getWeekDates(selectedDate);
    final today = DateTime.now();

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: FashionDesignSystem.spacingMD),
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: FashionDesignSystem.spacingLG),
        itemCount: weekDates.length,
        itemBuilder: (context, index) {
          final date = weekDates[index];
          final dateKey = DateTime(date.year, date.month, date.day);
          final calendarDay = calendarDays[dateKey] ?? CalendarDay(date: dateKey);
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
          final isSelected = selectedDate.year == date.year &&
              selectedDate.month == date.month &&
              selectedDate.day == date.day;

          return WeekDateCard(
            day: calendarDay,
            isSelected: isSelected,
            isToday: isToday,
            onTap: () => onDateSelected(date),
          );
        },
      ),
    );
  }
}

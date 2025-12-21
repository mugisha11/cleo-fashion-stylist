import 'package:flutter/material.dart';
import '../../../core/theme/grok_design_system.dart';
import '../../../core/models/calendar_day_model.dart';
import 'calendar_day_cell.dart';

/// Calendar Grid - Monthly calendar view
class CalendarGrid extends StatelessWidget {
  final DateTime currentMonth;
  final Map<DateTime, CalendarDay> calendarDays;
  final DateTime? selectedDate;
  final Function(DateTime) onDayTap;

  const CalendarGrid({
    super.key,
    required this.currentMonth,
    required this.calendarDays,
    this.selectedDate,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get first day of month and first Monday of the calendar view
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final firstMonday = firstDayOfMonth.subtract(
      Duration(days: (firstDayOfMonth.weekday - 1) % 7),
    );

    // Get last day of month
    final lastDayOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final lastSunday = lastDayOfMonth.add(
      Duration(days: (7 - lastDayOfMonth.weekday) % 7),
    );

    // Calculate number of weeks
    final daysDiff = lastSunday.difference(firstMonday).inDays;
    final weeks = (daysDiff + 1) ~/ 7;

    return Column(
      children: [
        // Weekday headers
        _buildWeekdayHeaders(),
        
        // Calendar grid
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
            ),
            itemCount: weeks * 7,
            itemBuilder: (context, index) {
              final date = firstMonday.add(Duration(days: index));
              final isCurrentMonth = date.month == currentMonth.month;
              
              // Get calendar day data if exists
              final dateKey = DateTime(date.year, date.month, date.day);
              final calendarDay = calendarDays[dateKey] ?? 
                  CalendarDay(date: dateKey);

              return CalendarDayCell(
                day: calendarDay,
                isSelected: selectedDate != null &&
                    selectedDate!.year == date.year &&
                    selectedDate!.month == date.month &&
                    selectedDate!.day == date.day,
                onTap: isCurrentMonth ? () => onDayTap(date) : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: GrokDesignSystem.spacingSM),
      decoration: const BoxDecoration(
        color: GrokDesignSystem.backgroundOffWhite,
        border: Border(
          bottom: BorderSide(
            color: GrokDesignSystem.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: weekdays.map((day) {
          return Expanded(
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: GrokDesignSystem.bodySmall().copyWith(
                fontWeight: FontWeight.w500,
                color: GrokDesignSystem.textSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}


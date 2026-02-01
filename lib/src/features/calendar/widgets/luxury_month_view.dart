import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../../../core/models/calendar_day_model.dart';
import '../theme/calendar_theme.dart';
import '../screens/fashion_event_detail_screen.dart';

/// Luxury Month View - Elegant grid calendar with event detail navigation
class LuxuryMonthView extends StatelessWidget {
  final DateTime selectedDate;
  final Map<DateTime, CalendarDay> calendarDays;
  final Function(DateTime) onDateSelected;

  const LuxuryMonthView({
    super.key,
    required this.selectedDate,
    required this.calendarDays,
    required this.onDateSelected,
  });

  void _onDayTapped(BuildContext context, DateTime date, CalendarDay? day) {
    HapticFeedback.lightImpact();
    
    // If day has an event, open detail screen
    if (day != null && (day.hasOutfit || day.eventName != null || day.eventType != null)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FashionEventDetailScreen(
            calendarDay: day,
            date: date,
          ),
        ),
      );
    } else {
      // Otherwise, just select the date
      onDateSelected(date);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Weekday headers
          Row(
            children: weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: CalendarTheme.captionText(
                      color: FashionDesignSystem.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 12),
          
          // Calendar grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: firstWeekday - 1 + daysInMonth,
              itemBuilder: (context, index) {
                if (index < firstWeekday - 1) {
                  return const SizedBox(); // Empty cell
                }
                
                final day = index - (firstWeekday - 1) + 1;
                final date = DateTime(selectedDate.year, selectedDate.month, day);
                final dateKey = DateTime(date.year, date.month, date.day);
                final calendarDay = calendarDays[dateKey];
                
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final isSelected = date.year == selectedDate.year &&
                    date.month == selectedDate.month &&
                    date.day == selectedDate.day;
                final hasEvent = calendarDay?.hasOutfit ?? false;

                return _buildDayCell(
                  context: context,
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

  Widget _buildDayCell({
    required BuildContext context,
    required DateTime date,
    required int day,
    required bool isToday,
    required bool isSelected,
    required bool hasEvent,
    CalendarDay? calendarDay,
  }) {
    return GestureDetector(
      onTap: () => _onDayTapped(context, date, calendarDay),
      child: AnimatedContainer(
        duration: CalendarTheme.fastAnimation,
        curve: CalendarTheme.springCurve,
        decoration: BoxDecoration(
          color: isSelected
              ? CalendarTheme.electricAccent.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isToday
              ? Border.all(
                  color: CalendarTheme.electricAccent,
                  width: 2,
                )
              : null,
        ),
        child: Stack(
          children: [
            // Day number
            Center(
              child: Text(
                '$day',
                style: CalendarTheme.bodyText(
                  color: isSelected
                      ? CalendarTheme.electricAccent
                      : (isToday
                          ? CalendarTheme.electricAccent
                          : FashionDesignSystem.textCharcoal),
                ).copyWith(
                  fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            
            // Event indicator
            if (hasEvent)
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: CalendarTheme.tryOnGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

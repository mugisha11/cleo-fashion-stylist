import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../../../core/models/calendar_day_model.dart';
import '../theme/calendar_theme.dart';
import '../screens/fashion_event_detail_screen.dart';

/// Luxury Week View - Horizontal scrollable week with event detail navigation
class LuxuryWeekView extends StatelessWidget {
  final DateTime selectedDate;
  final Map<DateTime, CalendarDay> calendarDays;
  final Function(DateTime) onDateSelected;

  const LuxuryWeekView({
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

  List<DateTime> _getWeekDates(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = _getWeekDates(selectedDate);
    final today = DateTime.now();

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: weekDates.length,
      itemBuilder: (context, index) {
        final date = weekDates[index];
        final dateKey = DateTime(date.year, date.month, date.day);
        final calendarDay = calendarDays[dateKey];
        
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final isSelected = selectedDate.year == date.year &&
            selectedDate.month == date.month &&
            selectedDate.day == date.day;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildDayCard(
            context: context,
            date: date,
            calendarDay: calendarDay,
            isToday: isToday,
            isSelected: isSelected,
          ),
        );
      },
    );
  }

  Widget _buildDayCard({
    required BuildContext context,
    required DateTime date,
    CalendarDay? calendarDay,
    required bool isToday,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _onDayTapped(context, date, calendarDay),
      child: AnimatedContainer(
        duration: CalendarTheme.mediumAnimation,
        curve: CalendarTheme.springCurve,
        width: 80,
        decoration: BoxDecoration(
          gradient: isSelected
              ? CalendarTheme.primaryGradient
              : (isToday
                  ? LinearGradient(
                      colors: [
                        CalendarTheme.electricAccent.withOpacity(0.1),
                        CalendarTheme.electricAccent.withOpacity(0.05),
                      ],
                    )
                  : null),
          color: isSelected || isToday
              ? null
              : CalendarTheme.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isToday
                    ? CalendarTheme.electricAccent
                    : CalendarTheme.glassBorder),
            width: isToday ? 2 : 1,
          ),
          boxShadow: isSelected ? CalendarTheme.softShadow : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Day name
            Text(
              DateFormat('EEE').format(date),
              style: CalendarTheme.captionText(
                color: isSelected
                    ? Colors.white
                    : FashionDesignSystem.textSecondary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Day number
            Text(
              '${date.day}',
              style: CalendarTheme.headlineText(
                color: isSelected
                    ? Colors.white
                    : (isToday
                        ? CalendarTheme.electricAccent
                        : FashionDesignSystem.textCharcoal),
              ).copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            // Event indicator
            if (calendarDay?.hasOutfit ?? false) ...[
              const SizedBox(height: 8),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : CalendarTheme.tryOnGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

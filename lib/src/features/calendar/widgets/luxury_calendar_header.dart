import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../theme/calendar_theme.dart';
import '../screens/luxury_calendar_screen.dart';

/// Luxury Calendar Header with View Switcher
class LuxuryCalendarHeader extends StatelessWidget {
  final DateTime selectedDate;
  final CalendarView currentView;
  final Function(CalendarView) onViewChanged;
  final Function(DateTime) onDateChanged;

  const LuxuryCalendarHeader({
    super.key,
    required this.selectedDate,
    required this.currentView,
    required this.onViewChanged,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: CalendarTheme.subtleGradient,
        boxShadow: CalendarTheme.softShadow,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Date Display with Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous Month
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      final prev = DateTime(
                        selectedDate.year,
                        selectedDate.month - 1,
                      );
                      onDateChanged(prev);
                    },
                    color: CalendarTheme.deepCharcoal,
                  ),
                  
                  // Current Month/Date
                  GestureDetector(
                    onTap: () => _showDatePicker(context),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(selectedDate),
                          style: CalendarTheme.headlineText(),
                        ),
                        if (currentView == CalendarView.day)
                          Text(
                            DateFormat('EEEE, d').format(selectedDate),
                            style: CalendarTheme.captionText(
                              color: FashionDesignSystem.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Next Month
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      final next = DateTime(
                        selectedDate.year,
                        selectedDate.month + 1,
                      );
                      onDateChanged(next);
                    },
                    color: CalendarTheme.deepCharcoal,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // View Switcher
              Container(
                decoration: CalendarTheme.glassCard,
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildViewButton(
                      CalendarView.month,
                      Icons.calendar_view_month,
                      'Month',
                    ),
                    _buildViewButton(
                      CalendarView.week,
                      Icons.calendar_view_week,
                      'Week',
                    ),
                    _buildViewButton(
                      CalendarView.day,
                      Icons.today,
                      'Day',
                    ),
                    _buildViewButton(
                      CalendarView.timeline,
                      Icons.timeline,
                      'Timeline',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewButton(CalendarView view, IconData icon, String label) {
    final isSelected = currentView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () => onViewChanged(view),
        child: AnimatedContainer(
          duration: CalendarTheme.fastAnimation,
          curve: CalendarTheme.springCurve,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? CalendarTheme.electricAccent.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? CalendarTheme.electricAccent
                    : FashionDesignSystem.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: CalendarTheme.captionText(
                  color: isSelected
                      ? CalendarTheme.electricAccent
                      : FashionDesignSystem.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDatePicker(BuildContext context) {
    showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: CalendarTheme.electricAccent,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    ).then((date) {
      if (date != null) {
        onDateChanged(date);
      }
    });
  }
}

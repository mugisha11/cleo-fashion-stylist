import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../screens/fashion_calendar_screen.dart';

/// Calendar Header - Clean, modern header with view switcher
class CalendarHeaderNew extends StatelessWidget {
  final DateTime selectedDate;
  final CalendarViewMode viewMode;
  final Function(CalendarViewMode) onViewChanged;
  final Function(DateTime) onDateChanged;

  const CalendarHeaderNew({
    super.key,
    required this.selectedDate,
    required this.viewMode,
    required this.onViewChanged,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.borderLight.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: 16,
        ),
        child: Column(
          children: [
            // Date Navigation Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous
                IconButton(
                  icon: Icon(Icons.chevron_left, color: theme.textPrimary),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _navigateDate(-1);
                  },
                ),

                // Current Date Display
                GestureDetector(
                  onTap: () => _showDatePicker(context, theme),
                  child: Column(
                    children: [
                      Text(
                        _getDateTitle(),
                        style: theme.titleLarge(color: theme.textPrimary).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (viewMode == CalendarViewMode.day)
                        Text(
                          DateFormat('EEEE').format(selectedDate),
                          style: theme.bodySmall(color: theme.textSecondary),
                        ),
                    ],
                  ),
                ),

                // Next
                IconButton(
                  icon: Icon(Icons.chevron_right, color: theme.textPrimary),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _navigateDate(1);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // View Mode Switcher
            Container(
              decoration: BoxDecoration(
                color: theme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildViewButton(
                    theme,
                    CalendarViewMode.day,
                    Icons.today,
                    'Day',
                  ),
                  _buildViewButton(
                    theme,
                    CalendarViewMode.week,
                    Icons.view_week,
                    'Week',
                  ),
                  _buildViewButton(
                    theme,
                    CalendarViewMode.month,
                    Icons.calendar_month,
                    'Month',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewButton(
    AppThemeData theme,
    CalendarViewMode mode,
    IconData icon,
    String label,
  ) {
    final isSelected = viewMode == mode;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onViewChanged(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : theme.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.bodySmall(
                  color: isSelected ? Colors.white : theme.textSecondary,
                ).copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDateTitle() {
    switch (viewMode) {
      case CalendarViewMode.day:
        return DateFormat('MMMM d, y').format(selectedDate);
      case CalendarViewMode.week:
        final weekStart = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d, y').format(weekEnd)}';
      case CalendarViewMode.month:
        return DateFormat('MMMM yyyy').format(selectedDate);
    }
  }

  void _navigateDate(int days) {
    DateTime newDate;
    switch (viewMode) {
      case CalendarViewMode.day:
        newDate = selectedDate.add(Duration(days: days));
        break;
      case CalendarViewMode.week:
        newDate = selectedDate.add(Duration(days: days * 7));
        break;
      case CalendarViewMode.month:
        newDate = DateTime(selectedDate.year, selectedDate.month + days, 1);
        break;
    }
    onDateChanged(newDate);
  }

  void _showDatePicker(BuildContext context, AppThemeData theme) {
    showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: theme.primary),
          ),
          child: child!,
        );
      },
    ).then((date) {
      if (date != null) {
        HapticFeedback.mediumImpact();
        onDateChanged(date);
      }
    });
  }
}

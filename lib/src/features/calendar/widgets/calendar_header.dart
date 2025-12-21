import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/grok_design_system.dart';

/// Calendar Header - Month/Year display with navigation
class CalendarHeader extends StatelessWidget {
  final DateTime currentMonth;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;
  final VoidCallback? onAddEvent;
  final VoidCallback? onBack;

  const CalendarHeader({
    super.key,
    required this.currentMonth,
    this.onPreviousMonth,
    this.onNextMonth,
    this.onAddEvent,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final monthYear = DateFormat('MMMM yyyy').format(currentMonth);
    final isToday = DateTime.now().year == currentMonth.year &&
        DateTime.now().month == currentMonth.month;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: GrokDesignSystem.spacingMD),
      decoration: const BoxDecoration(
        color: GrokDesignSystem.backgroundWhite,
        border: Border(
          bottom: BorderSide(
            color: GrokDesignSystem.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button or hamburger
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              onPressed: () {
                HapticFeedback.lightImpact();
                onBack?.call();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
            )
          else
            const SizedBox(width: 44),
          
          // Month + Year (centered)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous month arrow
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 24),
                  onPressed: onPreviousMonth != null
                      ? () {
                          HapticFeedback.lightImpact();
                          onPreviousMonth?.call();
                        }
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
                
                // Month/Year text
                GestureDetector(
                  onTap: isToday
                      ? () {
                          HapticFeedback.lightImpact();
                          // Could show month picker here
                        }
                      : null,
                  child: Text(
                    monthYear,
                    style: GrokDesignSystem.headlineSmall(),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Next month arrow
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 24),
                  onPressed: onNextMonth != null
                      ? () {
                          HapticFeedback.lightImpact();
                          onNextMonth?.call();
                        }
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ],
            ),
          ),
          
          // Add event button
          if (onAddEvent != null)
            IconButton(
              icon: const Icon(Icons.add, size: 24),
              onPressed: () {
                HapticFeedback.lightImpact();
                onAddEvent?.call();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
            )
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }
}


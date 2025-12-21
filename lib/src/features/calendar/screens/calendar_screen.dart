import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../../../core/widgets/fashion_scaffold.dart';
import '../../../core/models/calendar_day_model.dart';
import '../providers/calendar_provider.dart';
import '../widgets/week_calendar_strip.dart';
import '../widgets/outfit_of_the_day_card.dart';
import '../widgets/upcoming_event_card.dart';
import '../widgets/ai_calendar_assistant.dart';
import '../../../routes.dart';

/// Calendar Screen - AI-powered outfit planning calendar
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final ScrollController _weekScrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Initialize calendar to current month
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calendarStateProvider.notifier).goToToday();
      _selectedDate = DateTime.now();
    });
  }

  @override
  void dispose() {
    _weekScrollController.dispose();
    super.dispose();
  }

  void _onDateSelected(DateTime date) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedDate = date;
    });
    ref.read(selectedDayProvider.notifier).state = date;
  }

  void _onTryOn() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushNamed(Routes.tryon);
  }

  void _onChangeOutfit() {
    HapticFeedback.mediumImpact();
    // TODO: Show outfit planning dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Outfit planning coming soon!')),
    );
  }

  void _onEditEventOutfit(CalendarDay day) {
    HapticFeedback.mediumImpact();
    // TODO: Show edit outfit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit outfit coming soon!')),
    );
  }

  List<CalendarDay> _getUpcomingEvents(Map<DateTime, CalendarDay> calendarDays) {
    final now = DateTime.now();
    final upcoming = calendarDays.values
        .where((day) => day.date.isAfter(now) && (day.eventName != null || day.eventType != null))
        .toList();
    upcoming.sort((a, b) => a.date.compareTo(b.date));
    return upcoming.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(calendarStateProvider);
    final calendarDaysAsync = ref.watch(
      calendarDaysProvider(DateTime(calendarState.currentMonth.year, calendarState.currentMonth.month)),
    );

    return FashionScaffold(
      title: 'Style Calendar',
      currentBottomNavIndex: 0,
      currentRoute: Routes.calendar,
      body: calendarDaysAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            color: FashionDesignSystem.primaryColor,
          ),
        ),
        error: (error, stack) {
          // Show error but still allow calendar to display with empty data
          return Column(
          children: [
              Container(
                margin: EdgeInsets.all(FashionDesignSystem.spacingLG),
                padding: EdgeInsets.all(FashionDesignSystem.spacingMD),
                decoration: BoxDecoration(
                  color: FashionDesignSystem.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(FashionDesignSystem.radiusMD),
                ),
                child: Row(
                    children: [
                      Icon(
                      Icons.info_outline,
                      color: FashionDesignSystem.errorColor,
                      size: FashionDesignSystem.iconSize,
                      ),
                    SizedBox(width: FashionDesignSystem.spacingMD),
                    Expanded(
                      child: Text(
                        'Calendar data unavailable. Showing empty calendar.',
                        style: FashionDesignSystem.bodySmall().copyWith(
                          color: FashionDesignSystem.errorColor,
                        ),
                      ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _buildCalendarContent(<DateTime, CalendarDay>{}),
            ),
          ],
          );
        },
        data: (calendarDays) => _buildCalendarContent(calendarDays),
      ),
    );
  }

  Widget _buildCalendarContent(Map<DateTime, CalendarDay> calendarDays) {
    final selectedDateKey = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final selectedDay = calendarDays[selectedDateKey];
    final upcomingEvents = _getUpcomingEvents(calendarDays);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week Calendar Strip
          WeekCalendarStrip(
            selectedDate: _selectedDate,
            calendarDays: calendarDays,
            onDateSelected: _onDateSelected,
            scrollController: _weekScrollController,
          ),
          
          SizedBox(height: FashionDesignSystem.spacingLG),
          
          // Outfit of the Day (Hero Section)
          OutfitOfTheDayCard(
            day: selectedDay,
            onTryOn: selectedDay?.hasOutfit == true ? _onTryOn : null,
            onChangeOutfit: _onChangeOutfit,
          ),
          
          SizedBox(height: FashionDesignSystem.spacingXXL),
          
          // Upcoming Events Section
          if (upcomingEvents.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: FashionDesignSystem.spacingLG,
              ),
              child: Text(
                'Upcoming Events',
                style: FashionDesignSystem.titleLarge(),
              ),
            ),
            SizedBox(height: FashionDesignSystem.spacingMD),
            ...upcomingEvents.map((day) => UpcomingEventCard(
              day: day,
              onEditOutfit: () => _onEditEventOutfit(day),
            )),
            SizedBox(height: FashionDesignSystem.spacingXXL),
          ],
          
          // AI Calendar Assistant (Optional)
          AICalendarAssistant(
            message: 'You have a formal meeting Friday. Want outfit ideas?',
            onAction: () {
              // TODO: Navigate to recommendations
            },
          ),
          
          SizedBox(height: FashionDesignSystem.spacingXXL),
        ],
      ),
    );
  }
}

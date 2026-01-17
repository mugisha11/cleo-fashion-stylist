import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/fashion_scaffold.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/models/calendar_day_model.dart';
import '../providers/calendar_provider.dart';
import '../widgets/calendar_header_new.dart';
import '../widgets/calendar_day_view_new.dart';
import '../widgets/calendar_week_view_new.dart';
import '../widgets/calendar_month_view_new.dart';
import '../widgets/event_detail_drawer.dart';
import '../widgets/ai_assistant_button.dart';
import '../widgets/ai_assistant_dialog.dart';
import '../../../routes.dart';

/// Fashion Calendar Screen - Complete redesign from scratch
/// World-class, Google Calendar-inspired, fashion-aware calendar
class FashionCalendarScreen extends ConsumerStatefulWidget {
  const FashionCalendarScreen({super.key});

  @override
  ConsumerState<FashionCalendarScreen> createState() => _FashionCalendarScreenState();
}

enum CalendarViewMode { day, week, month }

class _FashionCalendarScreenState extends ConsumerState<FashionCalendarScreen>
    with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  CalendarViewMode _viewMode = CalendarViewMode.month;
  CalendarDay? _selectedEvent;
  bool _showEventDrawer = false;

  late AnimationController _viewTransitionController;
  late AnimationController _drawerController;
  late Animation<double> _drawerAnimation;

  @override
  void initState() {
    super.initState();
    
    _viewTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    
    _drawerAnimation = CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeOutCubic,
    );

    // Initialize calendar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calendarStateProvider.notifier).goToToday();
    });
  }

  @override
  void dispose() {
    _viewTransitionController.dispose();
    _drawerController.dispose();
    super.dispose();
  }

  void _switchView(CalendarViewMode mode) {
    if (_viewMode == mode) return;
    
    HapticFeedback.selectionClick();
    setState(() => _viewMode = mode);
    // Reset animation controller to ensure content is visible
    _viewTransitionController.reset();
  }

  void _onDateSelected(DateTime date) {
    HapticFeedback.lightImpact();
    setState(() => _selectedDate = date);
    ref.read(selectedDayProvider.notifier).state = date;
  }

  void _onEventTapped(CalendarDay event) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedEvent = event;
      _showEventDrawer = true;
    });
    _drawerController.forward();
  }

  void _closeEventDrawer() {
    _drawerController.reverse().then((_) {
      setState(() {
        _showEventDrawer = false;
        _selectedEvent = null;
      });
    });
  }

  void _onTryOn() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushNamed(Routes.tryon);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final calendarState = ref.watch(calendarStateProvider);
    final calendarDaysAsync = ref.watch(
      calendarDaysProvider(
        DateTime(calendarState.currentMonth.year, calendarState.currentMonth.month),
      ),
    );

    return FashionScaffold(
      title: 'Calendar',
      currentBottomNavIndex: 0,
      currentRoute: Routes.calendar,
      backgroundColor: theme.backgroundPrimary,
      body: Container(
        decoration: theme.backgroundGradient != null
            ? BoxDecoration(gradient: theme.backgroundGradient)
            : BoxDecoration(color: theme.backgroundPrimary),
        child: SafeArea(
          child: calendarDaysAsync.when(
            loading: () => _buildLoadingState(theme),
            error: (error, stack) => _buildErrorState(error, theme),
            data: (calendarDays) => _buildCalendarContent(theme, calendarDays),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.primary),
          const SizedBox(height: 24),
          Text(
            'Loading calendar...',
            style: theme.bodyMedium(color: theme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, AppThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.accentError),
            const SizedBox(height: 16),
            Text(
              'Unable to load calendar',
              style: theme.titleMedium(color: theme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection',
              style: theme.bodyMedium(color: theme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarContent(AppThemeData theme, Map<DateTime, CalendarDay> calendarDays) {
    return Stack(
      children: [
        // Main Calendar Content
        Column(
          children: [
            // Header
            CalendarHeaderNew(
              selectedDate: _selectedDate,
              viewMode: _viewMode,
              onViewChanged: _switchView,
              onDateChanged: (date) {
                setState(() => _selectedDate = date);
                // Only update month if we're in month view or if month actually changed
                final currentMonth = ref.read(calendarStateProvider).currentMonth;
                if (date.year != currentMonth.year || date.month != currentMonth.month) {
                  ref.read(calendarStateProvider.notifier).setMonth(date);
                }
              },
            ),

            // Calendar View
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: _buildCalendarView(calendarDays),
              ),
            ),
          ],
        ),

        // Event Detail Drawer
        if (_showEventDrawer && _selectedEvent != null)
          GestureDetector(
            onTap: _closeEventDrawer,
            child: Container(
              color: Colors.black.withValues(alpha: 0.5 * _drawerAnimation.value),
            ),
          ),
        
        if (_showEventDrawer && _selectedEvent != null)
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(_drawerAnimation),
            child: EventDetailDrawer(
              event: _selectedEvent!,
              onClose: _closeEventDrawer,
              onTryOn: _onTryOn,
            ),
          ),

        // Floating AI Assistant
        Positioned(
          bottom: 24,
          right: 24,
          child: AIAssistantButton(
            onTap: () {
              HapticFeedback.mediumImpact();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AIAssistantDialog(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarView(Map<DateTime, CalendarDay> calendarDays) {
    Widget view;
    switch (_viewMode) {
      case CalendarViewMode.day:
        view = CalendarDayViewNew(
          key: const ValueKey('day'),
          selectedDate: _selectedDate,
          calendarDays: calendarDays,
          onDateSelected: _onDateSelected,
          onEventTapped: _onEventTapped,
        );
        break;
      case CalendarViewMode.week:
        view = CalendarWeekViewNew(
          key: const ValueKey('week'),
          selectedDate: _selectedDate,
          calendarDays: calendarDays,
          onDateSelected: _onDateSelected,
          onEventTapped: _onEventTapped,
        );
        break;
      case CalendarViewMode.month:
        view = CalendarMonthViewNew(
          key: const ValueKey('month'),
          selectedDate: _selectedDate,
          calendarDays: calendarDays,
          onDateSelected: _onDateSelected,
          onEventTapped: _onEventTapped,
        );
        break;
    }
    return view;
  }
}

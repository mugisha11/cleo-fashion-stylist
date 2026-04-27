import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/models/calendar_day_model.dart';
import '../../social/providers/social_provider.dart';
import '../providers/calendar_provider.dart';
import '../widgets/calendar_header_new.dart';
import '../widgets/calendar_day_view_new.dart';
import '../widgets/calendar_week_view_new.dart';
import '../widgets/calendar_month_view_new.dart';
import '../widgets/day_detail_sheet.dart';
import '../widgets/ai_assistant_button.dart';
import '../widgets/ai_assistant_dialog.dart';
import '../../../routes.dart';
import '../../../core/widgets/cosmic_footer_widget.dart';
import '../../../core/widgets/fashion_drawer.dart';
import '../../../core/widgets/cosmic_header_widget.dart';

// ─── Route shims ──────────────────────────────────────────────────────────────
const _rWardrobe = Routes.wardrobe;
const _rTryOn = '/tryon';
const _rSocial = '/style-feed';

/// Fashion Calendar Screen - Complete redesign from scratch
/// World-class, Google Calendar-inspired, fashion-aware calendar
class FashionCalendarScreen extends ConsumerStatefulWidget {
  const FashionCalendarScreen({super.key});

  @override
  ConsumerState<FashionCalendarScreen> createState() =>
      _FashionCalendarScreenState();
}

enum CalendarViewMode { day, week, month }

class _FashionCalendarScreenState extends ConsumerState<FashionCalendarScreen>
    with TickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _navIndex = -1; // Calendar not in main nav

  DateTime _selectedDate = DateTime.now();
  CalendarViewMode _viewMode = CalendarViewMode.month;
  Map<DateTime, CalendarDay> _calendarDays = {};

  late AnimationController _viewTransitionController;

  @override
  void initState() {
    super.initState();

    _viewTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Initialize calendar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calendarStateProvider.notifier).goToToday();
    });
  }

  @override
  void dispose() {
    _viewTransitionController.dispose();
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

    final dateKey = DateTime(date.year, date.month, date.day);
    final calendarDay = _calendarDays[dateKey];
    _showDayDetail(date, calendarDay);
  }

  void _onEventTapped(CalendarDay event) {
    HapticFeedback.mediumImpact();
    _showDayDetail(event.date, event);
  }

  void _showDayDetail(DateTime date, CalendarDay? calendarDay) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DayDetailSheet(
        date: date,
        calendarDay: calendarDay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final calendarState = ref.watch(calendarStateProvider);
    final calendarDaysAsync = ref.watch(
      calendarDaysProvider(
        DateTime(
            calendarState.currentMonth.year, calendarState.currentMonth.month),
      ),
    );

    final unreadCount = ref.watch(socialUnreadCountProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(currentRoute: Routes.calendar),
        backgroundColor: Colors.white,
        extendBody: true,
        body: SafeArea(
          top: false,
          child: calendarDaysAsync.when(
            loading: () => _buildLoadingState(theme),
            error: (error, stack) => _buildErrorState(error, theme),
            data: (calendarDays) =>
                _buildCalendarContent(theme, calendarDays, unreadCount),
          ),
        ),
        bottomNavigationBar: CosmicFooter(
          bottomPadding: MediaQuery.of(context).padding.bottom,
          activeIndex: _navIndex,
          onTryOn: () {
            setState(() => _navIndex = 0);
            Navigator.pushNamed(context, _rTryOn);
          },
          onWardrobe: () {
            setState(() => _navIndex = 1);
            Navigator.pushNamed(context, _rWardrobe);
          },
          onHome: () {
            setState(() => _navIndex = 2);
            Navigator.pushNamed(context, Routes.dashboard);
          },
          onFriends: () {
            setState(() => _navIndex = 3);
            Navigator.pushNamed(context, _rSocial);
          },
          onOutfits: () {
            setState(() => _navIndex = 4);
            Navigator.pushNamed(context, Routes.savedTryOns);
          },
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

  Widget _buildCalendarContent(AppThemeData theme,
      Map<DateTime, CalendarDay> calendarDays, int unreadCount) {
    return Stack(
      children: [
        // Cosmic Header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: CosmicHeader(
            topPadding: MediaQuery.of(context).padding.top,
            hasNotification: unreadCount > 0,
            onMenuTap: () {
              try {
                _scaffoldKey.currentState?.openDrawer();
              } catch (_) {}
            },
            onBellTap: () {},
            onAvatarTap: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ),

        // Main Calendar Content
        Padding(
          padding:
              EdgeInsets.only(top: 80 + MediaQuery.of(context).padding.top),
          child: Column(
            children: [
              // Header
              CalendarHeaderNew(
                selectedDate: _selectedDate,
                viewMode: _viewMode,
                onViewChanged: _switchView,
                onDateChanged: (date) {
                  setState(() => _selectedDate = date);
                  // Only update month if we're in month view or if month actually changed
                  final currentMonth =
                      ref.read(calendarStateProvider).currentMonth;
                  if (date.year != currentMonth.year ||
                      date.month != currentMonth.month) {
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
    _calendarDays = calendarDays;

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

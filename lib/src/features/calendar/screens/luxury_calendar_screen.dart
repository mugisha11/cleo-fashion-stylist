import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/fashion_scaffold.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/models/calendar_day_model.dart';
import '../providers/calendar_provider.dart';
import '../theme/calendar_theme.dart';
import '../widgets/luxury_calendar_header.dart';
import '../widgets/luxury_month_view.dart';
import '../widgets/luxury_week_view.dart';
import '../widgets/luxury_day_view.dart';
import '../widgets/luxury_event_card.dart';
import '../widgets/ai_assistant_button.dart';
import '../widgets/ai_assistant_dialog.dart';
import '../widgets/calendar_filters.dart';
import '../widgets/schedule_suggestions_card.dart';
import '../../../routes.dart';

/// Luxury AI Calendar Screen - Stunning, emotion-driven, intelligent
class LuxuryCalendarScreen extends ConsumerStatefulWidget {
  const LuxuryCalendarScreen({super.key});

  @override
  ConsumerState<LuxuryCalendarScreen> createState() => _LuxuryCalendarScreenState();
}

enum CalendarView { month, week, day, timeline }

class _LuxuryCalendarScreenState extends ConsumerState<LuxuryCalendarScreen>
    with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  CalendarView _currentView = CalendarView.month;
  
  // Filter state
  String? _filterOccasion;
  bool? _filterOutfitReady;
  bool? _filterTryOnDone;
  
  late AnimationController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Page transition animation
    _pageController = AnimationController(
      vsync: this,
      duration: CalendarTheme.mediumAnimation,
    );
    
    // Fade in animation
    _fadeController = AnimationController(
      vsync: this,
      duration: CalendarTheme.slowAnimation,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: CalendarTheme.springCurve,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: CalendarTheme.springCurve,
      ),
    );
    
    _fadeController.forward();
    
    // Initialize calendar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calendarStateProvider.notifier).goToToday();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onDateSelected(DateTime date) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedDate = date;
    });
    ref.read(selectedDayProvider.notifier).state = date;
  }

  void _switchView(CalendarView view) {
    if (_currentView == view) return;
    
    HapticFeedback.mediumImpact();
    _pageController.forward(from: 0.0).then((_) {
      setState(() {
        _currentView = view;
      });
      _pageController.reverse();
    });
  }

  void _onTryOn() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushNamed(Routes.tryon);
  }

  void _showAIAssistant() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AIAssistantDialog(),
    );
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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: FashionScaffold(
          title: 'Style Calendar',
          currentBottomNavIndex: 0,
          currentRoute: Routes.calendar,
          backgroundColor: theme.backgroundPrimary,
          body: Container(
            decoration: theme.backgroundGradient != null
                ? BoxDecoration(gradient: theme.backgroundGradient)
                : BoxDecoration(color: theme.backgroundPrimary),
            child: Stack(
            children: [
              // Main calendar content
              calendarDaysAsync.when(
                  loading: () => _buildLoadingState(theme),
                  error: (error, stack) => _buildErrorState(error, theme),
                  data: (calendarDays) => _buildCalendarContent(calendarDays, theme),
              ),
              
              // Floating AI Assistant Button
              Positioned(
                bottom: 24,
                right: 24,
                child: AIAssistantButton(
                  onTap: _showAIAssistant,
                ),
              ),
            ],
            ),
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
          CircularProgressIndicator(
            color: theme.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your calendar...',
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.accentError,
            ),
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

  Widget _buildCalendarContent(Map<DateTime, CalendarDay> calendarDays, AppThemeData theme) {
    // Apply filters
    final filteredDays = _applyFilters(calendarDays);
    
    return Column(
      children: [
        // Luxury Header with View Switcher
        LuxuryCalendarHeader(
          selectedDate: _selectedDate,
          currentView: _currentView,
          onViewChanged: _switchView,
          onDateChanged: (date) {
            setState(() => _selectedDate = date);
            ref.read(calendarStateProvider.notifier).setMonth(date);
          },
        ),
        
        // Filters (only show for month/week views)
        if (_currentView == CalendarView.month || _currentView == CalendarView.week)
          CalendarFilters(
            selectedOccasion: _filterOccasion,
            outfitReady: _filterOutfitReady,
            tryOnDone: _filterTryOnDone,
            onFilterChanged: (occasion, outfitReady, tryOnDone) {
              setState(() {
                _filterOccasion = occasion;
                _filterOutfitReady = outfitReady;
                _filterTryOnDone = tryOnDone;
              });
          },
        ),
        
        // Calendar View Content
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildViewContent(filteredDays),
          ),
        ),
      ],
    );
  }

  Map<DateTime, CalendarDay> _applyFilters(Map<DateTime, CalendarDay> calendarDays) {
    if (_filterOccasion == null && _filterOutfitReady == null && _filterTryOnDone == null) {
      return calendarDays;
    }

    final filtered = <DateTime, CalendarDay>{};
    
    calendarDays.forEach((date, day) {
      bool matches = true;
      
      // Occasion filter
      if (_filterOccasion != null && day.eventType != _filterOccasion) {
        matches = false;
      }
      
      // Outfit ready filter
      if (_filterOutfitReady != null) {
        if (_filterOutfitReady == true && !day.hasOutfit) {
          matches = false;
        } else if (_filterOutfitReady == false && day.hasOutfit) {
          matches = false;
        }
      }
      
      // Try-on done filter (simplified - assumes hasOutfit means try-on done)
      if (_filterTryOnDone != null) {
        if (_filterTryOnDone == true && !day.hasOutfit) {
          matches = false;
        } else if (_filterTryOnDone == false && day.hasOutfit) {
          matches = false;
        }
      }
      
      if (matches) {
        filtered[date] = day;
      }
    });
    
    return filtered;
  }

  Widget _buildViewContent(Map<DateTime, CalendarDay> calendarDays) {
    switch (_currentView) {
      case CalendarView.month:
        return LuxuryMonthView(
          selectedDate: _selectedDate,
          calendarDays: calendarDays,
          onDateSelected: _onDateSelected,
        );
      case CalendarView.week:
        return LuxuryWeekView(
          selectedDate: _selectedDate,
          calendarDays: calendarDays,
          onDateSelected: _onDateSelected,
        );
      case CalendarView.day:
        return LuxuryDayView(
          selectedDate: _selectedDate,
          calendarDays: calendarDays,
          onTryOn: _onTryOn,
          onDateChanged: (date) {
            setState(() => _selectedDate = date);
            ref.read(selectedDayProvider.notifier).state = date;
          },
        );
      case CalendarView.timeline:
        return _buildTimelineView(calendarDays);
    }
  }

  Widget _buildTimelineView(Map<DateTime, CalendarDay> calendarDays) {
    final theme = context.appTheme;
    final now = DateTime.now();
    final upcomingEvents = calendarDays.values
        .where((day) => day.date.isAfter(now) && (day.eventName != null || day.eventType != null))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Schedule Suggestions
        ScheduleSuggestionsCard(
          calendarDays: calendarDays,
          selectedDate: _selectedDate,
        ),
        
        // Upcoming Events
        if (upcomingEvents.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline_outlined,
              size: 64,
                    color: theme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No upcoming events',
                    style: theme.titleMedium(color: theme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Plan your outfits to see them here',
                    style: theme.bodyMedium(color: theme.textSecondary),
            ),
          ],
        ),
            ),
          )
        else
          ...upcomingEvents.map((event) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: LuxuryEventCard(
            day: event,
            onTryOn: event.hasOutfit ? _onTryOn : null,
          ),
              )),
      ],
    );
  }
}

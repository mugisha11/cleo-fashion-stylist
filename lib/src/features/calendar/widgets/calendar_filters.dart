import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';

/// Calendar Filters - Intelligent filtering for events
class CalendarFilters extends StatefulWidget {
  final Function(String? occasion, bool? outfitReady, bool? tryOnDone)? onFilterChanged;
  final String? selectedOccasion;
  final bool? outfitReady;
  final bool? tryOnDone;

  const CalendarFilters({
    super.key,
    this.onFilterChanged,
    this.selectedOccasion,
    this.outfitReady,
    this.tryOnDone,
  });

  @override
  State<CalendarFilters> createState() => _CalendarFiltersState();
}

class _CalendarFiltersState extends State<CalendarFilters> {
  String? _selectedOccasion;
  bool? _outfitReady;
  bool? _tryOnDone;

  final List<String> _occasions = [
    'All',
    'Work',
    'Casual',
    'Event',
    'Formal',
    'Sport',
    'Party',
  ];

  @override
  void initState() {
    super.initState();
    _selectedOccasion = widget.selectedOccasion ?? 'All';
    _outfitReady = widget.outfitReady;
    _tryOnDone = widget.tryOnDone;
  }

  void _onOccasionChanged(String? occasion) {
    setState(() => _selectedOccasion = occasion);
    HapticFeedback.selectionClick();
    widget.onFilterChanged?.call(
      occasion == 'All' ? null : occasion,
      _outfitReady,
      _tryOnDone,
    );
  }

  void _onOutfitReadyChanged(bool? value) {
    setState(() => _outfitReady = value);
    HapticFeedback.selectionClick();
    widget.onFilterChanged?.call(
      _selectedOccasion == 'All' ? null : _selectedOccasion,
      value,
      _tryOnDone,
    );
  }

  void _onTryOnDoneChanged(bool? value) {
    setState(() => _tryOnDone = value);
    HapticFeedback.selectionClick();
    widget.onFilterChanged?.call(
      _selectedOccasion == 'All' ? null : _selectedOccasion,
      _outfitReady,
      value,
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedOccasion = 'All';
      _outfitReady = null;
      _tryOnDone = null;
    });
    HapticFeedback.mediumImpact();
    widget.onFilterChanged?.call(null, null, null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final hasActiveFilters = _selectedOccasion != 'All' || _outfitReady != null || _tryOnDone != null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.borderLight.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Header
          Row(
            children: [
              Icon(Icons.filter_list, color: theme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Filters',
                style: theme.bodyMedium(color: theme.textPrimary).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              if (hasActiveFilters)
                TextButton(
                  onPressed: _clearFilters,
                  child: Text(
                    'Clear',
                    style: theme.bodySmall(color: theme.primary),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Occasion Filter
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _occasions.map((occasion) {
              final isSelected = _selectedOccasion == occasion;
              return FilterChip(
                label: Text(occasion),
                selected: isSelected,
                onSelected: (selected) => _onOccasionChanged(selected ? occasion : 'All'),
                backgroundColor: theme.surfaceElevated,
                selectedColor: theme.primary.withOpacity(0.2),
                checkmarkColor: theme.primary,
                labelStyle: theme.bodySmall(
                  color: isSelected ? theme.primary : theme.textSecondary,
                ),
              );
            }).toList(),
          ),
          
          SizedBox(height: 12),
          
          // Status Filters
          Row(
            children: [
              Expanded(
                child: _buildStatusFilter(
                  theme,
                  label: 'Outfit Ready',
                  value: _outfitReady,
                  onChanged: _onOutfitReadyChanged,
                  icon: Icons.checkroom,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildStatusFilter(
                  theme,
                  label: 'Try-On Done',
                  value: _tryOnDone,
                  onChanged: _onTryOnDoneChanged,
                  icon: Icons.check_circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(
    AppThemeData theme, {
    required String label,
    required bool? value,
    required Function(bool?) onChanged,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        if (value == true) {
          onChanged(false);
        } else if (value == false) {
          onChanged(null);
        } else {
          onChanged(true);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value != null
              ? (value ? theme.accentSuccess.withOpacity(0.1) : theme.surfaceElevated)
              : theme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value != null && value
                ? theme.accentSuccess
                : theme.borderLight,
            width: value != null && value ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: value != null && value
                  ? theme.accentSuccess
                  : theme.textSecondary,
            ),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: theme.bodySmall(
                  color: value != null && value
                      ? theme.accentSuccess
                      : theme.textSecondary,
                ).copyWith(
                  fontWeight: value != null && value ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (value != null)
              Icon(
                value ? Icons.check : Icons.close,
                size: 14,
                color: value ? theme.accentSuccess : theme.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

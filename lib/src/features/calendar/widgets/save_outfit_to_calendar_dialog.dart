import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/models/calendar_day_model.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../providers/calendar_provider.dart';

/// Dialog to save an outfit from wardrobe to calendar
class SaveOutfitToCalendarDialog extends ConsumerStatefulWidget {
  final WardrobeItemModel? outfitItem;
  final List<WardrobeItemModel>? outfitItems; // For multi-item outfits
  final String? outfitName;
  final String? outfitImageUrl;

  const SaveOutfitToCalendarDialog({
    super.key,
    this.outfitItem,
    this.outfitItems,
    this.outfitName,
    this.outfitImageUrl,
  });

  @override
  ConsumerState<SaveOutfitToCalendarDialog> createState() => _SaveOutfitToCalendarDialogState();
}

class _SaveOutfitToCalendarDialogState extends ConsumerState<SaveOutfitToCalendarDialog> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _eventType;
  String? _eventName;
  final TextEditingController _eventNameController = TextEditingController();
  final List<String> _eventTypes = ['work', 'casual', 'event', 'formal', 'sport', 'party'];

  @override
  void dispose() {
    _eventNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveToCalendar() async {
    HapticFeedback.mediumImpact();
    
    try {
      final outfitId = widget.outfitItem?.id ?? 
          (widget.outfitItems?.isNotEmpty == true ? widget.outfitItems!.first.id : null);
      final outfitName = widget.outfitName ?? 
          widget.outfitItem?.category ?? 
          'Outfit';
      final outfitImageUrl = widget.outfitImageUrl ?? 
          widget.outfitItem?.processedImageUrl ?? 
          widget.outfitItem?.imageUrl;

      final eventDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final calendarDay = CalendarDay(
        date: eventDateTime,
        outfitId: outfitId,
        outfitName: outfitName,
        outfitImageUrl: outfitImageUrl,
        eventType: _eventType,
        eventName: _eventNameController.text.isEmpty ? null : _eventNameController.text,
        source: 'manual',
      );

      final actions = ref.read(calendarActionsProvider);
      await actions.saveDay(calendarDay);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Outfit saved to calendar'),
            backgroundColor: context.appTheme.accentSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: context.appTheme.accentError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.borderLight.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Save to Calendar',
                      style: theme.titleMedium(color: theme.textPrimary).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Outfit Preview
                    if (widget.outfitImageUrl != null || widget.outfitItem != null)
                      _buildOutfitPreview(theme),

                    SizedBox(height: AppThemeData.spacingLG),

                    // Date Selection
                    _buildDateSelector(theme),

                    SizedBox(height: AppThemeData.spacingMD),

                    // Time Selection
                    _buildTimeSelector(theme),

                    SizedBox(height: AppThemeData.spacingMD),

                    // Event Type
                    _buildEventTypeSelector(theme),

                    SizedBox(height: AppThemeData.spacingMD),

                    // Event Name
                    _buildEventNameInput(theme),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.borderLight.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.textPrimary,
                        side: BorderSide(color: theme.borderMedium),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveToCalendar,
                      child: Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutfitPreview(AppThemeData theme) {
    final imageUrl = widget.outfitImageUrl ?? 
        widget.outfitItem?.processedImageUrl ?? 
        widget.outfitItem?.imageUrl;

    if (imageUrl == null) return SizedBox.shrink();

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: theme.surfaceElevated,
          child: Center(
            child: CircularProgressIndicator(
              color: theme.primary,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: theme.surfaceElevated,
          child: Icon(Icons.broken_image, color: theme.textTertiary),
        ),
      ),
    );
  }

  Widget _buildDateSelector(AppThemeData theme) {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.borderLight.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: theme.primary, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: theme.bodySmall(color: theme.textSecondary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                    style: theme.bodyMedium(color: theme.textPrimary).copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(AppThemeData theme) {
    return InkWell(
      onTap: _selectTime,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.borderLight.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: theme.primary, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time',
                    style: theme.bodySmall(color: theme.textSecondary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _selectedTime.format(context),
                    style: theme.bodyMedium(color: theme.textPrimary).copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypeSelector(AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Type (Optional)',
          style: theme.bodyMedium(color: theme.textPrimary).copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _eventTypes.map((type) {
            final isSelected = _eventType == type;
            return FilterChip(
              label: Text(type.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _eventType = selected ? type : null);
                HapticFeedback.selectionClick();
              },
              backgroundColor: theme.surfaceElevated,
              selectedColor: theme.primary.withOpacity(0.2),
              checkmarkColor: theme.primary,
              labelStyle: theme.bodySmall(
                color: isSelected ? theme.primary : theme.textSecondary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEventNameInput(AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Name (Optional)',
          style: theme.bodyMedium(color: theme.textPrimary).copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _eventNameController,
          decoration: InputDecoration(
            hintText: 'e.g., Dinner Party, Work Meeting',
            hintStyle: theme.bodyMedium(color: theme.textTertiary),
            filled: true,
            fillColor: theme.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primary, width: 2),
            ),
          ),
          style: theme.bodyMedium(color: theme.textPrimary),
        ),
      ],
    );
  }
}

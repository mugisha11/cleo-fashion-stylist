import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/grok_design_system.dart';
import '../../../core/models/calendar_day_model.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../providers/calendar_provider.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';

/// Day Detail Bottom Sheet - Shows outfit details and scheduled events
class DayDetailSheet extends ConsumerStatefulWidget {
  final DateTime date;
  final CalendarDay? calendarDay;

  const DayDetailSheet({
    super.key,
    required this.date,
    this.calendarDay,
  });

  @override
  ConsumerState<DayDetailSheet> createState() => _DayDetailSheetState();
}

class _DayDetailSheetState extends ConsumerState<DayDetailSheet>
    with SingleTickerProviderStateMixin {
  bool _isLoadingAI = false;
  bool _isScheduling = false;
  bool _isLoadingManual = false;

  @override
  Widget build(BuildContext context) {
    final hasOutfit = widget.calendarDay?.hasOutfit ?? false;
    final dateStr = DateFormat('EEEE, MMMM d').format(widget.date);
    final dayEvents = ref.watch(dayEventsProvider(widget.date));

    return Container(
      decoration: const BoxDecoration(
        color: GrokDesignSystem.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: GrokDesignSystem.borderMedium,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(GrokDesignSystem.spacingMD),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: GrokDesignSystem.headlineSmall(),
                      ),
                      if (widget.calendarDay?.eventName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            widget.calendarDay!.eventName!,
                            style: GrokDesignSystem.bodySmall().copyWith(
                              color: GrokDesignSystem.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: GrokDesignSystem.spacingMD,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasOutfit) _buildOutfitView(),
                  if (!hasOutfit) _buildNoOutfitView(),
                  const SizedBox(height: GrokDesignSystem.spacingMD),
                  _buildEventsSection(dayEvents),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitView() {
    final day = widget.calendarDay!;
    final dayEvents = ref.watch(dayEventsProvider(widget.date));

    // Find the event associated with this outfit (if any)
    final associatedEvent = dayEvents.maybeWhen(
      data: (events) {
        try {
          return events.firstWhere(
            (event) =>
                event.eventName == day.outfitName ||
                event.eventType == day.eventType,
          );
        } catch (e) {
          return null;
        }
      },
      orElse: () => null,
    );

    final outfitImageUrl = day.outfitImageUrl?.trim();
    final linkedImageUrl = day.linkedOutfitImageUrl?.trim();
    final tryonImageUrl = day.linkedTryonImageUrl?.trim();

    // Prioritize: try-on image > linked outfit image > outfit image
    final primaryImageUrl = tryonImageUrl ?? linkedImageUrl ?? outfitImageUrl;
    final hasImage = primaryImageUrl != null && primaryImageUrl.isNotEmpty;
    final String imageUrl = primaryImageUrl ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Outfit Image / placeholder
        ClipRRect(
          borderRadius: BorderRadius.circular(GrokDesignSystem.radiusMD),
          child: hasImage
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: double.infinity,
                    height: 300,
                    color: GrokDesignSystem.backgroundLightGray,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: double.infinity,
                    height: 300,
                    color: GrokDesignSystem.backgroundLightGray,
                    child: const Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: GrokDesignSystem.textSecondary,
                    ),
                  ),
                )
              : Container(
                  width: double.infinity,
                  height: 300,
                  color: GrokDesignSystem.backgroundLightGray,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 48,
                          color: GrokDesignSystem.textSecondary,
                        ),
                        const SizedBox(height: GrokDesignSystem.spacingSM),
                        Text(
                          'Saved outfit plan',
                          style: GrokDesignSystem.headlineSmall().copyWith(
                            color: GrokDesignSystem.textSecondary,
                          ),
                        ),
                        const SizedBox(height: GrokDesignSystem.spacingXS),
                        Text(
                          'No image available yet',
                          style: GrokDesignSystem.bodySmall().copyWith(
                            color: GrokDesignSystem.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        const SizedBox(height: GrokDesignSystem.spacingMD),

        // Outfit Name and Source
        Row(
          children: [
            Expanded(
              child: Text(
                () {
                  // Show linked outfit name if available, otherwise outfit name
                  final linkedName = day.linkedOutfitName?.trim();
                  if (linkedName != null && linkedName.isNotEmpty) {
                    return linkedName;
                  }

                  final outfitName = day.outfitName?.trim();
                  return outfitName != null && outfitName.isNotEmpty
                      ? outfitName
                      : 'Planned outfit';
                }(),
                style: GrokDesignSystem.headlineSmall(),
              ),
            ),
            // Source indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: day.source == 'ai'
                    ? GrokDesignSystem.accentBlueLight
                    : GrokDesignSystem.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                day.source == 'ai' ? 'AI' : 'Manual',
                style: GrokDesignSystem.bodySmall().copyWith(
                  color: day.source == 'ai'
                      ? GrokDesignSystem.accentBlue
                      : GrokDesignSystem.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        // Time information if there's an associated event
        if (associatedEvent != null && associatedEvent.startTime != null) ...[
          const SizedBox(height: GrokDesignSystem.spacingSM),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 16,
                color: GrokDesignSystem.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Scheduled for ${DateFormat('h:mm a').format(associatedEvent.startTime!)}',
                style: GrokDesignSystem.bodySmall().copyWith(
                  color: GrokDesignSystem.textSecondary,
                ),
              ),
            ],
          ),
        ],

        // AI Recommendation badge
        if (day.isRecommended) ...[
          const SizedBox(height: GrokDesignSystem.spacingSM),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: GrokDesignSystem.accentBlueLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: GrokDesignSystem.accentBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI Recommended',
                      style: GrokDesignSystem.bodySmall().copyWith(
                        color: GrokDesignSystem.accentBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (day.confidenceScore != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '${(day.confidenceScore! * 100).toInt()}%',
                        style: GrokDesignSystem.bodySmall().copyWith(
                          color: GrokDesignSystem.accentBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: GrokDesignSystem.spacingLG),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                  // TODO: Navigate to try-on screen
                },
                icon: const Icon(Icons.checkroom, size: 20),
                label: const Text('Try On'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: GrokDesignSystem.spacingSM),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showOutfitActions();
                },
                icon: const Icon(Icons.more_vert, size: 20),
                label: const Text('Actions'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: GrokDesignSystem.spacingSM),

        // Quick Actions Row
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoadingAI ? null : _askAI,
                icon: _isLoadingAI
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 20),
                label:
                    Text(_isLoadingAI ? 'Generating...' : 'Get AI Suggestions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GrokDesignSystem.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  disabledBackgroundColor:
                      GrokDesignSystem.accentBlue.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(width: GrokDesignSystem.spacingSM),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isScheduling ? null : _scheduleReminder,
                icon: const Icon(Icons.notifications_active, size: 20),
                label: Text(_isScheduling ? 'Scheduling...' : 'Set Reminder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GrokDesignSystem.accentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: GrokDesignSystem.spacingMD),
      ],
    );
  }

  Widget _buildNoOutfitView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: GrokDesignSystem.spacingLG),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: GrokDesignSystem.backgroundLightGray,
            borderRadius: BorderRadius.circular(GrokDesignSystem.radiusMD),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 64,
                color: GrokDesignSystem.textSecondary,
              ),
              const SizedBox(height: GrokDesignSystem.spacingMD),
              Text(
                'No outfit planned',
                style: GrokDesignSystem.bodyLarge().copyWith(
                  color: GrokDesignSystem.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: GrokDesignSystem.spacingLG),
        Text(
          'Plan an outfit for this day',
          style: GrokDesignSystem.headlineSmall(),
        ),
        const SizedBox(height: GrokDesignSystem.spacingMD),

        // Manual Outfit Button - Primary Action
        ElevatedButton.icon(
          onPressed: _isLoadingManual ? null : _showManualOutfitPicker,
          icon: _isLoadingManual
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.checkroom, size: 20),
          label: Text(_isLoadingManual ? 'Loading...' : 'Choose from Wardrobe'),
          style: ElevatedButton.styleFrom(
            backgroundColor: GrokDesignSystem.accentBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: GrokDesignSystem.spacingSM),

        // AI Recommendation Button - Secondary Action
        OutlinedButton.icon(
          onPressed: _isLoadingAI ? null : _askAI,
          icon: _isLoadingAI
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome, size: 20),
          label: Text(_isLoadingAI ? 'Generating...' : 'Get AI Suggestion'),
          style: OutlinedButton.styleFrom(
            foregroundColor: GrokDesignSystem.accentBlue,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: GrokDesignSystem.spacingMD),

        // Quick Suggestions
        _buildQuickSuggestions(),
        const SizedBox(height: GrokDesignSystem.spacingMD),
      ],
    );
  }

  Widget _buildEventsSection(AsyncValue<List<OutfitEvent>> eventsAsync) {
    return eventsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: GrokDesignSystem.spacingMD),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (events) {
        if (events.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Day Events',
              style: GrokDesignSystem.headlineSmall().copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GrokDesignSystem.spacingSM),
            ...events.map(_buildEventTile),
          ],
        );
      },
    );
  }

  Widget _buildEventTile(OutfitEvent event) {
    final startLabel = event.startTime != null
        ? DateFormat('h:mm a').format(event.startTime!)
        : 'All day';

    return Card(
      margin: const EdgeInsets.only(bottom: GrokDesignSystem.spacingSM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GrokDesignSystem.radiusMD),
      ),
      child: ListTile(
        title: Text(event.eventName ?? 'Planned event'),
        subtitle: Text(
          '${event.eventType ?? 'Style event'} · $startLabel',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteEvent(event),
        ),
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    final suggestions = [
      {'type': 'work', 'label': 'Work', 'icon': Icons.business_center},
      {'type': 'casual', 'label': 'Casual', 'icon': Icons.checkroom},
      {'type': 'event', 'label': 'Event', 'icon': Icons.event},
      {'type': 'formal', 'label': 'Formal', 'icon': Icons.celebration},
    ];

    return Wrap(
      spacing: GrokDesignSystem.spacingSM,
      runSpacing: GrokDesignSystem.spacingSM,
      children: suggestions.map((suggestion) {
        return OutlinedButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            _requestOutfitForType(suggestion['type'] as String);
          },
          icon: Icon(suggestion['icon'] as IconData, size: 18),
          label: Text(suggestion['label'] as String),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showOutfitActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(GrokDesignSystem.spacingMD),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Outfit Details'),
              subtitle: const Text('Change name, time, or event type'),
              onTap: () {
                Navigator.of(context).pop();
                _editOutfitDetails();
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Replace Outfit'),
              subtitle: const Text('Choose a different outfit'),
              onTap: () {
                Navigator.of(context).pop();
                _showReplaceOutfitOptions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Get AI Recommendation'),
              subtitle: const Text('Let AI suggest a better outfit'),
              onTap: () {
                Navigator.of(context).pop();
                _askAI();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Choose from Wardrobe'),
              subtitle: const Text('Pick from your saved outfits'),
              onTap: () {
                Navigator.of(context).pop();
                _chooseFromWardrobe();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove Outfit',
                  style: TextStyle(color: Colors.red)),
              subtitle: const Text('Clear this day\'s outfit plan'),
              onTap: () {
                Navigator.of(context).pop();
                _confirmRemoveOutfit();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _askAI() async {
    setState(() => _isLoadingAI = true);
    HapticFeedback.mediumImpact();

    try {
      // Show loading message while AI generates outfit
      final actions = ref.read(calendarActionsProvider);
      await actions.generateAIOutfit(widget.date);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ AI outfit recommendation created!'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF667BFF),
          ),
        );
        // Refresh the sheet to show the new outfit
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating outfit: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAI = false);
      }
    }
  }

  void _requestOutfitForType(String type) {
    final suggestionName = switch (type) {
      'work' => 'Professional Workwear',
      'casual' => 'Casual Comfort',
      'event' => 'Event Ready Look',
      'formal' => 'Classic Formal Set',
      _ => 'Ready Outfit',
    };
    _saveManualOutfitByName(suggestionName);
  }

  Future<void> _saveManualOutfitByName(String outfitName) async {
    setState(() => _isLoadingManual = true);
    try {
      final actions = ref.read(calendarActionsProvider);
      final outfit = WardrobeItemModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        imageUrl: '',
        category: 'manual',
        colorTags: const [],
        createdAt: DateTime.now(),
        subcategory: outfitName,
      );
      await actions.saveOutfit(widget.date, outfit);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Saved "$outfitName" for ${DateFormat('EEEE').format(widget.date)}'),
            backgroundColor: GrokDesignSystem.accentBlue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving outfit: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingManual = false);
      }
    }
  }

  void _removeOutfit() async {
    final actions = ref.read(calendarActionsProvider);
    await actions.removeOutfit(widget.date);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Outfit removed')),
      );
    }
  }

  void _scheduleReminder() async {
    setState(() => _isScheduling = true);
    final actions = ref.read(calendarActionsProvider);

    try {
      await actions.scheduleReminder(
        widget.date,
        title: 'Outfit Reminder',
        message:
            'Don\'t forget your outfit plan for ${DateFormat('EEEE, MMM d').format(widget.date)}.',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder scheduled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule reminder: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScheduling = false);
      }
    }
  }

  void _editOutfitDetails() {
    final outfit = widget.calendarDay;
    if (outfit == null) return;

    final nameController = TextEditingController(text: outfit.outfitName ?? '');
    String? selectedEventType = outfit.eventType ?? 'casual';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Outfit Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Outfit Name',
                  hintText: 'e.g., Summer Casual',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Event Type',
                style: GrokDesignSystem.bodySmall().copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedEventType,
                items: ['casual', 'work', 'formal', 'event', 'other']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.replaceFirst(
                              type[0], type[0].toUpperCase())),
                        ))
                    .toList(),
                onChanged: (value) => selectedEventType = value,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final actions = ref.read(calendarActionsProvider);
              try {
                final updatedDay = outfit.copyWith(
                  outfitName: nameController.text.trim(),
                  eventType: selectedEventType,
                );
                await actions.saveDay(updatedDay);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Outfit details updated')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating outfit: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GrokDesignSystem.accentBlue,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReplaceOutfitOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(GrokDesignSystem.spacingMD),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('AI Recommendation'),
              subtitle: const Text('Get a new AI-suggested outfit'),
              onTap: () {
                Navigator.of(context).pop();
                _askAI();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('From Wardrobe'),
              subtitle: const Text('Choose from saved outfits'),
              onTap: () {
                Navigator.of(context).pop();
                _chooseFromWardrobe();
              },
            ),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('Repeat Last Outfit'),
              subtitle: const Text('Use your most recent outfit'),
              onTap: () {
                Navigator.of(context).pop();
                _repeatLastOutfit();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _chooseFromWardrobe() {
    _showManualOutfitPicker();
  }

  void _showManualOutfitPicker() {
    // Capture the provider reference before the async operation to avoid disposal
    final actions = ref.read(calendarActionsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManualOutfitPickerSheet(
        date: widget.date,
        onOutfitSelected: (outfitName, outfitId, imageUrl) async {
          setState(() => _isLoadingManual = true);
          try {
            // Create a custom outfit entry - use the actual ID or generate one
            final outfit = WardrobeItemModel(
              id: outfitId ?? DateTime.now().millisecondsSinceEpoch.toString(),
              userId: '', // Will be set by the service
              imageUrl: imageUrl ?? '',
              category: 'manual',
              colorTags: const [],
              createdAt: DateTime.now(),
              subcategory: outfitName,
            );
            await actions.saveOutfit(widget.date, outfit);
            if (mounted) {
              Navigator.of(context).pop(); // Close picker
              Navigator.of(context).pop(); // Close detail sheet
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '✅ Outfit "$outfitName" saved for ${DateFormat('EEEE').format(widget.date)}'),
                  backgroundColor: GrokDesignSystem.accentBlue,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error saving outfit: $e')),
              );
            }
          } finally {
            if (mounted) {
              setState(() => _isLoadingManual = false);
            }
          }
        },
      ),
    );
  }

  void _confirmRemoveOutfit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Outfit'),
        content:
            const Text('Are you sure you want to remove this outfit plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeOutfit();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _repeatLastOutfit() async {
    final actions = ref.read(calendarActionsProvider);
    try {
      await actions.repeatLastOutfit(widget.date);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Repeated last outfit successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to repeat outfit: $e')),
        );
      }
    }
  }

  void _deleteEvent(OutfitEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Remove this event from your day?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: GrokDesignSystem.accentError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final actions = ref.read(calendarActionsProvider);
    try {
      await actions.deleteEvent(event.id, widget.date);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete event: $e')),
        );
      }
    }
  }
}

/// Manual Outfit Picker - Bottom sheet for selecting outfit from wardrobe or creating custom
class _ManualOutfitPickerSheet extends ConsumerStatefulWidget {
  final DateTime date;
  final Function(String outfitName, String? outfitId, String? imageUrl)
      onOutfitSelected;

  const _ManualOutfitPickerSheet({
    required this.date,
    required this.onOutfitSelected,
  });

  @override
  ConsumerState<_ManualOutfitPickerSheet> createState() =>
      _ManualOutfitPickerSheetState();
}

class _ManualOutfitPickerSheetState
    extends ConsumerState<_ManualOutfitPickerSheet> {
  late PageController _pageController;
  int _currentPage = 0;
  final _outfitNameController = TextEditingController();
  final _outfitDescController = TextEditingController();
  String? _selectedOutfitId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _outfitNameController.dispose();
    _outfitDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: GrokDesignSystem.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(GrokDesignSystem.spacingMD),
            decoration: const BoxDecoration(
              color: GrokDesignSystem.backgroundLightGray,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Outfit for ${DateFormat('EEEE, MMM d').format(widget.date)}',
                        style: GrokDesignSystem.headlineSmall(),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Choose from your wardrobe or create custom outfit',
                          style: GrokDesignSystem.bodySmall().copyWith(
                            color: GrokDesignSystem.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Content - PageView for toggle between modes
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildWardrobeView(),
                _buildCustomOutfitView(),
              ],
            ),
          ),

          // Footer - Tab Indicator and Actions
          Container(
            padding: const EdgeInsets.all(GrokDesignSystem.spacingMD),
            decoration: const BoxDecoration(
              color: GrokDesignSystem.backgroundWhite,
              border: Border(
                top: BorderSide(
                  color: GrokDesignSystem.borderLight,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    label: 'From Wardrobe',
                    isActive: _currentPage == 0,
                    onTap: () => _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
                const SizedBox(width: GrokDesignSystem.spacingSM),
                Expanded(
                  child: _buildTabButton(
                    label: 'Custom Outfit',
                    isActive: _currentPage == 1,
                    onTap: () => _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: GrokDesignSystem.spacingSM,
          horizontal: GrokDesignSystem.spacingMD,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? GrokDesignSystem.accentBlue
              : GrokDesignSystem.backgroundLightGray,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GrokDesignSystem.bodySmall().copyWith(
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : GrokDesignSystem.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildWardrobeView() {
    final wardrobeAsync = ref.watch(wardrobeItemsProvider);

    return wardrobeAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: GrokDesignSystem.textSecondary,
            ),
            const SizedBox(height: GrokDesignSystem.spacingMD),
            Text(
              'Error loading wardrobe',
              style: GrokDesignSystem.headlineSmall(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error.toString(),
                style: GrokDesignSystem.bodySmall().copyWith(
                  color: GrokDesignSystem.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      data: (wardrobe) {
        if (wardrobe.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.checkroom_outlined,
                  size: 64,
                  color: GrokDesignSystem.textSecondary,
                ),
                const SizedBox(height: GrokDesignSystem.spacingMD),
                Text(
                  'Your wardrobe is empty',
                  style: GrokDesignSystem.headlineSmall(),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Add items to your wardrobe to schedule them',
                    style: GrokDesignSystem.bodySmall().copyWith(
                      color: GrokDesignSystem.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(GrokDesignSystem.spacingMD),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: GrokDesignSystem.spacingSM,
            mainAxisSpacing: GrokDesignSystem.spacingSM,
          ),
          itemCount: wardrobe.length,
          itemBuilder: (context, index) {
            final item = wardrobe[index];
            final isSelected = _selectedOutfitId == item.id;
            return _buildWardrobeItemCard(item, isSelected);
          },
        );
      },
    );
  }

  Widget _buildWardrobeItemCard(
    WardrobeItemModel item,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedOutfitId = item.id);
        // Auto-fill outfit name
        _outfitNameController.text = item.subcategory ?? item.category;
        // Show confirmation
        _showConfirmOutfitDialog(
            item.subcategory ?? item.category, item.id, item.imageUrl);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? GrokDesignSystem.accentBlue
                : GrokDesignSystem.borderLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(GrokDesignSystem.radiusMD),
          color: isSelected
              ? GrokDesignSystem.accentBlue.withValues(alpha: 0.05)
              : Colors.white,
        ),
        child: Stack(
          children: [
            // Item Image
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(GrokDesignSystem.radiusMD - 1),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: GrokDesignSystem.backgroundLightGray,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: GrokDesignSystem.backgroundLightGray,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: GrokDesignSystem.textSecondary,
                  ),
                ),
              ),
            ),
            // Item Info Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(GrokDesignSystem.spacingSM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.subcategory ?? item.category,
                      style: GrokDesignSystem.bodySmall().copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // Selection Indicator
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: const BoxDecoration(
                    color: GrokDesignSystem.accentBlue,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomOutfitView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(GrokDesignSystem.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Outfit Name Input
          TextField(
            controller: _outfitNameController,
            decoration: InputDecoration(
              labelText: 'Outfit Name',
              hintText: 'e.g., Business Casual',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GrokDesignSystem.radiusMD),
              ),
            ),
          ),
          const SizedBox(height: GrokDesignSystem.spacingMD),

          // Outfit Description
          TextField(
            controller: _outfitDescController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'Describe your outfit...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GrokDesignSystem.radiusMD),
              ),
            ),
          ),
          const SizedBox(height: GrokDesignSystem.spacingLG),

          // Save Button
          ElevatedButton.icon(
            onPressed: _outfitNameController.text.trim().isEmpty
                ? null
                : () => _showConfirmOutfitDialog(
                      _outfitNameController.text.trim(),
                      null,
                      null,
                    ),
            icon: const Icon(Icons.save, size: 20),
            label: const Text('Save Custom Outfit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: GrokDesignSystem.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmOutfitDialog(
    String outfitName,
    String? outfitId,
    String? imageUrl,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Outfit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set this outfit for ${DateFormat('EEEE, MMM d').format(widget.date)}?',
            ),
            const SizedBox(height: GrokDesignSystem.spacingMD),
            Container(
              padding: const EdgeInsets.all(GrokDesignSystem.spacingSM),
              decoration: BoxDecoration(
                color: GrokDesignSystem.backgroundLightGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Outfit: $outfitName',
                style: GrokDesignSystem.bodySmall().copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              widget.onOutfitSelected(outfitName, outfitId, imageUrl);
              Navigator.of(context).pop(); // Close bottom sheet
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GrokDesignSystem.accentBlue,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

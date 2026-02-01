import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/grok_design_system.dart';
import '../../../core/models/calendar_day_model.dart';
import '../providers/calendar_provider.dart';

/// Day Detail Bottom Sheet - Shows outfit details and AI recommendations
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

  @override
  Widget build(BuildContext context) {
    final hasOutfit = widget.calendarDay?.hasOutfit ?? false;
    final dateStr = DateFormat('EEEE, MMMM d').format(widget.date);

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
              child: hasOutfit ? _buildOutfitView() : _buildNoOutfitView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitView() {
    final day = widget.calendarDay!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Outfit image
        ClipRRect(
          borderRadius: BorderRadius.circular(GrokDesignSystem.radiusMD),
          child: CachedNetworkImage(
            imageUrl: day.outfitImageUrl!,
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
          ),
        ),

        const SizedBox(height: GrokDesignSystem.spacingMD),

        // Outfit name
        Text(
          day.outfitName ?? 'Outfit',
          style: GrokDesignSystem.headlineSmall(),
        ),

        const SizedBox(height: GrokDesignSystem.spacingSM),

        // AI badge if recommended
        if (day.isRecommended)
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

        const SizedBox(height: GrokDesignSystem.spacingLG),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  // Navigate to try-on screen
                  Navigator.of(context).pop();
                  // TODO: Navigate to try-on with outfit
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
                  _showChangeOutfitOptions();
                },
                icon: const Icon(Icons.swap_horiz, size: 20),
                label: const Text('Change'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: GrokDesignSystem.spacingSM),

        ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.mediumImpact();
            _askAI();
          },
          icon: const Icon(Icons.auto_awesome, size: 20),
          label: const Text('Ask AI for Suggestions'),
          style: ElevatedButton.styleFrom(
            backgroundColor: GrokDesignSystem.accentBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
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

        // Empty state illustration
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

        // Quick suggestions
        _buildQuickSuggestions(),

        const SizedBox(height: GrokDesignSystem.spacingMD),

        // AI recommendation button
        ElevatedButton.icon(
          onPressed: _isLoadingAI ? null : _askAI,
          icon: _isLoadingAI
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome, size: 20),
          label: Text(_isLoadingAI ? 'Generating...' : 'Get AI Recommendation'),
          style: ElevatedButton.styleFrom(
            backgroundColor: GrokDesignSystem.accentBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        const SizedBox(height: GrokDesignSystem.spacingMD),
      ],
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

  void _showChangeOutfitOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(GrokDesignSystem.spacingMD),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Get AI Recommendation'),
              onTap: () {
                Navigator.of(context).pop();
                _askAI();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Choose from Wardrobe'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Show wardrobe picker
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove Outfit'),
              onTap: () {
                Navigator.of(context).pop();
                _removeOutfit();
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
      // TODO: Call AI recommendation API
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      // For now, show a placeholder
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI recommendation feature coming soon!'),
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
    // TODO: Request outfit for specific type
    _askAI();
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
}


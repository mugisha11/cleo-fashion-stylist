import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../routes.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../providers/calendar_provider.dart';
import 'ai_assistant_dialog.dart';

/// Calendar Quick Actions Sheet
/// Provides fast access to outfit scheduling options when tapping a calendar date
class CalendarQuickActionsSheet extends ConsumerWidget {
  final DateTime date;

  const CalendarQuickActionsSheet({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(theme, context),

            // Actions
            _buildAction(
              context: context,
              ref: ref,
              icon: Icons.checkroom_outlined,
              title: 'Pick from Wardrobe',
              subtitle: 'Choose an existing outfit',
              onTap: () => _pickFromWardrobe(context, ref),
              isPrimary: true,
            ),

            _buildAction(
              context: context,
              ref: ref,
              icon: Icons.auto_awesome,
              title: 'Generate with AI',
              subtitle: 'Get AI-powered suggestions',
              onTap: () => _generateWithAI(context, ref),
            ),

            _buildAction(
              context: context,
              ref: ref,
              icon: Icons.repeat,
              title: 'Repeat Last Outfit',
              subtitle: 'Use your previous choice',
              onTap: () => _repeatLastOutfit(context, ref),
            ),

            _buildAction(
              context: context,
              ref: ref,
              icon: Icons.event,
              title: 'Add Event',
              subtitle: 'Create a custom event',
              onTap: () => _addEvent(context, ref),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeData theme, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.borderLight, width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _formatDate(date),
            style: theme.titleLarge(color: theme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose an action',
            style: theme.bodyMedium(color: theme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAction({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    final theme = context.appTheme;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isPrimary ? theme.primary : theme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isPrimary ? theme.textInverse ?? Colors.white : theme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: theme.bodyLarge(color: theme.textPrimary).copyWith(
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.bodySmall(color: theme.textSecondary),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.textSecondary,
      ),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop(); // Close the sheet
        onTap();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  void _pickFromWardrobe(BuildContext context, WidgetRef ref) async {
    // Navigate to wardrobe in selection mode
    final selectedOutfit = await Navigator.of(context).pushNamed(
      Routes.wardrobe,
      arguments: {'selectionMode': true, 'selectedDate': date},
    );

    if (selectedOutfit != null && selectedOutfit is WardrobeItemModel && context.mounted) {
      try {
        // Save the selected outfit to calendar
        final calendarActions = ref.read(calendarActionsProvider);
        await calendarActions.saveOutfit(date, selectedOutfit);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Outfit saved for ${date.day}/${date.month}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save outfit')),
        );
      }
    }
  }

  void _generateWithAI(BuildContext context, WidgetRef ref) {
    // Show AI assistant dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AIAssistantDialog(),
    );
  }

  void _repeatLastOutfit(BuildContext context, WidgetRef ref) async {
    try {
      final calendarActions = ref.read(calendarActionsProvider);
      await calendarActions.repeatLastOutfit(date);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Repeated last outfit for ${date.day}/${date.month}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No previous outfit found')),
        );
      }
    }
  }

  void _addEvent(BuildContext context, WidgetRef ref) {
    // TODO: Implement add event logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add event - Coming soon!')),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (selectedDate == today) {
      return 'Today';
    } else if (selectedDate == tomorrow) {
      return 'Tomorrow';
    } else {
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[date.month - 1]} ${date.day}';
    }
  }
}
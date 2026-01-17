import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/models/calendar_day_model.dart';
import '../providers/calendar_provider.dart';
import '../../../routes.dart';

/// Event Detail Drawer - Bottom sheet with full event details
class EventDetailDrawer extends ConsumerStatefulWidget {
  final CalendarDay event;
  final VoidCallback onClose;
  final VoidCallback onTryOn;

  const EventDetailDrawer({
    super.key,
    required this.event,
    required this.onClose,
    required this.onTryOn,
  });

  @override
  ConsumerState<EventDetailDrawer> createState() => _EventDetailDrawerState();
}

class _EventDetailDrawerState extends ConsumerState<EventDetailDrawer> {
  bool _isDeleting = false;

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Event'),
        content: Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: context.appTheme.accentError,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    HapticFeedback.mediumImpact();

    try {
      final actions = ref.read(calendarActionsProvider);
      await actions.removeOutfit(widget.event.date);
      
      if (mounted) {
        widget.onClose();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event deleted'),
            backgroundColor: context.appTheme.accentSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: context.appTheme.accentError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.borderMedium,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event Details',
                        style: theme.titleLarge(color: theme.textPrimary).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, MMMM d, y').format(widget.event.date),
                        style: theme.bodyMedium(color: theme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: theme.textSecondary),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Outfit Image
                  if (widget.event.outfitImageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: widget.event.outfitImageUrl!,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 300,
                          color: theme.surfaceElevated,
                          child: Center(
                            child: CircularProgressIndicator(color: theme.primary),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 300,
                          color: theme.surfaceElevated,
                          child: Icon(Icons.broken_image, color: theme.textTertiary),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Event Info
                  if (widget.event.eventName != null || widget.event.outfitName != null)
                    _buildInfoSection(
                      theme,
                      title: widget.event.eventName ?? widget.event.outfitName ?? 'Outfit',
                      icon: Icons.label_outline,
                    ),

                  if (widget.event.eventType != null) ...[
                    const SizedBox(height: 16),
                    _buildInfoSection(
                      theme,
                      title: widget.event.eventType!,
                      icon: Icons.category,
                    ),
                  ],

                  if (widget.event.isRecommended) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, color: theme.primary, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Recommended',
                                  style: theme.bodyMedium(color: theme.primary).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (widget.event.confidenceScore != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(widget.event.confidenceScore! * 100).toStringAsFixed(0)}% confidence',
                                    style: theme.bodySmall(color: theme.textSecondary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onTryOn,
                      icon: const Icon(Icons.checkroom, size: 20),
                      label: const Text('Try This Outfit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Edit event
                            HapticFeedback.mediumImpact();
                          },
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: theme.borderMedium),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isDeleting ? null : _deleteEvent,
                          icon: _isDeleting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.accentError,
                                  ),
                                )
                              : const Icon(Icons.delete_outline, size: 20),
                          label: Text(_isDeleting ? 'Deleting...' : 'Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.accentError,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: theme.accentError),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(AppThemeData theme, {required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: theme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: theme.bodyMedium(color: theme.textPrimary).copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

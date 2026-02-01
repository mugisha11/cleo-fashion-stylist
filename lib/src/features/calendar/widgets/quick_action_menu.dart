import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';

/// Quick Action Menu - Tap-and-hold actions for calendar events
class QuickActionMenu extends StatelessWidget {
  final VoidCallback? onReschedule;
  final VoidCallback? onEditOutfit;
  final VoidCallback? onDelete;
  final VoidCallback? onTryOn;
  final VoidCallback? onViewDetails;

  const QuickActionMenu({
    super.key,
    this.onReschedule,
    this.onEditOutfit,
    this.onDelete,
    this.onTryOn,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onViewDetails != null)
            _buildActionItem(
              theme,
              icon: Icons.info_outline,
              label: 'View Details',
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                onViewDetails?.call();
              },
            ),
          if (onTryOn != null)
            _buildActionItem(
              theme,
              icon: Icons.checkroom,
              label: 'Try On',
              color: theme.primary,
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                onTryOn?.call();
              },
            ),
          if (onReschedule != null)
            _buildActionItem(
              theme,
              icon: Icons.schedule,
              label: 'Reschedule',
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                onReschedule?.call();
              },
            ),
          if (onEditOutfit != null)
            _buildActionItem(
              theme,
              icon: Icons.edit_outlined,
              label: 'Edit Outfit',
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                onEditOutfit?.call();
              },
            ),
          if (onDelete != null) ...[
            Divider(height: 1, color: theme.borderLight),
            _buildActionItem(
              theme,
              icon: Icons.delete_outline,
              label: 'Delete',
              color: theme.accentError,
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionItem(
    AppThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? theme.textPrimary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: itemColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: theme.bodyMedium(color: itemColor).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: theme.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show quick action menu
void showQuickActionMenu({
  required BuildContext context,
  VoidCallback? onReschedule,
  VoidCallback? onEditOutfit,
  VoidCallback? onDelete,
  VoidCallback? onTryOn,
  VoidCallback? onViewDetails,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => QuickActionMenu(
      onReschedule: onReschedule,
      onEditOutfit: onEditOutfit,
      onDelete: onDelete,
      onTryOn: onTryOn,
      onViewDetails: onViewDetails,
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/theme_wrapper.dart';

/// Quick Actions Bar
/// Horizontal bar with primary actions
class QuickActionsBar extends StatelessWidget {
  final VoidCallback? onAskAI;
  final VoidCallback? onTryOn;
  final VoidCallback? onCalendar;
  final VoidCallback? onWardrobe;
  final VoidCallback? onSavedRecommendations;

  const QuickActionsBar({
    super.key,
    this.onAskAI,
    this.onTryOn,
    this.onCalendar,
    this.onWardrobe,
    this.onSavedRecommendations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              context,
              'Ask AI',
              Icons.chat_bubble_outline,
              theme.primary,
              onAskAI,
              isPrimary: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              context,
              'Try On',
              Icons.checkroom,
              theme.primary,
              onTryOn,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              context,
              'Calendar',
              Icons.calendar_today,
              theme.primary,
              onCalendar,
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                'Wardrobe',
                Icons.checkroom_outlined,
                theme.textSecondary,
                onWardrobe,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback? onTap, {
    bool isPrimary = false,
  }) {
    final theme = context.appTheme;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 14 : 16,
          ),
          decoration: BoxDecoration(
            color: isPrimary
                ? color.withOpacity(0.15)
                : theme.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary
                  ? color.withOpacity(0.3)
                  : theme.borderLight.withOpacity(0.2),
              width: isPrimary ? 1.5 : 1,
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isMobile ? 18 : 20,
                color: isPrimary ? color : theme.textPrimary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                    color: isPrimary ? color : theme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).scale(
          begin: const Offset(0.9, 0.9),
          duration: 200.ms,
        );
  }
}

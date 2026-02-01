import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/fashion_scaffold.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/models/tryon_session_model.dart';
import '../../../core/providers/tryon_memory_provider.dart';
import '../../../routes.dart';

/// Saved Try-Ons Screen - Displays all saved try-on sessions
class SavedTryOnsScreen extends ConsumerWidget {
  const SavedTryOnsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final accentPink = context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    final savedTryOnsAsync = ref.watch(savedTryOnsProvider);

    return FashionScaffold(
      title: 'Saved Try-Ons',
      currentBottomNavIndex: 2,
      currentRoute: Routes.tryon,
      backgroundColor: theme.backgroundPrimary,
      body: Container(
        decoration: theme.backgroundGradient != null
            ? BoxDecoration(gradient: theme.backgroundGradient)
            : BoxDecoration(color: theme.backgroundPrimary),
        child: savedTryOnsAsync.when(
          loading: () => _buildLoadingState(theme, accentPink),
          error: (error, stack) => _buildErrorState(error, theme),
          data: (tryOns) => _buildTryOnsGrid(context, theme, accentPink, tryOns),
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppThemeData theme, Color accentPink) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: accentPink),
          const SizedBox(height: 24),
          Text(
            'Loading saved try-ons...',
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
              'Unable to load saved try-ons',
              style: theme.titleMedium(color: theme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.bodyMedium(color: theme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTryOnsGrid(
    BuildContext context,
    AppThemeData theme,
    Color accentPink,
    List<TryOnSession> tryOns,
  ) {
    if (tryOns.isEmpty) {
      return _buildEmptyState(theme);
    }

    final isMobile = MediaQuery.of(context).size.width < 768;
    final crossAxisCount = isMobile ? 2 : 3;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: tryOns.length,
      itemBuilder: (context, index) {
        return _buildTryOnCard(context, theme, accentPink, tryOns[index]);
      },
    );
  }

  Widget _buildTryOnCard(
    BuildContext context,
    AppThemeData theme,
    Color accentPink,
    TryOnSession session,
  ) {
    return GestureDetector(
      onTap: () => _showTryOnDetails(context, theme, accentPink, session),
      child: Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.borderLight.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: session.resultImageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: theme.surfaceElevated,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: accentPink,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: theme.surfaceElevated,
                    child: Icon(
                      Icons.image_not_supported,
                      color: theme.textTertiary,
                    ),
                  ),
                ),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMM d, y').format(session.createdAt),
                    style: theme.bodySmall(color: theme.textSecondary),
                  ),
                  if (session.occasion != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      session.occasion!,
                      style: theme.bodyMedium(color: theme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (session.outfitIds.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${session.outfitIds.length} item${session.outfitIds.length > 1 ? 's' : ''}',
                      style: theme.bodySmall(color: theme.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: 64,
              color: theme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No saved try-ons yet',
              style: theme.titleMedium(color: theme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Try on outfits to save them here',
              style: theme.bodyMedium(color: theme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showTryOnDetails(
    BuildContext context,
    AppThemeData theme,
    Color accentPink,
    TryOnSession session,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TryOnDetailSheet(session: session, accentPink: accentPink),
    );
  }
}

class _TryOnDetailSheet extends ConsumerWidget {
  final TryOnSession session;
  final Color accentPink;

  const _TryOnDetailSheet({required this.session, required this.accentPink});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final dateFormat = DateFormat('MMMM d, y • h:mm a');

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.borderLight,
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
                        'Try-On Details',
                        style: theme.titleLarge(color: theme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(session.createdAt),
                        style: theme.bodyMedium(color: theme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: theme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Image
          Expanded(
            child: CachedNetworkImage(
              imageUrl: session.resultImageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(color: accentPink),
              ),
              errorWidget: (context, url, error) => Center(
                child: Icon(Icons.error, color: theme.accentError),
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Reuse button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed(Routes.tryon);
                      // TODO: Load this try-on in try-on screen
                    },
                    icon: Icon(Icons.refresh, color: theme.surface),
                    label: Text(
                      'Reuse This Image',
                      style: theme.bodyMedium(color: theme.surface),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentPink,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Action buttons row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Save to calendar
                        },
                        icon: Icon(Icons.calendar_today, color: accentPink),
                        label: Text(
                          'Save to Calendar',
                          style: theme.bodyMedium(color: accentPink),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: accentPink),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final service = ref.read(tryonMemoryServiceProvider);
                          await service.deleteTryOnSession(session.id);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ref.invalidate(savedTryOnsProvider);
                            HapticFeedback.mediumImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Try-on deleted'),
                                backgroundColor: theme.accentSuccess,
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.delete_outline,
                            color: theme.accentError),
                        label: Text(
                          'Delete',
                          style: theme.bodyMedium(color: theme.accentError),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: theme.accentError),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

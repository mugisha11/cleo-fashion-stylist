import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/calendar_day_model.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/app_theme_data.dart';
import '../providers/calendar_provider.dart';
import '../../../routes.dart';

/// Fashion Event Detail Screen
/// Full-screen detail view for calendar events with outfit preview, try-on, and editing
class FashionEventDetailScreen extends ConsumerStatefulWidget {
  final CalendarDay calendarDay;
  final DateTime date;

  const FashionEventDetailScreen({
    super.key,
    required this.calendarDay,
    required this.date,
  });

  @override
  ConsumerState<FashionEventDetailScreen> createState() => _FashionEventDetailScreenState();
}

class _FashionEventDetailScreenState extends ConsumerState<FashionEventDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Scaffold(
      backgroundColor: theme.backgroundPrimary,
      body: Container(
        decoration: theme.backgroundGradient != null
            ? BoxDecoration(gradient: theme.backgroundGradient)
            : BoxDecoration(color: theme.backgroundPrimary),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(theme, isMobile),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date & Event Info
                      _buildDateSection(theme),
                      
                      const SizedBox(height: AppThemeData.spacingLG),
                      
                      // Outfit Preview
                      if (widget.calendarDay.hasOutfit)
                        _buildOutfitPreview(theme, isMobile)
                      else
                        _buildNoOutfitState(theme),
                      
                      const SizedBox(height: AppThemeData.spacingLG),
                      
                      // Event Details
                      if (widget.calendarDay.eventType != null || widget.calendarDay.eventName != null)
                        _buildEventDetails(theme),
                      
                      const SizedBox(height: AppThemeData.spacingLG),
                      
                      // AI Recommendation Badge
                      if (widget.calendarDay.isRecommended)
                        _buildAIRecommendationBadge(theme),
                      
                      const SizedBox(height: AppThemeData.spacingLG),
                      
                      // Action Buttons
                      _buildActionButtons(theme, isMobile),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHeader(AppThemeData theme, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.borderLight.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: theme.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              'Event Details',
              style: theme.titleMedium(color: theme.textPrimary).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: theme.textPrimary),
            onPressed: _showEditDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(AppThemeData theme) {
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    final timeFormat = DateFormat('h:mm a');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.borderLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: theme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(widget.date),
                      style: theme.titleMedium(color: theme.textPrimary).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.calendarDay.eventName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.calendarDay.eventName!,
                        style: theme.bodyMedium(color: theme.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitPreview(AppThemeData theme, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Outfit Preview',
          style: theme.titleMedium(color: theme.textPrimary).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: isMobile ? 400 : 500,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Outfit Image
              CachedNetworkImage(
                imageUrl: widget.calendarDay.outfitImageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: theme.surfaceElevated,
                  child: Center(
                    child: CircularProgressIndicator(color: theme.primary),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: theme.surfaceElevated,
                  child: Icon(
                    Icons.broken_image,
                    color: theme.textTertiary,
                    size: 64,
                  ),
                ),
              ),
              
              // Try-On Badge Overlay
              if (widget.calendarDay.outfitImageUrl != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.checkroom, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Try-On Ready',
                          style: theme.bodySmall(color: Colors.white).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Outfit Name
        if (widget.calendarDay.outfitName != null)
          Text(
            widget.calendarDay.outfitName!,
            style: theme.bodyLarge(color: theme.textPrimary).copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildNoOutfitState(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.borderLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.checkroom_outlined,
            size: 64,
            color: theme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Outfit Planned',
            style: theme.titleMedium(color: theme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Plan an outfit for this event',
            style: theme.bodyMedium(color: theme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetails(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.borderLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Details',
            style: theme.bodyMedium(color: theme.textPrimary).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.calendarDay.eventType != null) ...[
            Row(
              children: [
                Icon(Icons.label_outline, color: theme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.calendarDay.eventType!,
                    style: theme.bodyMedium(color: theme.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildAIRecommendationBadge(AppThemeData theme) {
    return Container(
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
                if (widget.calendarDay.confidenceScore != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${(widget.calendarDay.confidenceScore! * 100).toStringAsFixed(0)}% confidence',
                    style: theme.bodySmall(color: theme.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppThemeData theme, bool isMobile) {
    return Column(
      children: [
        // Try-On Button
        if (widget.calendarDay.hasOutfit)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _openTryOn,
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
        
        // Action Row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _showChangeOutfitOptions,
                icon: const Icon(Icons.swap_horiz, size: 20),
                label: const Text('Change Outfit'),
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
                onPressed: _isLoading ? null : _askAIForOutfit,
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: const Text('AI Suggest'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: theme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        if (!widget.calendarDay.hasOutfit) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _selectFromWardrobe,
              icon: const Icon(Icons.folder_outlined, size: 20),
              label: const Text('Select from Wardrobe'),
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
        ],
      ],
    );
  }

  void _openTryOn() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushNamed(Routes.tryon);
  }

  void _showChangeOutfitOptions() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.appTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: context.appTheme.borderMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.auto_awesome, color: context.appTheme.primary),
                title: const Text('Get AI Recommendation'),
                onTap: () {
                  Navigator.pop(context);
                  _askAIForOutfit();
                },
              ),
              ListTile(
                leading: Icon(Icons.folder_outlined, color: context.appTheme.primary),
                title: const Text('Choose from Wardrobe'),
                onTap: () {
                  Navigator.pop(context);
                  _selectFromWardrobe();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: context.appTheme.accentError),
                title: const Text('Remove Outfit'),
                onTap: () {
                  Navigator.pop(context);
                  _removeOutfit();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _askAIForOutfit() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    
    try {
      // TODO: Integrate with AI chat service
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('AI recommendation feature coming soon!'),
            backgroundColor: context.appTheme.primary,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectFromWardrobe() {
    HapticFeedback.mediumImpact();
    // TODO: Show wardrobe picker and save to calendar
    Navigator.of(context).pushNamed(Routes.wardrobe);
  }

  void _removeOutfit() async {
    HapticFeedback.mediumImpact();
    try {
      final actions = ref.read(calendarActionsProvider);
      await actions.removeOutfit(widget.date);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Outfit removed'),
            backgroundColor: context.appTheme.accentSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove outfit: $e'),
            backgroundColor: context.appTheme.accentError,
          ),
        );
      }
    }
  }

  void _showEditDialog() {
    HapticFeedback.mediumImpact();
    // TODO: Show edit event dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Edit event feature coming soon!'),
        backgroundColor: context.appTheme.primary,
      ),
    );
  }
}

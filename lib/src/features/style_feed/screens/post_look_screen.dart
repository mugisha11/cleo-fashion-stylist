import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/widgets/dashboard_components.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../routes.dart';
import '../../social/providers/social_provider.dart';
import '../providers/style_feed_provider.dart';
import '../widgets/style_feed_image.dart';

class PostLookScreen extends ConsumerStatefulWidget {
  /// Pre-filled image path (e.g. from Try-On or last shared).
  final String? imagePath;
  /// Pre-filled image bytes (e.g. from Try-On result).
  final List<int>? imageBytes;
  /// Suggested caption (e.g. from AI).
  final String? suggestedCaption;

  const PostLookScreen({
    super.key,
    this.imagePath,
    this.imageBytes,
    this.suggestedCaption,
  });

  static Future<void> navigate(
    BuildContext context, {
    String? imagePath,
    Uint8List? imageBytes,
    String? suggestedCaption,
  }) {
    return Navigator.of(context).pushNamed(
      Routes.postLook,
      arguments: <String, dynamic>{
        'imagePath': imagePath,
        'imageBytes': imageBytes,
        'suggestedCaption': suggestedCaption,
      },
    );
  }

  @override
  ConsumerState<PostLookScreen> createState() => _PostLookScreenState();
}

class _PostLookScreenState extends ConsumerState<PostLookScreen> {
  late TextEditingController _captionController;
  final List<String> _tags = [];
  late bool _isPublic;
  bool _isPosting = false;
  String? _effectiveImagePath;
  Uint8List? _effectiveImageBytes;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.suggestedCaption ?? '');
    _isPublic = true;
    _effectiveImagePath = widget.imagePath;
    if (widget.imageBytes != null) {
      _effectiveImageBytes = Uint8List.fromList(widget.imageBytes!);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  bool get _hasImage =>
      (_effectiveImagePath != null && _effectiveImagePath!.isNotEmpty) ||
      _effectiveImageBytes != null;

  String? get _imagePathForPreview {
    if (_effectiveImagePath != null && _effectiveImagePath!.isNotEmpty) {
      return _effectiveImagePath;
    }
    if (_effectiveImageBytes != null) {
      return 'data:image/jpeg;base64,${base64Encode(_effectiveImageBytes!)}';
    }
    return null;
  }

  Future<void> _pickImage() async {
    // Use image_picker - need to add import and call
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _effectiveImagePath = null;
      _effectiveImageBytes = bytes;
    });
  }

  Future<void> _addTag() async {
    final theme = context.appTheme;
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text('Add tag', style: theme.titleLarge()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '#casual',
            hintStyle: theme.bodyMedium(color: theme.textTertiary),
          ),
          style: theme.bodyMedium(color: theme.textPrimary),
          autofocus: true,
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim().replaceFirst('#', '')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: theme.bodyMedium(color: theme.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              final t = controller.text.trim().replaceFirst('#', '');
              Navigator.of(ctx).pop(t.isEmpty ? null : t);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        if (!_tags.contains(result)) _tags.add(result);
      });
    }
  }

  Future<void> _post() async {
    if (!_hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a photo first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isPosting = true);

    final notifier = ref.read(styleFeedProvider.notifier);
    final post = await notifier.addPost(
      caption: _captionController.text.trim(),
      tags: List.from(_tags),
      isPublic: _isPublic,
      imagePath: _effectiveImagePath,
      imageBytes: _effectiveImageBytes,
    );

    if (!mounted) return;
    setState(() => _isPosting = false);
    if (post != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Look posted!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.styleFeed,
        (route) => route.isFirst,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not post. Try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final accentPink = context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    final previewPath = _imagePathForPreview;

    return Scaffold(
      appBar: DashboardTopBar(
        aiStatus: 'Post a look',
        isAITyping: false,
        notificationCount: ref.watch(socialUnreadCountProvider),
        onProfileTap: () => Navigator.of(context).pushNamed(Routes.settings),
        onNotificationsTap: () {
          Navigator.of(context).pushNamed(Routes.notificationCenter);
        },
      ),
      drawer: _buildNavigationDrawer(context),
      body: Container(
        decoration: theme.backgroundGradient != null
            ? BoxDecoration(gradient: theme.backgroundGradient)
            : BoxDecoration(color: theme.backgroundPrimary),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppThemeData.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Preview or pick image
            if (previewPath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(theme.borderRadiusLarge),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: StyleFeedImage(
                    imagePath: previewPath,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: theme.backgroundSecondary,
                    borderRadius: BorderRadius.circular(theme.borderRadiusLarge),
                    border: Border.all(color: theme.borderLight),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: theme.textTertiary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add photo',
                        style: theme.bodyMedium(color: theme.textTertiary),
                      ),
                    ],
                  ),
                ),
              ),
            if (previewPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Change photo'),
                ),
              ),
            const SizedBox(height: 24),
            TextField(
              controller: _captionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe your look…',
                hintStyle: theme.bodyMedium(color: theme.textTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(theme.borderRadius),
                ),
              ),
              style: theme.bodyMedium(color: theme.textPrimary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Tags',
                  style: theme.bodyMedium().copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _tags.map((t) {
                  return Chip(
                    label: Text('#$t'),
                    onDeleted: () => setState(() => _tags.remove(t)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Visibility',
                  style: theme.bodyMedium().copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('Public'),
                  selected: _isPublic,
                  onSelected: (v) => setState(() => _isPublic = true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Private'),
                  selected: !_isPublic,
                  onSelected: (v) => setState(() => _isPublic = false),
                ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isPosting ? null : _post,
              style: FilledButton.styleFrom(
                backgroundColor: accentPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isPosting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Post'),
            ),
          ],
        ),
      ),
    ),
    );
  }

  static Widget _buildNavigationDrawer(BuildContext context) {
    final isDark = context.isDarkMode;
    return Drawer(
      child: Container(
        color:
            isDark ? DesignTokens.darkBackground : DesignTokens.lightBackground,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? DesignTokens.darkBorder
                        : DesignTokens.lightBorder,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cleo Fashion',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? DesignTokens.darkAccent
                              : DesignTokens.lightAccent,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your style companion',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _buildNavItem(
              context: context,
              icon: Icons.home_outlined,
              label: 'Home',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.dashboard);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.auto_awesome_outlined,
              label: 'Try On',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.tryon);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.checkroom_outlined,
              label: 'My Closet',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.wardrobe);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.star_outline,
              label: 'Picks for You',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.recommendations);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.calendar_today_outlined,
              label: 'Calendar',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.calendar);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.grid_view_rounded,
              label: 'Style Feed',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.styleFeed);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.photo_library_outlined,
              label: 'My Outfits',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.generatedOutfits);
              },
            ),
            const Divider(),
            _buildNavItem(
              context: context,
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.settings);
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDarkMode;
    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent,
      ),
      title: Text(label),
      onTap: onTap,
      hoverColor: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
    );
  }
}

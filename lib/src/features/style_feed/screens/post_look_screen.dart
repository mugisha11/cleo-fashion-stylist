import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/widgets/cosmic_footer_widget.dart';
import '../../../core/widgets/fashion_drawer.dart';
import '../../../routes.dart';
import '../providers/style_feed_provider.dart';
import '../widgets/style_feed_image.dart';

const _rWardrobe = Routes.wardrobe;
const _rTryOn = Routes.tryon;
const _rSocial = Routes.styleFeed;

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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _navIndex = -1; // Post Look not in main nav

  late TextEditingController _captionController;
  final List<String> _tags = [];
  late bool _isPublic;
  bool _isPosting = false;
  String? _effectiveImagePath;
  Uint8List? _effectiveImageBytes;

  @override
  void initState() {
    super.initState();
    _captionController =
        TextEditingController(text: widget.suggestedCaption ?? '');
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
          onSubmitted: (v) =>
              Navigator.of(ctx).pop(v.trim().replaceFirst('#', '')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: theme.bodyMedium(color: theme.textSecondary)),
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
    final accentPink =
        context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    final previewPath = _imagePathForPreview;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(currentRoute: Routes.postLook),
        backgroundColor: Colors.white,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Post New Look',
              style: TextStyle(color: Colors.black)),
          centerTitle: true,
        ),
        body: Container(
          color: Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppThemeData.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Preview or pick image
                if (previewPath != null)
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(theme.borderRadiusLarge),
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
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(theme.borderRadiusLarge),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 48,
                            color: Colors.black.withValues(alpha: 0.7),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add photo',
                            style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.7)),
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
                      icon:
                          const Icon(Icons.edit, size: 18, color: Colors.black),
                      label: const Text('Change photo',
                          style: TextStyle(color: Colors.black)),
                    ),
                  ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(theme.borderRadius),
                  ),
                  child: TextField(
                    controller: _captionController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Describe your look…',
                      hintStyle:
                          TextStyle(color: Colors.black.withValues(alpha: 0.5)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _addTag,
                      icon:
                          const Icon(Icons.add, size: 18, color: Colors.black),
                      label: const Text('Add',
                          style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
                if (_tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _tags.map((t) {
                      return Chip(
                        label: Text('#$t',
                            style: const TextStyle(color: Colors.black)),
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        onDeleted: () => setState(() => _tags.remove(t)),
                        deleteIcon: const Icon(Icons.close,
                            size: 16, color: Colors.black),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Visibility',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('Public'),
                      selected: _isPublic,
                      onSelected: (v) => setState(() => _isPublic = true),
                      selectedColor: accentPink,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                          color: _isPublic
                              ? Colors.black
                              : Colors.black.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Private'),
                      selected: !_isPublic,
                      onSelected: (v) => setState(() => _isPublic = false),
                      selectedColor: accentPink,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                          color: !_isPublic
                              ? Colors.black
                              : Colors.black.withValues(alpha: 0.7)),
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
                    minimumSize: const Size(double.infinity, 50),
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
                      : const Text('Post Look',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: CosmicFooter(
          bottomPadding: MediaQuery.of(context).padding.bottom,
          activeIndex: _navIndex,
          onTryOn: () {
            setState(() => _navIndex = 0);
            Navigator.pushNamed(context, _rTryOn);
          },
          onWardrobe: () {
            setState(() => _navIndex = 1);
            Navigator.pushNamed(context, _rWardrobe);
          },
          onHome: () {
            setState(() => _navIndex = 2);
            Navigator.pushNamed(context, Routes.dashboard);
          },
          onFriends: () {
            setState(() => _navIndex = 3);
            Navigator.pushNamed(context, _rSocial);
          },
          onOutfits: () {
            setState(() => _navIndex = 4);
            Navigator.pushNamed(context, Routes.outfitPlanner);
          },
        ),
      ),
    );
  }
}

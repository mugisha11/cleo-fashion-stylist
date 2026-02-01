import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../../core/models/wardrobe_item_model.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/fashion_scaffold.dart';
import '../../../core/widgets/dashboard_components.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/providers/user_image_provider.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/screens/fashion_preferences_screen.dart';
import '../providers/tryon_provider.dart';
import '../../../routes.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TryOnScreen extends ConsumerStatefulWidget {
  const TryOnScreen({super.key});

  @override
  ConsumerState<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends ConsumerState<TryOnScreen> {
  String? _selectedAvatarUrl;
  Uint8List? _userImageBytes;
  final List<String> _selectedItemIds = [];
  String? _previewUrl;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadUserPhoto();
  }

  /// Load user photo from provider (auto-load on screen open)
  Future<void> _loadUserPhoto() async {
    final userImage = ref.read(userImageProvider);

    if (userImage.base64Image == null) {
      // No image uploaded - user should go to preferences
      if (mounted) {
        _showNoImageDialog();
      }
      return;
    }

    try {
      // Decode Base64 to bytes
      String base64String = userImage.base64Image!;
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }
      final bytes = base64Decode(base64String);

      setState(() {
        _userImageBytes = bytes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading photo: $e')),
        );
      }
    }
  }

  /// Show dialog if no image uploaded
  void _showNoImageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Your Photo'),
        content: const Text(
          'Upload your full-body photo in Preferences to use Try-On.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FashionPreferencesScreen(),
                ),
              );
            },
            child: const Text('Go to Preferences'),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePreview() async {
    if (_userImageBytes == null || _selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please upload a photo and select at least one clothing item',
          ),
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final wardrobeAsync = ref.read(wardrobeItemsProvider);
      final wardrobe = wardrobeAsync.value;
      if (wardrobe == null) return;

      final selectedItems =
          wardrobe.where((item) => _selectedItemIds.contains(item.id)).toList();
      final imageUrls = selectedItems.map((item) => item.imageUrl).toList();

      // Convert user image to Base64
      final base64UserImage = base64Encode(_userImageBytes!);
      final userImageBase64 = 'data:image/jpeg;base64,$base64UserImage';

      final tryOnService = ref.read(tryOnServiceProvider);
      final previewUrl = await tryOnService.generateTryOnPreviewFromBase64(
        userImageBase64: userImageBase64,
        clothingImageUrls: imageUrls,
      );

      setState(() {
        _previewUrl = previewUrl;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate preview: $e')),
        );
      }
    }
  }

  Future<void> _saveOutfit() async {
    if (_selectedItemIds.isEmpty) return;

    final nameController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Outfit'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Outfit Name',
            hintText: 'e.g., Casual Friday',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && nameController.text.isNotEmpty) {
      try {
        final tryOnService = ref.read(tryOnServiceProvider);
        await tryOnService.saveOutfit(
          name: nameController.text,
          itemIds: _selectedItemIds,
          previewImageUrl: _previewUrl,
        );
        ref.invalidate(savedOutfitsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Outfit saved')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save outfit: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wardrobeAsync = ref.watch(wardrobeItemsProvider);
    final theme = context.appTheme;

    return Scaffold(
      appBar: DashboardTopBar(
        aiStatus: 'Virtual Try-On',
        isAITyping: false,
        notificationCount: 0,
        onProfileTap: () {
          Navigator.of(context).pushNamed(Routes.settings);
        },
        onNotificationsTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No new notifications')),
          );
        },
      ),
      drawer: _buildNavigationDrawer(context),
      backgroundColor: theme.backgroundPrimary,
      body: wardrobeAsync.when(
        data: (items) => _buildContent(context, items),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<WardrobeItemModel> items) {
    return Column(
      children: [
        // Preview section - with auto-loaded user image
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
            child: _previewUrl != null
                ? CachedNetworkImage(
                    imageUrl: _previewUrl!,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const SkeletonLoader(
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                : _userImageBytes != null
                    ? Image.memory(
                        _userImageBytes!,
                        fit: BoxFit.contain,
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Upload photo in Preferences',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
          ),
        ),
        // Controls
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generatePreview,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isGenerating ? 'Generating...' : 'Try On'),
                    ),
                  ),
                  if (_previewUrl != null) ...[
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.save_outlined),
                      onPressed: _saveOutfit,
                      tooltip: 'Save Outfit',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // Wardrobe items selection
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            'No items in wardrobe',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isSelected =
                                _selectedItemIds.contains(item.id);
                            return _buildItemSelector(
                                context, item, isSelected);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemSelector(
    BuildContext context,
    WardrobeItemModel item,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedItemIds.remove(item.id);
          } else {
            _selectedItemIds.add(item.id);
          }
        });
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent)
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => const SkeletonLoader(
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        (context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().scale(
          duration: 200.ms,
          begin: const Offset(0.9, 0.9),
        );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
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
                    'Your AI Fashion Assistant',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _buildNavItem(
              context: context,
              icon: Icons.home,
              label: 'Dashboard',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.dashboard);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.checkroom,
              label: 'Wardrobe',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.wardrobe);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.image_search,
              label: 'Virtual Try-On',
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.lightbulb,
              label: 'Recommendations',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.recommendations);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.calendar_today,
              label: 'Calendar & Events',
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
            const Divider(),
            _buildNavItem(
              context: context,
              icon: Icons.settings,
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

  Widget _buildNavItem({
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

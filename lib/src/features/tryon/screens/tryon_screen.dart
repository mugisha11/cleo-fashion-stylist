import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/fashion_scaffold.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../../auth/providers/auth_provider.dart';
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
  final List<String> _selectedItemIds = [];
  String? _previewUrl;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadUserAvatar();
  }

  Future<void> _loadUserAvatar() async {
    final currentUser = ref.read(currentUserProvider);
    currentUser.whenData((user) {
      if (user != null && user.avatarUrl != null) {
        setState(() {
          _selectedAvatarUrl = user.avatarUrl;
        });
      }
    });
  }

  Future<void> _generatePreview() async {
    if (_selectedAvatarUrl == null || _selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an avatar and at least one clothing item')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final wardrobeAsync = ref.read(wardrobeItemsProvider);
      final wardrobe = await wardrobeAsync.value;
      if (wardrobe == null) return;
      final selectedItems = wardrobe.where((item) => _selectedItemIds.contains(item.id)).toList();
      final imageUrls = selectedItems.map((item) => item.imageUrl).toList();

      final tryOnService = ref.read(tryOnServiceProvider);
      final previewUrl = await tryOnService.generateTryOnPreview(
        avatarUrl: _selectedAvatarUrl!,
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

    return FashionScaffold(
      title: 'Virtual Try-On',
      currentBottomNavIndex: 2,
      currentRoute: Routes.tryon,
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
        // Preview section
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
                : _selectedAvatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: _selectedAvatarUrl!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const SkeletonLoader(
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Select items to try on',
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
                            final isSelected = _selectedItemIds.contains(item.id);
                            return _buildItemSelector(context, item, isSelected);
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
                ? Theme.of(context).colorScheme.primary
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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
}


// ══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
//  outfit_planner_screen.dart
//  100% Dart translation of Nikonyx HTML mockup (cosmic v14)
//  Header: CosmicHeader | Body: Full outfit planning showcase | Footer: CosmicFooter
// ══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../../core/models/outfit_model.dart';
import '../../../core/widgets/cosmic_header_widget.dart';
import '../../../core/widgets/cosmic_footer_widget.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/services/open_router_service.dart';
import '../../../core/services/tryon_service.dart';
import '../../../routes.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../providers/tryon_provider.dart';

// ─── Models ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
class OutfitCard {
  final String id;
  final String name;
  final String subtitle;
  final double score;
  final List<String> tags;
  final List<WardrobeItemModel> items;
  final Color gradientStart;
  final Color gradientEnd;
  final DateTime createdAt;

  OutfitCard({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.score,
    required this.tags,
    required this.items,
    required this.gradientStart,
    required this.gradientEnd,
    required this.createdAt,
  });
}

class SuggestedOutfit {
  final String id;
  final String name;
  final double score;
  final List<String> tags;
  final Color gradientStart;
  final Color gradientEnd;
  final List<WardrobeItemModel> previewItems;

  SuggestedOutfit({
    required this.id,
    required this.name,
    required this.score,
    required this.tags,
    required this.gradientStart,
    required this.gradientEnd,
    required this.previewItems,
  });
}

// ─── Screen ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
class OutfitPlannerScreen extends ConsumerStatefulWidget {
  const OutfitPlannerScreen({super.key});

  @override
  ConsumerState<OutfitPlannerScreen> createState() =>
      _OutfitPlannerScreenState();
}

class _OutfitPlannerScreenState extends ConsumerState<OutfitPlannerScreen> {
  late String _activeFilter;
  late bool _chatOpen;
  late TextEditingController _chatInput;
  late List<OutfitCard> _savedOutfits;
  late List<WardrobeItemModel> _selectedItems;
  late TextEditingController _outfitNameController;
  late List<Map<String, String>> _chatMessages;
  late bool _chatLoading;
  late bool _savingOutfit;
  late bool _deletingOutfit;
  late TryOnService _tryOnService;
  final OpenRouterService _openRouterService = OpenRouterService();

  final List<String> _filters = [
    'All',
    'Date Night',
    'Business',
    'Casual',
    'Evening',
    'Weekend'
  ];

  final List<Color> _gradients = [
    const Color(0xFFBCD0EA),
    const Color(0xFFC8DAF0),
    const Color(0xFFCCD4E8),
    const Color(0xFFD4E4F0),
    const Color(0xFFD0DAF0),
    const Color(0xFFC8E0D0),
    const Color(0xFFE0D4C8),
  ];

  @override
  void initState() {
    super.initState();
    _activeFilter = _filters[0];
    _chatOpen = true;
    _chatInput = TextEditingController();
    _outfitNameController = TextEditingController();
    _selectedItems = [];
    _chatMessages = [];
    _chatLoading = false;
    _savingOutfit = false;
    _deletingOutfit = false;
    _savedOutfits = [];
    _tryOnService = TryOnService();
    _loadSavedOutfits();
  }

  Future<void> _loadSavedOutfits() async {
    try {
      final outfits = await _tryOnService.getUserOutfits();
      if (!mounted) return;
      setState(() {
        _savedOutfits = outfits
            .map((outfit) => OutfitCard(
                  id: outfit.id,
                  name: outfit.name,
                  subtitle: '${outfit.itemIds.length} items',
                  score: 8.5,
                  tags: outfit.itemIds.isNotEmpty ? [outfit.itemIds.first] : [],
                  items: [],
                  gradientStart:
                      _gradients[outfits.indexOf(outfit) % _gradients.length],
                  gradientEnd: _gradients[
                      (outfits.indexOf(outfit) + 1) % _gradients.length],
                  createdAt: outfit.createdAt,
                ))
            .toList();
      });
    } catch (e) {
      debugPrint('Failed to load saved outfits: $e');
    }
  }

  void _showOutfitDetailsModal(OutfitCard outfit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF4F7FF),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      outfit.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0C1E48),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Created: ${outfit.createdAt.toString().split('.')[0]}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6070A0),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Items in this outfit',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0C1E48),
                  ),
                ),
                const SizedBox(height: 12),
                if (outfit.items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF5F8FF),
                      border: Border.all(
                        color: const Color(0xFFB4CDF0),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'No items details available',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6070A0),
                        ),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 160,
                    ),
                    itemCount: outfit.items.length,
                    itemBuilder: (context, index) {
                      final item = outfit.items[index];
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE6EAF6),
                          ),
                          color: Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                child: item.imageUrl.isNotEmpty
                                    ? Image.network(
                                        item.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: const Color(0xFFF0F4FB),
                                            child: const Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                color: Color(0xFFB4CDF0),
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: const Color(0xFFF0F4FB),
                                        child: const Center(
                                          child: Icon(
                                            Icons.photo,
                                            color: Color(0xFFB4CDF0),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.brand ?? item.category,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0C1E48),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    item.category,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF6070A0),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _tryOnOutfit(outfit);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0A1E58), Color(0xFF060F2E)],
                            ),
                          ),
                          child: const Text(
                            'Try-On Now',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD2E8FF),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _editOutfit(outfit);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFB4CDF0),
                            ),
                            color: Colors.white,
                          ),
                          child: const Text(
                            'Edit',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A3060),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _deleteOutfit(outfit);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.red.withValues(alpha: 0.1),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _tryOnOutfit(OutfitCard outfit) async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading try-on interface...'),
          duration: Duration(seconds: 2),
        ),
      );
      // Navigate to try-on screen with outfit data
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        Routes.tryon,
        arguments: {
          'outfitId': outfit.id,
          'outfitName': outfit.name,
          'items': outfit.items,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load try-on: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editOutfit(OutfitCard outfit) {
    _outfitNameController.text = outfit.name;
    _selectedItems = List.from(outfit.items);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF4F7FF),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Outfit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0C1E48),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _outfitNameController.clear();
                          _selectedItems = [];
                          Navigator.pop(context);
                        },
                        child: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _outfitNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter outfit name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Items from Wardrobe',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0C1E48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<WardrobeItemModel>>(
                    future: ref.read(wardrobeItemsProvider.future),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 220,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2A58C8),
                            ),
                          ),
                        );
                      }

                      final items = snapshot.data ?? [];
                      if (items.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFFF5F8FF),
                          ),
                          child: const Text(
                            'No wardrobe items available',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6070A0),
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          mainAxisExtent: 180,
                        ),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isSelected =
                              _selectedItems.any((i) => i.id == item.id);
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                _toggleWardrobeItem(item);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2A58C8)
                                      : const Color(0xFFE6EAF6),
                                  width: isSelected ? 2 : 1,
                                ),
                                color: Colors.white,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                      child: item.imageUrl.isNotEmpty
                                          ? Image.network(
                                              item.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  color:
                                                      const Color(0xFFF0F4FB),
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      color: Color(0xFFB4CDF0),
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: const Color(0xFFF0F4FB),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.photo,
                                                  color: Color(0xFFB4CDF0),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.brand ?? item.category,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0C1E48),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          item.category,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: Color(0xFF6070A0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8,
                                        bottom: 8,
                                      ),
                                      child: Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: isSelected
                                            ? const Color(0xFF2A58C8)
                                            : const Color(0xFFB4CDF0),
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _outfitNameController.clear();
                            _selectedItems = [];
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFB4CDF0),
                              ),
                              color: Colors.white,
                            ),
                            child: const Text(
                              'Cancel',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A3060),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            if (_outfitNameController.text.isEmpty ||
                                _selectedItems.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please name your outfit and select items',
                                  ),
                                ),
                              );
                              return;
                            }

                            try {
                              final itemIds = _selectedItems
                                  .map((item) => item.id)
                                  .toList();

                              final updatedOutfitName =
                                  _outfitNameController.text;

                              // Update outfit in Firestore
                              // Note: TryOnService doesn't have update method yet,
                              // so we'll delete and recreate
                              await _tryOnService.deleteOutfit(outfit.id);
                              await _tryOnService.saveOutfit(
                                name: updatedOutfitName,
                                itemIds: itemIds,
                                previewImageUrl: _selectedItems.isNotEmpty
                                    ? _selectedItems.first.imageUrl
                                    : null,
                                isRecommended: false,
                              );

                              _outfitNameController.clear();
                              _selectedItems = [];

                              // Load saved outfits before popping the modal
                              await _loadSavedOutfits();

                              // Show success message before popping the modal
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Outfit "$updatedOutfitName" updated successfully!',
                                  ),
                                  backgroundColor: const Color(0xFF2A58C8),
                                ),
                              );

                              if (!mounted) return;
                              Navigator.pop(context);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update outfit: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A1E58), Color(0xFF060F2E)],
                              ),
                            ),
                            child: const Text(
                              'Save Changes',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD2E8FF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteOutfit(OutfitCard outfit) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Outfit'),
        content: Text('Are you sure you want to delete "${outfit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (!mounted) return;
              setState(() {
                _deletingOutfit = true;
              });

              try {
                await _tryOnService.deleteOutfit(outfit.id);
                if (!mounted) return;
                setState(() {
                  _savedOutfits.removeWhere((o) => o.id == outfit.id);
                  _deletingOutfit = false;
                });

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Outfit deleted successfully'),
                    backgroundColor: Color(0xFF2A58C8),
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                setState(() {
                  _deletingOutfit = false;
                });

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete outfit: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleWardrobeItem(WardrobeItemModel item) {
    setState(() {
      final index = _selectedItems.indexWhere((i) => i.id == item.id);
      if (index >= 0) {
        _selectedItems.removeAt(index);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  void _showCreateOutfitModal() {
    _outfitNameController.clear();
    _selectedItems = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF4F7FF),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Create New Outfit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0C1E48),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _outfitNameController.clear();
                          _selectedItems = [];
                          Navigator.pop(context);
                        },
                        child: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _outfitNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter outfit name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Items from Wardrobe',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0C1E48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<WardrobeItemModel>>(
                    future: ref.read(wardrobeItemsProvider.future),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 220,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2A58C8),
                            ),
                          ),
                        );
                      }

                      final items = snapshot.data ?? [];
                      if (items.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFFF5F8FF),
                          ),
                          child: const Text(
                            'No wardrobe items available',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6070A0),
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          mainAxisExtent: 180,
                        ),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isSelected =
                              _selectedItems.any((i) => i.id == item.id);
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                _toggleWardrobeItem(item);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2A58C8)
                                      : const Color(0xFFE6EAF6),
                                  width: isSelected ? 2 : 1,
                                ),
                                color: Colors.white,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                      child: item.imageUrl.isNotEmpty
                                          ? Image.network(
                                              item.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  color:
                                                      const Color(0xFFF0F4FB),
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      color: Color(0xFFB4CDF0),
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: const Color(0xFFF0F4FB),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.photo,
                                                  color: Color(0xFFB4CDF0),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.brand ?? item.category,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0C1E48),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          item.category,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: Color(0xFF6070A0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8,
                                        bottom: 8,
                                      ),
                                      child: Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: isSelected
                                            ? const Color(0xFF2A58C8)
                                            : const Color(0xFFB4CDF0),
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _outfitNameController.clear();
                            _selectedItems = [];
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFB4CDF0),
                              ),
                              color: Colors.white,
                            ),
                            child: const Text(
                              'Cancel',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A3060),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            if (_outfitNameController.text.isEmpty ||
                                _selectedItems.isEmpty) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please name your outfit and select items',
                                  ),
                                ),
                              );
                              return;
                            }

                            try {
                              final itemIds = _selectedItems
                                  .map((item) => item.id)
                                  .toList();

                              final outfitName = _outfitNameController.text;

                              await _tryOnService.saveOutfit(
                                name: outfitName,
                                itemIds: itemIds,
                                previewImageUrl: _selectedItems.isNotEmpty
                                    ? _selectedItems.first.imageUrl
                                    : null,
                                isRecommended: false,
                              );

                              _outfitNameController.clear();
                              _selectedItems = [];

                              // Load saved outfits before popping the modal
                              await _loadSavedOutfits();

                              // Show success message before popping the modal
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Outfit "$outfitName" created successfully!',
                                  ),
                                  backgroundColor: const Color(0xFF2A58C8),
                                ),
                              );

                              if (!mounted) return;
                              Navigator.pop(context);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to create outfit: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A1E58), Color(0xFF060F2E)],
                              ),
                            ),
                            child: const Text(
                              'Create Outfit',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD2E8FF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveOutfit() async {
    if (_outfitNameController.text.isEmpty || _selectedItems.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please name your outfit and select items'),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _savingOutfit = true;
    });

    try {
      final itemIds = _selectedItems.map((item) => item.id).toList();

      await _tryOnService.saveOutfit(
        name: _outfitNameController.text,
        itemIds: itemIds,
        previewImageUrl:
            _selectedItems.isNotEmpty ? _selectedItems.first.imageUrl : null,
        isRecommended: false,
      );

      if (!mounted) return;
      setState(() {
        _savingOutfit = false;
      });

      _outfitNameController.clear();
      _selectedItems = [];

      await _loadSavedOutfits();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Outfit saved successfully!'),
          backgroundColor: Color(0xFF2A58C8),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savingOutfit = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save outfit: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendChatMessage() async {
    if (_chatInput.text.trim().isEmpty) return;

    final message = _chatInput.text.trim();
    _chatInput.clear();

    if (!mounted) return;
    setState(() {
      _chatMessages.add({'type': 'user', 'text': message});
      _chatLoading = true;
    });

    try {
      final systemPrompt = OpenRouterService.buildFashionSystemPrompt(
        userName: 'User',
        wardrobeSummary: _savedOutfits
            .expand((outfit) => outfit.items)
            .map((item) => {
                  'id': item.id,
                  'name': item.brand ?? item.category,
                  'category': item.category,
                })
            .toList(),
      );

      final response = await _openRouterService.chat(
        messages: [
          {'role': 'user', 'content': message}
        ],
        systemPrompt: systemPrompt,
        maxTokens: 512,
      );

      if (!mounted) return;
      setState(() {
        _chatMessages.add({'type': 'ai', 'text': response});
        _chatLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chatMessages.add({
          'type': 'ai',
          'text': 'Sorry, I couldn\'t process your request. Please try again.'
        });
        _chatLoading = false;
      });
    }
  }

  Widget _buildChatMessage(Map<String, String> msg) {
    final isUser = msg['type'] == 'user';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: const Color(0xFFA0D2FF).withValues(alpha: 0.3),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.16),
                  Colors.white.withValues(alpha: 0.06),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.person,
                size: 16,
                color: const Color(0xFFC8E1FF).withValues(alpha: 0.6),
              ),
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: isUser
                    ? const Radius.circular(12)
                    : const Radius.circular(4),
                topRight: const Radius.circular(12),
                bottomLeft: const Radius.circular(12),
                bottomRight: isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(12),
              ),
              color: isUser
                  ? const Color(0xFF2A58C8)
                  : const Color(0xFFDCEBFF).withValues(alpha: 0.92),
            ),
            child: Text(
              msg['text'] ?? '',
              style: TextStyle(
                fontSize: 10,
                color:
                    isUser ? const Color(0xFFD2E8FF) : const Color(0xFF0A1428),
                height: 1.5,
              ),
            ),
          ),
        ),
        if (isUser)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A1E58), Color(0xFF060F2E)],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.person,
                size: 16,
                color: Color(0xFFD2E8FF),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _chatInput.dispose();
    _outfitNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FF),
        body: Column(
          children: [
            CosmicHeader(
              onBellTap: () {},
              onAvatarTap: () {},
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPageHeader(),
                    _buildFilterTabs(),
                    _buildSectionHeader('Saved Outfits', 'See all'),
                    _buildOutfitCardsScroll(),
                    _buildDivider(),
                    _buildReuseBar(),
                    _buildSectionHeader('NX Suggests For You', 'See all'),
                    _buildSuggestedScroll(),
                    _buildChatPanel(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            CosmicFooter(
              onTryOn: () {},
              onWardrobe: () {},
              onHome: () {},
              onFriends: () {},
              onOutfits: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFB4CDF0).withValues(alpha: 0.28),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'My Outfits',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0C1E48),
              letterSpacing: -0.2,
            ),
          ),
          _buildCreateButton(),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: _showCreateOutfitModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1E58), Color(0xFF060F2E)],
          ),
          border: Border.all(
            color: const Color(0xFF64A0FF).withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF030828).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CustomPaint(
                painter: _PlusPainter(),
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              'Create',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD2E8FF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFB4CDF0).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        children: _filters.map((filter) {
          final isActive = filter == _activeFilter;
          return _buildFilterTab(filter, isActive);
        }).toList(),
      ),
    );
  }

  Widget _buildFilterTab(String label, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isActive
                ? const [Color(0xFF0A1E58), Color(0xFF060F2E)]
                : const [Color(0xFFF0F5FF), Color(0xFFE4EDF8)],
          ),
          border: Border.all(
            color: isActive
                ? const Color(0xFF64A0FF).withValues(alpha: 0.4)
                : const Color(0xFFB4CDF0).withValues(alpha: 0.55),
            width: 1,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: const Color(0xFF030828).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            if (!isActive)
              BoxShadow(
                color: const Color(0xff1432780).withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: isActive ? const Color(0xFFD2E8FF) : const Color(0xFF1A2A50),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String link) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0C1E48),
              letterSpacing: -0.1,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Text(
              link,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF2A58C8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitCardsScroll() {
    return SizedBox(
      height: 320,
      child: _savedOutfits.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No outfits yet. Tap "Create" to build your first outfit!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF6070A0).withValues(alpha: 0.7),
                  ),
                ),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _savedOutfits.length,
              itemBuilder: (context, index) =>
                  _buildOutfitCard(_savedOutfits[index]),
            ),
    );
  }

  Widget _buildOutfitCard(OutfitCard outfit) {
    return GestureDetector(
      onTap: () => _showOutfitDetailsModal(outfit),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 148,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          boxShadow: [
            const BoxShadow(
              color: Color(0xFF8AACCC),
              blurRadius: 0,
              offset: Offset.zero,
              spreadRadius: 1.5,
            ),
            const BoxShadow(
              color: Color(0xFFD4E8F8),
              blurRadius: 0,
              offset: Offset.zero,
              spreadRadius: 3,
            ),
            const BoxShadow(
              color: Color(0xFF7898B8),
              blurRadius: 0,
              offset: Offset.zero,
              spreadRadius: 4.5,
            ),
            BoxShadow(
              color: const Color(0xff1432780).withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [outfit.gradientStart, outfit.gradientEnd],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildOutfitImagePreview(outfit),
                  Positioned(
                    top: 7,
                    left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0A1E58), Color(0xFF060F2E)],
                        ),
                        border: Border.all(
                          color: const Color(0xFF78B4FF).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.male, size: 10, color: Color(0xFF9FCBFF)),
                          SizedBox(width: 4),
                          Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFC8E8FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0A1E58), Color(0xFF060F2E)],
                        ),
                        border: Border.all(
                          color: const Color(0xFF78B4FF).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star,
                              size: 8, color: Color(0xFF4DA3FF)),
                          const SizedBox(width: 3),
                          Text(
                            '${outfit.score}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFC8E8FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFFB4D2F0).withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outfit.name,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0C1E48),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      outfit.subtitle,
                      style: const TextStyle(
                        fontSize: 8.5,
                        color: Color(0xFF6070A0),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 4,
                      children: outfit.tags
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFEEF3FF),
                                      Color(0xFFE4EDF8)
                                    ],
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFB4CDF0)
                                        .withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2A4080),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context); // Close details if open
                              _tryOnOutfit(outfit);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF0A1E58),
                                    Color(0xFF060F2E)
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0xFF64A0FF)
                                      .withValues(alpha: 0.32),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF030828)
                                        .withValues(alpha: 0.28),
                                    blurRadius: 7,
                                    offset: const Offset(0, 3),
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFA0D2FF)
                                        .withValues(alpha: 0.18),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Try-On',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFD2E8FF),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context); // Close details if open
                              _editOutfit(outfit);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFF0F5FF),
                                    Color(0xFFE4EDF8)
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0xFFB4CDF0)
                                      .withValues(alpha: 0.55),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Edit',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A3060),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewImageThumbnail(WardrobeItemModel item,
      {double size = 28}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFB4CDF0).withValues(alpha: 0.65),
          width: 1,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Image.network(
        item.processedImageUrl ?? item.imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.image_not_supported,
                color: Color(0xFF8EA7CC), size: 16),
          );
        },
      ),
    );
  }

  Widget _buildOutfitImagePreview(OutfitCard outfit) {
    if (outfit.items.isEmpty) {
      return Container(
        width: 72,
        height: 82,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF5A8CC8).withValues(alpha: 0.42),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CustomPaint(
                painter: _ImagePlaceholderPainter(),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Add Photo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 7,
                color: const Color(0xFF5A8CC8).withValues(alpha: 0.45),
                height: 1.3,
              ),
            ),
          ],
        ),
      );
    }

    final previewItems = outfit.items.take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < previewItems.length; i++) ...[
            _buildPreviewImageThumbnail(previewItems[i], size: 44),
            if (i < previewItems.length - 1) const SizedBox(width: 6),
          ],
          if (outfit.items.length > previewItems.length) ...[
            const SizedBox(width: 6),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF3FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFB4CDF0).withValues(alpha: 0.65),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '+${outfit.items.length - previewItems.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2A58C8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 3,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            const Color(0xFF96B9E6).withValues(alpha: 0.3),
            const Color(0xFFC8E1F8).withValues(alpha: 0.8),
            const Color(0xFFF4F7FF),
            const Color(0xFFC8E1F8).withValues(alpha: 0.8),
            const Color(0xFF96B9E6).withValues(alpha: 0.3),
            Colors.transparent,
          ],
          stops: const [0, 0.15, 0.4, 0.5, 0.6, 0.85, 1],
        ),
      ),
    );
  }

  Widget _buildReuseBar() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment(0.7, 0),
            end: Alignment(-0.7, 1),
            colors: [Color(0xFF0A1E58), Color(0xFF060F2E)],
          ),
          border: Border.all(
            color: const Color(0xFF64A0FF).withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF030828).withValues(alpha: 0.32),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color(0xFFA0D2FF).withValues(alpha: 0.18),
              blurRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reuse Existing Outfit',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD2E8FF),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mix & match from your wardrobe',
                    style: TextStyle(
                      fontSize: 9,
                      color: const Color(0xFFA0C8FF).withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward,
              size: 14,
              color: const Color(0xFFA0C8FF).withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedScroll() {
    // Generate AI suggestions based on saved outfits
    final List<SuggestedOutfit> suggestions = _generateAISuggestions();

    return SizedBox(
      height: 140,
      child: suggestions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Create an outfit first to get AI suggestions!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF6070A0).withValues(alpha: 0.7),
                  ),
                ),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: suggestions.length,
              itemBuilder: (context, index) =>
                  _buildSuggestedCard(suggestions[index]),
            ),
    );
  }

  List<SuggestedOutfit> _generateAISuggestions() {
    if (_savedOutfits.isEmpty) return [];

    final combinedItems =
        _savedOutfits.expand((outfit) => outfit.items).toList();
    if (combinedItems.isEmpty) return [];

    // AI grouping by occasion/category
    final occasionGroups = <String, List<String>>{
      'Business Meeting': ['Navy', 'White', 'Black'],
      'Evening Date': ['Charcoal', 'Warm'],
      'Weekend Casual': ['Casual', 'Relaxed'],
      'Social Event': ['Evening', 'Formal'],
    };

    return occasionGroups.entries.map((entry) {
      final randomScore = (entry.key.hashCode % 4) / 10 + 8.5;
      final previewItems = <WardrobeItemModel>[];
      for (var offset = 0; offset < 3; offset++) {
        previewItems.add(
          combinedItems[(entry.key.hashCode + offset) % combinedItems.length],
        );
      }

      return SuggestedOutfit(
        id: entry.key,
        name: entry.key,
        score: randomScore.clamp(8.0, 9.9),
        tags: entry.value,
        gradientStart: _gradients[entry.key.hashCode % _gradients.length],
        gradientEnd: _gradients[(entry.key.hashCode + 1) % _gradients.length],
        previewItems: previewItems,
      );
    }).toList();
  }

  Widget _buildSuggestedCard(SuggestedOutfit outfit) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          const BoxShadow(
            color: Color(0xFFB0C8E0),
            blurRadius: 0,
            offset: Offset.zero,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Color(0xFFD8ECF8),
            blurRadius: 0,
            offset: Offset.zero,
            spreadRadius: 2.5,
          ),
          const BoxShadow(
            color: Color(0xFF8AACCC),
            blurRadius: 0,
            offset: Offset.zero,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: const Color(0xff1432780).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [outfit.gradientStart, outfit.gradientEnd],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: outfit.previewItems.isEmpty
                    ? Container(
                        width: 44,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                const Color(0xFF5A8CC8).withValues(alpha: 0.35),
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CustomPaint(
                              painter: _ImagePlaceholderPainter(),
                            ),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: outfit.previewItems
                            .take(3)
                            .map((item) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: _buildPreviewImageThumbnail(item,
                                      size: 28),
                                ))
                            .toList(),
                      ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFB4D2F0).withValues(alpha: 0.22),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outfit.name,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0C1E48),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '★ ${outfit.score}',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Color(0xFF2A58C8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment(0.7, 0),
          end: Alignment(-0.7, 1),
          colors: [Color(0xFF0A1E58), Color(0xFF060F2E)],
        ),
        border: Border.all(
          color: const Color(0xFF64A0FF).withValues(alpha: 0.38),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF030828).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: const Color(0xFFA0D2FF).withValues(alpha: 0.18),
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _chatOpen = !_chatOpen),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF64A0FF).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDot(),
                          const SizedBox(width: 2.5),
                          _buildDot(),
                          const SizedBox(width: 2.5),
                          _buildDot(),
                        ],
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'NX Chat',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD2E8FF),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF78A0FF).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _chatOpen ? 'Minimize' : 'Expand',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFFA0C8FF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_chatOpen) ...[
            SizedBox(
              height: 200, // Fixed height for chat messages area
              child: SingleChildScrollView(
                reverse: true,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _chatMessages.isEmpty
                        ? [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(
                                      color: const Color(0xFFA0D2FF)
                                          .withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.16),
                                        Colors.white.withValues(alpha: 0.06),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.person,
                                      size: 16,
                                      color: const Color(0xFFC8E1FF)
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                      color: const Color(0xFFDCEBFF)
                                          .withValues(alpha: 0.92),
                                    ),
                                    child: const Text(
                                      'Hi! I\'m Nikonyx, your fashion stylist. Start by adding items to your wardrobe, then I\'ll help you create amazing outfits!',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF0A1428),
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ]
                        : _chatMessages
                            .map((msg) => _buildChatMessage(msg))
                            .toList(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color:
                              const Color(0xFF64A0FF).withValues(alpha: 0.28),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _chatInput,
                        enabled: !_chatLoading,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFD2E8FF),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask NX about your outfits…',
                          hintStyle: TextStyle(
                            fontSize: 10,
                            color:
                                const Color(0xFFA0C8FF).withValues(alpha: 0.45),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _chatLoading ? null : _sendChatMessage,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _chatLoading
                              ? [
                                  const Color(0xFF1A2A50),
                                  const Color(0xFF0F1828)
                                ]
                              : [
                                  const Color(0xFF2A58C8),
                                  const Color(0xFF1A3A9A)
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF143CC8).withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _chatLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFD2E8FF),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.arrow_upward,
                              size: 11,
                              color: Color(0xFFD2E8FF),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: const Color(0xFFC8E1FF).withValues(alpha: 0.6),
      ),
    );
  }
}

// ─── Custom Painters ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
class _PlusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD2E8FF)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const length = 6.0;

    // Vertical line
    canvas.drawLine(Offset(centerX, centerY - length),
        Offset(centerX, centerY + length), paint);

    // Horizontal line
    canvas.drawLine(Offset(centerX - length, centerY),
        Offset(centerX + length, centerY), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ImagePlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5A8CC8).withValues(alpha: 0.48)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(size.width * 0.15, size.height * 0.15,
        size.width * 0.7, size.height * 0.7);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.08)),
        paint);

    final circlePaint = Paint()
      ..color = const Color(0xFF5A8CC8).withValues(alpha: 0.48)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.35),
        size.width * 0.08, circlePaint);

    final linePaint = Paint()
      ..color = const Color(0xFF5A8CC8).withValues(alpha: 0.48)
      ..strokeWidth = 1.3;
    canvas.drawLine(Offset(size.width * 0.85, size.height * 0.7),
        Offset(size.width * 0.15, size.height * 0.85), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

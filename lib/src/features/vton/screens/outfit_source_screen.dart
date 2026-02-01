import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/vton_service.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import 'tryon_preview_screen.dart';

/// Outfit source selection screen
class OutfitSourceScreen extends ConsumerStatefulWidget {
  final String photoUrl;

  const OutfitSourceScreen({super.key, required this.photoUrl});

  @override
  ConsumerState<OutfitSourceScreen> createState() => _OutfitSourceScreenState();
}

class _OutfitSourceScreenState extends ConsumerState<OutfitSourceScreen> {
  String? _selectedOutfitId;
  String? _selectedOutfitUrl;
  String _selectedSource = 'wardrobe'; // 'wardrobe' or 'web'
  final _webUrlController = TextEditingController();

  @override
  void dispose() {
    _webUrlController.dispose();
    super.dispose();
  }

  Future<void> _proceedWithTryOn() async {
    if (_selectedSource == 'wardrobe' && _selectedOutfitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an outfit from your wardrobe')),
      );
      return;
    }

    if (_selectedSource == 'web' && _selectedOutfitUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid outfit URL')),
      );
      return;
    }

    try {
      final sessionId = await ref.read(vtonServiceProvider).submitTryOnJob(
            photoUrl: widget.photoUrl,
            outfitSource: _selectedSource,
            outfitId: _selectedOutfitId,
            outfitUrl: _selectedOutfitUrl,
          );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TryOnPreviewScreen(sessionId: sessionId),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text('Choose Outfit'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Source selection tabs
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _SourceTab(
                      label: 'My Wardrobe',
                      isSelected: _selectedSource == 'wardrobe',
                      onTap: () => setState(() => _selectedSource = 'wardrobe'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceTab(
                      label: 'Web/Catalog',
                      isSelected: _selectedSource == 'web',
                      onTap: () => setState(() => _selectedSource = 'web'),
                    ),
                  ),
                ],
              ),
            ),

            // Content based on selection
            Expanded(
              child: _selectedSource == 'wardrobe'
                  ? _WardrobeSelector(
                      selectedId: _selectedOutfitId,
                      onSelect: (id) => setState(() => _selectedOutfitId = id),
                    )
                  : _WebUrlInput(
                      controller: _webUrlController,
                      onUrlSet: (url) => setState(() => _selectedOutfitUrl = url),
                    ),
            ),

            // Proceed button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _proceedWithTryOn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8C7AE6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Start Try-On',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SourceTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFF8C7AE6) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF1E1E2E),
            ),
          ),
        ),
      ),
    );
  }
}

class _WardrobeSelector extends ConsumerWidget {
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _WardrobeSelector({
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wardrobeAsync = ref.watch(wardrobeItemsProvider);

    return wardrobeAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.checkroom_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No items in wardrobe',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isSelected = selectedId == item.id;

            return GestureDetector(
              onTap: () => onSelect(item.id),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF8C7AE6),
                          width: 4,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black.withOpacity(0.3),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _WebUrlInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onUrlSet;

  const _WebUrlInput({
    required this.controller,
    required this.onUrlSet,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Outfit Image URL',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Paste a URL to an outfit image from a catalog or website',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'https://example.com/outfit.jpg',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.link),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && Uri.tryParse(value) != null) {
                onUrlSet(value);
              }
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Make sure the image URL is publicly accessible and shows a clear view of the outfit',
                    style: TextStyle(color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


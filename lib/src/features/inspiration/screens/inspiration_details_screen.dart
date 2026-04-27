import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../core/services/backend_config_service.dart';
import '../../../core/widgets/cosmic_header_widget.dart';
import '../../../core/widgets/cosmic_footer_widget.dart';
import '../../../core/widgets/fashion_drawer.dart';
import '../../../routes.dart';

class InspirationDetailsScreen extends ConsumerStatefulWidget {
  final String? imageUrl;
  final String? outfitTitle;
  final String? outfitDescription;

  const InspirationDetailsScreen({
    super.key,
    this.imageUrl,
    this.outfitTitle,
    this.outfitDescription,
  });

  @override
  ConsumerState<InspirationDetailsScreen> createState() =>
      _InspirationDetailsScreenState();
}

class _InspirationDetailsScreenState
    extends ConsumerState<InspirationDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isAnalyzing = false;
  String? _analysisMessage;
  Map<String, dynamic>? _extractedFeatures;

  Future<void> _analyzeUserImage() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _isAnalyzing = true;
      _analysisMessage = 'Analyzing your inspiration image…';
    });

    try {
      final baseUrl = await BackendConfigService.getBackendUrl();
      final bytes = await File(pickedFile.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http
          .post(
            Uri.parse('$baseUrl/clothing-recognition/recognize'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'image_data': base64Image,
              'mode': 'outfit_features',
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _extractedFeatures = data;
          _analysisMessage = 'Outfit analysis complete! Finding similar items…';
        });

        // Automatically search for products based on extracted features
        if (mounted) {
          _searchForSimilarProducts(data);
        }
      } else {
        throw Exception('Analysis failed: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analysisMessage = 'Could not analyze image. Please try another.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _analyzeImageUrl(String url) async {
    setState(() {
      _isAnalyzing = true;
      _analysisMessage = 'Analyzing inspiration…';
    });

    try {
      final baseUrl = await BackendConfigService.getBackendUrl();
      final response = await http
          .post(
            Uri.parse('$baseUrl/clothing-recognition/recognize-url'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'image_url': url}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _extractedFeatures = data;
          _analysisMessage = 'Got it! Finding matching pieces…';
        });

        if (mounted) {
          _searchForSimilarProducts(data);
        }
      } else {
        throw Exception('Analysis failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analysisMessage =
              'Could not analyze this URL. Try uploading a photo.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  void _searchForSimilarProducts(Map<String, dynamic> features) {
    final garments = features['garments'] as List? ?? [];
    if (garments.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No clothing items detected.')),
        );
      }
      return;
    }

    final searchQueries = garments
        .whereType<Map<String, dynamic>>()
        .map((g) => (g['category'] ?? '') + ' ' + (g['color'] ?? ''))
        .where((q) => q.trim().isNotEmpty)
        .toList();

    if (searchQueries.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not extract outfit details.')),
        );
      }
      return;
    }

    // Navigate to recommendations with combined search query
    final combinedQuery = searchQueries.join(' ');
    if (mounted) {
      Navigator.of(context).pushNamed(Routes.recommendations);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4FF),
      drawer: const AppDrawer(currentRoute: Routes.inspiration),
      body: Stack(
        children: [
          Column(
            children: [
              CosmicHeader(
                topPadding: MediaQuery.of(context).padding.top,
                hasNotification: false,
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                onBellTap: () {},
                onAvatarTap: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.imageUrl != null)
                          _buildInspirationPreview()
                        else
                          _buildUploadSection(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                        if (_extractedFeatures != null) ...[
                          const SizedBox(height: 24),
                          _buildExtractedFeatures(),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
              CosmicFooter(
                bottomPadding: MediaQuery.of(context).padding.bottom,
                activeIndex: 0,
                onTryOn: () => Navigator.of(context).pushNamed(Routes.tryon),
                onWardrobe: () =>
                    Navigator.of(context).pushNamed(Routes.wardrobe),
                onHome: () => Navigator.of(context).pushNamed(Routes.dashboard),
                onFriends: () {},
                onOutfits: () => Navigator.pushNamed(context, Routes.savedTryOns),
              ),
            ],
          ),
          if (_isAnalyzing)
            Container(
              color: Colors.black26,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _analysisMessage ?? 'Processing…',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInspirationPreview() {
    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.imageUrl!,
          height: 300,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 300,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Upload Inspiration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share an Instagram look or upload a photo to get style recommendations',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _analyzeUserImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Upload Photo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _analyzeUserImage,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Choose from Gallery'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            _showPasteUrlDialog();
          },
          icon: const Icon(Icons.link),
          label: const Text('Paste Instagram URL'),
        ),
      ],
    );
  }

  Widget _buildExtractedFeatures() {
    final garments = _extractedFeatures?['garments'] as List? ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detected Outfit Items',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...garments.map((g) {
              final garment = g as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _parseColor(garment['color'] ?? 'gray'),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            garment['category'] ?? 'Item',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            garment['color'] ?? 'Unknown color',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showPasteUrlDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paste Image URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://instagram.com/...',
            border: OutlineInputBorder(),
          ),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(context);
                _analyzeImageUrl(url);
              }
            },
            child: const Text('Analyze'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorName) {
    final lower = colorName.toLowerCase();
    if (lower.contains('black')) return Colors.black;
    if (lower.contains('white')) return Colors.white;
    if (lower.contains('blue')) return Colors.blue;
    if (lower.contains('red')) return Colors.red;
    if (lower.contains('green')) return Colors.green;
    if (lower.contains('yellow')) return Colors.yellow;
    if (lower.contains('gray') || lower.contains('grey')) return Colors.grey;
    if (lower.contains('pink')) return Colors.pink;
    if (lower.contains('purple')) return Colors.purple;
    if (lower.contains('orange')) return Colors.orange;
    if (lower.contains('brown')) return Colors.brown;
    return Colors.grey[400]!;
  }
}

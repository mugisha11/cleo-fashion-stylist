import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/utils/file_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/platform_image.dart';
import '../../../core/widgets/cosmic_header_widget.dart';
import '../../../core/widgets/cosmic_footer_widget.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../../../routes.dart';
import '../providers/wardrobe_provider.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

const Color _wardrobeSurface = Color(0xFFF0F4FA);
const Color _wardrobeField = Color(0xFFF7F9FC);
const Color _wardrobeBorder = Color(0xFF0A4E8F);
const Color _wardrobeButton = Color(0xFF2050C8);
const Color _wardrobeText = Color(0xFF0A1830);
const Color _wardrobeSubtle = Color(0xFF4A6A9A);

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _brandController = TextEditingController();
  final _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  io.File? _selectedImage;
  Uint8List? _selectedImageBytes; // For web compatibility
  final List<String> _selectedColors = [];
  bool _isUploading = false;

  final List<String> _categories = [
    'Top',
    'Bottom',
    'Dress',
    'Shoes',
    'Accessories',
    'Outerwear',
  ];

  final List<String> _colors = [
    'Black',
    'White',
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Pink',
    'Purple',
    'Orange',
    'Brown',
    'Gray',
    'Navy',
  ];

  @override
  void dispose() {
    _categoryController.dispose();
    _brandController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        if (kIsWeb) {
          // For web, read bytes from XFile
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null;
          });
        } else {
          setState(() {
            _selectedImage = createPlatformFile(image.path) as io.File?;
            _selectedImageBytes = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _uploadItem() async {
    if (_selectedImage == null && _selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final service = ref.read(wardrobeServiceProvider);
      // Pass bytes for web, file for mobile
      final fileToUpload = kIsWeb ? _selectedImageBytes : _selectedImage;

      if (fileToUpload != null) {
        // AI will auto-detect category and colors if not provided
        await service.uploadItem(
          imageFile: fileToUpload,
          category: _categoryController.text.isEmpty
              ? null
              : _categoryController.text,
          colorTags: _selectedColors.isEmpty ? null : _selectedColors,
          brand: _brandController.text.isEmpty ? null : _brandController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
      } else {
        throw Exception('No image selected');
      }

      if (mounted) {
        // Invalidate and wait for refresh to ensure UI updates
        ref.invalidate(wardrobeItemsProvider);
        // Wait a moment for Firestore to sync
        await Future.delayed(const Duration(milliseconds: 500));
        // Refresh the provider
        await ref.read(wardrobeItemsProvider.future);

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        // Show detailed error message
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        // Also print to console for debugging
        print('Wardrobe upload error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          CosmicHeader(
            topPadding: mq.padding.top,
            hasNotification: false,
            onMenuTap: () {},
            onBellTap: () {},
            onAvatarTap: () => Navigator.pushNamed(context, Routes.settings),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: FashionDesignSystem.spacingLG,
                  vertical: FashionDesignSystem.spacingXL,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: _wardrobeSurface,
                          borderRadius: BorderRadius.circular(
                              FashionDesignSystem.radiusLG),
                          border: Border.all(
                            color: _wardrobeBorder,
                            width: 1.5,
                          ),
                        ),
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: SizedBox(
                            height: 300,
                            child: (_selectedImageBytes != null ||
                                    (!kIsWeb && _selectedImage != null))
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        FashionDesignSystem.radiusLG),
                                    child: PlatformImage(
                                      file: kIsWeb ? null : _selectedImage,
                                      bytes: _selectedImageBytes,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 64,
                                        color: _wardrobeButton,
                                      ),
                                      const SizedBox(
                                          height:
                                              FashionDesignSystem.spacingMD),
                                      Text(
                                        'Tap to select image',
                                        style: FashionDesignSystem.titleMedium()
                                            .copyWith(
                                          color: _wardrobeText,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: FashionDesignSystem.spacingXXL),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _wardrobeField,
                          labelText:
                              'Category (Optional - AI will auto-detect)',
                          helperText: 'Leave empty for automatic detection',
                          prefixIcon: const Icon(
                            Icons.category_outlined,
                            color: _wardrobeSubtle,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                FashionDesignSystem.radiusMD),
                            borderSide:
                                const BorderSide(color: _wardrobeBorder, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                FashionDesignSystem.radiusMD),
                            borderSide:
                                const BorderSide(color: _wardrobeButton, width: 2),
                          ),
                        ),
                        dropdownColor: _wardrobeSurface,
                        style: FashionDesignSystem.bodyMedium()
                            .copyWith(color: _wardrobeText),
                        items: [
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text('Auto-detect (Recommended)'),
                          ),
                          ..._categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          _categoryController.text = value ?? '';
                        },
                      ),
                      const SizedBox(height: FashionDesignSystem.spacingLG),
                      TextFormField(
                        controller: _brandController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _wardrobeField,
                          labelText: 'Brand (Optional)',
                          prefixIcon: const Icon(
                            Icons.store_outlined,
                            color: _wardrobeSubtle,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                FashionDesignSystem.radiusMD),
                            borderSide:
                                const BorderSide(color: _wardrobeBorder, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                FashionDesignSystem.radiusMD),
                            borderSide:
                                const BorderSide(color: _wardrobeButton, width: 2),
                          ),
                        ),
                        style: FashionDesignSystem.bodyMedium()
                            .copyWith(color: _wardrobeText),
                      ),
                      const SizedBox(height: FashionDesignSystem.spacingLG),
                      Row(
                        children: [
                          Text(
                            'Colors (Optional)',
                            style: FashionDesignSystem.titleMedium()
                                .copyWith(color: _wardrobeText),
                          ),
                          const SizedBox(width: 8),
                          const Tooltip(
                            message:
                                'AI will automatically detect colors if none selected',
                            child: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Color(0xFF808B9E),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'AI will auto-detect colors if none selected',
                        style: FashionDesignSystem.bodySmall().copyWith(
                          color: _wardrobeSubtle,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: FashionDesignSystem.spacingMD),
                      Wrap(
                        spacing: FashionDesignSystem.spacingSM,
                        runSpacing: FashionDesignSystem.spacingSM,
                        children: _colors.map((color) {
                          final isSelected = _selectedColors.contains(color);
                          return FilterChip(
                            label: Text(color),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : _wardrobeText,
                            ),
                            selected: isSelected,
                            selectedColor: _wardrobeButton.withOpacity(0.22),
                            checkmarkColor: _wardrobeButton,
                            backgroundColor: _wardrobeField,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedColors.add(color);
                                } else {
                                  _selectedColors.remove(color);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: FashionDesignSystem.spacingLG),
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _wardrobeField,
                          labelText: 'Notes (Optional)',
                          prefixIcon: const Icon(
                            Icons.note_outlined,
                            color: _wardrobeSubtle,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                FashionDesignSystem.radiusMD),
                            borderSide:
                                const BorderSide(color: _wardrobeBorder, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                FashionDesignSystem.radiusMD),
                            borderSide:
                                const BorderSide(color: _wardrobeButton, width: 2),
                          ),
                        ),
                        maxLines: 3,
                        style: FashionDesignSystem.bodyMedium()
                            .copyWith(color: _wardrobeText),
                      ),
                      const SizedBox(height: FashionDesignSystem.spacingXXXL),
                      ElevatedButton(
                        onPressed: _isUploading ? null : () => _uploadItem(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _wardrobeButton,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: FashionDesignSystem.spacingMD,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                FashionDesignSystem.radiusMD),
                          ),
                        ),
                        child: _isUploading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Add to Wardrobe',
                                style:
                                    FashionDesignSystem.bodyMedium().copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          CosmicFooter(
            bottomPadding: mq.padding.bottom,
            activeIndex: 1,
            onTryOn: () => Navigator.pushNamed(context, Routes.tryon),
            onWardrobe: () => Navigator.pushNamed(context, Routes.wardrobe),
            onHome: () => Navigator.pushNamed(context, Routes.dashboard),
            onFriends: () => Navigator.pushNamed(context, Routes.styleFeed),
            onOutfits: () => Navigator.pushNamed(context, Routes.savedTryOns),
          ),
        ],
      ),
    );
  }
}

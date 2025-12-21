import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/utils/file_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/platform_image.dart';
import '../../../core/widgets/fashion_scaffold.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../providers/wardrobe_provider.dart';
import '../../../routes.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _brandController = TextEditingController();
  final _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  io.File? _selectedImage;
  Uint8List? _selectedImageBytes; // For web compatibility
  List<String> _selectedColors = [];
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
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null && _selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }
    if (_selectedColors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one color')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final service = ref.read(wardrobeServiceProvider);
      // Pass bytes for web, file for mobile
      final fileToUpload = kIsWeb ? _selectedImageBytes : _selectedImage;
      
      if (fileToUpload != null) {
        await service.uploadItem(
          imageFile: fileToUpload,
          category: _categoryController.text,
          colorTags: _selectedColors,
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
    return FashionScaffold(
      title: 'Add Item',
      showBottomNav: false,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(FashionDesignSystem.spacingLG),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: FashionDesignSystem.backgroundLight,
                    borderRadius: BorderRadius.circular(FashionDesignSystem.radiusLG),
                    border: Border.all(
                      color: FashionDesignSystem.borderColor,
                      width: 2,
                    ),
                  ),
                  child: (_selectedImageBytes != null || (!kIsWeb && _selectedImage != null))
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(FashionDesignSystem.radiusMD),
                          child: PlatformImage(
                            file: kIsWeb ? null : _selectedImage,
                            bytes: _selectedImageBytes,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 64,
                              color: FashionDesignSystem.primaryColor,
                            ),
                            SizedBox(height: FashionDesignSystem.spacingMD),
                            Text(
                              'Tap to select image',
                              style: FashionDesignSystem.titleMedium(),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: FashionDesignSystem.spacingXXL),
              // Category
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(
                    Icons.category_outlined,
                    color: FashionDesignSystem.textSecondary,
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  _categoryController.text = value ?? '';
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              SizedBox(height: FashionDesignSystem.spacingLG),
              // Brand (optional)
              TextFormField(
                controller: _brandController,
                decoration: InputDecoration(
                  labelText: 'Brand (Optional)',
                  prefixIcon: Icon(
                    Icons.store_outlined,
                    color: FashionDesignSystem.textSecondary,
                  ),
                ),
              ),
              SizedBox(height: FashionDesignSystem.spacingLG),
              // Colors
              Text(
                'Colors',
                style: FashionDesignSystem.titleMedium(),
              ),
              SizedBox(height: FashionDesignSystem.spacingMD),
              Wrap(
                spacing: FashionDesignSystem.spacingSM,
                runSpacing: FashionDesignSystem.spacingSM,
                children: _colors.map((color) {
                  final isSelected = _selectedColors.contains(color);
                  return FilterChip(
                    label: Text(color),
                    selected: isSelected,
                    selectedColor: FashionDesignSystem.primaryColor.withOpacity(0.2),
                    checkmarkColor: FashionDesignSystem.primaryColor,
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
              SizedBox(height: FashionDesignSystem.spacingLG),
              // Notes (optional)
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  prefixIcon: Icon(
                    Icons.note_outlined,
                    color: FashionDesignSystem.textSecondary,
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: FashionDesignSystem.spacingXXXL),
              // Upload button
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FashionDesignSystem.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: FashionDesignSystem.spacingMD,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FashionDesignSystem.radiusMD),
                  ),
                ),
                child: _isUploading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Add to Wardrobe',
                        style: FashionDesignSystem.bodyMedium().copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


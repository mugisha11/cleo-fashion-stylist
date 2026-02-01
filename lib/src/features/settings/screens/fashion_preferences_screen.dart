import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../core/theme/settings_theme.dart';
import '../../../core/providers/user_image_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section_card.dart';

class FashionPreferencesScreen extends ConsumerStatefulWidget {
  const FashionPreferencesScreen({super.key});

  @override
  ConsumerState<FashionPreferencesScreen> createState() =>
      _FashionPreferencesScreenState();
}

class _FashionPreferencesScreenState
    extends ConsumerState<FashionPreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  String? _selectedBodyType;
  final List<String> _bodyTypes = [
    'Slim',
    'Athletic',
    'Curvy',
    'Plus Size',
    'Petite',
    'Tall'
  ];

  List<String> _selectedStyles = [];
  List<String> _selectedColors = [];
  List<String> _selectedEvents = [];

  final List<String> _styles = [
    'Casual',
    'Formal',
    'Streetwear',
    'Bohemian',
    'Minimalist',
    'Vintage',
    'Sporty'
  ];
  final List<String> _colors = [
    'Black',
    'White',
    'Navy',
    'Gray',
    'Beige',
    'Pastels',
    'Bright Colors'
  ];
  final List<String> _events = [
    'Casual',
    'Work',
    'Party',
    'Traditional',
    'Wedding',
    'Travel'
  ];

  void _loadInitialValues(WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    _heightController.text = settings.height?.toStringAsFixed(0) ?? '';
    _selectedBodyType = settings.bodyType;
    _selectedStyles = List.from(settings.preferredStyles);
    _selectedColors = List.from(settings.colorPreferences);
    _selectedEvents = List.from(settings.eventPreferences);
  }

  @override
  void dispose() {
    _heightController.dispose();
    super.dispose();
  }

  /// Pick and upload user image for try-on (gallery or camera).
  Future<void> _pickAndUploadImage({ImageSource source = ImageSource.gallery}) async {
    try {
      HapticFeedback.mediumImpact();
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final mimeType = _getMimeTypeFromPath(pickedFile.path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text('Saving your photo…'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        final success = await ref
            .read(userImageProvider.notifier)
            .uploadUserImage(bytes, mimeType);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('✓ Photo saved — it’ll load in Try-On every time'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
                backgroundColor: SettingsTheme.success,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to save photo'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Empty state for My Try-On Photo card (elegant placeholder).
  Widget _buildEmptyPhotoPlaceholder(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(SettingsTheme.primaryBlue),
              ),
            )
          else ...[
            Icon(
              Icons.person_outline_rounded,
              size: 56,
              color: SettingsTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No photo yet',
              style: TextStyle(
                color: SettingsTheme.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Upload a clear full-body photo',
              style: TextStyle(
                color: SettingsTheme.textTertiary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Get MIME type from file path
  String _getMimeTypeFromPath(String path) {
    if (path.toLowerCase().endsWith('.png')) {
      return 'image/png';
    } else if (path.toLowerCase().endsWith('.gif')) {
      return 'image/gif';
    } else if (path.toLowerCase().endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg'; // Default to JPEG
  }

  /// Delete user image
  Future<void> _deleteUserImage() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo?'),
        content:
            const Text('Your try-on photo will be removed from all pages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success =
          await ref.read(userImageProvider.notifier).deleteUserImage();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '✓ Photo deleted' : 'Failed to delete'),
          ),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    final height = double.tryParse(_heightController.text);

    await ref.read(settingsProvider.notifier).updateFashionPreferences(
          height: height,
          bodyType: _selectedBodyType,
          preferredStyles: _selectedStyles,
          colorPreferences: _selectedColors,
          eventPreferences: _selectedEvents,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final userImage = ref.watch(userImageProvider);
    final userImageBytes = ref.watch(userImageBytesProvider);

    // Load initial values on first build
    if (_heightController.text.isEmpty && settings.height != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialValues(ref);
      });
    }

    return Scaffold(
      backgroundColor: SettingsTheme.backgroundLightBlue,
      appBar: AppBar(
        title: const Text('Fashion Preferences'),
        backgroundColor: SettingsTheme.backgroundWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: SettingsTheme.textPrimary),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(SettingsTheme.spacingMD),
          children: [
            // MY TRY-ON PHOTO SECTION — premium card, soft shadow, persisted for Try-On page
            SettingsSectionCard(
              title: 'My Try-On Photo',
              children: [
                Padding(
                  padding: const EdgeInsets.all(SettingsTheme.spacingMD),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saved here once — Try-On uses it every time. Clear full-body photo works best.',
                        style: TextStyle(
                          color: SettingsTheme.textSecondary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: SettingsTheme.spacingLG),
                      // Rounded card with soft shadow
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: SettingsTheme.backgroundWhite,
                          borderRadius: BorderRadius.circular(SettingsTheme.radiusLG),
                          border: Border.all(
                            color: SettingsTheme.dividerColor,
                            width: 1,
                          ),
                          boxShadow: SettingsTheme.cardShadow,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(SettingsTheme.radiusLG),
                          child: userImageBytes.when(
                            data: (bytes) {
                              if (bytes != null) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(
                                      height: 220,
                                      width: double.infinity,
                                      child: Image.memory(
                                        bytes,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(SettingsTheme.spacingMD),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: userImage.isLoading
                                                  ? null
                                                  : () => _pickAndUploadImage(source: ImageSource.gallery),
                                              icon: const Icon(Icons.photo_library_outlined, size: 20),
                                              label: const Text('Change photo'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: SettingsTheme.primaryBlue,
                                                side: BorderSide(color: SettingsTheme.primaryBlue.withOpacity(0.6)),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: SettingsTheme.spacingSM),
                                          OutlinedButton.icon(
                                            onPressed: userImage.isLoading ? null : _deleteUserImage,
                                            icon: Icon(Icons.delete_outline, size: 20, color: SettingsTheme.error),
                                            label: Text(
                                              'Remove',
                                              style: TextStyle(color: SettingsTheme.error, fontWeight: FontWeight.w500),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: SettingsTheme.error),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return _buildEmptyPhotoPlaceholder(userImage.isLoading);
                            },
                            loading: () => _buildEmptyPhotoPlaceholder(true),
                            error: (error, _) => Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(Icons.error_outline, size: 48, color: SettingsTheme.error),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Couldn’t load image',
                                      style: TextStyle(color: SettingsTheme.error, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: SettingsTheme.spacingMD),
                      // Primary CTA when no photo
                      if (userImage.base64Image == null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: userImage.isLoading ? null : () => _pickAndUploadImage(),
                            icon: const Icon(Icons.add_photo_alternate_outlined, size: 22),
                            label: Text(
                              userImage.isLoading ? 'Saving…' : 'Upload your photo',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SettingsTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(SettingsTheme.radiusSM),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SettingsSectionCard(
              title: 'Body Measurements',
              children: [
                Padding(
                  padding: const EdgeInsets.all(SettingsTheme.spacingMD),
                  child: TextFormField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Height (cm)',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(SettingsTheme.radiusSM),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(SettingsTheme.radiusSM),
                        borderSide: const BorderSide(
                            color: SettingsTheme.primaryBlue, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final height = double.tryParse(value);
                        if (height == null || height < 100 || height > 250) {
                          return 'Please enter a valid height (100-250 cm)';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const Divider(height: 1, color: SettingsTheme.dividerColor),
                Padding(
                  padding: const EdgeInsets.all(SettingsTheme.spacingMD),
                  child: DropdownButtonFormField<String>(
                    value: _selectedBodyType,
                    decoration: InputDecoration(
                      labelText: 'Body Type',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(SettingsTheme.radiusSM),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(SettingsTheme.radiusSM),
                        borderSide: const BorderSide(
                            color: SettingsTheme.primaryBlue, width: 2),
                      ),
                    ),
                    items: _bodyTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedBodyType = value);
                    },
                  ),
                ),
              ],
            ),
            SettingsSectionCard(
              title: 'Preferred Styles',
              children: [
                Padding(
                  padding: const EdgeInsets.all(SettingsTheme.spacingMD),
                  child: Wrap(
                    spacing: SettingsTheme.spacingSM,
                    runSpacing: SettingsTheme.spacingSM,
                    children: _styles.map((style) {
                      final isSelected = _selectedStyles.contains(style);
                      return FilterChip(
                        label: Text(style),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedStyles.add(style);
                            } else {
                              _selectedStyles.remove(style);
                            }
                          });
                        },
                        selectedColor:
                            SettingsTheme.primaryBlue.withOpacity(0.2),
                        checkmarkColor: SettingsTheme.primaryBlue,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            SettingsSectionCard(
              title: 'Color Preferences',
              children: [
                Padding(
                  padding: const EdgeInsets.all(SettingsTheme.spacingMD),
                  child: Wrap(
                    spacing: SettingsTheme.spacingSM,
                    runSpacing: SettingsTheme.spacingSM,
                    children: _colors.map((color) {
                      final isSelected = _selectedColors.contains(color);
                      return FilterChip(
                        label: Text(color),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedColors.add(color);
                            } else {
                              _selectedColors.remove(color);
                            }
                          });
                        },
                        selectedColor:
                            SettingsTheme.primaryBlue.withOpacity(0.2),
                        checkmarkColor: SettingsTheme.primaryBlue,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            SettingsSectionCard(
              title: 'Event Preferences',
              children: [
                Padding(
                  padding: const EdgeInsets.all(SettingsTheme.spacingMD),
                  child: Wrap(
                    spacing: SettingsTheme.spacingSM,
                    runSpacing: SettingsTheme.spacingSM,
                    children: _events.map((event) {
                      final isSelected = _selectedEvents.contains(event);
                      return FilterChip(
                        label: Text(event),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedEvents.add(event);
                            } else {
                              _selectedEvents.remove(event);
                            }
                          });
                        },
                        selectedColor:
                            SettingsTheme.primaryBlue.withOpacity(0.2),
                        checkmarkColor: SettingsTheme.primaryBlue,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SettingsTheme.spacingLG),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SettingsTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: SettingsTheme.spacingMD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SettingsTheme.radiusSM),
                  ),
                ),
                child: const Text('Save Preferences'),
              ),
            ),
            const SizedBox(height: SettingsTheme.spacingXL),
          ],
        ),
      ),
    );
  }
}

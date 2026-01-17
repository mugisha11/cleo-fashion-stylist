import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/settings_theme.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section_card.dart';

class FashionPreferencesScreen extends ConsumerStatefulWidget {
  const FashionPreferencesScreen({super.key});

  @override
  ConsumerState<FashionPreferencesScreen> createState() => _FashionPreferencesScreenState();
}

class _FashionPreferencesScreenState extends ConsumerState<FashionPreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  String? _selectedBodyType;
  final List<String> _bodyTypes = ['Slim', 'Athletic', 'Curvy', 'Plus Size', 'Petite', 'Tall'];
  
  List<String> _selectedStyles = [];
  List<String> _selectedColors = [];
  List<String> _selectedEvents = [];
  
  final List<String> _styles = ['Casual', 'Formal', 'Streetwear', 'Bohemian', 'Minimalist', 'Vintage', 'Sporty'];
  final List<String> _colors = ['Black', 'White', 'Navy', 'Gray', 'Beige', 'Pastels', 'Bright Colors'];
  final List<String> _events = ['Casual', 'Work', 'Party', 'Traditional', 'Wedding', 'Travel'];

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
                        borderRadius: BorderRadius.circular(SettingsTheme.radiusSM),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(SettingsTheme.radiusSM),
                        borderSide: const BorderSide(color: SettingsTheme.primaryBlue, width: 2),
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
                        borderRadius: BorderRadius.circular(SettingsTheme.radiusSM),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(SettingsTheme.radiusSM),
                        borderSide: const BorderSide(color: SettingsTheme.primaryBlue, width: 2),
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
                        selectedColor: SettingsTheme.primaryBlue.withOpacity(0.2),
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
                        selectedColor: SettingsTheme.primaryBlue.withOpacity(0.2),
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
                        selectedColor: SettingsTheme.primaryBlue.withOpacity(0.2),
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
                  padding: const EdgeInsets.symmetric(vertical: SettingsTheme.spacingMD),
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


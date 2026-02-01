import '../../../core/utils/io_stub.dart' if (dart.library.io) 'dart:io' as io;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/utils/file_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/virtualwearon_provider.dart';
import '../services/ready_player_me_service.dart';
import '../../../core/models/wardrobe_item_model.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/platform_image.dart';

/// VirtualWearOn Screen - Professional 3D Avatar with Wardrobe Try-On
/// World-class UI/UX with game-like interactions and animations
class VirtualWearOnScreen extends ConsumerStatefulWidget {
  const VirtualWearOnScreen({super.key});

  @override
  ConsumerState<VirtualWearOnScreen> createState() => _VirtualWearOnScreenState();
}

class _VirtualWearOnScreenState extends ConsumerState<VirtualWearOnScreen>
    with TickerProviderStateMixin {
  static const _logPath = 'd:\\styleapp\\.cursor\\debug.log';
  void _log(String location, String message,
      {Map<String, dynamic>? data,
      String runId = 'run1',
      String hypothesisId = 'H3'}) {
    final payload = jsonEncode({
      'location': location,
      'message': message,
      'data': data ?? {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'sessionId': 'debug-session',
      'runId': runId,
      'hypothesisId': hypothesisId,
    });
    if (!kIsWeb) {
      io.File(_logPath).writeAsStringSync('$payload\n', flush: true);
    } else {
      // ignore: avoid_print
      print(payload);
    }
  }

  final ImagePicker _picker = ImagePicker();
  io.File? _selectedSelfie;
  Uint8List? _selectedSelfieBytes;
  bool _showOnboarding = true;
  BodyMeasurements? _measurements;
  late AnimationController _pulseController;
  late AnimationController _slideController;

  // Onboarding controllers
  final _heightController = TextEditingController(text: '170');
  final _weightController = TextEditingController(text: '70');
  String _selectedBodyType = 'average';
  String _selectedGender = 'non-binary';
  String _selectedStyle = 'casual';
  final _ageController = TextEditingController(text: '25');

  @override
  void initState() {
    _log('virtualwearon_screen.dart:46', 'initState called', hypothesisId: 'H3');
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Defer provider modification until after build completes
    // Use SchedulerBinding to ensure it's completely outside the build phase
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _log('virtualwearon_screen.dart:58',
          'addPostFrameCallback executed for _loadWardrobe',
          hypothesisId: 'H3');
      // Double-defer with Future to ensure we're completely outside build
      Future(() {
    _loadWardrobe();
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadWardrobe() async {
    _log('virtualwearon_screen.dart:72', '_loadWardrobe called', hypothesisId: 'H3');
    await ref.read(virtualWearOnProvider.notifier).loadWardrobe();
  }

  Future<void> _pickSelfie() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedSelfieBytes = bytes;
            _selectedSelfie = null;
          });
        } else {
          setState(() {
            _selectedSelfie = createPlatformFile(image.path) as io.File?;
            _selectedSelfieBytes = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedSelfieBytes = bytes;
            _selectedSelfie = null;
          });
        } else {
          setState(() {
            _selectedSelfie = createPlatformFile(image.path) as io.File?;
            _selectedSelfieBytes = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateAvatar() async {
    _measurements ??= BodyMeasurements(
        height: double.tryParse(_heightController.text) ?? 170.0,
        weight: double.tryParse(_weightController.text) ?? 70.0,
        bodyType: _selectedBodyType,
        gender: _selectedGender,
        stylePreference: _selectedStyle,
        age: int.tryParse(_ageController.text) ?? 25,
      );

    await ref.read(virtualWearOnProvider.notifier).generateAvatar(
      selfieFile: kIsWeb ? _selectedSelfieBytes : _selectedSelfie,
      measurements: _measurements!,
    );

    if (mounted) {
      setState(() {
        _showOnboarding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(virtualWearOnProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Virtual Twin',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          if (!_showOnboarding)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _showOnboarding = true;
                  _selectedSelfie = null;
                  _selectedSelfieBytes = null;
                });
              },
              tooltip: 'Create New Avatar',
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog(context);
            },
            tooltip: 'About Virtual Twin',
          ),
        ],
      ),
      body: _showOnboarding
          ? _buildOnboardingView(context, state, theme, colorScheme)
          : _build3DView(context, state, theme, colorScheme),
    );
  }

  Widget _buildOnboardingView(
    BuildContext context,
    VirtualWearOnState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surface.withOpacity(0.8),
            colorScheme.primary.withOpacity(0.1),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Section
            _buildHeroSection(context, theme, colorScheme)
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: -0.2, end: 0),
            const SizedBox(height: 32),
            // Selfie Upload Section
            _buildSelfieUploadSection(context, theme, colorScheme)
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .scale(begin: const Offset(0.95, 0.95), delay: 200.ms),
            const SizedBox(height: 24),
            // Measurements Section
            _buildMeasurementsSection(context, theme, colorScheme)
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms)
                .slideY(begin: 0.1, end: 0, delay: 300.ms),
            const SizedBox(height: 32),
            // Generate Button
            _buildGenerateButton(context, state, theme, colorScheme)
                .animate()
                .fadeIn(duration: 300.ms, delay: 500.ms)
                .scale(begin: const Offset(0.9, 0.9), delay: 500.ms),
            if (state.error != null) ...[
              const SizedBox(height: 16),
              AppErrorWidget(
                message: state.error!,
                onRetry: _generateAvatar,
              ).animate().fadeIn(duration: 300.ms),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.face_retouching_natural,
            size: 64,
            color: colorScheme.primary,
          ),
        ).animate(onPlay: (controller) => controller.repeat())
            .scale(duration: 2000.ms, begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05))
            .then()
            .scale(duration: 2000.ms, begin: const Offset(1.05, 1.05), end: const Offset(1.0, 1.0)),
        const SizedBox(height: 24),
        Text(
          'Create Your Virtual Twin',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Upload a selfie and provide measurements to generate your personalized 3D avatar',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSelfieUploadSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final hasImage = _selectedSelfieBytes != null || (!kIsWeb && _selectedSelfie != null);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withOpacity(0.9),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.camera_alt, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Upload Selfie (Optional)',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickSelfie,
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasImage
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: hasImage
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: PlatformImage(
                                file: kIsWeb ? null : _selectedSelfie as dynamic, // Never pass file on web; cast to avoid web stub type mismatch
                                bytes: _selectedSelfieBytes,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 72,
                              color: colorScheme.primary.withOpacity(0.6),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tap to take a selfie',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Or select from gallery',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onPressed: _pickSelfie,
                      colorScheme: colorScheme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onPressed: _pickFromGallery,
                      colorScheme: colorScheme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Avatar will be generated even without a photo using your measurements',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildMeasurementsSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.straighten, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Body Measurements',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Height & Weight Row
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementField(
                    context,
                    controller: _heightController,
                    label: 'Height (cm)',
                    icon: Icons.height,
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMeasurementField(
                    context,
                    controller: _weightController,
                    label: 'Weight (kg)',
                    icon: Icons.monitor_weight,
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Body Type
            _buildDropdownField(
              context,
              label: 'Body Type',
              icon: Icons.accessibility_new,
              value: _selectedBodyType,
              items: const [
                DropdownMenuItem(value: 'slim', child: Text('Slim')),
                DropdownMenuItem(value: 'athletic', child: Text('Athletic')),
                DropdownMenuItem(value: 'average', child: Text('Average')),
                DropdownMenuItem(value: 'curvy', child: Text('Curvy')),
                DropdownMenuItem(value: 'plus', child: Text('Plus Size')),
              ],
              onChanged: (value) => setState(() => _selectedBodyType = value ?? 'average'),
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            // Gender
            _buildDropdownField(
              context,
              label: 'Gender',
              icon: Icons.person,
              value: _selectedGender,
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'non-binary', child: Text('Non-Binary')),
              ],
              onChanged: (value) => setState(() => _selectedGender = value ?? 'non-binary'),
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            // Style Preference
            _buildDropdownField(
              context,
              label: 'Style Preference',
              icon: Icons.style,
              value: _selectedStyle,
              items: const [
                DropdownMenuItem(value: 'casual', child: Text('Casual')),
                DropdownMenuItem(value: 'formal', child: Text('Formal')),
                DropdownMenuItem(value: 'streetwear', child: Text('Streetwear')),
                DropdownMenuItem(value: 'sporty', child: Text('Sporty')),
                DropdownMenuItem(value: 'elegant', child: Text('Elegant')),
              ],
              onChanged: (value) => setState(() => _selectedStyle = value ?? 'casual'),
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            // Age
            _buildMeasurementField(
              context,
              controller: _ageController,
              label: 'Age',
              icon: Icons.calendar_today,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildDropdownField(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required ColorScheme colorScheme,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
      ),
      value: value,
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildGenerateButton(
    BuildContext context,
    VirtualWearOnState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: state.isGenerating ? null : _generateAvatar,
        icon: state.isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.auto_awesome, color: Colors.white),
        label: Text(
          state.isGenerating ? 'Generating Avatar...' : 'Generate Virtual Twin',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _build3DView(
    BuildContext context,
    VirtualWearOnState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (state.isGenerating) {
      return _buildLoadingState(context, theme, colorScheme);
    }

    if (state.error != null && state.avatarUrl == null) {
      return _buildErrorState(context, state, theme);
    }

    return Column(
      children: [
        // 3D Avatar Viewer
        Expanded(
          flex: 3,
          child: _build3DAvatarViewer(context, state, theme, colorScheme),
        ),
        // Wardrobe Selection Toolbar
        _buildWardrobeToolbar(context, state, theme, colorScheme),
        // 3D Controls
        _build3DControls(context, state, theme, colorScheme),
      ],
    );
  }

  Widget _build3DAvatarViewer(
    BuildContext context,
    VirtualWearOnState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest,
            colorScheme.surface,
          ],
        ),
      ),
      child: Stack(
        children: [
          // 3D Model Viewer
          Center(
            child: state.modelUrl != null
                ? _build3DViewer(context, state, colorScheme)
                : state.previewUrl != null
                    ? _buildPreviewFallback(context, state, theme)
                    : const Center(child: CircularProgressIndicator()),
          ),
          // Loading overlay
          if (state.isGenerating)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Generating your virtual twin...',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(
          duration: 400.ms,
          begin: const Offset(0.9, 0.9),
        );
  }

  Widget _build3DViewer(
    BuildContext context,
    VirtualWearOnState state,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ModelViewer(
          src: state.modelUrl!,
          alt: '3D Virtual Twin',
          ar: true,
          autoRotate: true,
          cameraControls: true,
          shadowIntensity: state.lightingIntensity,
          exposure: state.lightingIntensity,
          environmentImage: 'neutral',
        ),
      ),
    );
  }

  Widget _buildPreviewFallback(
    BuildContext context,
    VirtualWearOnState state,
    ThemeData theme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.previewUrl != null)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: state.previewUrl!,
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            '3D model loading...',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Preview shown while model loads',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWardrobeToolbar(
    BuildContext context,
    VirtualWearOnState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (state.isLoadingWardrobe) {
      return Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.wardrobeItems.isEmpty) {
      return Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.checkroom_outlined,
                size: 48,
                color: colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No wardrobe items yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add items to your wardrobe to try them on',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.checkroom, color: colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Your Wardrobe',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${state.appliedItems.length} applied',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: state.wardrobeItems.length,
              itemBuilder: (context, index) {
                final item = state.wardrobeItems[index];
                final isApplied = state.appliedItems.contains(item.id);
                return _buildWardrobeItemCard(
                  context,
                  item,
                  isApplied,
                  state,
                  theme,
                  colorScheme,
                );
              },
            ),
          ),
        ],
      ),
    ).animate().slideY(duration: 400.ms, begin: 0.3);
  }

  Widget _buildWardrobeItemCard(
    BuildContext context,
    WardrobeItemModel item,
    bool isApplied,
    VirtualWearOnState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () {
        if (isApplied) {
          ref.read(virtualWearOnProvider.notifier).removeWardrobeItem(item.id);
        } else {
          ref.read(virtualWearOnProvider.notifier).applyWardrobeItem(item);
        }
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isApplied
                ? colorScheme.primary
                : Colors.transparent,
            width: 3,
          ),
          boxShadow: isApplied
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => const SkeletonLoader(
                  width: 120,
                  height: 120,
                ),
                errorWidget: (context, url, error) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.error_outline,
                    color: colorScheme.error,
                  ),
                ),
              ),
            ),
            if (isApplied)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            // Category badge
            Positioned(
              bottom: 6,
              left: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  Widget _build3DControls(
    BuildContext context,
    VirtualWearOnState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom control
          Row(
            children: [
              Icon(Icons.zoom_out, size: 20, color: colorScheme.primary),
              Expanded(
                child: Slider(
                  value: state.zoom,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: 'Zoom: ${state.zoom.toStringAsFixed(1)}x',
                  onChanged: (value) {
                    ref.read(virtualWearOnProvider.notifier).updateZoom(value);
                  },
                ),
              ),
              Icon(Icons.zoom_in, size: 20, color: colorScheme.primary),
            ],
          ),
          const SizedBox(height: 12),
          // Lighting control
          Row(
            children: [
              Icon(Icons.light_mode, size: 20, color: colorScheme.primary),
              Expanded(
                child: Slider(
                  value: state.lightingIntensity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: 'Lighting: ${(state.lightingIntensity * 100).toInt()}%',
                  onChanged: (value) {
                    ref.read(virtualWearOnProvider.notifier).updateLighting(value);
                  },
                ),
              ),
              Icon(Icons.lightbulb, size: 20, color: colorScheme.primary),
            ],
          ),
          const SizedBox(height: 16),
          // Reset button
          OutlinedButton.icon(
            onPressed: () {
              ref.read(virtualWearOnProvider.notifier).resetView();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset View'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(duration: 400.ms, begin: 0.3, delay: 100.ms);
  }

  Widget _buildLoadingState(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Generating your virtual twin...',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few moments',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    VirtualWearOnState state,
    ThemeData theme,
  ) {
    return AppErrorWidget(
      message: state.error ?? 'Failed to generate avatar',
      onRetry: () {
        setState(() {
          _showOnboarding = true;
          _selectedSelfie = null;
          _selectedSelfieBytes = null;
        });
      },
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Virtual Twin'),
        content: const Text(
          'Virtual Twin uses advanced AI and 3D technology to create a personalized avatar from your photo and measurements. You can try on items from your wardrobe and see how they look in 3D.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/vton_service.dart';
import '../providers/vton_provider.dart';

/// Try-on preview screen with before/after slider
class TryOnPreviewScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const TryOnPreviewScreen({super.key, required this.sessionId});

  @override
  ConsumerState<TryOnPreviewScreen> createState() => _TryOnPreviewScreenState();
}

class _TryOnPreviewScreenState extends ConsumerState<TryOnPreviewScreen> {
  double _sliderValue = 0.5;
  bool _isPolling = true;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || !_isPolling) return;
      ref.read(tryonStatusProvider(widget.sessionId).future).then((status) {
        if (status['status'] == 'completed' && mounted) {
          setState(() => _isPolling = false);
        } else if (status['status'] == 'failed' && mounted) {
          setState(() => _isPolling = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Try-on failed: ${status['error_message']}')),
          );
        } else if (mounted) {
          _startPolling();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(tryonStatusProvider(widget.sessionId));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: statusAsync.when(
        data: (status) {
          final resultUrl = status['result_url'] as String?;
          final rawPhotoUrl = status['raw_photo_url'] as String;
          final isCompleted = status['status'] == 'completed';

          return Stack(
            children: [
              // Before/After comparison
              if (isCompleted && resultUrl != null)
                _BeforeAfterSlider(
                  beforeUrl: rawPhotoUrl,
                  afterUrl: resultUrl,
                  sliderValue: _sliderValue,
                  onSliderChanged: (value) => setState(() => _sliderValue = value),
                )
              else
                _ProcessingView(status: status['status'] as String),

              // Bottom actions
              if (isCompleted && resultUrl != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _ActionBar(
                    onSave: () {
                      // Save to wardrobe
                    },
                    onLike: () {
                      ref.read(vtonServiceProvider).submitFeedback(widget.sessionId, 'like');
                    },
                    onDislike: () {
                      ref.read(vtonServiceProvider).submitFeedback(widget.sessionId, 'dislike');
                    },
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class _BeforeAfterSlider extends StatelessWidget {
  final String beforeUrl;
  final String afterUrl;
  final double sliderValue;
  final ValueChanged<double> onSliderChanged;

  const _BeforeAfterSlider({
    required this.beforeUrl,
    required this.afterUrl,
    required this.sliderValue,
    required this.onSliderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Before image (full)
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: beforeUrl,
            fit: BoxFit.contain,
          ),
        ),
        // After image (revealed by slider)
        Positioned.fill(
          child: ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: sliderValue,
              child: CachedNetworkImage(
                imageUrl: afterUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        // Slider handle
        Positioned(
          left: MediaQuery.of(context).size.width * sliderValue - 20,
          top: 0,
          bottom: 0,
          child: GestureDetector(
            onPanUpdate: (details) {
              final newValue = (details.localPosition.dx / MediaQuery.of(context).size.width)
                  .clamp(0.0, 1.0);
              onSliderChanged(newValue);
            },
            child: Container(
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.drag_handle, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProcessingView extends StatelessWidget {
  final String status;

  const _ProcessingView({required this.status});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 24),
          Text(
            status == 'processing' ? 'Processing your try-on...' : 'Preparing...',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take 20-60 seconds',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onLike;
  final VoidCallback onDislike;

  const _ActionBar({
    required this.onSave,
    required this.onLike,
    required this.onDislike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(
              icon: Icons.close,
              label: 'Dislike',
              color: Colors.red,
              onTap: onDislike,
            ),
            _ActionButton(
              icon: Icons.save_alt,
              label: 'Save',
              color: Colors.blue,
              onTap: onSave,
            ),
            _ActionButton(
              icon: Icons.favorite,
              label: 'Like',
              color: Colors.green,
              onTap: onLike,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}

